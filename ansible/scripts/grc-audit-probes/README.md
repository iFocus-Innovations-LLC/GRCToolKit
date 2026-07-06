# Install grc-audit probe wrappers on target hosts (SysAdmin)

```bash
# From GRCToolKit repo on jump host or config management
sudo install -m 0755 -o root -g root \
  ansible/scripts/grc-audit-probes/grc-audit-ac-3 \
  ansible/scripts/grc-audit-probes/grc-audit-ac-6 \
  ansible/scripts/grc-audit-probes/grc-audit-au-2 \
  ansible/scripts/grc-audit-probes/grc-audit-sc-7 \
  /usr/local/sbin/
sudo install -m 0644 -o root -g root \
  ansible/scripts/grc-audit-probes/common.sh \
  /usr/local/sbin/grc-audit-probes-common.sh
```

Scripts output JSON to stdout. Set `GRCTOOLKIT_CHANGE_ID` before run for ITIL correlation.

See [ANSIBLE-AUDIT-COMMAND-MATRIX.md](../../docs/ANSIBLE-AUDIT-COMMAND-MATRIX.md) and [ANSIBLE-AUDIT-OPERATIONS.md](../../docs/ANSIBLE-AUDIT-OPERATIONS.md).
