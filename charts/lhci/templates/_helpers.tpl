{{/*
Expand the name of the chart.
*/}}
{{- define "lhci.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
Reuse release names ending in the chart name; substring matches can collide with database subcharts.
*/}}
{{- define "lhci.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if or (eq $name .Release.Name) (hasSuffix (printf "-%s" $name) .Release.Name) }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lhci.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lhci.labels" -}}
helm.sh/chart: {{ include "lhci.chart" . }}
{{ include "lhci.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lhci.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lhci.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "lhci.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "lhci.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "lhci.image" -}}
{{- $repository := printf "%s/%s" .Values.image.registry .Values.image.repository -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" $repository .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" $repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}
{{- end -}}

{{/* Derived names reserve suffix space before truncating. */}}
{{- define "lhci.suffixedName" -}}
{{- printf "%s-%s" (include "lhci.fullname" .context | trunc (int (sub 62 (len .suffix))) | trimSuffix "-") .suffix -}}
{{- end -}}

{{- define "lhci.dialect" -}}
{{- if .Values.postgresql.enabled -}}postgres
{{- else if .Values.mysql.enabled -}}mysql
{{- else -}}{{ .Values.lhci.storage.sqlDialect }}{{- end -}}
{{- end -}}

{{/* Resolve names through the dependency itself, including fullnameOverride. */}}
{{- define "lhci.databaseHost" -}}
{{- if .Values.postgresql.enabled -}}
{{- include "postgresql.v1.primary.fullname" .Subcharts.postgresql -}}
{{- else if .Values.mysql.enabled -}}
{{- include "mysql.primary.fullname" .Subcharts.mysql -}}
{{- end -}}
{{- end -}}
{{- define "lhci.databaseSecret" -}}
{{- if .Values.postgresql.enabled -}}
{{- include "postgresql.v1.secretName" .Subcharts.postgresql -}}
{{- else if .Values.mysql.enabled -}}
{{- include "mysql.secretName" .Subcharts.mysql -}}
{{- else -}}
{{- .Values.lhci.storage.existingSecret.name | default (include "lhci.suffixedName" (dict "context" . "suffix" "database")) -}}
{{- end -}}
{{- end -}}
{{- define "lhci.databasePasswordKey" -}}
{{- if .Values.postgresql.enabled -}}
{{- include "postgresql.v1.userPasswordKey" .Subcharts.postgresql -}}
{{- else -}}mysql-password{{- end -}}
{{- end -}}

{{/* Scalar options reach both the image startup script and the LHCI CLI. */}}
{{- define "lhci.environment" -}}
LHCI_PORT: {{ .Values.lhci.port | quote }}
LHCI_HOST: {{ .Values.lhci.host | quote }}
LHCI_LOG_LEVEL: {{ .Values.lhci.logLevel | quote }}
LHCI_STORAGE__STORAGE_METHOD: sql
LHCI_STORAGE__SQL_DIALECT: {{ include "lhci.dialect" . | quote }}
LHCI_STORAGE__SQL_DATABASE_PATH: {{ .Values.lhci.storage.sqlDatabasePath | quote }}
LHCI_STORAGE__SQL_CONNECTION_SSL: {{ or .Values.lhci.storage.sqlConnectionSsl (not (empty .Values.lhci.storage.tls.existingSecret)) | quote }}
LHCI_STORAGE__SQL_DANGEROUSLY_RESET_DATABASE: {{ .Values.lhci.storage.sqlDangerouslyResetDatabase | quote }}
LHCI_STORAGE__SQL_MIGRATION_OPTIONS__TABLE_NAME: {{ .Values.lhci.storage.sqlMigrationOptions.tableName | quote }}
LHCI_DB_WAIT_RETRIES: {{ .Values.lhci.dbWait.retries | quote }}
LHCI_DB_WAIT_TIMEOUT: {{ .Values.lhci.dbWait.timeout | quote }}
PSI_CACHEBUST_TIMEOUT_MS: {{ .Values.lhci.psiCollectCron.cachebustTimeoutMs | quote }}
{{- range $name := list "postgresql" "mysql" }}
{{- $db := index $.Values $name }}
{{- if $db.enabled }}
LHCI_STORAGE__SQL_CONNECTION_URL: {{ printf "%s://%s:%v/%s" (include "lhci.dialect" $) (include "lhci.databaseHost" $) (index $db.primary.service.ports $name) ($db.auth.database | urlquery | replace "+" "%20") | quote }}
LHCI_STORAGE__SEQUELIZE_OPTIONS__USERNAME: {{ $db.auth.username | quote }}
{{- end }}
{{- end }}
LHCI_CONFIG: /etc/lhci/lighthouserc.yaml
HOME: {{ .Values.persistence.mountPath | quote }}
{{- if and (ne (include "lhci.dialect" .) "sqlite") (not (or .Values.postgresql.enabled .Values.mysql.enabled)) }}
LHCI_STORAGE__SQL_CONNECTION_URL_FILE: /etc/lhci/database/uri
{{- end }}
{{- if .Values.lhci.basicAuth.enabled }}
LHCI_BASIC_AUTH__USERNAME_FILE: /etc/lhci/basic-auth/username
LHCI_BASIC_AUTH__PASSWORD_FILE: /etc/lhci/basic-auth/password
{{- end }}
{{- end -}}

{{/* Only non-secret structured options enter the ConfigMap. */}}
{{- define "lhci.configuration" -}}
{{- $server := dict "useBodyParser" .Values.lhci.useBodyParser "storage" (dict "sqlDialectOptions" (deepCopy .Values.lhci.storage.sqlDialectOptions) "sequelizeOptions" .Values.lhci.storage.sequelizeOptions) -}}
{{- if .Values.lhci.psiCollectCron.sites -}}
{{- $psi := dict "sites" .Values.lhci.psiCollectCron.sites -}}
{{- if .Values.lhci.psiCollectCron.psiApiEndpoint -}}{{- $_ := set $psi "psiApiEndpoint" .Values.lhci.psiCollectCron.psiApiEndpoint -}}{{- end -}}
{{- $_ := set $server "psiCollectCron" $psi -}}
{{- end -}}
{{- if .Values.lhci.deleteOldBuildsCron -}}{{- $_ := set $server "deleteOldBuildsCron" .Values.lhci.deleteOldBuildsCron -}}{{- end -}}
{{- if .Values.lhci.storage.tls.existingSecret -}}
{{- $_ := set $server.storage.sqlDialectOptions "ssl" (dict "rejectUnauthorized" .Values.lhci.storage.tls.rejectUnauthorized) -}}
{{- end -}}
{{- dict "ci" (dict "server" $server) | toYaml -}}
{{- end -}}

{{/* Cross-field validation survives README/schema regeneration. */}}
{{- define "lhci.validate" -}}
{{- if not (has .Values.kind (list "Deployment" "StatefulSet")) -}}{{ fail "kind must be Deployment or StatefulSet" }}{{- end -}}
{{- if ne .Values.lhci.storage.storageMethod "sql" -}}{{ fail "Only sql storage is supported" }}{{- end -}}
{{- if not (has .Values.lhci.storage.sqlDialect (list "sqlite" "postgres" "mysql")) -}}{{ fail "lhci.storage.sqlDialect must be sqlite, postgres or mysql" }}{{- end -}}
{{- if not (has .Values.lhci.logLevel (list "silent" "verbose")) -}}{{ fail "lhci.logLevel must be silent or verbose" }}{{- end -}}
{{- if or (lt (int .Values.lhci.port) 1) (gt (int .Values.lhci.port) 65535) -}}{{ fail "lhci.port must be between 1 and 65535" }}{{- end -}}
{{- if lt (int .Values.replicaCount) 1 -}}{{ fail "replicaCount must be positive" }}{{- end -}}
{{- if and .Values.postgresql.enabled .Values.mysql.enabled -}}{{ fail "Enable only one database subchart" }}{{- end -}}
{{- $bundled := or .Values.postgresql.enabled .Values.mysql.enabled -}}
{{- $storage := .Values.lhci.storage -}}
{{- if and $bundled (or $storage.sqlConnectionUrl $storage.existingSecret.name) -}}{{ fail "Subcharts cannot be combined with an external database URI or Secret" }}{{- end -}}
{{- if and $storage.sqlConnectionUrl $storage.existingSecret.name -}}{{ fail "Set sqlConnectionUrl or existingSecret, not both" }}{{- end -}}
{{- if and $bundled (ne $storage.sqlDialect "sqlite") (ne $storage.sqlDialect (include "lhci.dialect" .)) -}}{{ fail "The explicit SQL dialect conflicts with the enabled database subchart" }}{{- end -}}
{{- if eq (include "lhci.dialect" .) "sqlite" -}}
  {{- if ne (int .Values.replicaCount) 1 -}}{{ fail "SQLite requires replicaCount=1" }}{{- end -}}
  {{- if or $storage.sqlConnectionUrl $storage.existingSecret.name $storage.tls.existingSecret -}}{{ fail "SQLite does not use external database credentials or TLS" }}{{- end -}}
  {{- if not (hasPrefix (printf "%s/" (trimSuffix "/" .Values.persistence.mountPath)) $storage.sqlDatabasePath) -}}{{ fail "sqlDatabasePath must be inside persistence.mountPath" }}{{- end -}}
  {{- if and (eq .Values.kind "Deployment") .Values.strategy (ne .Values.strategy.type "Recreate") -}}{{ fail "SQLite Deployments require strategy.type=Recreate" }}{{- end -}}
{{- else if not $bundled -}}
  {{- if not (or $storage.sqlConnectionUrl $storage.existingSecret.name) -}}{{ fail "External SQL requires sqlConnectionUrl or existingSecret.name" }}{{- end -}}
{{- end -}}
{{- if and .Values.persistence.existingClaim (not .Values.persistence.enabled) -}}{{ fail "An existing SQLite claim requires persistence.enabled=true" }}{{- end -}}
{{- if not (hasPrefix "/" .Values.persistence.mountPath) -}}{{ fail "persistence.mountPath must be absolute" }}{{- end -}}
{{- if and $storage.tls.certKey (not $storage.tls.keyKey) -}}{{ fail "TLS certKey requires keyKey" }}{{- end -}}
{{- if and $storage.tls.keyKey (not $storage.tls.certKey) -}}{{ fail "TLS keyKey requires certKey" }}{{- end -}}
{{- if and $storage.tls.existingSecret (not (or $storage.tls.caKey $storage.tls.certKey)) -}}{{ fail "TLS Secret requires a CA or client certificate key" }}{{- end -}}
{{- if and .Values.lhci.basicAuth.enabled (not .Values.lhci.basicAuth.existingSecret.name) (not (and .Values.lhci.basicAuth.username .Values.lhci.basicAuth.password)) -}}{{ fail "Basic auth requires username and password or an existing Secret" }}{{- end -}}
{{- if and (or .Values.lhci.psiCollectCron.sites .Values.lhci.deleteOldBuildsCron) (ne (int .Values.replicaCount) 1) -}}{{ fail "Built-in cron jobs require replicaCount=1 to avoid duplicate execution" }}{{- end -}}
{{- if and .Values.lhci.psiCollectCron.sites (not (or .Values.lhci.psiCollectCron.psiApiKey .Values.lhci.psiCollectCron.existingSecret.name)) -}}{{ fail "PSI collection requires an API key or existing Secret" }}{{- end -}}
{{- range .Values.lhci.psiCollectCron.sites -}}
  {{- if not (and .projectSlug .schedule .urls) -}}{{ fail "Each PSI site requires projectSlug, schedule and urls" }}{{- end -}}
{{- end -}}
{{- range .Values.lhci.deleteOldBuildsCron -}}
  {{- if not (and .schedule .maxAgeInDays) -}}{{ fail "Each retention entry requires schedule and maxAgeInDays" }}{{- end -}}
  {{- if lt (int .maxAgeInDays) 1 -}}{{ fail "Retention maxAgeInDays must be positive" }}{{- end -}}
{{- end -}}
{{- range $name := list "postgresql" "mysql" -}}
  {{- $db := index $.Values $name -}}
  {{- if $db.enabled -}}
    {{- if ne $db.architecture "standalone" -}}{{ fail "Database subcharts currently require standalone architecture" }}{{- end -}}
    {{- if not (and $db.auth.username $db.auth.database) -}}{{ fail "Database subcharts require an application username and database" }}{{- end -}}
    {{- if or (eq $db.auth.username "postgres") (eq $db.auth.username "root") -}}{{ fail "Use a dedicated application database user" }}{{- end -}}
  {{- end -}}
{{- end -}}
{{- if and .Values.podDisruptionBudget.enabled (not (kindIs "invalid" .Values.podDisruptionBudget.minAvailable)) (not (kindIs "invalid" .Values.podDisruptionBudget.maxUnavailable)) -}}{{ fail "Set only one of podDisruptionBudget.minAvailable or maxUnavailable" }}{{- end -}}
{{- $managed := include "lhci.environment" . | fromYaml -}}
{{- range .Values.extraEnvVars -}}
  {{- if or (hasKey $managed .name) (hasPrefix "LHCI_" .name) -}}{{ fail (printf "Use dedicated values instead of overriding %s in extraEnvVars" .name) }}{{- end -}}
{{- end -}}
{{- end -}}
