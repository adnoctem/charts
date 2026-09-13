# Ad Noctem Collective - `helm` Repository Contributing Guidelines

Contributions are welcome via GitHub's Pull Requests. This document outlines the process to help get your contribution
accepted.

Start with the [Architecture][architecture] for the repository layout and chart release flow. Participation follows
the [Code of Conduct][conduct]; report suspected vulnerabilities privately using the [Security Policy][security].

## ⚒️ Building

The project uses the `Make` build tool with targets defined in the projects top-level [`Makefile`](../Makefile). The
file includes a debug mode that will print usage information for each `make` target when the variable `PRINT_HELP=y` is
defined. It will not execute any commands, but solely print the information so no actions will be taken on your machine.

Before running _any_ other target you should run the `tools-check` target which will look for all executables required
to operate the project locally. If any of the required executables are not found the `make` will let you know.

The hostname setup used by `make env` and `make prune` also requires an installed [libsh][libsh]. Export `LIBSH_DIR`
using the path printed by its installer; it must point to the directory containing `lib.sh`. `make tools-check`
does not check this dependency. The hostname script confirms edits and uses sudo when the host file is not writable.
Installing published charts does not require libsh.

After you have all the necessary tools installed you will want to generate a TLS certificate authority to issue local
TLS certificates for your applications' Ingress manifests. To this you can run:

```shell
make secrets
```

This will create a new `secrets` directory in the project root and fill the directory with a `Kustomization.yaml`, a
TLS certificate as well as a private key, and a CSR (we won't need this). You will need to set up your browser to trust
this CA certificate to avoid TLS issues. For Google Chrome this can be done by navigating to the settings, then
under `Privacy and security > Security > Manage certificates > Authorities` click `Import` and select the generated
certificate.

These files will also be reused when setting up the development environment. Said environment is facilitated
through `kind` and can be created with:

```shell
make env
```

This will set up a new local `kind`, already pre-configured to
be [ingress-ready](https://kind.sigs.k8s.io/docs/user/ingress/#ingress-nginx) and
install [Jetstack's Cert-Manager](https://artifacthub.io/packages/helm/cert-manager/cert-manager) as well as
the [Kubernetes Project's Ingress-Nginx Controller](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx).
As mentioned `cert-manager` is already set up to make use of our previously generated CA. Most charts' `ci/test-values`
already include the
necessary `Ingress` [annotations to auto-generate TLS certificates](https://cert-manager.io/docs/usage/certificate/)
with `cert-manager`. Lastly this will also insert the hostnames defined in [`scripts/hosts.sh`](../scripts/hosts.sh) in
your `/etc/hosts/` to be-able to resolve the hostnames in your browser. If your current user has root-privileges then
the script will just insert the hostnames, otherwise you will be prompt for the `sudo` password.

When developing new charts the [`Makefile`](../Makefile) provides a couple of handy targets to `template`, `install`
or `dry-install` any chart. To run them you might execute something like this:

```shell
make template CHART=charts/paperless-ngx VALUES=ci/test-values.yaml RELEASE_NAME=paperless-override
```

Take a look at each target's output with `PRINT_HELP=y` set for more in-depth information.

Updates to the `values.schema.json` and the `README.md` can be performed with the `make gen` target:

```shell
make gen CHART=charts/paperless-ngx
```

If you have made a general change like a stylistic one for the chart `README` or any change which might affect multiple
charts at a time you might want to regenerate the `values.schema.json` and `README.md` files and re-build all charts.
This can be achieved with the `all` target:

```shell
make all
```

When you're done and want to delete the cluster as well as the hostnames inserted in your `/etc/hosts` you might
run the `prune` target which will revert these changes for you.

```shell
make prune
```

## ℹ️ Commit Message Format

This specification is inspired by and supersedes the **AngularJS commit message format**.

We have very precise rules over how our Git commit messages must be formatted.
This format leads to **easier to read commit history**.

Each commit message consists of a **header**, a **body**, and a **footer**.

```text
<header>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

The `header` is mandatory and must conform to the [Commit Message Header](#commit-header) format.

The `body` is mandatory for all commits except for those of type "docs".
When the body is present it must be at least 20 characters long and must conform to
the [Commit Message Body](#commit-body) format.

The `footer` is optional. The [Commit Message Footer](#commit-footer) format describes what the footer is used for and
the structure it must have.

### <a name="commit-header"></a>Commit Message Header

```text
<type>(<scope>): <short summary>
  │       │             │
  │       │             └─⫸ Summary in present tense. Not capitalized. No period at the end.
  │       │
  │       └─⫸ Commit Scope: charts|make|scripts|docs
  │
  └─⫸ Commit Type: build|ci|docs|feat|fix|perf|refactor|test
```

The `<type>` and `<summary>` fields are mandatory, the `(<scope>)` field is optional.

#### Type

Must be one of the following:

- **feat**: New features
- **fix**: bugfixes
- **docs**: Documentation changes
- **refactor**: Code changes which neither add features nor fix bugs
- **test**: Adding tests or improving upon existing tests
- **chore**: Miscellaneous maintenance tasks which can generally be ignored
- **build**: Changes or improvements to the build tool or to the projects dependencies (_supported Scopes_: `make`)
- **ci**: Changes to CI configuration files and scripts (_supported Scopes_: `actions`)

#### Scopes

The following is the list of supported scopes:

- `charts` - Changes affecting a multitude of charts at once
- `charts/*` - Changes affecting single charts
- `k8s` - Changes to Kubernetes manifests (development setup)
- `make` - Changes affecting the Make-based build tool
- `scripts` - Changes to scripts
- `config` - Changes to configuration files

#### Summary

Use the summary field to provide a succinct description of the change:

- use the imperative, present tense: "change" not "changed" nor "changes"
- don't capitalize the first letter
- no dot (.) at the end

#### <a name="commit-body"></a>Commit Message Body

Just as in the summary, use the imperative, present tense: "fix" not "fixed" nor "fixes".

Explain the motivation for the change in the commit message body. This commit message should explain _why_ you are
making the change.
You can include a comparison of the previous behavior with the new behavior in order to illustrate the impact of the
change.

#### <a name="commit-footer"></a>Commit Message Footer

The footer can contain information about breaking changes and deprecations and is also the place to reference GitHub
issues, Jira tickets, and other PRs that this commit closes or is related to.
For example:

```text
BREAKING CHANGE: <breaking change summary>
<BLANK LINE>
<breaking change description + migration instructions>
<BLANK LINE>
<BLANK LINE>
Fixes #<issue number>
```

or

```text
DEPRECATED: <what is deprecated>
<BLANK LINE>
<deprecation description + recommended update path>
<BLANK LINE>
<BLANK LINE>
Closes #<pr number>
```

Breaking Change section should start with the phrase "BREAKING CHANGE: " followed by a summary of the breaking change, a
blank line, and a detailed description of the breaking change that also includes migration instructions.

Similarly, a Deprecation section should start with "DEPRECATED: " followed by a short description of what is deprecated,
a blank line, and a detailed description of the deprecation that also mentions the recommended update path.

#### Revert commits

If the commit reverts a previous commit, it should begin with `revert:`, followed by the header of the reverted commit.

The content of the commit message body should contain:

- information about the SHA of the commit being reverted in the following format: `This reverts commit <SHA>`,
- a clear description of the reason for reverting the commit message.

## 🏗️ Chart Design Principles

These apply to new charts going forward. Existing charts that don't yet follow them will be brought in line
individually, in their own PRs — don't retrofit them as a side effect of unrelated work.

### Mirror the existing charts

Use a neighboring chart as the starting point for `.helmignore`, `Chart.yaml` and `README.md`. Preserve the existing
field order, annotation conventions, logo presentation, installation sections and generated parameter tables;
adapt the application-specific content instead of introducing a new layout or toolchain. Keep end-user chart documentation
in its `README.md`, including detailed configuration references, so it is published on Artifact Hub. Development
notices belong exclusively in `docs/`, as described below. Add the chart to
the root README's overview using the same logo, version columns and reference-style links as the surrounding entries.
Use the existing `make gen` and chart-testing workflows, with additional `ci/*-values.yaml` fixtures where needed.

### One resource per file

Each `templates/*.yaml` file should render exactly one Kubernetes resource, named after that resource's kind in
`camelCase` (`configmap.yaml`, `deployment.yaml`, `statefulset.yaml`, `pvc.yaml`, `svc.yaml`, `ingress.yaml`, `pdb.yaml`,
`rbac.yaml`, `serviceaccount.yaml`). The one exception is when a chart genuinely needs to render **more than one
resource of the same kind** — in that case, combine them into a single file and pluralize the filename
(`secrets.yaml` for multiple `Secret` resources, for example), separated by `---` document markers. Don't create
`secret-admin.yaml`, `secret-smtp.yaml`, etc. as separate files for the same resource kind.

Shared template logic that isn't a resource on its own (label helpers, a reusable pod spec included by both
`deployment.yaml` and `statefulset.yaml`, name-generation helpers) goes in a `_`-prefixed partial
(`_helpers.tpl`, `_podSpec.tpl`) — the leading underscore keeps Helm from attempting to render it as its own
manifest.

### Prefer dedicated `values.yaml` fields over `extraEnvVars`

An `extraEnvVars`-style generic passthrough field is a valid escape hatch, but it isn't a substitute for actually
modeling a chart's configuration surface. For a new chart, the goal is to expose **every environment variable the
upstream application supports** as its own documented, typed `values.yaml` field, grouped sensibly (`database.*`,
`redis.*`, `smtp.*`, `auth.<provider>.*`, and so on) — not to reach for `extraEnvVars` as a shortcut past the
less-common settings.

This matters because these charts are meant to be genuinely high-quality references, not thin wrappers that punt
config modeling to the end user. A dedicated field gets a `## @param` description, a sensible default, schema
validation, and shows up in the generated README's parameter tables — none of which `extraEnvVars` gets you.

If a small number of settings genuinely can't reasonably get a dedicated field in a chart's first version (an
upstream integration so obscure it isn't worth a whole values section yet, for example), `extraEnvVars` is fine as
a deliberate, documented exception — not a default. Note explicitly in the chart's README which upstream settings
are only reachable that way, and why, so a future pass has a clear list of what's left to model properly rather
than an unexplained gap.

### Separate end-user and development documentation

A chart's `README.md` is exclusively for end users: installation, configuration, operational limitations, upgrades,
backup/persistence behavior and generated parameter tables. Development commands, fixture coverage, CI-specific
image choices, maintainer notes and implementation handoffs belong **only in the repository's `docs/` directory**.
Use the chart-specific development section below for chart workflows and test prerequisites. Larger development
plans can have their own document under `docs/`; do not ship them as extra documentation files inside a chart.

### Keep application responsibilities in the container

Charts configure and deploy the supported container interface. Use native environment variables, Secret references
and application configuration files rendered in ConfigMaps or Secrets. Preserve the image's entrypoint and startup
logic; do not add runtime JavaScript helpers, shell wrappers or credential-processing scripts to the chart.
Application regression tests and API smoke-test programs belong in the container project, not in chart-specific
Helm test pods or additional test harnesses. Use the existing chart-testing workflow and `ci/*-values.yaml` fixtures
for chart validation.

If our own image needs enhancements, describe them in a `docs/` handoff for the container maintainer. Follow that
project's existing shell scripts and shared libraries when implementing startup, secrets or diagnostic behavior.
Expose only functionality the released image actually supports; record user-facing limitations in the chart README.
For a separately versioned container project, `appVersion` tracks that container release, and the README also states
the bundled upstream application version.

### Workloads, persistence and Secrets

File-backed storage does not inherently require a StatefulSet. Choose a suitable default workload; a single-replica
Deployment with a PVC and `Recreate` strategy is appropriate for SQLite. When both Deployment and StatefulSet are
supported, share their pod specification in `_podSpec.tpl`, keeping resource-kind-specific fields and update
strategies in the correct manifests. Use a governing headless Service for StatefulSets where needed.

Model persistence, existing claims and retention explicitly. Prevent unsafe configurations such as multiple SQLite
writers or overlapping SQLite Deployment rollouts. Explain backups, claim retention and backend/workload migration
in end-user documentation. Offer existing Secret references for production credentials; do not duplicate a database
subchart's generated passwords or read Secrets with Helm `lookup` just to reconstruct connection strings. Application
credential normalization belongs in the container or its native configuration interface.

### Optional database subcharts

Follow neighboring charts for optional Bitnami dependencies under `oci://registry-1.docker.io/bitnamicharts`.
The Helm dependency repository is distinct from the container image repository. Keep the self-contained application
backend as the default when appropriate (SQLite for LHCI), make backend selection unambiguous, and reject conflicting
subchart/external database settings. Resolve names, service ports and Secret keys consistently with the dependency,
including overrides.

Provide an external database path suitable for CNPG or another database operator; that is our preferred production
setup. Subcharts are a convenience. Explain image availability and licensing limitations prominently in the end-user
README, as Paperless does. Verify actual image availability and compatibility instead of assuming a historical tag,
`latest`, or a different vendor's image is interchangeable. Keep any approved CI-only archived-image overrides in
`ci/*-values.yaml`, with their rationale in `docs/`, rather than changing production defaults for the sake of CI.

### Exercise the chart API in CI values

`ci/test-values.yaml` should be an expansive, runnable development configuration, not a minimal readiness smoke test.
Use `paperless-ngx` and `linkwarden` as examples. Exercise meaningful non-default settings across the chart's API:
application options, authentication, persistence, ingress/TLS, Services, probes, resources, security contexts,
service accounts, scheduling, metadata, disruption budgets and supported environment/volume extensions.

For alternative backends or workload types, add separate, independently installable fixtures such as
`ci/mysql-values.yaml` and `ci/postgresql-values.yaml`. Chart-testing installs each file separately; a fixture must not
rely on values or resources from another fixture. Distribute mutually exclusive configurations across the fixtures
rather than enabling incompatible features together. Vary ports, names and Secret keys where possible to catch
hard-coded assumptions. Prefer real settings and resource references to commented-out examples or lists of defaults.

Fixtures should work in chart-testing's clean kind environment without production credentials, paid services or
operator-managed resources that CI does not create. Ingress/TLS manifests can use the repository's development
hostnames and issuer; controller reconciliation and browser testing happen on the bootstrapped development cluster.
A plain CI cluster can still validate their manifests without requiring ingress-nginx or cert-manager to be installed.
Do not turn a fixture into an application test program or add a provisioning harness just to cover an external resource.
Document remaining manual cases (existing PVCs/Secrets, operator integration, private registries, external load balancers)
in the chart-specific development section, including prerequisites and the limits of automated coverage.

## 🧪 Chart-specific development

Keep each chart's maintainer workflow, fixture descriptions and development notices here. End users should find
all deployment and operational guidance in the chart README, without having to read this section.

### Lighthouse CI (`lhci`)

The chart uses the existing generation and chart-testing workflow:

```shell
make tools-check
helm dependency update charts/lhci
make gen CHART=charts/lhci
ct lint --config config/ct-config.yaml --charts charts/lhci
ct install --config config/ct-config.yaml --charts charts/lhci
```

The initial chart remains `0.1.0` while it is being developed before its first release; subsequent releases follow
the versioning rules below. Its container release is `1.0.1`, containing upstream LHCI `0.15.1`.

| Fixture                     | Configuration and coverage                                                                                                                                                                                                                                                                                                                                                                                              |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ci/test-values.yaml`       | SQLite Deployment with `Recreate`, custom HTTP/Service ports and SQLite path, migration table and pool options, chart-managed basic auth, PSI configuration, two retention schedules, annotated PVC, ingress/TLS, session affinity, service account, metadata, scheduling, hardened security, an init container and shared scratch volume, extra environment/Secret passthrough, probes and a minimum-availability PDB. |
| `ci/mysql-values.yaml`      | MySQL subchart with custom resource name, database credentials/name and Service port; LHCI Deployment rolling-update strategy, alternate app/Service ports, dialect/pool options, basic auth, writable ephemeral HOME, NodePort with automatic port allocation, an extra Service port, ingress/TLS, resources/probes and a maximum-unavailable PDB.                                                                     |
| `ci/postgresql-values.yaml` | PostgreSQL subchart with custom name/port, auto-generated database TLS certificates, LHCI StatefulSet and governing Service, native CA Secret reference with verification enabled, existing-Secret basic auth using the subchart's service-binding Secret, retention, an existing service account, ingress/TLS, resources/probes and a percentage PDB.                                                                  |

All three fixtures install independently into fresh namespaces. The SQL fixtures pin compatible `bitnamilegacy` images
for CI only because the original `bitnami/*` tags are unavailable. This includes PostgreSQL's `os-shell`
certificate-copy init image when TLS is enabled. These archived images receive no security updates
and are not production recommendations; the chart's default repositories remain `bitnami/*`. The SQL passwords
contain reserved URI characters to exercise the native Sequelize password configuration.

The PostgreSQL fixture reuses its generated service-binding credentials for HTTP basic auth solely to exercise
existing-Secret name/key mapping without an external prerequisite. Production HTTP authentication should use a
separate Secret. The SQLite PSI entry exercises configuration parsing and scheduling, not collection: it uses a
placeholder API key/project and a loopback endpoint that cannot call the real PSI service. Runtime regression tests
belong in the container repository.

For browser testing, bootstrap the development environment described above and install one fixture:

```shell
helm install lhci charts/lhci --namespace lhci-dev --create-namespace -f charts/lhci/ci/test-values.yaml --wait
```

Open `https://lhci.charts.internal` using `ci` / `ci-test-password` and trust the development CA in `secrets/ca.pem`.
The fixture's Service is named `lhci-ci` and exposes port `80`; its application listens on `9101`. The MySQL and
PostgreSQL fixtures use `mysql.lhci.charts.internal` and `postgresql.lhci.charts.internal`; add these to local hostname
resolution if testing them in a browser. They expose HTTP Services on `8080`, targeting app ports `9102` and `9103`.
MySQL basic auth is `mysql-ci` / `ci-http-password`; PostgreSQL uses its fixture database username/password.

Do not install two Ingress resources for the same host/path on a cluster with ingress-nginx admission enabled.
If a development installation already owns a fixture hostname, use another hostname consistently in both
`ingress.hosts` and `ingress.tls`, or remove that development installation before running chart-testing. For example:

```shell
LHCI_CI_INGRESS="--set=ingress.hosts[0].host=lhci-ci.charts.internal"
LHCI_CI_INGRESS+=" --set=ingress.tls[0].hosts[0]=lhci-ci.charts.internal"
ct install --config config/ct-config.yaml --charts charts/lhci --helm-extra-set-args "$LHCI_CI_INGRESS"
```

Remaining manual cases need resources outside these fixtures: an existing SQLite PVC (also test retention/reuse),
external PostgreSQL/MySQL URI Secrets such as CNPG application Secrets, independently managed basic-auth and PSI
Secrets, client TLS certificates, private image-pull Secrets, existing ConfigMap environment passthrough, and
cluster-specific load-balancer, priority-class or dual-stack settings. Provision the prerequisites in the release
namespace, render the corresponding values, install and verify readiness and the intended behavior. Do not add
nonexistent resource names to automated fixtures. Keep `sqlDangerouslyResetDatabase` disabled; destructive reset,
actual PSI collection, application credential parsing and database migration regression coverage belong in the
container project. A ready `/healthz` alone does not prove ongoing SQL connectivity or successful scheduled jobs.

## ✅ How to Contribute

1. Fork this repository, develop, and test your changes
2. Add your GitHub username to the [`AUTHORS`](../.github/AUTHORS) and [`CODEOWNERS`](../.github/CODEOWNERS) files
3. Submit a pull request

_**NOTE**_: In order to make testing and merging of PRs easier, please submit changes to multiple charts in separate
PRs.

### Technical Requirements

- Must follow [Charts best practices](https://helm.sh/docs/topics/chart_best_practices/)
- Must pass CI jobs for linting and installing changed charts with
  the [chart-testing](https://github.com/helm/chart-testing) tool
- Any change to a chart requires a version bump following [SemVer](https://semver.org/) principles.
  See [Immutability](#immutability) and [Versioning](#versioning) below

Once changes have been merged, the release job will automatically run to package and release changed charts.

### Immutability

Chart releases must be immutable. Any change to a chart warrants a chart version bump even if it is only changed to the
documentation.

### Versioning

The chart `version` should follow [SemVer](https://semver.org/).

New charts should start at `0.1.0`. They will be upgraded to a _stable_ `1.0.0` after they have been used in production
clusters for more than a month without issues. This is obviously hard to do, but as [I](https://github.com/mvprowess)
operate a cluster myself I will be taking care of this.

Any breaking (backwards incompatible) changes to a chart should:

1. Bump the MAJOR version
2. In the README, under a section called "Upgrading", describe the manual steps necessary to upgrade to the new (
   specified) MAJOR version

<!-- Project documentation -->

[architecture]: ARCHITECTURE.md
[conduct]: CODE_OF_CONDUCT.md
[security]: SECURITY.md
[libsh]: https://github.com/adnoctem/libsh
