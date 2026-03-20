# Cleanup policy set

Add Kyverno `ValidatingPolicy` manifests as `*.yaml` in this directory.

Enable the set in Helm values:

```yaml
cleanupPolicies:
  enabled: true
```

Use `cleanupPolicies.excluded` and `cleanupPolicies.overrides` the same way as other sets (see root `values.yaml`).
