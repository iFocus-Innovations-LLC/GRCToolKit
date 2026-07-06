# Ansible Audit Command Matrix

Maps NIST control validation tasks to **read-only** commands for the `grc-audit` service account and [`/etc/sudoers.d/grc-audit`](../templates/sudoers.d/grc-audit) allow-list.

**Profile:** `grc_audit_mode: read_only` ([`ansible/playbooks/group_vars/all.yml`](../playbooks/group_vars/all.yml))

**Wrapper scripts:** [`ansible/scripts/grc-audit-probes/`](../scripts/grc-audit-probes/) → deploy to `/usr/local/sbin/`

---

## AC-3 Access Enforcement

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| AC-3.1 sshd | `/bin/systemctl is-active sshd` | Often yes | `grc-audit-ac-3` |
| AC-3.1 PAM | `/usr/bin/stat /etc/pam.d/system-auth` | No (read) | playbook `stat` |
| AC-3.3 sudoers | `/usr/bin/stat /etc/sudoers` | No (read mode 0440) | `grc-audit-ac-3` |
| AC-3.4 auditd | `/bin/systemctl is-active auditd` | Often yes | `grc-audit-ac-3` |
| AC-3.4 rules | `/usr/bin/stat /etc/audit/rules.d/audit.rules` | No (read) | `grc-audit-ac-3` |

**Removed (mutating):** `systemd: state: started`, `acl: state: present`, `file: mode:` on `/etc/sudoers`

---

## AC-6 Least Privilege

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| AC-6.1 NOPASSWD | `/usr/bin/grep -E '^[^#]*NOPASSWD' /etc/sudoers` | No (read) | `grc-audit-ac-6` |
| AC-6.1 root UIDs | `/usr/bin/awk -F: '$3==0 {print $1}' /etc/passwd` | No | `grc-audit-ac-6` |
| AC-6.3 world-writable | `/usr/bin/find /etc /var/log /usr/local -xdev -type f -perm -002` | Often yes | `grc-audit-ac-6` |
| AC-6.3 SUID/SGID | `/usr/bin/find ... -perm -4000 -o -perm -2000` (scoped) | Often yes | `grc-audit-ac-6` |
| AC-6.4 root procs | `/bin/ps aux` + awk filter | Often yes | playbook |

**Scoped paths:** `grc_audit_find_paths` in group_vars (not `find /`)

**Removed:** `systemd: state: stopped` on telnet/rsh/ftp

---

## AU-2 Audit Events

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| AU-2.1 auditd | `/bin/systemctl is-active auditd` | Often yes | `grc-audit-au-2` |
| AU-2.2 rules count | `/usr/bin/grep -c '^[^#]' /etc/audit/rules.d/audit.rules` | No | `grc-audit-au-2` |
| AU-2.3 log files | `/usr/bin/find /var/log/audit -maxdepth 1 -name 'audit.log*'` | No (group read) | `grc-audit-au-2` |
| AU-2.4 log perms | `/usr/bin/stat /var/log/audit/audit.log` | No (group read) | `grc-audit-au-2` |
| AU-2.5 auditd.conf | `/usr/bin/grep -cE '^[^#].*=' /etc/audit/auditd.conf` | No | playbook |

**Removed:** `systemd: state: started` on auditd

---

## SC-7 Boundary Protection

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| SC-7.1 iptables | `/bin/systemctl is-active iptables` | Often yes | `grc-audit-sc-7` |
| SC-7.1 ufw | `/bin/systemctl is-active ufw` | Often yes | `grc-audit-sc-7` |
| SC-7.2 iptables rules | `/usr/sbin/iptables -L` | Yes | `grc-audit-sc-7` |
| SC-7.2 ufw status | `/usr/sbin/ufw status` | Yes | `grc-audit-sc-7` |
| SC-7.3 interfaces | `/usr/sbin/ip link show` | Often yes | `grc-audit-sc-7` |
| SC-7.4 config files | `/usr/bin/stat` on `/etc/iptables/rules.v4`, etc. | No | playbook |

**Removed:** `systemd: state: started` on firewall units

---

## Sudoers summary

```sudoers
Cmnd_Alias GRC_AUDIT = /usr/local/sbin/grc-audit-ac-3, \
                        /usr/local/sbin/grc-audit-ac-6, \
                        /usr/local/sbin/grc-audit-au-2, \
                        /usr/local/sbin/grc-audit-sc-7
grc-audit ALL=(root) NOPASSWD: GRC_AUDIT
```

Full template: [`ansible/templates/sudoers.d/grc-audit`](../templates/sudoers.d/grc-audit)

---

## ITIL change metadata

Set before running wrappers:

```bash
export GRCTOOLKIT_CHANGE_ID="CHG-2026-001"
sudo -u grc-audit /usr/local/sbin/grc-audit-au-2
```

Evidence JSON includes `change_id` for auditor correlation.

---

## Related docs

- [ANSIBLE-AUDIT-OPERATIONS.md](ANSIBLE-AUDIT-OPERATIONS.md)
- [inventory.production.example.yml](../playbooks/inventory.production.example.yml)
