# PSS Baseline + Restricted + Best Practices Kyverno Policies

Single chart deploying Kyverno ValidatingPolicies for Pod Security Standards (Baseline + Restricted) and Best Practices, with optional customization (exclude/override) for each set.

## Contents

- **`pod-security/`** – PSS policy YAML files (10 baseline + 6 restricted)
- **`best-practices/`** – Best-practices policy YAML files (15 policies)
- **Helm chart** – Deploy with `helm install`; supports excluding policies and overriding fields per set. All policies are cluster-scoped (no namespace).

## Published chart (Nirmata)

Repository: [github.com/nirmata/n4k-policies](https://github.com/nirmata/n4k-policies). Helm chart name (in `Chart.yaml`): **`n4k-policies`**. ValidatingPolicies use **`policies.kyverno.io/v1beta1`** (Kyverno 1.16.x).

### GitHub Pages Helm repository (recommended)

After [one-time setup](#publishing-the-chart-github-pages), add the repo and install:

```bash
helm repo add n4k-policies https://nirmata.github.io/n4k-policies/
helm repo update
helm install my-policies n4k-policies/n4k-policies -n kyverno --create-namespace
```

Install a specific chart version:

```bash
helm install my-policies n4k-policies/n4k-policies -n kyverno --version 0.1.6
```

The first segment (`n4k-policies` in `n4k-policies/n4k-policies`) is the **repo alias** from `helm repo add`; the second is the **chart name** from this project’s `Chart.yaml`.

### Other ways to install

**OCI (GitHub Container Registry):**

```bash
helm install my-policies oci://ghcr.io/nirmata/charts/n4k-policies --version 0.1.6 -n kyverno --create-namespace
```

**GitHub Release asset (direct `.tgz` URL):**

```bash
helm install my-policies https://github.com/nirmata/n4k-policies/releases/download/v0.1.6/n4k-policies-0.1.6.tgz -n kyverno --create-namespace
```

## Deploy with Helm (from source)

```bash
# Install all policies (default: Audit mode)
helm install my-policies . -n kyverno --create-namespace

# Exclude specific policies
helm install my-policies . -n kyverno --set 'policies.excluded[0]=disallow-host-ports' --set 'policies.excluded[1]=restrict-volume-types'

# Override policies (e.g. switch to Enforce, add labels)
helm install my-policies . -n kyverno -f my-values.yaml

# Disable best-practices set
helm install my-policies . -n kyverno --set 'bestPractices.enabled=false'

# Exclude a best-practices policy
helm install my-policies . -n kyverno --set 'bestPractices.excluded[0]=require-requests-limits'
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

## Publishing the chart (GitHub Pages)

Publishing is done by [`.github/workflows/publish-helm-pages.yml`](.github/workflows/publish-helm-pages.yml). On each push to `main` that changes the chart (or the workflow file), it:

1. Runs `helm package` for the chart at the repo root.
2. Pushes the `.tgz` files and a merged **`index.yaml`** to the **`gh-pages`** branch so Helm can use the site as a chart repository.

**One-time setup (maintainers):**

1. In the GitHub repo: **Settings → Pages → Build and deployment**.
2. Under **Source**, choose **Deploy from a branch**, branch **`gh-pages`**, folder **`/ (root)`**, then Save.
3. The repository URL for `helm repo add` is:

   `https://nirmata.github.io/n4k-policies/`

   (Pattern: `https://<org>.github.io/<repo>/`.)

4. Merge the workflow to `main` (or run **Actions → Publish Helm chart to GitHub Pages → Run workflow**). After the first successful run, `https://nirmata.github.io/n4k-policies/index.yaml` should load in a browser.

**Release a new chart version:** bump `version` in `Chart.yaml`, commit, and push to `main`. The workflow repackages and updates the Helm index on `gh-pages`.

**Private repositories:** GitHub Pages for private repos requires a [paid GitHub plan](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages); otherwise use OCI or Release `.tgz` URLs for distribution.
