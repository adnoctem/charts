# Copyright (C) 2024 The Ad Noctem Collective Helm Authors
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.

DBG_MAKEFILE ?=
ifeq ($(DBG_MAKEFILE),1)
$(warning ***** starting Makefile for goal(s) "$(MAKECMDGOALS)")
$(warning ***** $(shell date))
else
# If we're not debugging the Makefile, don't echo recipes.
MAKEFLAGS += -s
endif

# -------------------------------------
# Configuration
# -------------------------------------

SHELL := /bin/bash

export ROOT_DIR = $(shell git rev-parse --show-toplevel)
export ROOT_DIR_NAME = $(shell basename "$(ROOT_DIR)")
export PROJ_NAME = $(shell printf "%s-%s" $(ROOT_DIR_NAME) charts)

# ---------------------------
# Sources
# ---------------------------
FIND_FLAGS := -mindepth 1 -maxdepth 1 -type d

CHARTS := $(shell find $(ROOT_DIR)/charts $(FIND_FLAGS))

SOURCES := $(CHARTS)

# Only export variables from here since we do not want to mix the top-level
# Makefile's notion of 'SOURCES' with the different sub-makes
export

# ---------------------------
# Constants
# ---------------------------

# Build output
OUT_DIR := $(ROOT_DIR)/dist
SCRIPT_DIR := $(ROOT_DIR)/scripts
CONFIG_DIR := $(ROOT_DIR)/config
CONFIG_SSL_DIR := $(CONFIG_DIR)/ssl
CONFIG_K8S_DIR := $(CONFIG_DIR)/k8s
SECRETS_DIR := $(ROOT_DIR)/secrets
CI_DIR := $(ROOT_DIR)/.github
ALL_CHARTS := $(sort $(dir $(wildcard charts/*/)))

# Documentation
DOCS_DIR := $(ROOT_DIR)/docs
GIT_CLIFF_CONFIG := $(DOCS_DIR)/cliff.toml
MARKDOWNLINT_CONFIG := $(CI_DIR)/linters/.markdown-lint.yml
GITLEAKS_CONFIG := $(CI_DIR)/linters/.gitleaks.toml

DATE := $(shell date '+%d.%m.%y-%T')

# Executables
kubectl := kubectl
helm := helm
helmfile := helmfile
kind := kind
npx := npx
cfssl := cfssl
cfssljson := cfssljson

EXECUTABLES := $(helm) $(helmfile) $(kind) $(npx) $(cfssl) $(cfssljson) $(kubectl)

# Packages
README_GEN_PACKAGE := @bitnami/readme-generator-for-helm

define USAGE
$(PROJ_NAME) Makefile

Targets:
--------
env            - Create a development Cluster with $(kind)
build          - Build a Helm Chart's .tgz bundle
install        - Install a Helm Chart onto the development Cluster
upgrade        - Upgrade a currently installed Helm Chart
template       - Template a Helm Chart
dry-install    - Dry-Install a Helm Chart (requires dev environment)
secrets        - Generate Secrets before running the dev environment
prune          - Remove the running development cluster created with $(kind)
clean-dist     - Remove the distribution directory for Helm Charts
clean-secrets  - Remove generated Cluster secrets
tools-check    - Check if you have the required tools installed
registry-login - Log in to the GHCR container registry
lint           - Run CI linting tools ahead of time (requires tools not covered in 'tools-check')
endef


# Internal Helm variables
ifdef CHART
CHART_NAME := $(shell basename $(CHART))
CHART_VERSION := $(shell cat charts/$(CHART_NAME)/Chart.yaml | yq '.version')
endif

# ---------------------------
# User-defined variables
# ---------------------------
PRINT_HELP ?=
CHART ?=
VALUES ?=
RELEASE_NAME ?= $(shell printf "%s-%s" $(CHART_NAME) test)
HELM_ARGS ?=
REGISTRY_USER ?=

# ---------------------------
# Custom functions
# ---------------------------

define log
 @case ${2} in \
	gray)    echo -e "\e[90m${1}\e[0m" ;; \
	red)     echo -e "\e[91m${1}\e[0m" ;; \
	green)   echo -e "\e[92m${1}\e[0m" ;; \
	yellow)  echo -e "\e[93m${1}\e[0m" ;; \
	*)       echo -e "\e[97m${1}\e[0m" ;; \
 esac
endef

define log_info
 $(call log, $(1), "gray")
endef

define log_success
 $(call log, $(1), "green")
endef

define log_notice
 $(call log, $(1), "yellow")
endef

define log_attention
 $(call log, $(1), "red")
endef

# Kustomization for TLS certificates generated with cfssl with 'secrets' target
define kustomization
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
secretGenerator:
	- name: root-ca
		type: "kubernetes.io/tls"
		namespace: cert-manager
		files:
			- tls.crt=ca.pem
			- tls.key=ca-key.pem
		options:
			disableNameSuffixHash: true
endef

# ---------------------------
#   Development Environment
# ---------------------------

define ENV_INFO
# Create a local development environment for Helm charts. This is a wrapper
# target which requires the 'dev-cluster' and 'dev-cluster-bootstrap' Make
# targets.
endef
.PHONY: env
ifeq ($(PRINT_HELP), y)
env:
	echo "$$ENV_INFO"
else
env: cluster cluster-bootstrap
endif

# ---------------------------
#   Helm Chart Targets
# ---------------------------

# The implementation for this target directly contradicts the GNU Make documentation for standard targets and also
# builds the chart documentation and JSON schemas along with the tarballs
# ref: https://www.gnu.org/software/make/manual/html_node/Standard-Targets.html#Standard-Targets
#
# This is due to the fact that Bitnami's README generator generates a JSON schema by default before ever updating the
# chart's README. Separating these steps would require considerable effort with little time savings. Maybe as the number
# of charts grows this will be reconsidered
define ALL_INFO
# Generate updated schemas and README and build all charts.
#
# Arguments:
#   PRINT_HELP: 'y' or 'n'
endef
.PHONY: all
ifeq ($(PRINT_HELP), y)
all:
	echo "$$ALL_INFO"
else
all: dist-dir
	for chart in $(ALL_CHARTS); do $(MAKE) gen CHART=$$chart; done
	prettier --write '**/*.{json,md}'
	for chart in $(ALL_CHARTS); do $(MAKE) build CHART=$$chart;	done
endif

define BUILD_INFO
# Package a Helm Chart and put it into the repository's output directory
# at: ($(OUT_DIR)). The chart may be picked with the 'CHART' Make variable.
#
# Arguments:
#   PRINT_HELP: 'y' or 'n'
#   CHART: charts/.. (any subdirectory)
endef
.PHONY: build
ifeq ($(PRINT_HELP), y)
build:
	echo "$$BUILD_INFO"
else
build: dist-dir
	$(call log_success, "Building Helm Chart $(CHART_NAME) into $(OUT_DIR)")
	$(helm) package $(CHART) --destination $(OUT_DIR)
endif

define INSTALL_INFO
# Install a Helm Chart onto the currently configured cluster. The chart may
# be picked with the 'CHART' Make variable. By default the default values are
# used but they may be configured with the 'VALUES' Make variable. The variable
# however is restricted to chart-local files.
#
# Arguments:
#   PRINT_HELP: 'y' or 'n'
#   RELEASE_NAME: The Helm release to install the chart as
#   CHART: charts/.. (any subdirectory)
#   VALUES: chart-local path to values (e.g. "ci/test-values.yaml")
#   HELM_ARGS: #   HELM_ARGS: extra Helm arguments (e.g. --upgrade)
endef
.PHONY: install
ifeq ($(PRINT_HELP), y)
install:
	echo "$$INSTALL_INFO"
else
install:
	$(call log_success, "Installing Helm Chart $(CHART_NAME) using values: $(VALUES)")
ifdef VALUES
	$(helm) install $(RELEASE_NAME) $(CHART) --values $(CHART)/$(VALUES) $(HELM_ARGS)
else
	$(helm) install $(RELEASE_NAME) $(CHART) $(HELM_ARGS)
endif
endif

define UPGRADE_INFO
# Upgrade a installed Helm Chart in the currently configured cluster. The chart may
# be picked with the 'CHART' Make variable. By default the default values are
# used but they may be configured with the 'VALUES' Make variable. The variable
# however is restricted to chart-local files.
#
# Arguments:
#   PRINT_HELP: 'y' or 'n'
#   RELEASE_NAME: The Helm release to install the chart as
#   CHART: charts/.. (any subdirectory)
#   VALUES: chart-local path to values (e.g. "ci/test-values.yaml")
#   HELM_ARGS: #   HELM_ARGS: extra Helm arguments (e.g. --upgrade)
endef
.PHONY: upgrade
ifeq ($(PRINT_HELP), y)
upgrade:
	echo "$$UPGRADE_INFO"
else
upgrade:
	$(call log_success, "Upgrading Helm Chart $(CHART_NAME) using values: $(VALUES)")
ifdef VALUES
	$(helm) upgrade $(RELEASE_NAME) $(CHART) --values $(CHART)/$(VALUES) --install $(HELM_ARGS)
else
	$(helm) upgrade $(RELEASE_NAME) $(CHART) --install $(HELM_ARGS)
endif
endif

define TEMPLATE_INFO
# Run Helm's template engine on some or all files of a Helm Chart.
# The chart may be picked with the 'CHART' Make variable whereas 'FILE'
# controls which file should be templated. Omitting a value for the Make
# variable 'FILE' runs the template engine for all chart contents.
#
# Arguments:
#   PRINT_HELP: 'y' or 'n'
#   RELEASE_NAME: The Helm release to install the chart as
#   CHART: charts/.. (any subdirectory)
#   VALUES: chart-local path to values (e.g. "ci/test-values.yaml")
#   HELM_ARGS: extra Helm arguments (e.g. -s configmap.yaml)
endef
.PHONY: template
ifeq ($(PRINT_HELP), y)
template:
	echo "$$TEMPLATE_INFO"
else
template:
	$(call log_success, "Templating chart: $(CHART)")
ifdef VALUES
	$(helm) template $(RELEASE_NAME) $(CHART) --values $(CHART)/$(VALUES) --debug $(HELM_ARGS)
else
	$(helm) template $(RELEASE_NAME) $(CHART) --debug $(HELM_ARGS)
endif
endif

define DRY_INSTALL_INFO
# Run a Helm "dry" installation for the specified Helm Chart.
# The chart may be picked with the 'CHART' Make variable. Since Helm
# requires a release name to perform the dry installation the chart name
# will be suffixed with '-test' to satisfy this requirement.
#
# Arguments:
#   PRINT_HELP: 'y' or 'n'
#   CHART: charts/.. (any subdirectory)
#   VALUES: chart-local path to values (e.g. "ci/test-values.yaml")
endef
.PHONY: dry-install
ifeq ($(PRINT_HELP), y)
dry-install:
	echo "$$DRY_INSTALL_INFO"
else
dry-install:
	$(call log_success, "Running Helm dry installation for chart: $(CHART)")
ifdef VALUES
	$(helm) install $(RELEASE_NAME) $(CHART) --values $(CHART)/$(VALUES) --debug --dry-run=client
else
	$(helm) install $(RELEASE_NAME) $(CHART) --debug --dry-run=client
endif
endif

# ---------------------------
#   Secrets
# ---------------------------

define SECRETS_INFO
# Cloudflare's `cfssl` tool to generate a root CA for use within the local Kubernetes cluster.
# Afterwards instruct Kustomize to create a secret named 'root-ca' in the 'cert-manager'
# namespace so that TLS certificates may be issued.
endef
.PHONY: secrets
ifeq ($(PRINT_HELP), y)
secrets:
	echo "$$SECRETS_INFO"
else
secrets: secrets-dir
	$(call log_success, "Generating TLS certificates for local Kubernetes cluster!")
	cd $(SECRETS_DIR) && cfssl genkey -initca $(CONFIG_SSL_DIR)/cfssl-ca-csr.json | cfssljson -bare ca
	$(file > $(SECRETS_DIR)/kustomization.yaml,$(kustomization))
endif

# ---------------------------
#   Code Generation
# ---------------------------

define GENERATE_README_INFO
# Run Bitnami's (VMware) README generator for Helm chart on the specified Chart.
# The generator will use the configuration file 'readme-gen.json' in the 'config'
# subdirectory. The chart may be picked with the 'CHART' Make variable.
#
# Arguments:
#   PRINT_HELP: 'y' or 'n'
#   CHART: charts/.. (any subdirectory)
endef
.PHONY: gen
ifeq ($(PRINT_HELP), y)
gen:
	echo "$$GENERATE_README_INFO"
else
gen:
	$(call log_success, "Generating README Helm Chart table for chart: $(CHART)")
	$(npx) $(README_GEN_PACKAGE) \
		-c $(CONFIG_DIR)/bitnami-readme-gen.json \
		-v $(CHART)/values.yaml \
		-r $(CHART)/README.md \
		-s $(CHART)/values.schema.json
endif

# ---------------------------
#   Housekeeping
# ---------------------------

.PHONY: help
help:
	 $(call log_notice, $$USAGE)

.PHONY: prune
prune:
	$(call log_attention, "Removing development cluster and hosts file configuration")
	$(kind) delete cluster \
		--name $(PROJ_NAME)
	$(SCRIPT_DIR)/hosts.sh remove

.PHONY: clean-dist
clean-dist:
	$(call log_notice, "Removing temporary distribution directories..")
	@rm -rf $(OUT_DIR)

.PHONY: clean-secrets
clean-secrets:
	$(call log_notice, "Removing secret directories..")
	@rm -rf $(SECRETS_DIR)

.PHONY: tools-check
tools-check:
	$(foreach exe,$(EXECUTABLES), $(if $(shell command -v $(exe) 2> /dev/null), $(info Found $(exe)), $(info Please install $(exe))))

# ---------------------------
#   Dependencies
# ---------------------------

.PHONY: dist-dir
dist-dir:
	$(call log_notice, "Creating distribution directory for Helm charts at: $(OUT_DIR)")
	@mkdir -p $(OUT_DIR)

.PHONY: secrets-dir
secrets-dir:
	$(call log_notice, "Creating directory for secrets at: $(SECRETS_DIR)")
	@mkdir -p $(SECRETS_DIR)

.PHONY: cluster
cluster:
	$(call log_success, "Creating local 'kind' Kubernetes cluster using configuration in: $(KIND_CLUSTER_CONFIG)!")
	$(kind) create cluster \
		--config $(CONFIG_K8S_DIR)/cluster/kind-config.yaml \
		--name $(PROJ_NAME) \
		--wait 15s

.PHONY: cluster-bootstrap
cluster-bootstrap:
	$(call log_success, "Bootstrapping development cluster")
	$(helmfile) apply -f $(CONFIG_K8S_DIR)/helmfile.yaml
	$(kubectl) apply -k $(CONFIG_K8S_DIR)/kustomize
	$(SCRIPT_DIR)/hosts.sh add

.PHONY: registry-login
registry-login:
ifndef REGISTRY_USER
	$(call log_attention, "Cannot login to GHCR registry using empty username! REGISTRY_USER must be defined")
else
	gh auth token | helm registry login ghcr.io -u $(REGISTRY_USER) --password-stdin
endif

.PHONY: lint
lint: markdownlint actionlint shellcheck shfmt chart-testing

.PHONY: chart-testing
chart-testing:
ifndef CHART
	ct lint --all
else
	ct lint --charts $(CHART)
endif

.PHONY: markdownlint
markdownlint:
	markdownlint -c $(MARKDOWNLINT_CONFIG) '**/*.md'

.PHONY: actionlint
actionlint:
	actionlint

.PHONY: gitleaks
gitleaks:
	gitleaks detect --no-banner --no-git --redact --config $(GITLEAKS_CONFIG) --verbose --source .

.PHONY: shellcheck
shellcheck:
	shellcheck scripts/**/*.sh -x

.PHONY: shfmt
shfmt:
	shfmt -d .
