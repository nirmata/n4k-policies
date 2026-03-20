# Platform engineering policy set

Add Kyverno `ValidatingPolicy` manifests as `*.yaml` in this directory.

Enable the set in Helm values:

```yaml
platformEngineering:
  enabled: true
```

Use `platformEngineering.excluded` and `platformEngineering.overrides` the same way as other sets (see root `values.yaml`).
