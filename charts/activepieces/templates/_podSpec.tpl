{{/*
  Define the Kubernetes pod spec to be reused within the Deployment/StatefulSet.
*/}}
{{- define "activepieces.podSpec" -}}
replicas: 1
selector:
  matchLabels:
      {{- include "activepieces.selectorLabels" . | nindent 6 }}
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
        {{- include "activepieces.selectorLabels" . | nindent 8 }}
        {{- if .Values.podLabels -}}
        {{- toYaml .Values.podLabels | nindent 8 }}
        {{- end }}
  spec:
      {{- if .Values.image.pullSecrets }}
    imagePullSecrets:
        {{- toYaml .Values.image.pullSecrets | nindent 8 }}
      {{- end }}
    serviceAccountName: {{ include "activepieces.serviceAccountName" . }}
    automountServiceAccountToken: {{ .Values.serviceAccount.automount }}
    containers:
      - name: {{ .Chart.Name }}
        image: {{ include "activepieces.image" . }}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        envFrom:
          - configMapRef:
              name: {{ include "activepieces.fullname" . }}
        env:
          - name: AP_ENCRYPTION_KEY
            valueFrom:
              secretKeyRef:
                name: {{ default (include "activepieces.secrets.encryption" .) .Values.activepieces.encryption.existingSecret }}
                key: connection
          - name: AP_JWT_SECRET
            valueFrom:
              secretKeyRef:
                name: {{ default (include "activepieces.secrets.encryption" .) .Values.activepieces.encryption.existingSecret }}
                key: jwt
          {{- if and .Values.activepieces.queue.enableUI (or .Values.activepieces.queue.username .Values.activepieces.queue.existingSecret) }}
          - name: AP_QUEUE_UI_USERNAME
            valueFrom:
              secretKeyRef:
                name: {{ default (include "activepieces.secrets.queue" .) .Values.activepieces.queue.existingSecret }}
                key: username
          - name: AP_QUEUE_UI_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ default (include "activepieces.secrets.queue" .) .Values.activepieces.queue.existingSecret }}
                key: password
          {{- end }}
          {{- if and (eq .Values.activepieces.database "postgres") (or .Values.activepieces.postgresql.username .Values.activepieces.postgresql.existingSecret) }}
          - name: AP_POSTGRES_USERNAME
            valueFrom:
              secretKeyRef:
                name: {{ default (include "activepieces.secrets.postgresql" .) .Values.activepieces.postgresql.existingSecret }}
                key: username
          - name: AP_POSTGRES_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ default (include "activepieces.secrets.postgresql" .) .Values.activepieces.postgresql.existingSecret }}
                key: password
          {{- end }}
          {{- if and (eq .Values.activepieces.queue.mode "redis") (or .Values.activepieces.redis.password .Values.activepieces.redis.existingSecret) }}
          {{- if .Values.activepieces.redis.username }}
          - name: AP_REDIS_USER
            valueFrom:
              secretKeyRef:
                name: {{ default (include "activepieces.secrets.redis" .) .Values.activepieces.redis.existingSecret }}
                key: username
          {{- end }}
          - name: AP_REDIS_PASSWORD
            valueFrom:
              secretKeyRef:
                name: {{ default (include "activepieces.secrets.redis" .) .Values.activepieces.redis.existingSecret }}
                key: password
          {{- end }}
          {{- if or .Values.activepieces.copilot.openAI.apiKey .Values.activepieces.copilot.openAI.existingSecret }}
          - name: AP_OPENAI_API_KEY
            valueFrom:
              secretKeyRef:
                name: {{ default (include "activepieces.secrets.openai" .) .Values.activepieces.copilot.openAI.existingSecret }}
                key: apiKey
          {{- end }}
          {{- if .Values.extraEnvVars }}
          {{- toYaml .Values.extraEnvVars | nindent 10 }}
          {{- end }}
        ports:
          - name: http
            containerPort: 80
            protocol: TCP
        volumeMounts:
          - name: {{ include "activepieces.pv" . }}
            mountPath: {{ .Values.activepieces.data.rootPath }}
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
            path: /
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
            path: /
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
            path: /
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
      - name: {{ include "activepieces.pv" . }}
        persistentVolumeClaim:
          claimName: {{ default (include "activepieces.pvc" .) .Values.activepieces.data.pvc.existingClaim }}
    {{- if .Values.volumes }}
      {{- toYaml .Values.volumes | nindent 8 }}
    {{- end }}
    {{- if .Values.priorityClassName }}
    priorityClassName: {{ .Values.priorityClassName }}
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
