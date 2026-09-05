{{- /*
Set the names of the secrets
*/}}
{{- define "paperless.secrets.general" -}}
{{- printf "%s-general" (include "paperless.fullname" .) }}
{{- end }}

{{- define "paperless.secrets.admin" -}}
{{- printf "%s-admin" (include "paperless.fullname" .) }}
{{- end }}

{{- define "paperless.secrets.postgresql" -}}
{{- printf "%s-postgresql-auth" (include "paperless.fullname" .) }}
{{- end }}

{{- define "paperless.secrets.redis" -}}
{{- printf "%s-redis-auth" (include "paperless.fullname" .) }}
{{- end }}

{{- define "paperless.secrets.smtp" -}}
{{- printf "%s-smtp-auth" (include "paperless.fullname" .) }}
{{- end }}

{{- define "paperless.secrets.allauth" -}}
{{- printf "%s-allauth" (include "paperless.fullname" .) }}
{{- end }}

{{- /*
Build connection URI's
*/}}
{{- define "paperless.postgresql.host" -}}
{{- if .Values.paperless.postgresql.host -}}
{{- printf "%s" .Values.paperless.postgresql.host }}
{{- else -}}
{{- printf "%s-%s" .Release.Name "postgresql" }}
{{- end -}}
{{- end }}

{{- define "paperless.redis.host" -}}
{{- if .Values.paperless.redis.host -}}
{{- printf "%s" .Values.paperless.redis.host }}
{{- else -}}
{{- printf "%s-%s" .Release.Name "redis-master" }}
{{- end -}}
{{- end }}

{{- define "paperless.redis.uri" -}}
{{- printf "redis://%s:%s@%s:%d" .Values.paperless.redis.username .Values.paperless.redis.password (include "paperless.redis.host" .) (int .Values.paperless.redis.port) }}
{{- end }}

{{- define "paperless.tika.endpoint" -}}
{{- if .Values.paperless.tika.endpoint -}}
{{- printf "%s" .Values.paperless.tika.endpoint }}
{{- else -}}
{{- printf "%s-%s" .Release.Name "tika" }}
{{- end -}}
{{- end }}

{{- define "paperless.tika.uri" -}}
{{- printf "http://%s:%d" (include "paperless.tika.endpoint" .) 9998 }}
{{- end }}

{{- define "paperless.gotenberg.endpoint" -}}
{{- if .Values.paperless.gotenberg.endpoint -}}
{{- printf "%s" .Values.paperless.gotenberg.endpoint }}
{{- else -}}
{{- printf "%s-%s" .Release.Name "gotenberg" }}
{{- end -}}
{{- end }}

{{- define "paperless.gotenberg.uri" -}}
{{- printf "http://%s:%d" (include "paperless.gotenberg.endpoint" .) 80 }}
{{- end }}

{{/*
  Detect or generate a secret key for the installation. If neither an explicit value nor an
  existing Secret is configured, reuse whatever was already persisted in the cluster rather than
  generating a fresh one on every render - otherwise the key (and therefore every active session
  and other signed token) would rotate on every single `helm upgrade`.
*/}}
{{- define "paperless.secretkey" -}}
{{- if .Values.paperless.secretKey.value }}
{{- printf "%s" .Values.paperless.secretKey.value }}
{{- else }}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "paperless.secrets.general" .) }}
{{- if $existing }}
{{- index $existing.data "secretKey" | b64dec }}
{{- else }}
{{- randAlphaNum 32 }}
{{- end }}
{{- end }}
{{- end }}
