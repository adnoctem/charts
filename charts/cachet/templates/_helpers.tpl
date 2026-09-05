{{/*
Expand the name of the chart.
*/}}
{{- define "cachet.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "cachet.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "cachet.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Build the Docker Hub image reference as used within the main and init-containers.
*/}}
{{- define "cachet.image" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{ end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "cachet.labels" -}}
helm.sh/chart: {{ include "cachet.chart" . }}
{{ include "cachet.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "cachet.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cachet.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "cachet.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "cachet.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define the PV name
*/}}
{{- define "cachet.pv.name" -}}
{{- printf "%s-pv" (include "cachet.fullname" .)}}
{{- end -}}

{{/*
Define the PVC name
*/}}
{{- define "cachet.pvc.name" -}}
{{- printf "%s-pvc" (include "cachet.fullname" .)}}
{{- end -}}

{{/*
Define the Secret names
*/}}
{{- define "cachet.secrets.appKey" -}}
{{- printf "%s-key" (include "cachet.fullname" .)}}
{{- end -}}

{{- define "cachet.secrets.db" -}}
{{- printf "%s-db-credentials" (include "cachet.fullname" .)}}
{{- end -}}

{{- define "cachet.secrets.mail" -}}
{{- printf "%s-mail-credentials" (include "cachet.fullname" .)}}
{{- end -}}

{{- define "cachet.secrets.github" -}}
{{- printf "%s-github-token" (include "cachet.fullname" .)}}
{{- end -}}

{{/*
Resolve the PostgreSQL host: explicit value wins, otherwise fall back to the
bundled subchart's generated service name (only when it's actually enabled).
*/}}
{{- define "cachet.database.host" -}}
{{- if .Values.cachet.database.host -}}
{{- printf "%s" .Values.cachet.database.host }}
{{- else if .Values.postgresql.enabled -}}
{{- printf "%s-%s" .Release.Name "postgresql" }}
{{- end -}}
{{- end }}

{{/*
Resolve the Redis host: explicit value wins, otherwise fall back to the
bundled subchart's generated service name (only when it's actually enabled).
*/}}
{{- define "cachet.redis.host" -}}
{{- if .Values.cachet.redis.host -}}
{{- printf "%s" .Values.cachet.redis.host }}
{{- else if .Values.redis.enabled -}}
{{- printf "%s-%s" .Release.Name "redis-master" }}
{{- end -}}
{{- end }}

{{/*
Obtain the API version for the Pod Disruption Budget
*/}}
{{- define "cachet.pdb.apiVersion" -}}
{{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
{{- print "policy/v1" }}
{{- else -}}
{{- print "policy/v1beta1" }}
{{- end -}}
{{- end -}}
