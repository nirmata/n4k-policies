{{/*
Render Kyverno ValidatingPolicies from chart files matching glob when the set is enabled.
- set.excluded: list of policy metadata.name to skip
- set.overrides: map of policy name -> partial policy YAML (deep-merged)
*/}}
{{- define "n4k-policies.renderPolicySet" -}}
{{- $root := index . "root" }}
{{- $set := index . "set" | default dict }}
{{- if $set.enabled }}
{{- $excluded := $set.excluded | default list }}
{{- $overridesRoot := $set.overrides | default dict }}
{{- $glob := index . "glob" }}
{{- range $path, $_ := $root.Files.Glob $glob }}
{{- $content := $root.Files.Get $path }}
{{- $policy := $content | fromYaml }}
{{- if and $policy $policy.metadata }}
{{- $name := $policy.metadata.name }}
{{- if not (has $name $excluded) }}
{{- $o := index $overridesRoot $name | default dict }}
{{- $merged := mergeOverwrite (deepCopy $policy) $o }}
{{- if $merged.metadata }}{{- $_ := unset $merged.metadata "namespace" }}{{- end }}
---
{{ $merged | toYaml }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
