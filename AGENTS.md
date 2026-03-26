# AGENTS.md

## Cursor Cloud specific instructions

This repository is a **Helm chart** (`n4k-policies`) that packages Kyverno `ValidatingPolicy` YAML manifests. There is no application code, no runtime services, and no language-specific dependencies — the only dev tool needed is **Helm v3**.

### Key development commands

| Task | Command |
|------|---------|
| Lint | `helm lint .` |
| Render templates (dry-run) | `helm template my-policies . --set podSecurity.enabled=true` |
| Package | `helm package . -d /tmp/pkg` |

Enable policy sets via `--set <set>.enabled=true`. Available sets: `podSecurity`, `bestPractices`, `cleanupPolicies`, `platformEngineering`, `reportingRBAC`. See `README.md` for full usage examples including exclusions and overrides.

### Notes

- No policies render unless at least one set has `enabled: true` (opt-in behavior).
- Templates are cluster-scoped; `metadata.namespace` is stripped automatically.
- A Kubernetes cluster with Kyverno is only needed for end-to-end admission testing. `helm lint` and `helm template` cover chart correctness without a cluster.
- The CI workflow (`.github/workflows/publish-helm-pages.yml`) publishes the chart to GitHub Pages and GHCR on push to `main` when chart-related files change.
