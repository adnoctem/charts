{{/*
  Define the Kubernetes pod spec to be reused within the Deployment/StatefulSet.
*/}}
{{- define "vaultwarden.podSpec" -}}
replicas: 1
selector:
  matchLabels:
    {{- include "vaultwarden.selectorLabels" . | nindent 6 }}
{{- if eq (include "vaultwarden.resourceType" .) "Deployment" }}
strategy:
{{- else }}
updateStrategy:
  {{- toYaml .Values.strategy | nindent 4 }}
{{- end }}
template:
  metadata:
    {{- if .Values.podAnnotations }}
    annotations:
      checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      checksum/secrets: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
      {{- if .Values.podAnnotations }}
      {{- toYaml .Values.podAnnotations | nindent 8 }}
      {{- end }}
    {{- end }}
    labels:
      {{- include "vaultwarden.selectorLabels" . | nindent 8 }}
      {{- if .Values.podLabels -}}
      {{- toYaml .Values.podLabels | nindent 8 }}
      {{- end }}
  spec:
    {{- if .Values.image.pullSecrets }}
    imagePullSecrets:
      {{- toYaml .Values.image.pullSecrets | nindent 8 }}
    {{- end }}
    serviceAccountName: {{ include "vaultwarden.serviceAccountName" . }}
    automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
    {{- if .Values.priorityClassName }}
    priorityClassName: {{ .Values.priorityClassName }}
    {{- end }}
    containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        envFrom:
          - configMapRef:
              name: {{ include "vaultwarden.fullname" . }}
        env:
          {{- if or .Values.vaultwarden.adminToken.value .Values.vaultwarden.adminToken.existingSecret.name }}
          - name: ADMIN_TOKEN
            valueFrom:
              secretKeyRef:
                name: {{ .Values.vaultwarden.adminToken.existingSecret.name | default (include "vaultwarden.secrets.admin" .) }}
                key: {{ .Values.vaultwarden.adminToken.existingSecret.key | default "ADMIN_TOKEN" }}
          {{- end }}
          {{- if or .Values.vaultwarden.email.smtp.username .Values.vaultwarden.email.smtp.existingSecret.name }}
          - name: SMTP_USERNAME
            valueFrom:
              secretKeyRef:
                name: {{ .Values.vaultwarden.email.smtp.existingSecret.name | default (include "vaultwarden.secrets.smtp" .) }}
                key: "username"
          {{- end }}
          {{- if or .Values.vaultwarden.email.smtp.password .Values.vaultwarden.email.smtp.existingSecret.name }}
          - name: SMTP_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ .Values.vaultwarden.email.smtp.existingSecret.name | default (include "vaultwarden.secrets.smtp" .) }}
                key: "password"
          {{- end }}
          {{- if .Values.vaultwarden.database.existingSecret.name }}
          - name: DATABASE_URL
            valueFrom:
              secretKeyRef:
                name: {{ .Values.vaultwarden.database.existingSecret.name | default (include "vaultwarden.secrets.db" .) }}
                key: {{ .Values.vaultwarden.database.existingSecret.key | default "uri" }}
          {{- end }}
          {{- if or .Values.vaultwarden.hibpApiKey.existingSecret.name .Values.vaultwarden.hibpApiKey.value }}
          - name: HIBP_API_KEY
            valueFrom:
              secretKeyRef:
                name: {{ .Values.vaultwarden.hibpApiKey.existingSecret.name | default (include "vaultwarden.secrets.hibp" .) }}
                key: {{ .Values.vaultwarden.hibpApiKey.existingSecret.key | default "apiKey" }}
          {{- end }}
          {{- if .Values.vaultwarden.sso.enabled }}
          - name: SSO_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.vaultwarden.sso.existingSecret.name | default (include "vaultwarden.secrets.sso" .) }}
                key: "clientId"
          - name: SSO_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.vaultwarden.sso.existingSecret.name | default (include "vaultwarden.secrets.sso" .) }}
                key: "clientSecret"
          {{- end }}
        ports:
          - name: http
            containerPort: {{ .Values.vaultwarden.rocket.port }}
            protocol: TCP
        volumeMounts:
          - name: {{ include "vaultwarden.pv.name" . }}
            mountPath: {{ .Values.vaultwarden.data.rootPath | default "/data" }}
        {{- if .Values.volumeMounts }}
          {{- toYaml .Values.volumeMounts | nindent 12 }}
        {{- end }}
        {{- if .Values.resources }}
        resources:
          {{- toYaml .Values.resources | nindent 12 }}
        {{- end }}
        {{- if .Values.securityContext }}
        securityContext:
          {{- toYaml .Values.securityContext | nindent 12 }}
        {{- end }}
        {{- if .Values.livenessProbe.enabled }}
        livenessProbe:
          httpGet:
            path: /alive
            port: http
          initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
          periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
          timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
          successThreshold: {{ .Values.livenessProbe.successThreshold }}
          failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
        {{- end }}
        {{- if .Values.readinessProbe.enabled }}
        readinessProbe:
          httpGet:
            path: /alive
            port: http
          initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
          periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
          timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
          successThreshold: {{ .Values.readinessProbe.successThreshold }}
          failureThreshold: {{ .Values.readinessProbe.failureThreshold }}
        {{- end }}
        {{- if .Values.startupProbe.enabled }}
        startupProbe:
          httpGet:
            path: /alive
            port: http
          initialDelaySeconds: {{ .Values.startupProbe.initialDelaySeconds }}
          periodSeconds: {{ .Values.startupProbe.periodSeconds }}
          timeoutSeconds: {{ .Values.startupProbe.timeoutSeconds }}
          successThreshold: {{ .Values.startupProbe.successThreshold }}
          failureThreshold: {{ .Values.startupProbe.failureThreshold }}
        {{- end }}
    {{- if .Values.priorityClassName }}
    priorityClassName: {{ .Values.priorityClassName }}
    {{- end }}
    volumes:
      - name: {{ include "vaultwarden.pv.name" . }}
        persistentVolumeClaim:
          claimName: {{ .Values.vaultwarden.data.pvc.existingClaim | default (include "vaultwarden.pvc.name" .) }}
    {{- if .Values.volumes }}
      {{- toYaml .Values.volumes | nindent 8 }}
    {{- end }}
    {{- if .Values.nodeSelector }}
    nodeSelector:
      {{- toYaml .Values.nodeSelector | nindent 8 }}
    {{- end }}
    {{- if .Values.affinity }}
    affinity:
      {{- toYaml .Values.affinity | nindent 8 }}
    {{- end }}
    {{- if .Values.tolerations }}
    tolerations:
      {{- toYaml .Values.tolerations | nindent 8 }}
    {{- end }}
    {{- if .Values.podSecurityContext }}
    securityContext:
      {{- toYaml .Values.podSecurityContext | nindent 8 }}
    {{- end }}
    {{- if .Values.initContainers }}
    initContainers:
      {{- toYaml .Values.initContainers | nindent 8 }}
    {{- end }}
{{- end }}
