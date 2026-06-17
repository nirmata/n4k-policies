# n4k-policies — Kyverno ValidatingPolicy sets

Helm chart that can deploy **one or more optional policy sets**. Each set is **opt-in** (`enabled: true`). Use it for Pod Security Standards, best practices, cleanup policies, platform-engineering rules, or custom YAML you add under the matching directories.

## Policy sets (directories)

| Values key | Directory | Purpose |
|------------|-----------|---------|
| `podSecurity` | `pod-security/` | PSS baseline + restricted |
| `bestPractices` | `best-practices/` | General best-practice policies |
| `cleanupPolicies` | `cleanup-policies/` | Add your cleanup-related policies |
| `platformEngineering` | `platform-engineering/` | Add platform / governance policies |
| `customPolicies` | `custom-policies/` | Drop in any ad-hoc policies without touching built-in sets |

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
helm install n4k-policies n4k-policies/n4k-policies -n kyverno --create-namespace \
  --set podSecurity.enabled=true
```

Pin a chart version:

```bash
helm install n4k-policies n4k-policies/n4k-policies -n kyverno --version 0.2.0 \
  --set podSecurity.enabled=true --set bestPractices.enabled=true
```

### OCI

```bash
helm install n4k-policies oci://ghcr.io/nirmata/charts/n4k-policies --version 0.2.0 -n kyverno --create-namespace \
  --set podSecurity.enabled=true
```

### GitHub Release (`.tgz`)

```bash
helm install n4k-policies https://github.com/nirmata/n4k-policies/releases/download/v0.2.0/n4k-policies-0.2.0.tgz -n kyverno --create-namespace \
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

**Custom policies only** (deploy only your own policies from local source):

> **Note:** `customPolicies` requires a local-source deployment. Because Helm bundles chart files at package time, policies you place in `custom-policies/` are only visible when you run `helm install` directly from the cloned chart directory — not from the published Helm repo.

> **Webhook timeout:** Kyverno's policy validation webhook has a 10-second timeout. Installing all policies in one `helm install` creates them simultaneously and overwhelms the webhook. Use the provided `custom-policies/scripts/install.sh` for a fresh install — it deploys in four waves of ~10 policies each, printing the newly deployed policies after each wave. Subsequent `helm upgrade` calls work fine without the script.

```bash
# 1. Clone the chart
git clone https://github.com/nirmata/n4k-policies.git
cd n4k-policies

# 2. Copy your ClusterPolicy YAML files into custom-policies/
cp /path/to/my-policy.yaml custom-policies/

# 3. Fresh install — use the batched install script
./custom-policies/scripts/install.sh                              # defaults: release=n4k-policies, namespace=kyverno
./custom-policies/scripts/install.sh n4k-policies kyverno .        # explicit args

# 4. Subsequent upgrades (no batching needed)
helm upgrade n4k-policies . -n kyverno --set customPolicies.enabled=true
```

Or with a values file:

```yaml
# my-values.yaml
customPolicies:
  enabled: true
  excluded:
    - my-noisy-policy        # skip a specific policy by metadata.name
  overrides:
    my-policy-name:
      spec:
        validationFailureAction: Enforce  # promote from Audit to Enforce without editing the file
```

```bash
# Fresh install
./custom-policies/scripts/install.sh n4k-policies kyverno .
# then apply your values overrides via upgrade
helm upgrade n4k-policies . -n kyverno -f my-values.yaml
```

Any `*.yaml` file placed under `custom-policies/` is picked up automatically. Do not commit customer-specific policies to this repo.

**Reporting RBAC** (for policies that need aggregated reports-controller roles, e.g. `check-deprecated-apis`):

```bash
helm install n4k-policies n4k-policies/n4k-policies -n kyverno --create-namespace \
  --set bestPractices.enabled=true \
  --set reportingRBAC.enabled=true
```

## Deploy from source

For a **fresh install of `customPolicies`** use the batched script (avoids Kyverno webhook timeouts):

```bash
./custom-policies/scripts/install.sh                        # release=n4k-policies, namespace=kyverno
./custom-policies/scripts/install.sh <release> <namespace>  # custom args
```

For all **other sets** (podSecurity, bestPractices, etc.) or for **upgrades**, a plain Helm command works:

```bash
helm install n4k-policies . -n kyverno --create-namespace \
  --set podSecurity.enabled=true

# Exclude policies by name
helm install n4k-policies . -n kyverno --create-namespace \
  --set podSecurity.enabled=true \
  --set 'podSecurity.excluded[0]=disallow-host-ports'

# Override a policy (e.g. Enforce)
helm install n4k-policies . -n kyverno --create-namespace -f my-values.yaml

# Upgrade (works for all sets without batching)
helm upgrade n4k-policies . -n kyverno --set customPolicies.enabled=true
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

### Custom policies (`custom-policies/`) — 38 policies

| | | |
|---|---|---|
| add-networkpolicy | disallow-host-ports | require-run-as-nonroot |
| add-safe-to-evict | disallow-host-ports-range | restrict-apparmor-profiles |
| add-ttl-jobs | disallow-ingress-nginx-custom-snippets | restrict-controlplane-scheduling |
| check-deprecated-apis | disallow-latest-tag | restrict-external-ips |
| check-ephmeral-storage-capacity | disallow-privilege-escalation | restrict-image-registries |
| check-evicted-pods | disallow-privileged-containers | restrict-nodeport |
| disallow-capabilities | disallow-proc-mount | restrict-seccomp-strict |
| disallow-capabilities-strict | disallow-selinux | restrict-sysctls |
| disallow-container-sock-mounts | drop-all-capabilities | restrict-volume-types |
| disallow-default-namespace | drop-cap-net-raw | require-ephemeral-storage-requests-limits |
| disallow-empty-ingress-host | require-labels | require-namespace-quota |
| disallow-helm-tiller | require-requests-limits | |
| disallow-host-path | require-ro-rootfs | |
| | require-run-as-non-root-user | |

### Best-practices (`best-practices/`)

check-deprecated-apis, disallow-container-sock-mounts, disallow-default-namespace, disallow-empty-ingress-host, disallow-helm-tiller, disallow-latest-tag, drop-all-capabilities, drop-cap-net-raw, require-labels, require-requests-limits, require-pod-probes, require-ro-rootfs, restrict-image-registries, restrict-nodeport, restrict-external-ips

## Publishing the chart (GitHub Pages)

See [`.github/workflows/publish-helm-pages.yml`](.github/workflows/publish-helm-pages.yml). Enable **Pages** from the **`gh-pages`** branch in repo settings. Bump `version` in `Chart.yaml` and push to `main` to publish a new package.
