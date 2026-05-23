# L4 Network Exposure, Firewall, Fail2Ban, DNS, And Time

Goal: every listening port has an owner and justification; firewall, egress, Fail2Ban, DNS, and forensic time posture are visible.

## Read-Only Checks

```bash
ip -br addr
ip route
ss -tulpen
ss -tnp state established 2>/dev/null
ufw status verbose 2>/dev/null
nft list ruleset 2>/dev/null
iptables -S 2>/dev/null
iptables -L -n -v 2>/dev/null
ip6tables -S 2>/dev/null
systemctl status fail2ban --no-pager 2>/dev/null
fail2ban-client status 2>/dev/null
find /etc/fail2ban -maxdepth 3 -type f -printf '%p %u %g %m %TY-%Tm-%Td\n' 2>/dev/null
resolvectl status 2>/dev/null || cat /etc/resolv.conf
systemctl status systemd-resolved dnsmasq bind9 unbound --no-pager 2>/dev/null
timedatectl status 2>/dev/null
chronyc tracking 2>/dev/null
ntpq -p 2>/dev/null
systemctl status chrony systemd-timesyncd ntp --no-pager 2>/dev/null
```

## Interpretation

- Classify exposure as `public`, `private`, `loopback`, or `unknown` where possible.
- Report nftables and iptables separately; call out coexistence or inconsistent visibility.
- Egress filtering must be explicitly classified as `present`, `absent`, `unknown`, or `blocked`.
- Fail2Ban jail/bans often require root; mark `partial` if service is active but client status is blocked.
- NTP/time synchronization is evidence quality for incident response and legal traceability.
