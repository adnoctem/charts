{{/*
  SSO Authentication providers
*/}}
{{- define "linkwarden.auth.providers" -}}
  {{- $list := list "fortytwo" "apple" "atlassian" "auth0" "authelia" "authentik" "azure_ad" "azure_ad_b2c" "battleNet" "box" "bungie" "cognito" "coinbase" "discord" "dropbox" "duende_ids6" "eveOnline" "facebook" "faceit" "foursquare" "freshbooks" "fusionauth" "github" "gitlab" "google" "hubspot" "ids4" "kakao" "keycloak" "line" "linkedin" "mailchimp" "mailru" "naver" "netlify" "oidc" "okta" "onelogin" "osso" "osu!" "patreon" "pinterest" "pipedrive" "reddit" "salesforce" "slack" "spotify" "strava" "synology" "todoist" "twitch" "unitedEffects" "vk" "wikimedia" "wordpress" "yandex" "zitadel" "zoho" "zoom" }}
  {{- $list | toJson }}
{{- end }}

{{- define "linkwarden.auth.providers.withIssuers" }}
  {{- $list := list "auth0" "authentik" "battleNet" "box" "cognito" "ids6" "fusionauth" "ids4" "keycloak" "okta" "onelogin" "osso" "unitedEffects" "zitadel" }}
  {{- $list | toJson }}
{{- end }}

{{- define "linkwarden.auth.providers.withWellKnown" }}
  {{- $list := list "authelia" "oidc" "synology" }}
  {{- $list | toJson }}
{{- end }}

{{/*
  Define reusable environment variables for SSO configuration
*/}}
{{- define "linkwarden.auth.envs.nextPublicEnable" -}}
{{ printf "NEXT_PUBLIC_%s_ENABLED" .provider | upper }}
{{- end }}

{{- define "linkwarden.auth.envs.customName" -}}
{{ printf "%s_CUSTOM_NAME" .provider | upper }}
{{- end }}

{{- define "linkwarden.auth.envs.clientId" -}}
{{ printf "%s_CLIENT_ID" .provider | upper }}
{{- end }}

{{- define "linkwarden.auth.envs.clientSecret" -}}
{{ printf "%s_CLIENT_SECRET" .provider | upper }}
{{- end }}

{{- define "linkwarden.auth.envs.issuer" -}}
{{ printf "%s_ISSUER" .provider | upper }}
{{- end }}

{{- define "linkwarden.auth.envs.wellKnownUrl" -}}
{{ printf "%s_WELLKNOWN_URL" .provider | upper }}
{{- end }}

{{/*
  Authentication secret base name - will be suffixed with the configured provider
*/}}
{{- define "linkwarden.auth.secrets.base" -}}
{{- printf "%s-auth" (include "linkwarden.fullname" .) }}
{{- end }}
