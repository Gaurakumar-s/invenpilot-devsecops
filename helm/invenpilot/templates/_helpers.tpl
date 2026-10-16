{{- define "invenpilot.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{- define "invenpilot.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "invenpilot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: invenpilot
{{- end }}

{{- define "invenpilot.backendImage" -}}
{{ .Values.image.registry }}/{{ .Values.image.backend }}:{{ .Values.image.tag }}
{{- end }}

{{- define "invenpilot.frontendImage" -}}
{{ .Values.image.registry }}/{{ .Values.image.frontend }}:{{ .Values.image.tag }}
{{- end }}

{{- define "invenpilot.databaseUrl" -}}
postgresql+psycopg://{{ .Values.postgres.username }}:{{ .Values.postgres.password }}@postgres:5432/{{ .Values.postgres.database }}
{{- end }}
