<#
.SYNOPSIS
    Automates secure employee offboarding in Microsoft 365 / Entra ID.

.DESCRIPTION
    Performs the standard offboarding steps for a departing user:
      1. Blocks sign-in immediately (disables the account).
      2. Revokes all active sessions / refresh tokens.
      3. Converts the mailbox to shared (optional) so colleagues retain access.
      4. Removes the user from all groups.
      5. Reclaims the assigned license(s).
      6. Optionally forwards incoming mail to a manager.

    Designed to make offboarding fast, consistent, and auditable, closing the
    security gap that manual offboarding often leaves open.

.NOTES
    Author : Sameer Akram
    Modules: Microsoft.Graph, ExchangeOnlineManagement
    Scope   : Reference / portfolio script. Test in a non-production tenant.
              Converting a mailbox to shared requires ExchangeOnline.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory)] [string]  $UserPrincipalName,
    [Parameter()]          [string]  $ForwardTo,                 # manager's UPN (optional)
    [Parameter()]          [switch]  $ConvertMailboxToShared
)

function Connect-GraphIfNeeded {
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes @(
            "User.ReadWrite.All",
            "Group.ReadWrite.All",
            "Directory.AccessAsUser.All"
        ) | Out-Null
    }
}

try {
    Connect-GraphIfNeeded
    $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
    Write-Host "Offboarding: $($user.DisplayName) <$UserPrincipalName>" -ForegroundColor Cyan

    # --- 1. Block sign-in -----------------------------------------------------
    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Block sign-in")) {
        Update-MgUser -UserId $user.Id -AccountEnabled:$false
        Write-Host "Sign-in blocked." -ForegroundColor Green
    }

    # --- 2. Revoke active sessions -------------------------------------------
    if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Revoke all sessions")) {
        Revoke-MgUserSignInSession -UserId $user.Id | Out-Null
        Write-Host "All active sessions revoked." -ForegroundColor Green
    }

    # --- 3. Remove from all groups -------------------------------------------
    $memberships = Get-MgUserMemberOf -UserId $user.Id -All |
        Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group' }

    foreach ($m in $memberships) {
        $groupName = $m.AdditionalProperties['displayName']
        if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Remove from group $groupName")) {
            try {
                Remove-MgGroupMemberByRef -GroupId $m.Id -DirectoryObjectId $user.Id -ErrorAction Stop
                Write-Host "Removed from group: $groupName" -ForegroundColor Green
            }
            catch {
                Write-Warning "Could not remove from '$groupName' (may be dynamic/sync-managed): $($_.Exception.Message)"
            }
        }
    }

    # --- 4. Reclaim licenses --------------------------------------------------
    $licenses = Get-MgUserLicenseDetail -UserId $user.Id
    if ($licenses) {
        $skuIds = $licenses.SkuId
        if ($PSCmdlet.ShouldProcess($UserPrincipalName, "Remove licenses")) {
            Set-MgUserLicense -UserId $user.Id -AddLicenses @() -RemoveLicenses $skuIds | Out-Null
            Write-Host "Reclaimed $($skuIds.Count) license(s)." -ForegroundColor Green
        }
    }

    # --- 5. Mailbox handling (Exchange Online) --------------------------------
    if ($ConvertMailboxToShared -or $ForwardTo) {
        if (-not (Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
            Connect-ExchangeOnline -ShowBanner:$false
        }
        if ($ConvertMailboxToShared -and $PSCmdlet.ShouldProcess($UserPrincipalName, "Convert mailbox to shared")) {
            Set-Mailbox -Identity $UserPrincipalName -Type Shared
            Write-Host "Mailbox converted to shared." -ForegroundColor Green
        }
        if ($ForwardTo -and $PSCmdlet.ShouldProcess($UserPrincipalName, "Forward mail to $ForwardTo")) {
            Set-Mailbox -Identity $UserPrincipalName -ForwardingAddress $ForwardTo -DeliverToMailboxAndForward $false
            Write-Host "Mail forwarding set to: $ForwardTo" -ForegroundColor Green
        }
    }

    Write-Host "`nOffboarding complete for $UserPrincipalName." -ForegroundColor Cyan
}
catch {
    Write-Error "Offboarding failed: $($_.Exception.Message)"
}
