{{/*
Expand the name of the chart.
*/}}
{{- define "vaultwarden.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vaultwarden.fullname" -}}
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
{{- define "vaultwarden.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vaultwarden.labels" -}}
helm.sh/chart: {{ include "vaultwarden.chart" . }}
{{ include "vaultwarden.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vaultwarden.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vaultwarden.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vaultwarden.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vaultwarden.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Set the names of the secrets
*/}}
{{- define "vaultwarden.secrets.admin" -}}
{{- printf "%s-admin" (include "vaultwarden.fullname" .) }}
{{- end }}

{{- define "vaultwarden.secrets.smtp" -}}
{{- printf "%s-smtp" (include "vaultwarden.fullname" .) }}
{{- end }}

{{- define "vaultwarden.secrets.db" -}}
{{- printf "%s-db" (include "vaultwarden.fullname" .) }}
{{- end }}

{{- define "vaultwarden.secrets.hibp" -}}
{{- printf "%s-hibp" (include "vaultwarden.fullname" .) }}
{{- end }}

{{- define "vaultwarden.secrets.sso" -}}
{{- printf "%s-sso" (include "vaultwarden.fullname" .) }}
{{- end }}

{{/*
Define the PV name
*/}}
{{- define "vaultwarden.pv.name" -}}
{{- printf "%s-pv" (include "vaultwarden.fullname" .)}}
{{- end -}}

{{/*
Define the PVC name
*/}}
{{- define "vaultwarden.pvc.name" -}}
{{- printf "%s-pvc" (include "vaultwarden.fullname" .)}}
{{- end -}}



{{/*
Obtain the API version for the Pod Disruption Budget
*/}}
{{- define "vaultwarden.pdb.apiVersion" -}}
{{- if and (.Capabilities.APIVersions.Has "policy/v1") (semverCompare ">= 1.21-0" .Capabilities.KubeVersion.Version) -}}
{{- print "policy/v1" }}
{{- else -}}
{{- print "policy/v1beta1" }}
{{- end -}}
{{- end -}}

{{/*
Create the database URI from the received values
*/}}
{{- define "vaultwarden.db.uri" -}}
{{- $dbUser := .Values.vaultwarden.database.user }}
{{- $dbPass := .Values.vaultwarden.database.password }}
{{- $dbHost := .Values.vaultwarden.database.host }}
{{- $dbPort := .Values.vaultwarden.database.port }}
{{- $dbName := .Values.vaultwarden.database.name }}
{{- if (eq .Values.vaultwarden.database.type "postgresql")  -}}
{{- printf "postgresql://%s:%s@%s:%d/%s" $dbUser $dbPass $dbHost $dbPort $dbName }}
{{- else if (eq .Values.vaultwarden.database.type "mysql") -}}
{{- printf "mysql://%s:%s@%s:%d/%s" $dbUser $dbPass $dbHost $dbPort $dbName }}
{{- else -}}
{{- print "data/db.sqlite3" }}
{{- end -}}
{{- end -}}

{{/*
Database connection initialization statements
*/}}
{{- define "vaultwarden.db.conn_init" -}}
{{- if (eq .Values.vaultwarden.database.type "sqlite") }}
{{- "PRAGMA busy_timeout = 5000; PRAGMA synchronous = NORMAL;" }}
{{- end }}
{{- end }}


{{/*
Determine which Kubernetes resource to create: StatefulSet or Deployment
*/}}
{{- define "vaultwarden.resourceType" -}}
{{- if eq .Values.vaultwarden.database.type "sqlite" }}
{{- "StatefulSet" }}
{{- else }}
{{- "Deployment" }}
{{- end }}
{{- end }}
