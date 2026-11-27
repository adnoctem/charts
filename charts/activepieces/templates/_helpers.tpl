{{/*
Expand the name of the chart.
*/}}
{{- define "activepieces.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "activepieces.fullname" -}}
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
{{- define "activepieces.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Build the Docker Hub image reference as used within the main and init-containers.
*/}}
{{- define "activepieces.image" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{ end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "activepieces.labels" -}}
helm.sh/chart: {{ include "activepieces.chart" . }}
{{ include "activepieces.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "activepieces.selectorLabels" -}}
app.kubernetes.io/name: {{ include "activepieces.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "activepieces.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "activepieces.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Define the PV name
*/}}
{{- define "activepieces.pv" -}}
{{- printf "%s-pv" (include "activepieces.fullname" .)}}
{{- end -}}

{{/*
Define the PVC name
*/}}
{{- define "activepieces.pvc" -}}
{{- printf "%s-pvc" (include "activepieces.fullname" .)}}
{{- end -}}

{{/*
Define the Secret names
*/}}
{{- define "activepieces.secrets.encryption" -}}
{{- printf "%s-encryption-keys" (include "activepieces.fullname" .)}}
{{- end -}}

{{- define "activepieces.secrets.queue" -}}
{{- printf "%s-queue-ui-credentials" (include "activepieces.fullname" .)}}
{{- end -}}

{{- define "activepieces.secrets.postgresql" -}}
{{- printf "%s-postgresql-credentials" (include "activepieces.fullname" .)}}
{{- end -}}

{{- define "activepieces.secrets.redis" -}}
{{- printf "%s-redis-credentials" (include "activepieces.fullname" .)}}
{{- end -}}

{{- define "activepieces.secrets.openai" -}}
{{- printf "%s-openai-api-key" (include "activepieces.fullname" .)}}
{{- end -}}


{{/*
Obtain the API version for the Pod Disruption Budget
*/}}
{{- define "activepieces.pdb.apiVersion" -}}
{{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
{{- print "policy/v1" }}
{{- else -}}
{{- print "policy/v1beta1" }}
{{- end -}}
{{- end -}}

{{/*
Define Ingress scheme and URL
*/}}
{{- define "activepieces.ingress.scheme" }}
{{- if gt (len .Values.ingress.tls) 0 -}}
{{- print "https" }}
{{- else -}}
{{- print "http" }}
{{- end -}}
{{- end }}

{{- define "activepieces.ingress.url" -}}
{{ printf "%s://%s" (include "activepieces.ingress.scheme" .) .Values.activepieces.domain }}
{{- end }}

{{/*
Define storage paths
*/}}
{{- define "activepieces.data.path" }}
{{- trimSuffix "/" (printf "%s/%s" (trimSuffix "/" .Values.activepieces.data.rootPath) (trimSuffix "/" .Values.activepieces.configPath)) }}
{{- end }}

{{/*
Allow worker intake to stop (5s), flows to finish (timeout + 90s), and teardown (10s).
*/}}
{{- define "activepieces.terminationGracePeriodSeconds" -}}
{{- $timeout := .Values.activepieces.sandbox.flowTimeoutSeconds -}}
{{- $grace := .Values.terminationGracePeriodSeconds -}}
{{- if or (not (regexMatch "^[0-9]+$" (toString $timeout))) (le (int64 $timeout) 0) -}}
{{- fail "activepieces.sandbox.flowTimeoutSeconds must be a positive whole number" -}}
{{- end -}}
{{- if not (regexMatch "^[0-9]+$" (toString $grace)) -}}
{{- fail "terminationGracePeriodSeconds must be a nonnegative whole number (0 means automatic)" -}}
{{- end -}}
{{- if eq (int64 $grace) 0 -}}
{{- add $timeout 105 -}}
{{- else -}}
{{- $grace -}}
{{- end -}}
{{- end -}}

{{/*
Explicit values take precedence; otherwise preserve generated credentials on connected upgrades.
Offline renderers must supply stable values or an existing Secret.
*/}}
{{- define "activepieces.secretValue" -}}
{{- if .value -}}
{{- .value | b64enc -}}
{{- else -}}
{{- $secret := lookup "v1" "Secret" .root.Release.Namespace .name -}}
{{- $data := ($secret | default dict).data | default dict -}}
{{- get $data .key | default (randAlphaNum 32 | b64enc) -}}
{{- end -}}
{{- end -}}
