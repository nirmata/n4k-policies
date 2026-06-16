# custom-policies

Drop any Kyverno `ValidatingPolicy` (or `ClusterPolicy`) YAML files here and enable the set in `values.yaml`:

```yaml
customPolicies:
  enabled: true
```

All built-in policy sets can remain disabled, so only your custom policies are deployed:

```yaml
podSecurity:
  enabled: false
bestPractices:
  enabled: false
cleanupPolicies:
  enabled: false
platformEngineering:
  enabled: false
customPolicies:
  enabled: true
```

You can also use `excluded` and `overrides` exactly as with built-in sets:

```yaml
customPolicies:
  enabled: true
  excluded:
    - my-policy-name          # skip this policy
  overrides:
    my-other-policy:
      spec:
        validationActions:
          - Enforce           # promote from Audit to Enforce
```

Files in this directory are loaded via `Files.Glob("custom-policies/*.yaml")` — only `.yaml` files are picked up.
