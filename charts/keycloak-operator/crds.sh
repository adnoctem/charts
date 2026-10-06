#!/usr/bin/env bash

set -euo pipefail

CHART_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# shellcheck disable=SC2002
APP_VERSION="$(cat "${CHART_DIR}/Chart.yaml" | yq .appVersion)"

KEYCLOAK_CRD_BASE_URL="https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${APP_VERSION}/kubernetes/keycloaks.k8s.keycloak.org-v1.yml"
KEYCLOAKREALMIMPORTS_BASE_URL="https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${APP_VERSION}/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml"
KEYCLOAKOIDCCLIENTS_BASE_URL="https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${APP_VERSION}/kubernetes/keycloakoidcclients.k8s.keycloak.org-v1.yml"
KEYCLOAKSAMLCLIENTS_BASE_URL="https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/${APP_VERSION}/kubernetes/keycloaksamlclients.k8s.keycloak.org-v1.yml"

DOWNLOADS=(
	"$KEYCLOAK_CRD_BASE_URL"
	"$KEYCLOAKREALMIMPORTS_BASE_URL"
	"$KEYCLOAKOIDCCLIENTS_BASE_URL"
	"$KEYCLOAKSAMLCLIENTS_BASE_URL"
)

for download in "${DOWNLOADS[@]}"; do
	output=$(basename -- "${download}")
	curl -fsSL "${download}" -o "${CHART_DIR}/crds/${output}"
done

echo "Downloaded CRDs for Keycloak Operator version ${APP_VERSION}"
