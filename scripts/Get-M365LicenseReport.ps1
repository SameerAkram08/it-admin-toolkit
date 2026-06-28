<#
.SYNOPSIS
    Generates a Microsoft 365 license utilization report.

.DESCRIPTION
    Connects to Microsoft Graph, retrieves all subscribed SKUs, and reports
    how many licenses are assigned versus available for each. Also flags
    disabled (blocked) accounts that still hold licenses, which are a common
    source of wasted spend. Exports the result to CSV for review or chargeback.

    Useful for cost control and for keeping license assignment clean across
    multi-site tenants.

.NOTES
    Author : Sameer Akram
    Modules: Microsoft.Graph
    Scope   : Read-only. Safe to run in production (no changes are made).
#>

[CmdletBinding()]
param(
    [Parameter()] [string] $ExportPath = ".\M365-License-Report.csv"
)

function Connect-GraphIfNeeded {
    if (-not (Get-MgContext)) {
        Connect-MgGraph -Scopes @("Organization.Read.All", "User.Read.All") | Out-Null
    }
}

try {
    Connect-GraphIfNeeded

    # --- Per-SKU utilization --------------------------------------------------
    $skus = Get-MgSubscribedSku
    $report = foreach ($sku in $skus) {
        $enabled  = $sku.PrepaidUnits.Enabled
        $consumed = $sku.ConsumedUnits
        [pscustomobject]@{
            License        = $sku.SkuPartNumber
            Total          = $enabled
            Assigned       = $consumed
            Available      = $enabled - $consumed
            PercentUsed    = if ($enabled -gt 0) { [math]::Round(($consumed / $enabled) * 100, 1) } else { 0 }
        }
    }

    Write-Host "`n=== Microsoft 365 License Utilization ===" -ForegroundColor Cyan
    $report | Sort-Object PercentUsed -Descending | Format-Table -AutoSize

    # --- Flag disabled accounts still holding licenses ------------------------
    Write-Host "Checking for blocked accounts that still hold licenses..." -ForegroundColor Yellow
    $licensedDisabled = Get-MgUser -Filter "accountEnabled eq false" -All `
                          -Property "displayName,userPrincipalName,assignedLicenses,accountEnabled" |
        Where-Object { $_.AssignedLicenses.Count -gt 0 } |
        Select-Object DisplayName, UserPrincipalName,
                      @{ N = "LicenseCount"; E = { $_.AssignedLicenses.Count } }

    if ($licensedDisabled) {
        Write-Host "Blocked accounts wasting licenses (reclaim candidates):" -ForegroundColor Red
        $licensedDisabled | Format-Table -AutoSize
    }
    else {
        Write-Host "No blocked accounts are holding licenses. Clean." -ForegroundColor Green
    }

    # --- Export ---------------------------------------------------------------
    $report | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Report exported to: $ExportPath" -ForegroundColor Green
}
catch {
    Write-Error "License report failed: $($_.Exception.Message)"
}
