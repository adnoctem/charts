{{/* Shared workload spec; callers add kind-specific identity fields. */}}
{{- define "lhci.podSpec" -}}
replicas: {{ .Values.replicaCount }}
selector:
  matchLabels:
    {{- include "lhci.selectorLabels" . | nindent 4 }}
{{- if eq .Values.kind "Deployment" }}
strategy:
  {{- toYaml (.Values.strategy | default (dict "type" "Recreate")) | nindent 2 }}
{{- else }}
updateStrategy:
  {{- toYaml (.Values.strategy | default (dict "type" "RollingUpdate")) | nindent 2 }}
{{- end }}
template:
  metadata:
    labels:
      {{- include "lhci.selectorLabels" . | nindent 6 }}
      {{- with .Values.podLabels }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    annotations:
      checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      checksum/secrets: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
      {{- with .Values.podAnnotations }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
  spec:
    serviceAccountName: {{ include "lhci.serviceAccountName" . }}
    automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
    {{- with .Values.image.pullSecrets }}
    imagePullSecrets:
      {{- range . }}
      - name: {{ . | quote }}
      {{- end }}
    {{- end }}
    {{- with .Values.podSecurityContext }}
    securityContext:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    containers:
      - name: lhci
        image: {{ include "lhci.image" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        env:
          {{- $env := include "lhci.environment" . | fromYaml }}
          {{- range $key, $_ := $env }}
          - name: {{ $key }}
            valueFrom:
              configMapKeyRef:
                name: {{ include "lhci.fullname" $ }}
                key: {{ $key }}
          {{- end }}
          {{- if or .Values.postgresql.enabled .Values.mysql.enabled }}
          - name: LHCI_STORAGE__SEQUELIZE_OPTIONS__PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ include "lhci.databaseSecret" . }}
                key: {{ include "lhci.databasePasswordKey" . }}
          {{- end }}
          {{- if .Values.lhci.psiCollectCron.sites }}
          - name: LHCI_PSI_COLLECT_CRON__PSI_API_KEY
            valueFrom:
              secretKeyRef:
                name: {{ .Values.lhci.psiCollectCron.existingSecret.name | default (include "lhci.suffixedName" (dict "context" . "suffix" "psi")) }}
                key: {{ ternary .Values.lhci.psiCollectCron.existingSecret.key "apiKey" (not (empty .Values.lhci.psiCollectCron.existingSecret.name)) }}
          {{- end }}
          {{- if .Values.lhci.storage.tls.existingSecret }}
          {{- range $name, $key := dict "CA" .Values.lhci.storage.tls.caKey "CERT" .Values.lhci.storage.tls.certKey "KEY" .Values.lhci.storage.tls.keyKey }}
          {{- if $key }}
          - name: LHCI_STORAGE__SQL_DIALECT_OPTIONS__SSL__{{ $name }}
            valueFrom:
              secretKeyRef:
                name: {{ $.Values.lhci.storage.tls.existingSecret }}
                key: {{ $key }}
          {{- end }}
          {{- end }}
          {{- end }}
          {{- with .Values.extraEnvVars }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
        {{- if or .Values.extraEnvVarsSecret .Values.extraEnvVarsConfigMap }}
        envFrom:
          {{- if .Values.extraEnvVarsSecret }}
          - secretRef:
              name: {{ .Values.extraEnvVarsSecret }}
          {{- end }}
          {{- if .Values.extraEnvVarsConfigMap }}
          - configMapRef:
              name: {{ .Values.extraEnvVarsConfigMap }}
          {{- end }}
        {{- end }}
        ports:
          - name: http
            containerPort: {{ .Values.lhci.port }}
        {{- with .Values.securityContext }}
        securityContext:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- with .Values.resources }}
        resources:
          {{- toYaml . | nindent 10 }}
        {{- end }}
        {{- range $name := list "startupProbe" "readinessProbe" "livenessProbe" }}
        {{- $probe := index $.Values $name }}
        {{- if $probe.enabled }}
        {{ $name }}:
          httpGet:
            path: /healthz
            port: http
          {{- omit $probe "enabled" | toYaml | nindent 10 }}
        {{- end }}
        {{- end }}
        volumeMounts:
          - name: config
            mountPath: /etc/lhci
            readOnly: true
          - name: data
            mountPath: {{ .Values.persistence.mountPath | quote }}
          - name: tmp
            mountPath: /tmp
          {{- if and (ne (include "lhci.dialect" .) "sqlite") (not (or .Values.postgresql.enabled .Values.mysql.enabled)) }}
          - name: database
            mountPath: /etc/lhci/database
            readOnly: true
          {{- end }}
          {{- if .Values.lhci.basicAuth.enabled }}
          - name: basic-auth
            mountPath: /etc/lhci/basic-auth
            readOnly: true
          {{- end }}
          {{- with .Values.volumeMounts }}
          {{- toYaml . | nindent 10 }}
          {{- end }}
    volumes:
      - name: config
        configMap:
          name: {{ include "lhci.fullname" . }}
      - name: data
        {{- if and (eq (include "lhci.dialect" .) "sqlite") .Values.persistence.enabled }}
        persistentVolumeClaim:
          claimName: {{ .Values.persistence.existingClaim | default (include "lhci.fullname" .) }}
        {{- else }}
        emptyDir: {}
        {{- end }}
      - name: tmp
        emptyDir: {}
      {{- if and (ne (include "lhci.dialect" .) "sqlite") (not (or .Values.postgresql.enabled .Values.mysql.enabled)) }}
      - name: database
        secret:
          secretName: {{ include "lhci.databaseSecret" . }}
          items:
            - key: {{ ternary .Values.lhci.storage.existingSecret.key "uri" (not (empty .Values.lhci.storage.existingSecret.name)) }}
              path: uri
      {{- end }}
      {{- if .Values.lhci.basicAuth.enabled }}
      - name: basic-auth
        secret:
          secretName: {{ .Values.lhci.basicAuth.existingSecret.name | default (include "lhci.suffixedName" (dict "context" . "suffix" "basic-auth")) }}
          items:
            - key: {{ ternary .Values.lhci.basicAuth.existingSecret.usernameKey "username" (not (empty .Values.lhci.basicAuth.existingSecret.name)) }}
              path: username
            - key: {{ ternary .Values.lhci.basicAuth.existingSecret.passwordKey "password" (not (empty .Values.lhci.basicAuth.existingSecret.name)) }}
              path: password
      {{- end }}
      {{- with .Values.volumes }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
    {{- range $key := list "affinity" "nodeSelector" "tolerations" "initContainers" }}
    {{- with index $.Values $key }}
    {{ $key }}:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- end }}
    {{- with .Values.priorityClassName }}
    priorityClassName: {{ . | quote }}
    {{- end }}
{{- end -}}
