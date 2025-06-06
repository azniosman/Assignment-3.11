{{/*
Expand the name of the chart.
*/}}
{{- define "azni-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "azni-app.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "azni-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "azni-app.labels" -}}
helm.sh/chart: {{ include "azni-app.chart" . }}
{{ include "azni-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "azni-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "azni-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "azni-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "azni-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a name for the component
*/}}
{{- define "azni-app.componentName" -}}
{{- $componentName := .componentName | default "app" -}}
{{- printf "%s-%s" (include "azni-app.fullname" .context) $componentName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate environment-specific labels
*/}}
{{- define "azni-app.environmentLabels" -}}
environment: {{ .Values.global.environment | default "development" }}
{{- end -}}
