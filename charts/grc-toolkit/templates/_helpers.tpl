{{/*
Expand the name of the chart.
*/}}
{{- define "grc-toolkit.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "grc-toolkit.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label
*/}}
{{- define "grc-toolkit.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "grc-toolkit.selectorLabels" -}}
app.kubernetes.io/name: {{ include "grc-toolkit.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: grc-toolkit
{{- end }}

{{/*
Common labels
*/}}
{{- define "grc-toolkit.labels" -}}
helm.sh/chart: {{ include "grc-toolkit.chart" . }}
{{ include "grc-toolkit.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Image reference
*/}}
{{- define "grc-toolkit.image" -}}
{{- if .Values.image.full -}}
{{- .Values.image.full -}}
{{- else -}}
{{- $reg := .Values.image.registry -}}
{{- $repo := .Values.image.repository -}}
{{- $tag := .Values.image.tag | toString -}}
{{- if $reg -}}
{{- printf "%s/%s:%s" $reg $repo $tag -}}
{{- else -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Namespace name
*/}}
{{- define "grc-toolkit.namespace" -}}
{{- .Values.namespace.name }}
{{- end }}
