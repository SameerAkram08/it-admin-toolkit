# IT Administration Toolkit & Documentation

A portfolio of PowerShell automation and operational documentation for Microsoft 365, Entra ID (Azure AD), and Windows environments, drawn from real IT support and systems administration practice.

> All scripts and documents are sanitized reference material. They contain no client names, credentials, tenant identifiers, or confidential data. Group names, SKUs, and similar values are placeholders to be set per environment.

---

## Scripts

| Script | What it does |
|---|---|
| [`New-EmployeeOnboarding.ps1`](./scripts/New-EmployeeOnboarding.ps1) | Creates an Entra ID user, assigns a license, adds department-based groups, and enforces MFA on first sign-in. Standardizes onboarding. |
| [`Remove-EmployeeAccess.ps1`](./scripts/Remove-EmployeeAccess.ps1) | Secure offboarding: blocks sign-in, revokes sessions, removes group membership, reclaims licenses, and handles the mailbox. |
| [`Get-M365LicenseReport.ps1`](./scripts/Get-M365LicenseReport.ps1) | Read-only license utilization report; flags blocked accounts still holding licenses to reduce wasted spend. |

**Requirements:** PowerShell 5.1 / 7+, `Microsoft.Graph` module (and `ExchangeOnlineManagement` for mailbox operations). Test in a non-production tenant first.

## Documentation

| Document | Purpose |
|---|---|
| [`SOP-Entra-MFA-Conditional-Access.md`](./docs/SOP-Entra-MFA-Conditional-Access.md) | Step-by-step procedure to enforce MFA via Conditional Access, including pilot, report-only validation, and break-glass safety. |
| [`Runbook-VPN-Troubleshooting.md`](./docs/Runbook-VPN-Troubleshooting.md) | Ordered diagnostic process for remote-user VPN issues, with escalation criteria. |

---

## About

Maintained by **Sameer Akram**, IT Support Engineer specializing in Microsoft 365 and Entra ID administration.
📧 sameerakramwork44@gmail.com · [LinkedIn](https://www.linkedin.com/in/sameer0811)
