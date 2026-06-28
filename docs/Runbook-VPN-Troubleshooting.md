# Runbook: Troubleshooting VPN Connectivity Issues

**Document type:** Troubleshooting Runbook
**Owner:** IT Support
**Audience:** Level 1 / Level 2 support engineers
**Last reviewed:** 2026

---

## Purpose

A structured, repeatable process for diagnosing and resolving remote-user VPN connection problems, ordered from the most common and least disruptive checks to the more advanced. Following the order keeps resolution fast and consistent and reduces escalations.

## Scope

Applies to remote users connecting to corporate resources over VPN (client-to-site). Tool-agnostic; applies to common clients such as the built-in Windows client, OpenVPN, or vendor clients.

---

## Triage: gather this first

Before changing anything, capture:

- What exact error message appears (screenshot if possible)?
- When did it last work? What changed (new network, password change, update)?
- Is the user on home Wi-Fi, mobile hotspot, or a public network?
- Does it affect one user or several? (Several = likely server-side.)

---

## Resolution steps (work top to bottom)

### Step 1 — Confirm basic internet connectivity
The VPN cannot connect if the underlying connection is down.
- Have the user open a website without VPN.
- If no internet: resolve the local connection first (see Wi-Fi/LAN runbook).

### Step 2 — Verify credentials and account state
- Confirm the username/password is correct and not recently expired.
- Check the account is not disabled or locked in Entra ID / AD.
- If MFA is required for VPN, confirm the user completes the prompt.

### Step 3 — Restart the VPN client and adapter
- Fully close and reopen the VPN client.
- Disable and re-enable the network adapter, or restart the device.
- Many transient failures clear here.

### Step 4 — Check for IP / DNS conflicts
- A home network using the same subnet as the corporate network (e.g. `192.168.1.0/24`) can cause routing conflicts. If so, advise changing the home router's LAN subnet.
- Flush DNS: `ipconfig /flushdns`.
- Confirm the client receives a valid VPN-assigned IP once connected.

### Step 5 — Inspect firewall / security software
- Local firewalls or third-party antivirus can block VPN ports/protocols.
- Temporarily test with the security software's VPN/blocking feature disabled (re-enable immediately after).
- Confirm required ports are open (depends on protocol, e.g. UDP 1194 for OpenVPN, UDP 500/4500 for IKEv2).

### Step 6 — Validate server-side (if multiple users affected)
- Check VPN gateway/service status.
- Confirm the user's account is in the correct access group.
- Review server logs for rejected connections or capacity limits.

### Step 7 — Test from a known-good network
- Have the user try a mobile hotspot. If it works there, the problem is the original network (ISP, router, or firewall), not the VPN or the account.

---

## Escalation criteria

Escalate to L2/L3 or network team when:
- Multiple users are affected simultaneously (server/gateway issue).
- Server logs show authentication or certificate errors at the gateway.
- The issue persists after all client-side steps and from a known-good network.

Include in the escalation: the triage answers, the exact error, which steps were tried, and the result of the known-good-network test.

---

## Verification

- User connects successfully and can reach an internal resource (e.g. a file share or intranet page).
- Connection remains stable for several minutes without dropping.

---

*This runbook reflects standard troubleshooting practice and contains no organization-specific or confidential data.*
