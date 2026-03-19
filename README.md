# PSS Baseline + Restricted + Best Practices Kyverno Policies

Single chart deploying Kyverno ValidatingPolicies for Pod Security Standards (Baseline + Restricted) and Best Practices, with optional customization (exclude/override) for each set.

## Contents

- **`pod-security/`** – PSS policy YAML files (10 baseline + 6 restricted)
- **`best-practices/`** – Best-practices policy YAML files (15 policies)
- **Helm chart** – Deploy with `helm install`; supports excluding policies and overriding fields per set. All policies are cluster-scoped (no namespace).

## Installing from the Helm repository

Once the chart is [published](#publishing-the-chart), anyone can install it from the public Helm repo:

```bash
helm repo add n4k-policies https://nirmata.github.io/n4k-policies
helm repo update
helm install pss-policies n4k-policies/pss-kyverno-policies -n kyverno --create-namespace
```

To install a specific version:

```bash
helm install pss-policies n4k-policies/pss-kyverno-policies -n kyverno --version 0.1.0
```

**If you get `404 Not Found` for index.yaml:** the Helm repo index is created only after the first release. Push a version tag (e.g. `v0.1.0`) to trigger the [Release Charts](.github/workflows/release-charts.yml) workflow, then in the repo **Settings → Pages** set Source to the **gh-pages** branch. After the workflow completes, `helm repo add` will work.

**Alternative – install from a GitHub Release URL** (works as soon as a release exists, no Helm repo needed):

```bash
helm install pss-policies https://github.com/nirmata/n4k-policies/releases/download/v0.1.0/pss-kyverno-policies-0.1.0.tgz -n kyverno --create-namespace
```

Replace `v0.1.0` and `pss-kyverno-policies-0.1.0.tgz` with the tag and asset name from the [releases](https://github.com/nirmata/n4k-policies/releases) page.

## Deploy with Helm (from source)

```bash
# Install all policies (default: Audit mode)
helm install pss-policies . -n kyverno --create-namespace

# Exclude specific policies
helm install pss-policies . -n kyverno --set 'policies.excluded[0]=disallow-host-ports' --set 'policies.excluded[1]=restrict-volume-types'

# Override policies (e.g. switch to Enforce, add labels)
helm install pss-policies . -n kyverno -f my-values.yaml

# Disable best-practices set
helm install pss-policies . -n kyverno --set 'bestPractices.enabled=false'

# Exclude a best-practices policy
helm install pss-policies . -n kyverno --set 'bestPractices.excluded[0]=require-requests-limits'
```

### Customize with values

**PSS policies – exclude** – Do not deploy listed policies (use `metadata.name` of each policy):

```yaml
policies:
  excluded:
    - disallow-host-ports
    - restrict-volume-types
```

**PSS policies – override** – Deep-merge overrides onto the base policy. Keys are policy `metadata.name`:

```yaml
policies:
  overrides:
    disallow-capabilities:
      spec:
        validationActions:
          - Enforce
```

**Best-practices** – Same capabilities: `bestPractices.enabled`, `bestPractices.excluded`, `bestPractices.overrides`:

```yaml
bestPractices:
  enabled: true
  excluded:
    - require-requests-limits
  overrides:
    disallow-latest-tag:
      spec:
        validationActions:
          - Enforce
```

## Policy list (by `metadata.name`)

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

## Publishing the chart

The chart is published via [Helm chart-releaser](https://github.com/helm/chart-releaser-action) when you push a version tag.

**Private repos:** The workflow will create the GitHub Release and the **gh-pages** branch. GitHub Pages for private repositories requires a paid plan (Team/Enterprise); if Pages is not available, you can still install the chart from the Release URL (see below).

1. **Enable GitHub Pages** in the repo: **Settings → Pages → Source**: deploy from the **gh-pages** branch (root). Save. The Helm index will be served at `https://nirmata.github.io/n4k-policies`.

2. **Bump the chart version** in `Chart.yaml` (e.g. set `version: 0.1.1`).

3. **Create and push a tag** matching `v*` (e.g. same as `version` in Chart.yaml):
   ```bash
   git add Chart.yaml
   git commit -m "chore: release 0.1.1"
   git tag v0.1.1
   git push origin main
   git push origin v0.1.1
   ```

4. The **Release Charts** workflow will run: it packages the chart, creates a GitHub Release, uploads the `.tgz`, and updates `index.yaml` on the `gh-pages` branch. After it completes, users can install with:
   ```bash
   helm repo add n4k-policies https://nirmata.github.io/n4k-policies
   helm install pss-policies n4k-policies/pss-kyverno-policies -n kyverno --version 0.1.1
   ```
