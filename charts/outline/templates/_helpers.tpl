{{/*
Expand the name of the chart.
*/}}
{{- define "outline.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "outline.fullname" -}}
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
{{- define "outline.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Build the Docker Hub image reference as used within the main container.
*/}}
{{- define "outline.image" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{ end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "outline.labels" -}}
helm.sh/chart: {{ include "outline.chart" . }}
{{ include "outline.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "outline.selectorLabels" -}}
app.kubernetes.io/name: {{ include "outline.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "outline.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "outline.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define the PV name
*/}}
{{- define "outline.pv" -}}
{{- printf "%s-pv" (include "outline.fullname" .)}}
{{- end -}}

{{/*
Define the PVC name
*/}}
{{- define "outline.pvc" -}}
{{- printf "%s-pvc" (include "outline.fullname" .)}}
{{- end -}}

{{/*
Define the Secret names
*/}}
{{- define "outline.secrets.keys" -}}
{{- printf "%s-keys" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.database" -}}
{{- printf "%s-database" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.redis" -}}
{{- printf "%s-redis" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.smtp" -}}
{{- printf "%s-smtp" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.s3" -}}
{{- printf "%s-s3" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.cloudfront" -}}
{{- printf "%s-cloudfront" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.oidc" -}}
{{- printf "%s-oidc" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.google" -}}
{{- printf "%s-google" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.slack" -}}
{{- printf "%s-slack" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.azure" -}}
{{- printf "%s-azure" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.discord" -}}
{{- printf "%s-discord" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.github" -}}
{{- printf "%s-github" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.gitlab" -}}
{{- printf "%s-gitlab" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.linear" -}}
{{- printf "%s-linear" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.slackIntegration" -}}
{{- printf "%s-slack-integration" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.figma" -}}
{{- printf "%s-figma" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.notion" -}}
{{- printf "%s-notion" (include "outline.fullname" .)}}
{{- end -}}

{{- define "outline.secrets.iframely" -}}
{{- printf "%s-iframely" (include "outline.fullname" .)}}
{{- end -}}

{{/*
Obtain the API version for the Pod Disruption Budget
*/}}
{{- define "outline.pdb.apiVersion" -}}
{{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
{{- print "policy/v1" }}
{{- else -}}
{{- print "policy/v1beta1" }}
{{- end -}}
{{- end -}}

{{/*
Define Ingress scheme and URL
*/}}
{{- define "outline.ingress.scheme" }}
{{- if gt (len .Values.ingress.tls) 0 -}}
{{- print "https" }}
{{- else -}}
{{- print "http" }}
{{- end -}}
{{- end }}

{{/*
Extract the bare hostname from outline.url, for use in the Ingress `host` field.
*/}}
{{- define "outline.domain" -}}
{{- (urlParse .Values.outline.url).host }}
{{- end -}}

{{/*
Build the DATABASE_URL connection string from the individual database fields.
*/}}
{{- define "outline.database.uri" -}}
{{- $user := .Values.outline.database.username }}
{{- $pass := .Values.outline.database.password }}
{{- $host := .Values.outline.database.host }}
{{- $port := .Values.outline.database.port }}
{{- $name := .Values.outline.database.name }}
{{- printf "postgres://%s:%s@%s:%v/%s" $user $pass $host $port $name }}
{{- end -}}

{{/*
Build the REDIS_URL connection string from the individual redis fields.
*/}}
{{- define "outline.redis.uri" -}}
{{- $scheme := "redis" }}
{{- if .Values.outline.redis.useTLS }}
{{- $scheme = "rediss" }}
{{- end }}
{{- $user := .Values.outline.redis.username }}
{{- $pass := .Values.outline.redis.password }}
{{- $host := .Values.outline.redis.host }}
{{- $port := .Values.outline.redis.port }}
{{- if and $user $pass }}
{{- printf "%s://%s:%s@%s:%v" $scheme $user $pass $host $port }}
{{- else if $pass }}
{{- printf "%s://:%s@%s:%v" $scheme $pass $host $port }}
{{- else }}
{{- printf "%s://%s:%v" $scheme $host $port }}
{{- end }}
{{- end -}}
