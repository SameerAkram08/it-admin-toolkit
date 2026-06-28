# SOP: Configuring MFA and Conditional Access in Microsoft Entra ID

**Document type:** Standard Operating Procedure
**Owner:** IT Support / Identity Administration
**Audience:** IT support engineers, systems administrators
**Last reviewed:** 2026

---

## Purpose

This procedure describes how to enforce multi-factor authentication (MFA) for users in Microsoft Entra ID using Conditional Access, the recommended modern method. It replaces the legacy per-user MFA approach and gives granular, policy-based control over when and how MFA is required.

## Scope

Applies to all cloud and hybrid identities in the tenant. Conditional Access requires Entra ID P1 or higher.

## Prerequisites

- Entra ID P1/P2 licensing for targeted users
- An account with at least the **Conditional Access Administrator** or **Security Administrator** role
- A defined pilot group before tenant-wide rollout
- A documented break-glass (emergency access) account that is **excluded** from all Conditional Access policies

---

## Procedure

### 1. Create a pilot group

1. In the Entra admin center, go to **Groups > New group**.
2. Create a security group named `CA-MFA-Pilot`.
3. Add a small set of test users before enforcing tenant-wide.

### 2. Verify the break-glass account exclusion

Before enabling any policy, confirm at least one emergency access account exists and will be excluded. Locking every administrator out is the most common Conditional Access failure.

### 3. Create the Conditional Access policy

1. Go to **Protection > Conditional Access > Policies > New policy**.
2. Name it clearly, e.g. `CA01 - Require MFA for All Users`.
3. **Assignments > Users:**
   - Include: the pilot group (later, *All users*).
   - Exclude: the break-glass account and any service accounts that cannot do MFA.
4. **Target resources:** Select *All cloud apps* (or scope to specific apps for a phased rollout).
5. **Grant:** Select **Grant access > Require multifactor authentication**.
6. **Enable policy:** Set to **Report-only** first.

### 4. Validate in report-only mode

Leave the policy in **Report-only** for several days. Review sign-in logs under **Monitoring > Sign-in logs** and check the **Report-only** tab to confirm the policy would apply correctly and would not block legitimate access.

### 5. Enforce

1. Once validated, edit the policy and set **Enable policy** to **On**.
2. Expand the assignment from the pilot group to **All users** (keeping exclusions).
3. Communicate to users in advance and provide MFA registration guidance.

### 6. Drive MFA registration

Encourage users to register methods at `https://aka.ms/mfasetup`. For new accounts, registration is enforced at first sign-in. Prefer the Microsoft Authenticator app over SMS for security.

---

## Verification

- A targeted user is prompted for MFA at next sign-in.
- The break-glass account is **not** prompted and retains access.
- Sign-in logs show the policy applied as expected.

## Rollback

If the policy causes unexpected lockouts, set **Enable policy** to **Off**. Because the break-glass account is excluded, an administrator can always sign in to disable the policy.

## Common issues

| Symptom | Likely cause | Resolution |
|---|---|---|
| Admins locked out | No exclusion configured | Use break-glass account to disable policy |
| User not prompted | User outside assignment scope | Confirm group membership |
| Legacy app fails | App uses legacy authentication | Block legacy auth separately; use app passwords only if unavoidable |

---

*This runbook reflects standard administrative practice and contains no organization-specific or confidential data.*
