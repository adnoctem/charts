{{/*
  Define the Kubernetes pod spec to be reused within the Deployment/StatefulSet.
*/}}
{{- define "outline.podSpec" -}}
replicas: 1
selector:
  matchLabels:
      {{- include "outline.selectorLabels" . | nindent 6 }}
{{- if .Values.strategy -}}
{{- if eq .Values.kind "Deployment" }}
strategy:
{{- else }}
updateStrategy:
{{- end }}
  {{- toYaml .Values.strategy | nindent 4 }}
{{- end }}
template:
  metadata:
    annotations:
      checksum/secrets: {{ include (print $.Template.BasePath "/secrets.yaml") . | sha256sum }}
      checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
        {{- if .Values.podAnnotations }}
        {{- toYaml .Values.podAnnotations | nindent 8 }}
        {{- end }}
    labels:
        {{- include "outline.selectorLabels" . | nindent 8 }}
        {{- if .Values.podLabels -}}
        {{- toYaml .Values.podLabels | nindent 8 }}
        {{- end }}
  spec:
      {{- if .Values.image.pullSecrets }}
    imagePullSecrets:
        {{- toYaml .Values.image.pullSecrets | nindent 8 }}
      {{- end }}
    serviceAccountName: {{ include "outline.serviceAccountName" . }}
    automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
    containers:
      - name: {{ .Chart.Name }}
        image: {{ include "outline.image" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        envFrom:
          - configMapRef:
              name: {{ include "outline.fullname" . }}
        env:
          - name: SECRET_KEY
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.secretKey.existingSecret.name | default (include "outline.secrets.keys" .) }}
                key: {{ .Values.outline.secretKey.existingSecret.key | default "SECRET_KEY" }}
          - name: UTILS_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.utilsSecret.existingSecret.name | default (include "outline.secrets.keys" .) }}
                key: {{ .Values.outline.utilsSecret.existingSecret.key | default "UTILS_SECRET" }}
          - name: DATABASE_URL
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.database.existingSecret.name | default (include "outline.secrets.database" .) }}
                key: {{ .Values.outline.database.existingSecret.key | default "DATABASE_URL" }}
          - name: REDIS_URL
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.redis.existingSecret.name | default (include "outline.secrets.redis" .) }}
                key: {{ .Values.outline.redis.existingSecret.key | default "REDIS_URL" }}
          {{- /* TODO: doesn't work when outline.redis.existingSecret.name is set - see docs/TODO.md */}}
          {{- if and .Values.outline.redis.collaborationUrl (not .Values.outline.redis.existingSecret.name) }}
          - name: REDIS_COLLABORATION_URL
            valueFrom:
              secretKeyRef:
                name: {{ include "outline.secrets.redis" . }}
                key: "REDIS_COLLABORATION_URL"
          {{- end }}
          {{- if .Values.outline.ssl.key }}
          - name: SSL_KEY
            valueFrom:
              secretKeyRef:
                name: {{ printf "%s-ssl" (include "outline.fullname" .) }}
                key: SSL_KEY
          {{- end }}
          {{- if or .Values.outline.smtp.username .Values.outline.smtp.password .Values.outline.smtp.existingSecret.name }}
          - name: SMTP_USERNAME
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.smtp.existingSecret.name | default (include "outline.secrets.smtp" .) }}
                key: "username"
          - name: SMTP_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.smtp.existingSecret.name | default (include "outline.secrets.smtp" .) }}
                key: "password"
          {{- end }}
          {{- if eq .Values.outline.fileStorage.type "s3" }}
          - name: AWS_ACCESS_KEY_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.fileStorage.s3.existingSecret.name | default (include "outline.secrets.s3" .) }}
                key: "accessKeyId"
          - name: AWS_SECRET_ACCESS_KEY
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.fileStorage.s3.existingSecret.name | default (include "outline.secrets.s3" .) }}
                key: "secretAccessKey"
          {{- if or .Values.outline.fileStorage.s3.cloudfront.privateKey .Values.outline.fileStorage.s3.cloudfront.existingSecret.name }}
          - name: AWS_CLOUDFRONT_PRIVATE_KEY
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.fileStorage.s3.cloudfront.existingSecret.name | default (include "outline.secrets.cloudfront" .) }}
                key: "privateKey"
          {{- end }}
          {{- end }}
          {{- if or .Values.outline.auth.oidc.clientId .Values.outline.auth.oidc.existingSecret.name }}
          - name: OIDC_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.oidc.existingSecret.name | default (include "outline.secrets.oidc" .) }}
                key: "clientId"
          - name: OIDC_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.oidc.existingSecret.name | default (include "outline.secrets.oidc" .) }}
                key: "clientSecret"
          {{- end }}
          {{- if or .Values.outline.auth.google.clientId .Values.outline.auth.google.existingSecret.name }}
          - name: GOOGLE_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.google.existingSecret.name | default (include "outline.secrets.google" .) }}
                key: "clientId"
          - name: GOOGLE_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.google.existingSecret.name | default (include "outline.secrets.google" .) }}
                key: "clientSecret"
          {{- end }}
          {{- if or .Values.outline.auth.slack.clientId .Values.outline.auth.slack.existingSecret.name }}
          - name: SLACK_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.slack.existingSecret.name | default (include "outline.secrets.slack" .) }}
                key: "clientId"
          - name: SLACK_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.slack.existingSecret.name | default (include "outline.secrets.slack" .) }}
                key: "clientSecret"
          {{- end }}
          {{- if or .Values.outline.auth.azure.clientId .Values.outline.auth.azure.existingSecret.name }}
          - name: AZURE_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.azure.existingSecret.name | default (include "outline.secrets.azure" .) }}
                key: "clientId"
          - name: AZURE_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.azure.existingSecret.name | default (include "outline.secrets.azure" .) }}
                key: "clientSecret"
          {{- end }}
          {{- if or .Values.outline.auth.discord.clientId .Values.outline.auth.discord.existingSecret.name }}
          - name: DISCORD_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.discord.existingSecret.name | default (include "outline.secrets.discord" .) }}
                key: "clientId"
          - name: DISCORD_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.auth.discord.existingSecret.name | default (include "outline.secrets.discord" .) }}
                key: "clientSecret"
          {{- end }}
          {{- if or .Values.outline.integrations.github.clientId .Values.outline.integrations.github.appId .Values.outline.integrations.github.existingSecret.name }}
          - name: GITHUB_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.github.existingSecret.name | default (include "outline.secrets.github" .) }}
                key: "clientId"
                optional: true
          - name: GITHUB_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.github.existingSecret.name | default (include "outline.secrets.github" .) }}
                key: "clientSecret"
                optional: true
          - name: GITHUB_WEBHOOK_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.github.existingSecret.name | default (include "outline.secrets.github" .) }}
                key: "webhookSecret"
                optional: true
          - name: GITHUB_APP_PRIVATE_KEY
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.github.existingSecret.name | default (include "outline.secrets.github" .) }}
                key: "appPrivateKey"
                optional: true
          {{- end }}
          {{- if or .Values.outline.integrations.gitlab.clientId .Values.outline.integrations.gitlab.existingSecret.name }}
          - name: GITLAB_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.gitlab.existingSecret.name | default (include "outline.secrets.gitlab" .) }}
                key: "clientId"
          - name: GITLAB_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.gitlab.existingSecret.name | default (include "outline.secrets.gitlab" .) }}
                key: "clientSecret"
          {{- end }}
          {{- if or .Values.outline.integrations.linear.clientId .Values.outline.integrations.linear.existingSecret.name }}
          - name: LINEAR_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.linear.existingSecret.name | default (include "outline.secrets.linear" .) }}
                key: "clientId"
          - name: LINEAR_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.linear.existingSecret.name | default (include "outline.secrets.linear" .) }}
                key: "clientSecret"
          {{- end }}
          {{- if or .Values.outline.integrations.slack.verificationToken .Values.outline.integrations.slack.existingSecret.name }}
          - name: SLACK_VERIFICATION_TOKEN
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.slack.existingSecret.name | default (include "outline.secrets.slackIntegration" .) }}
                key: "verificationToken"
          {{- end }}
          {{- if or .Values.outline.integrations.figma.clientId .Values.outline.integrations.figma.existingSecret.name }}
          - name: FIGMA_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.figma.existingSecret.name | default (include "outline.secrets.figma" .) }}
                key: "clientId"
          - name: FIGMA_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.figma.existingSecret.name | default (include "outline.secrets.figma" .) }}
                key: "clientSecret"
          {{- end }}
          {{- if or .Values.outline.integrations.notion.clientId .Values.outline.integrations.notion.existingSecret.name }}
          - name: NOTION_CLIENT_ID
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.notion.existingSecret.name | default (include "outline.secrets.notion" .) }}
                key: "clientId"
          - name: NOTION_CLIENT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.notion.existingSecret.name | default (include "outline.secrets.notion" .) }}
                key: "clientSecret"
          {{- end }}
          {{- if or .Values.outline.integrations.iframely.apiKey .Values.outline.integrations.iframely.existingSecret.name }}
          - name: IFRAMELY_API_KEY
            valueFrom:
              secretKeyRef:
                name: {{ .Values.outline.integrations.iframely.existingSecret.name | default (include "outline.secrets.iframely" .) }}
                key: "apiKey"
          {{- end }}
          {{- if .Values.extraEnvVars }}
          {{- toYaml .Values.extraEnvVars | nindent 10 }}
          {{- end }}
        ports:
          - name: http
            containerPort: {{ .Values.outline.port }}
            protocol: TCP
        {{- if eq .Values.outline.fileStorage.type "local" }}
        volumeMounts:
          - name: {{ include "outline.pv" . }}
            mountPath: {{ .Values.outline.fileStorage.local.rootDir }}
        {{- if .Values.volumeMounts }}
          {{- toYaml .Values.volumeMounts | nindent 12 }}
        {{- end }}
        {{- else if .Values.volumeMounts }}
        volumeMounts:
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
            path: /_health
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
            path: /_health
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
            path: /_health
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
    {{- if eq .Values.outline.fileStorage.type "local" }}
    volumes:
      - name: {{ include "outline.pv" . }}
        persistentVolumeClaim:
          claimName: {{ .Values.outline.data.pvc.existingClaim | default (include "outline.pvc" .) }}
    {{- if .Values.volumes }}
      {{- toYaml .Values.volumes | nindent 8 }}
    {{- end }}
    {{- else if .Values.volumes }}
    volumes:
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
