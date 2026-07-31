# Ansible Audit Command Matrix

Maps NIST control validation tasks to **read-only** commands for the `grc-audit` service account and [`/etc/sudoers.d/grc-audit`](../templates/sudoers.d/grc-audit) allow-list.

**Profile:** `grc_audit_mode: read_only` ([`ansible/playbooks/group_vars/all.yml`](../playbooks/group_vars/all.yml))

**OS / K8s paths:** Playbooks resolve config locations via [`tasks/load_platform_vars.yml`](../playbooks/tasks/load_platform_vars.yml) and [`vars/platform/`](../playbooks/vars/platform/) (not hardcoded `/etc/...` alone). Commands below show typical Linux paths; Darwin/Alpine/RedHat overlays may differ.

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

## Purple-team validation pack (v1 — playbook probes; sudo wrappers TBD)

These controls use **read-only** playbook tasks on lab localhost (`grc_audit_become: false`). Production `grc-audit-*` wrappers / sudoers entries for this pack are **deferred** pending sysadmin review.

### AC-2 Account Management

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| UID 0 count | `awk -F: '$3==0 {print $1}' /etc/passwd` | No | playbook |
| passwd inventory | `wc -l /etc/passwd` | No | playbook |
| nologin shells | `awk` on `/etc/passwd` | No | playbook |
| shadow presence | `/usr/bin/stat /etc/shadow` | Often for content | TBD |

### IA-2 Identification and Authentication

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| sshd_config | `stat` / `grep` PasswordAuthentication, PubkeyAuthentication, PermitRootLogin | No | playbook |
| PAM sshd/login | `stat /etc/pam.d/sshd` or `/etc/pam.d/login` | No | playbook |

### IA-5 Authenticator Management

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| login.defs | `grep PASS_MAX_DAYS\|PASS_MIN_LEN /etc/login.defs` | No | playbook |
| pwquality | `stat /etc/security/pwquality.conf` | No | playbook |
| Darwin | `which pwpolicy` (managed Mac policies separate) | No | playbook |

### AU-3 Content of Audit Records

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| audit rules | `grep -cE '^[^#]' /etc/audit/rules.d/audit.rules` | No | playbook |
| content keywords | `grep -Ei 'identity\|auth\|logon' ...` | No | playbook |

### AU-12 Audit Generation

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| auditd | `/bin/systemctl is-active auditd` | Often yes | TBD |
| rsyslog | `/bin/systemctl is-active rsyslog` | Often yes | TBD |
| log paths | `stat /var/log/auth.log`, `/var/log/secure`, `/var/log` | No | playbook |

### CM-6 Configuration Settings

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| sysctl samples | `sysctl -n net.ipv4.ip_forward` (etc.) | No | playbook |
| sshd MaxAuthTries / Protocol | `grep` on `/etc/ssh/sshd_config` | No | playbook |

**Never applies** sysctl or sshd changes.

### CM-7 Least Functionality

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| risky units | `systemctl is-active telnet\|vsftpd\|...` | Often yes | TBD |
| process heuristics | `ps aux \| grep -Eiw 'telnetd\|vsftpd\|...'` | No | playbook |

**Removed / forbidden:** stopping or disabling services.

### SC-8 Transmission Confidentiality

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| sshd crypto | `grep Ciphers\|MACs\|KexAlgorithms /etc/ssh/sshd_config` | No | playbook |
| OpenSSL | `openssl version` | No | playbook |
| TLS server configs | `stat` nginx/apache/openssl.cnf | No | playbook |

### SC-28 Protection of Information at Rest

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| Darwin FileVault | `fdesetup status` | Often yes | TBD |
| Linux LUKS | `which cryptsetup`; `lsblk` crypto/luks lines | No / often | TBD |
| sensitive paths | `stat /etc/shadow`, `~/.ssh` | No | playbook |

### SI-4 System Monitoring

| Task | Read-only command | Sudo required | Wrapper |
|------|-------------------|---------------|---------|
| agent bins | `which rsyslogd\|osqueryd\|auditd\|...` | No | playbook |
| units | `systemctl is-active rsyslog\|auditd\|osqueryd` | Often yes | TBD |
| `/var/log` | `stat` / `find -maxdepth 1` | No | playbook |

**Never installs or starts** monitoring agents.

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
