## Summary

<!-- What does this PR change and why? Keep it concise. -->

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing behavior to change)
- [ ] Documentation only
- [ ] Infrastructure / CI / deployment
- [ ] Security / compliance (NIST, OSCAL, PQC, HITL)

## Related issues

<!-- Link issues: Fixes #123, Relates to #456 -->

## Testing

<!-- How did you verify this? Include commands run and environments tested. -->

- [ ] `bash -n scripts/deploy.sh` and `bash -n scripts/test-mvp-demo.sh`
- [ ] Local app tested (`./scripts/run-local.sh` or Docker)
- [ ] MVP demo script (`./scripts/test-mvp-demo.sh`) if UI/runtime behavior changed
- [ ] No secrets, API keys, or credentials in the diff

## HITL / security checklist

- [ ] No automated remediation without documented human approval path
- [ ] No hardcoded secrets (uses env vars / Secret Manager per `docs/SECRETS-SETUP.md`)
- [ ] NIST / OSCAL / PQC references verified if compliance logic changed

## Screenshots / logs

<!-- Optional: UI changes, CI output, demo evidence -->

## Notes for reviewers

<!-- Anything non-obvious: rollout steps, follow-up work, areas you want extra eyes on -->
