{{/*
Expand the name of the chart.
*/}}
{{- define "kcOperator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kcOperator.fullname" -}}
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
{{- define "kcOperator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Build the quay.io image reference as used within the main and init-containers.
*/}}
{{- define "kcOperator.image" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{ end }}
{{- end }}

{{- define "kcOperator.image.related" -}}
{{ .Values.image.registry }}/keycloak/keycloak:{{ .Values.image.tag }}{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{ end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kcOperator.labels" -}}
helm.sh/chart: {{ include "kcOperator.chart" . }}
{{ include "kcOperator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
{{- end }}
app.kubernetes.io/managed-by: quarkus
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kcOperator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kcOperator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "kcOperator.annotations" -}}
app.quarkus.io/quarkus-version: 3.33.3.1
app.quarkus.io/vcs-uri: https://github.com/keycloak/keycloak.git
app.quarkus.io/build-timestamp: 2026-08-31 - 09:35:27 +0000
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kcOperator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kcOperator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Templates to build the names for RBAC manifests
*/}}
{{- define "kcOperator.rbac.template.clusterrole" -}}
{{- printf "%s-cluster-role" .name }}
{{- end }}

{{- define "kcOperator.rbac.template.crbinding" -}}
{{- printf "%s-cluster-role-binding" .name }}
{{- end }}

{{- define "kcOperator.rbac.template.rbinding" -}}
{{- printf "%s-role-binding" .name }}
{{- end }}

{{- define "kcOperator.rbac.template.rbview" -}}
{{- printf "%s-view" .name }}
{{- end }}

{{/*
Build the names for RBAC manifests
*/}}

{{- define "kcOperator.rbac.clusterrole.kcOperator" -}}
{{- include "kcOperator.rbac.template.clusterrole" (dict "name" "keycloak-operator") }}
{{- end }}

{{- define "kcOperator.rbac.clusterrole.kcrealmimportcontroller" -}}
{{- include "kcOperator.rbac.template.clusterrole" (dict "name" "keycloakrealmimportcontroller") }}
{{- end }}

{{- define "kcOperator.rbac.clusterrole.kccontroller" -}}
{{- include "kcOperator.rbac.template.clusterrole" (dict "name" "keycloakcontroller") }}
{{- end }}

{{- define "kcOperator.rbac.clusterrole.kcoidcclientcontroller" -}}
{{- include "kcOperator.rbac.template.clusterrole" (dict "name" "keycloakoidcclientcontroller") }}
{{- end }}

{{- define "kcOperator.rbac.clusterrole.kcsamlclientcontroller" -}}
{{- include "kcOperator.rbac.template.clusterrole" (dict "name" "keycloaksamlclientcontroller") }}
{{- end }}

{{- define "kcOperator.rbac.crbinding.kcOperator" -}}
{{- include "kcOperator.rbac.template.crbinding" (dict "name" "keycloak-operator") }}
{{- end }}

{{- define "kcOperator.rbac.rbinding.kcrealmimportcontroller" -}}
{{- include "kcOperator.rbac.template.rbinding" (dict "name" "keycloakrealmimportcontroller") }}
{{- end }}

{{- define "kcOperator.rbac.rbinding.kccontroller" -}}
{{- include "kcOperator.rbac.template.rbinding" (dict "name" "keycloakcontroller") }}
{{- end }}

{{- define "kcOperator.rbac.rbinding.kcoidcclientcontroller" -}}
{{- include "kcOperator.rbac.template.rbinding" (dict "name" "keycloakoidcclientcontroller") }}
{{- end }}

{{- define "kcOperator.rbac.rbinding.kcsamlclientcontroller" -}}
{{- include "kcOperator.rbac.template.rbinding" (dict "name" "keycloaksamlclientcontroller") }}
{{- end }}

{{- define "kcOperator.rbac.rbview.kcOperator" -}}
{{- include "kcOperator.rbac.template.rbview" (dict "name" "keycloak-operator") }}
{{- end }}
