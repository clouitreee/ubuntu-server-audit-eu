# L3 Identity, SSH, Sudo, And MFA

Goal: understand human/service identities, privilege paths, SSH posture, active sessions, login anomalies, and MFA evidence.

## Read-Only Checks

```bash
getent passwd
grep -vE ':(/usr/sbin/nologin|/sbin/nologin|/bin/false)$' /etc/passwd 2>/dev/null
getent group sudo adm docker lxd systemd-journal 2>/dev/null
grep -R '^[^#].*ALL=' /etc/sudoers /etc/sudoers.d 2>/dev/null
sshd -T 2>/dev/null | egrep 'permitrootlogin|passwordauthentication|pubkeyauthentication|authorizedkeysfile|kexalgorithms|hostkeyalgorithms|pubkeyacceptedalgorithms|authenticationmethods|permitemptypasswords|maxauthtries'
grep -nE '^[[:space:]]*(PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AuthorizedKeysFile|KexAlgorithms|HostKeyAlgorithms|PubkeyAcceptedAlgorithms|AuthenticationMethods|PermitEmptyPasswords|MaxAuthTries)' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/* 2>/dev/null
command -v ssh-audit 2>/dev/null
grep -RInE 'pam_google_authenticator|pam_oath|pam_u2f|pam_duo|auth required|AuthenticationMethods' /etc/pam.d /etc/ssh 2>/dev/null
last -n 20
lastlog
who
w
ss -tnp 2>/dev/null | grep ':22' || true
find /home /root -maxdepth 3 -name authorized_keys -type f -printf '%p %u %g %m %TY-%Tm-%Td %TH:%TM\n' 2>/dev/null
```

## Interpretation

- Report users with active shells, privileged groups, sudoers, Docker/LXD access, and login history.
- Report SSH algorithms explicitly: Ed25519/ECDSA/RSA, RSA allowance, and whether RSA strength can be inferred.
- `sshd -T` may be blocked by unreadable host keys; mark effective config as `partial/blocked` and use config files as evidence.
- Report `AuthorizedKeysFile` paths and whether they are standard.
- Report MFA/PAM/TOTP as `present`, `absent`, `partial`, or `blocked`.
- If `ssh-audit` is already installed locally or remotely, it may be used as a read-only SSH protocol probe. Do not install it.

Do not print private keys or full authorized key material unless explicitly requested; metadata and counts are enough.
