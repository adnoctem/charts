{{/*
  Define capabilities - reused in _checks.tpl
*/}}
{{- define "gobackup.config.databases" -}}
  {{- $list := list "mysql" "postgresql" "mongodb" "mssql" "redis" "sqlite" "influxdb2" "mariadb" "etcd" "firebird" }}
  {{- $list | toJson }}
{{- end }}

{{- define "gobackup.config.storages.basicAuth" -}}
  {{- $list := list "ftp" "webdav"  }}
  {{- $list | toJson }}
{{- end }}

{{- define "gobackup.config.storages.basicAuthKP" -}}
  {{- $list := list "sftp" "scp"  }}
  {{- $list | toJson }}
{{- end }}

{{- define "gobackup.config.storages.s3" -}}
  {{- $list := list "s3" "oss" "r2" "spaces" "b2" "cos" "us3" "kodo" "bos" "minio" "obs" "tos" "upyun"  }}
  {{- $list | toJson }}
{{- end }}

{{- define "gobackup.config.storages" -}}
  {{- $basicAuthStorages := (include "gobackup.config.storages.basicAuth") | fromJsonArray }}
  {{- $basicAuthKPStorages := (include "gobackup.config.storages.basicAuthKP") | fromJsonArray }}
  {{- $basicAuthS3Storages := (include "gobackup.config.storages.s3") | fromJsonArray }}
  {{- $list := list "local" "gcs" "azure" $basicAuthStorages $basicAuthKPStorages $basicAuthS3Storages }}
  {{- $list | toJson }}
{{- end }}

{{- define "gobackup.config.notifiers" -}}
  {{- $list := list "mail" "webhook" "discord" "slack" "telegram" "dingtalk" "feishu" "ses" "postmark" "sendgrid" "github" "googlechat" }}
  {{- $list | toJson }}
{{- end }}


{{/*
  Basic configuration templates
*/}}
{{- define "gobackup.config.templates.base" -}}
description: {{ .description }}
default_storage: {{ .default }}
{{- if .schedule }}
schedule:
  {{- toYaml .schedule | nindent 2 }}
{{- end }}
{{- if .scripts.before }}
before_script: {{ toYaml .scripts.before }}
{{- end }}
{{- if .scripts.after }}
after_script: {{ toYaml .scripts.after }}
{{- end }}
{{- if .compression }}
compress_with:
  type: {{ .compression }}
{{- end }}
{{- if .encryption }}
encrypt_with:
  type: openssl
  password: {{ include "gobackup.env.encryption.password" (dict "model" .name) }}
  {{- toYaml (omit .encryption "password") | nindent 2 }}
{{- end }}
{{- if .archive }}
archive:
  {{- toYaml .archive | nindent 2 }}
{{- end }}
{{- if .splitter }}
split_with:
  {{- toYaml .splitter | nindent 2 }}
{{- end }}
{{- end }}

{{/*
  Configuration templates
*/}}
{{- define "gobackup.config.templates.database" -}}
{{ .name }}:
  type: {{ .type }}
  {{- toYaml (omit .config "username" "password") | nindent 2 }}
  username: ${ {{- include "gobackup.env.username" (dict "model" .model "type" .type) -}} }
  password: ${ {{- include "gobackup.env.password" (dict "model" .model "type" .type) -}} }
{{- end }}

{{- define "gobackup.config.templates.storage" -}}
{{ .name }}:
  type: {{ .type }}
  {{- toYaml (omit .config "username" "password" "private_key" "passphrase" "credentials" "client_id" "client_secret" "access_key_id" "secret_access_key") | nindent 2 }}
  {{- if (has .type (include "gobackup.config.storages.basicAuth" . | fromJsonArray )) }}
  username: ${ {{- include "gobackup.env.username" (dict "model" .model "type" .type) -}} }
  password: ${ {{- include "gobackup.env.password" (dict "model" .model "type" .type) -}} }
  {{- end }}
  {{- if (has .type (include "gobackup.config.storages.basicAuthKP" . | fromJsonArray )) }}
  username: ${ {{- include "gobackup.env.username" (dict "model" .model "type" .type) -}} }
  password: ${ {{- include "gobackup.env.password" (dict "model" .model "type" .type) -}} }
  private_key: ${ {{- include "gobackup.env.privateKey" (dict "model" .model "type" .type) -}}}
  passphrase: ${ {{- include "gobackup.env.passphrase" (dict "model" .model "type" .type) -}} }
  {{- end }}
  {{- if eq .type "gcs" }}
  credentials: ${ {{- include "gobackup.env.credentials" (dict "model" .model "type" .type) -}} }
  {{- end }}
  {{- if eq .type "azure" }}
  client_id: ${ {{- include "gobackup.env.clientId" (dict "model" .model "type" .type) -}} }
  client_secret: ${ {{- include "gobackup.env.clientSecret" (dict "model" .model "type" .type) -}} }
  {{- end }}
  {{- if (has .type (include "gobackup.config.storages.s3" . | fromJsonArray )) }}
  access_key_id: ${ {{- include "gobackup.env.accessKey" (dict "model" .model "type" .type) -}} }
  secret_access_key: ${ {{- include "gobackup.env.secretKey" (dict "model" .model "type" .type) -}} }
  {{- end }}
{{- end }}

{{- define "gobackup.config.templates.notifiers" -}}
{{ .name }}:
  type: {{ .type }}
  {{- toYaml (omit .config "username" "password" "access_key_id" "secret_access_key" "token") | nindent 2 }}
  {{- if eq .type "mail" }}
  username: ${ {{- include "gobackup.env.username" (dict "model" .model "type" .type) -}} }
  password: ${ {{- include "gobackup.env.password" (dict "model" .model "type" .type) -}} }
  {{- end }}
  {{- if eq .type "ses" }}
  access_key_id: ${ {{- include "gobackup.env.accessKey" (dict "model" .model "type" .type) -}} }
  secret_access_key: ${ {{- include "gobackup.env.secretKey" (dict "model" .model "type" .type) -}}}
  {{- end }}
  {{- if (has .type (list "telegram" "github" "postmark" "sendgrid")) }}
  token: ${ {{- include "gobackup.env.token" (dict "model" .model "type" .type) -}} }
  {{- end }}
{{- end }}
