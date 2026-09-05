{{/*
Expand the name of the chart.
*/}}
{{- define "popeye.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "popeye.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Build the Docker Hub image reference as used within the main and init-containers.
*/}}
{{- define "popeye.image" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{ end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "popeye.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "popeye.labels" -}}
helm.sh/chart: {{ include "popeye.chart" . }}
{{ include "popeye.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "popeye.selectorLabels" -}}
app.kubernetes.io/name: {{ include "popeye.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "popeye.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "popeye.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define ConfigMap names
*/}}
{{- define "popeye.configmap.spinach" -}}
{{- printf "%s-spinach-config" (include "popeye.fullname" .) }}
{{- end -}}

{{/*
Define Secret names
*/}}
{{- define "popeye.secret.scans" -}}
{{- printf "%s-%s-config" .type (include "popeye.fullname" .root) }}
{{- end -}}

{{/*
Define Popeye args
*/}}
{{- define "popeye.arg.filter" -}}
{{- $filteredArgs := (dict) }}
{{- range $k, $v := .Values.popeye.args }}
{{- if not (or (regexMatch "^push-gtwy-(password|user|url)$" $k) (regexMatch "^s3-(bucket|endpoint|region)$" $k) (eq (toString $v) "false")) }}
{{- $_ := set $filteredArgs $k $v }}
{{- end }}
{{- end }}
{{- toYaml $filteredArgs -}}
{{- end -}}

{{- define "popeye.arg.scans" -}}
{{- if has "push-gtwy" .Values.popeye.scans.destinations }}
- --push-gtwy-url {{ .Values.popeye.scans.pushGateway.url | quote }}
{{- if .Values.popeye.scans.pushGateway.user }}
- --push-gtwy-user {{ .Values.popeye.scans.pushGateway.user }}
{{- end }}
{{- if .Values.popeye.scans.pushGateway.password }}
- --push-gtwy-password {{ .Values.popeye.scans.pushGateway.password }}
{{- end }}
{{- end }}
{{- if has "s3" .Values.popeye.scans.destinations }}
- --s3-bucket {{ .Values.popeye.scans.s3.bucket }}
{{- if .Values.popeye.scans.s3.region }}
- --s3-region {{ .Values.popeye.scans.s3.region }}
{{- end }}
{{- if .Values.popeye.scans.s3.endpoint }}
- --s3-endpoint {{ .Values.popeye.scans.s3.endpoint }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "popeye.args" -}}
{{- $lines := list }}
{{- range $k, $v := (include "popeye.arg.filter" . | fromYaml) }}
{{- if eq (toString $v) "true" }}
{{- $lines = append $lines (printf "- --%s" (lower $k)) }}
{{- else }}
{{- $lines = append $lines (printf "- --%s %s" (lower $k) (lower $v)) }}
{{- end }}
{{- end }}
{{- range (splitList "\n" (include "popeye.arg.scans" .)) }}
{{- if . }}
{{- $lines = append $lines . }}
{{- end }}
{{- end }}
{{- join "\n" $lines }}
{{- end -}}
