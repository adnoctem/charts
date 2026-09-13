# Helm Charts Architecture

This repository contains independently versioned Helm charts maintained by Ad Noctem Collective. Each chart
configures Kubernetes resources for an application or operator; the application runs in its container image.
Charts are distributed through a Helm repository and an OCI registry.

This document describes the repository boundaries and release flow. Each [chart README][charts] owns its
installation and configuration reference. [Contributing][contributing] owns development practices and naming rules.

## Layout

```text
├── charts/<name>/
│   ├── Chart.yaml          # Chart version, application version, metadata and dependencies
│   ├── values.yaml         # Defaults and parameter documentation
│   ├── values.schema.json  # Generated values schema
│   ├── README.md           # User guide and generated parameter tables
│   ├── templates/          # Kubernetes manifests and shared Helm partials
│   └── ci/                 # Values files for chart-testing and local development
├── config/                 # Testing, releasing, code generation and local cluster configuration
├── docs/                   # Architecture, project policies and contributor guidance
├── scripts/hosts.sh        # Local development hostname management using libsh
├── dist/                   # Generated chart packages; gitignored
├── secrets/                # Local CA material and local notes; gitignored
├── .github/workflows/      # Quality checks, chart tests and publication
└── Makefile                # Supported entrypoint for repository development tasks
```

Root `AGENTS.md` links to `docs/AGENTS.md` for agent-facing guidance. Development documentation stays outside
chart directories so it is not shipped as chart documentation or published to Artifact Hub.

## Chart and Application Boundaries

`Chart.yaml` has two separate versions: `version` identifies the chart package, while `appVersion` identifies
the application release. Image defaults live in `values.yaml`; changing the image does not automatically migrate
application data or make an arbitrary image version compatible with the chart.

Templates render application configuration, workloads, Services, storage and optional resources such as Ingress
and disruption budgets. Supported resources vary by chart. Shared template logic belongs in underscore-prefixed
partials. Application startup, credential processing and database migrations belong in the application container.

Some charts offer optional database or application subcharts. Their dependencies are declared in `Chart.yaml`;
lockfiles and downloaded packages are not committed. Resolve dependencies before rendering or packaging a checkout.
For production, prefer external or operator-managed databases where the chart supports them. Read the chart's
storage and upgrade guidance before changing database backends, workload types or persistent claims.

## Configuration and Generated Documentation

The annotated `values.yaml` is the source for both the values schema and README parameter tables.
`make gen CHART=charts/<name>` runs the README generator using [the shared configuration][generator]. Edit the
source values and comments, then regenerate; do not maintain generated tables or schemas by hand.

The rest of each chart README is maintained manually, including installation examples and upgrade instructions.
The root [overview][overview] is also maintained manually and records chart versions, application versions and
default container image repositories. Every chart change requires a new chart version, including documentation changes.

## Local Development

The root Makefile provides rendering, generation, linting, packaging and deployment targets. Chart targets take
a repository-relative directory, for example `CHART=charts/uptime-kuma`; `VALUES=ci/test-values.yaml` is relative
to that chart. See [Contributing][contributing] for the complete workflow.

The development environment uses kind, ingress-nginx, cert-manager and Kustomize. `make secrets` creates local
CA material; `make env` creates and bootstraps the cluster and adds `*.charts.internal` hostnames.
The hostname script requires an installed [libsh][libsh] and `LIBSH_DIR` pointing to the directory containing
`lib.sh`. It confirms host-file edits and uses sudo when necessary. This dependency is for development tooling;
installing a published chart does not require libsh or this checkout.

Install and upgrade targets use the active kubeconfig context and namespace unless explicitly overridden.
`make prune` deletes the development cluster and removes the managed host entries. The environment is disposable;
it is not a production cluster configuration. See [Security][security] for its trust boundaries.

## Verification and Publishing

The [Testing workflow][testing] runs pre-commit checks, identifies changed charts, validates them with
chart-testing and Artifact Hub's linter, and installs charts in kind. Chart-testing uses the `ci/*-values.yaml`
fixtures separately. These checks validate the chart deployment; they do not replace upstream application tests
or production migration testing. Super-Linter provides additional repository checks.

Successful chart testing on pushes to `main` dispatches the [Release workflow][release]. It can also be started
manually. Chart-releaser signs packages, creates GitHub releases and updates the Pages repository index. The
workflow also pushes packages to `oci://ghcr.io/adnoctem/charts`. Artifact Hub indexes the published repository.

Charts release independently. Conventional commit messages describe changes, while each chart's `Chart.yaml`
version determines its package version; this repository does not use libsh's semantic-release versioning flow.
Released versions are immutable. Review the chart's upgrade notes and pin the chart version when deploying.

Charts at `0.x.y` remain in pre-1.0 development: breaking changes use a minor chart version bump and require
migration notes. Each chart advances to stable `1.0.0` only after an explicit maintainer decision based on testing
and operational validation. Application versions do not determine chart stability. The
[versioning policy][versioning] covers both pre-1.0 and stable releases.

<!-- File references -->

[charts]: ../charts
[contributing]: CONTRIBUTING.md
[versioning]: CONTRIBUTING.md#versioning
[security]: SECURITY.md
[generator]: ../config/bitnami-readme-gen.json
[overview]: ../README.md#-overview
[testing]: ../.github/workflows/testing.yaml
[release]: ../.github/workflows/release.yaml

<!-- General links -->

[libsh]: https://github.com/adnoctem/libsh
