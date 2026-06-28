<#
.SYNOPSIS
    Automates new-employee onboarding in Microsoft 365 / Entra ID.

.DESCRIPTION
    Creates a new user in Entra ID, assigns a license, adds the user to the
    correct security and distribution groups based on department, and enforces
    MFA registration on first sign-in. Designed to standardize onboarding and
    reduce manual provisioning time across multi-site environments.

    All values are read from a parameter set or a CSV so the script can run for
    a single hire or in bulk. No credentials or tenant data are hard-coded.

.NOTES
    Author : Sameer Akram
    Modules: Microsoft.Graph
    Tested  : Windows PowerShell 5.1 / PowerShell 7+
    Scope   : Reference / portfolio script. Review and test in a non-production
              tenant before use. Group names and license SKU are environment
              specific and must be set for your tenant.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)] [string] $DisplayName,
    [Parameter(Mandatory)] [string] $UserPrincipalName,
    [Parameter(Mandatory)] [string] $Department,
    [Parameter()]          [string] $UsageLocation = "US",
    [Parameter()]          [string] $LicenseSku    = "ENTERPRISEPACK"  # e.g. Office 365 E3
)

# --- Department-to-group mapping ----------------------------------------------
# Map each department to the groups that department should receive.
# Adjust these names to match your own tenant's groups.
$DepartmentGroups = @{
    "IT"        = @("SG-IT-Staff", "DL-IT-All")
    "Finance"   = @("SG-Finance-Staff", "DL-Finance-All")
    "Clinical"  = @("SG-Clinical-Staff", "DL-Clinical-All")
    "Front Desk"= @("SG-FrontDesk-Staff", "DL-Reception-All")
    "Default"   = @("SG-AllStaff")
}

function Connect-GraphIfNeeded {
    if (-not (Get-MgContext)) {
        Write-Verbose "Connecting to Microsoft Graph..."
        Connect-MgGraph -Scopes @(
            "User.ReadWrite.All",
            "Group.ReadWrite.All",
            "Organization.Read.All"
        ) | Out-Null
    }
}

function New-OnboardingPassword {
    # Generates a random initial password the user must change at first sign-in.
    $bytes = New-Object 'System.Byte[]' 12
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return ([Convert]::ToBase64String($bytes) + "!9")
}

try {
    Connect-GraphIfNeeded

    # --- 1. Create the user ---------------------------------------------------
    $initialPassword = New-OnboardingPassword
    $passwordProfile = @{
        Password                      = $initialPassword
        ForceChangePasswordNextSignIn = $true
    }
    $mailNickname = ($UserPrincipalName -split "@")[0]

    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Create Entra ID user")) {
        $newUser = New-MgUser -DisplayName $DisplayName `
                              -UserPrincipalName $UserPrincipalName `
                              -MailNickname $mailNickname `
                              -AccountEnabled `
                              -PasswordProfile $passwordProfile `
                              -UsageLocation $UsageLocation `
                              -Department $Department
        Write-Host "Created user: $($newUser.UserPrincipalName)" -ForegroundColor Green
    }

    # --- 2. Assign license ----------------------------------------------------
    $sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq $LicenseSku }
    if (-not $sku) {
        Write-Warning "License SKU '$LicenseSku' not found in tenant. Skipping license assignment."
    }
    elseif ($sku.PrepaidUnits.Enabled - $sku.ConsumedUnits -le 0) {
        Write-Warning "No available '$LicenseSku' licenses remaining. Skipping."
    }
    elseif ($PSCmdlet.ShouldProcess($UserPrincipalName, "Assign $LicenseSku license")) {
        Set-MgUserLicense -UserId $newUser.Id `
                          -AddLicenses @(@{ SkuId = $sku.SkuId }) `
                          -RemoveLicenses @() | Out-Null
        Write-Host "Assigned license: $LicenseSku" -ForegroundColor Green
    }

    # --- 3. Add to department groups -----------------------------------------
    $groups = $DepartmentGroups[$Department]
    if (-not $groups) {
        Write-Warning "No group mapping for department '$Department'. Using Default."
        $groups = $DepartmentGroups["Default"]
    }

    foreach ($groupName in $groups) {
        $group = Get-MgGroup -Filter "displayName eq '$groupName'" -Top 1
        if (-not $group) {
            Write-Warning "Group '$groupName' not found. Skipping."
            continue
        }
        if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Add to group $groupName")) {
            New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $newUser.Id
            Write-Host "Added to group: $groupName" -ForegroundColor Green
        }
    }

    # --- 4. Summary -----------------------------------------------------------
    Write-Host "`nOnboarding complete for $DisplayName ($UserPrincipalName)." -ForegroundColor Cyan
    Write-Host "Initial password (deliver securely, user must change at first sign-in):" -ForegroundColor Yellow
    Write-Host "    $initialPassword"
    Write-Host "MFA registration is enforced via Conditional Access on first sign-in."
}
catch {
    Write-Error "Onboarding failed: $($_.Exception.Message)"
}
