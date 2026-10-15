{{- define "stockpilot.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{- define "stockpilot.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "stockpilot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: stockpilot
{{- end }}

{{- define "stockpilot.backendImage" -}}
{{ .Values.image.registry }}/{{ .Values.image.backend }}:{{ .Values.image.tag }}
{{- end }}

{{- define "stockpilot.frontendImage" -}}
{{ .Values.image.registry }}/{{ .Values.image.frontend }}:{{ .Values.image.tag }}
{{- end }}

{{- define "stockpilot.databaseUrl" -}}
postgresql+psycopg://{{ .Values.postgres.username }}:{{ .Values.postgres.password }}@postgres:5432/{{ .Values.postgres.database }}
{{- end }}
