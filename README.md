# n4k-policies — Kyverno ValidatingPolicy sets

Helm chart that can deploy **one or more optional policy sets**. Each set is **opt-in** (`enabled: true`). Use it for Pod Security Standards, best practices, cleanup policies, platform-engineering rules, or custom YAML you add under the matching directories.

## Policy sets (directories)

| Values key | Directory | Purpose |
|------------|-----------|---------|
| `podSecurity` | `pod-security/` | PSS baseline + restricted |
| `bestPractices` | `best-practices/` | General best-practice policies |
| `cleanupPolicies` | `cleanup-policies/` | Add your cleanup-related policies |
| `platformEngineering` | `platform-engineering/` | Add platform / governance policies |

Each set supports **`enabled`**, **`excluded`** (skip policy names), and **`overrides`** (deep-merge by `metadata.name`). All rendered resources are cluster-scoped.

## Default behavior (v0.2.0+)

**No policies are installed** until you set at least one `*.enabled: true`. This replaces the old top-level `policies:` key — use **`podSecurity`** instead.

**Upgrade from chart &lt; 0.2.0:** replace `policies.excluded` / `policies.overrides` with `podSecurity.excluded` / `podSecurity.overrides`, and set `podSecurity.enabled: true` (and `bestPractices.enabled: true` if you relied on that set).

## Published chart (Nirmata)

Repository: [github.com/nirmata/n4k-policies](https://github.com/nirmata/n4k-policies). Chart name: **`n4k-policies`**. ValidatingPolicies use **`policies.kyverno.io/v1beta1`** (Kyverno 1.16.x).

### GitHub Pages

```bash
helm repo add n4k-policies https://nirmata.github.io/n4k-policies/
helm repo update
helm install my-policies n4k-policies/n4k-policies -n kyverno --create-namespace \
  --set podSecurity.enabled=true
```

Pin a chart version:

```bash
helm install my-policies n4k-policies/n4k-policies -n kyverno --version 0.2.0 \
  --set podSecurity.enabled=true --set bestPractices.enabled=true
```

### OCI

```bash
helm install my-policies oci://ghcr.io/nirmata/charts/n4k-policies --version 0.2.0 -n kyverno --create-namespace \
  --set podSecurity.enabled=true
```

### GitHub Release (`.tgz`)

```bash
helm install my-policies https://github.com/nirmata/n4k-policies/releases/download/v0.2.0/n4k-policies-0.2.0.tgz -n kyverno --create-namespace \
  --set podSecurity.enabled=true
```

## Examples

**Pod Security only:**

```bash
helm install pss n4k-policies/n4k-policies -n kyverno --create-namespace \
  --set podSecurity.enabled=true --set bestPractices.enabled=false
```

**Best practices only:**

```bash
helm install bp n4k-policies/n4k-policies -n kyverno --create-namespace \
  --set podSecurity.enabled=false --set bestPractices.enabled=true
```

**Multiple sets (after you add YAML under those folders):**

```bash
helm install all n4k-policies/n4k-policies -n kyverno --create-namespace \
  --set podSecurity.enabled=true \
  --set bestPractices.enabled=true \
  --set cleanupPolicies.enabled=true \
  --set platformEngineering.enabled=true
```

**Reporting RBAC** (for policies that need aggregated reports-controller roles, e.g. `check-deprecated-apis`):

```bash
helm install my-policies n4k-policies/n4k-policies -n kyverno --create-namespace \
  --set bestPractices.enabled=true \
  --set reportingRBAC.enabled=true
```

## Deploy from source

```bash
helm install my-policies . -n kyverno --create-namespace \
  --set podSecurity.enabled=true

# Exclude PSS policies by name
helm install my-policies . -n kyverno --create-namespace \
  --set podSecurity.enabled=true \
  --set 'podSecurity.excluded[0]=disallow-host-ports'

# Override a policy (e.g. Enforce)
helm install my-policies . -n kyverno --create-namespace -f my-values.yaml
```

### `my-values.yaml` example

```yaml
podSecurity:
  enabled: true
  excluded:
    - disallow-host-ports
  overrides:
    disallow-capabilities:
      spec:
        validationActions:
          - Enforce

bestPractices:
  enabled: true
  excluded:
    - require-requests-limits

reportingRBAC:
  enabled: true
```

## Adding a new policy set

1. Add a directory at the chart root, e.g. `my-set/*.yaml` (ValidatingPolicy manifests).
2. Add a matching block in `values.yaml` and a line in `templates/policies.yaml`:

   ```yaml
   {{ include "n4k-policies.renderPolicySet" (dict "root" $root "set" .Values.mySet "glob" "my-set/*.yaml") }}
   ```

3. Document the set in this README.

## Policy names (`metadata.name`)

### Pod Security (`pod-security/`)

| Baseline | Restricted |
|----------|------------|
| disallow-capabilities | disallow-capabilities-strict |
| disallow-host-namespaces | disallow-privilege-escalation |
| disallow-host-path | require-run-as-non-root-user |
| disallow-host-ports | require-run-as-nonroot |
| disallow-host-process | restrict-seccomp-strict |
| disallow-privileged-containers | restrict-volume-types |
| disallow-proc-mount | |
| disallow-selinux | |
| restrict-seccomp | |
| restrict-sysctls | |

### Best-practices (`best-practices/`)

check-deprecated-apis, disallow-container-sock-mounts, disallow-default-namespace, disallow-empty-ingress-host, disallow-helm-tiller, disallow-latest-tag, drop-all-capabilities, drop-cap-net-raw, require-labels, require-requests-limits, require-pod-probes, require-ro-rootfs, restrict-image-registries, restrict-nodeport, restrict-external-ips

## Publishing the chart (GitHub Pages)

See [`.github/workflows/publish-helm-pages.yml`](.github/workflows/publish-helm-pages.yml). Enable **Pages** from the **`gh-pages`** branch in repo settings. Bump `version` in `Chart.yaml` and push to `main` to publish a new package.
