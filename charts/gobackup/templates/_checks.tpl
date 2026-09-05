{{/*
  Check whether the given database types are supported
*/}}
{{- define "gobackup.checks.databases" -}}
{{- $allowedList := include "gobackup.config.databases" . | fromJsonArray }}
{{- $modelsLength := len .Values.gobackup.models }}
  {{- if (gt $modelsLength 0) }}
  {{- range $_, $v := .Values.gobackup.models }}
  {{- if (hasKey $v "databases") }}
    {{- range $_, $val := $v.databases }}
    {{- if not has $allowedList $val.type }}
      {{- $errMsg := printf "Invalid database type %s" $val.type }}
      {{- fail $errMsg }}
    {{- end }}
    {{- end }}
  {{- else }}
  {{ fail "Running GoBackup without any databases to backup will leave it within nothing to do" }}
  {{- end }}
  {{- end }}
  {{- end }}
{{- end -}}

{{/*
  Check whether the given storage types are supported
*/}}
{{- define "gobackup.checks.storages" -}}
{{- $allowedList := include "gobackup.config.storages" . | fromJsonArray }}
{{- $modelsLength := len .Values.gobackup.models }}
  {{- if (gt $modelsLength 0) }}
  {{- range $_, $v := .Values.gobackup.models }}
  {{- if (hasKey $v "storages") }}
    {{- range $_, $val := $v.storages }}
    {{- if not has $allowedList $val.type }}
      {{- $errMsg := printf "Invalid storage type %s" $val.type }}
      {{- fail $errMsg }}
    {{- end }}
    {{- end }}
  {{- else }}
  {{ fail "Running GoBackup without any storages to backup won't work" }}
  {{- end }}
  {{- end }}
  {{- end }}
{{- end -}}

{{/*
  Check whether the given notifier types are supported
*/}}
{{- define "gobackup.checks.notifiers" -}}
{{- $allowedList := include "gobackup.config.notifiers" . | fromJsonArray }}
{{- $modelsLength := len .Values.gobackup.models }}
  {{- if (gt $modelsLength 0) }}
  {{- range $_, $v := .Values.gobackup.models }}
  {{- if (hasKey $v "notifiers") }}
    {{- range $_, $val := $v.notifiers }}
    {{- if not has $allowedList $val.type }}
      {{- $errMsg := printf "Invalid notifier type %s" $val.type }}
      {{- fail $errMsg }}
    {{- end }}
    {{- end }}
  {{- else }}
  {{ fail "Running GoBackup without any notifier will leave " }}
  {{- end }}
  {{- end }}
  {{- end }}
{{- end -}}
