# Agent guide — Ad Noctem Collective Helm charts

Agent-facing development guide for this repository. [`docs/CONTRIBUTING.md`](CONTRIBUTING.md) is the canonical,
detailed guide (commit format, chart design principles, per-chart dev notes); read it before non-trivial chart work.
This file records what an agent otherwise gets wrong.

## Repository map

- `charts/<name>/` — 16 independent Helm charts (Kubernetes `>=1.26.0`): `Chart.yaml`, `values.yaml`, committed
  `values.schema.json`, `templates/`, `ci/` fixtures and a generated end-user `README.md`.
- `config/` — `ct-config.yaml` (chart-testing), `cr-config.yaml` (chart-releaser), `bitnami-readme-gen.json`,
  `k8s/` (kind cluster, helmfile, kustomize dev setup), `ssl/` (cfssl CA CSR).
- `docs/` — development documentation only (`CONTRIBUTING.md`, `TODO.md`). Never put development notices in a
  chart `README.md`; that file is for end users and is published to Artifact Hub.
- `scripts/hosts.sh` — manages `*.charts.internal` entries in `/etc/hosts`. Requires an installed
  [libsh](https://github.com/adnoctem/libsh) with `LIBSH_DIR` exported, prompts for confirmation, and uses sudo
  when `/etc/hosts` is not writable. Not covered by `make tools-check`.
- `.github/workflows/` — `testing.yaml` (CI), `release.yaml` (release), `superlint.yaml`. `.github/linters/` holds
  the markdownlint, gitleaks, shellcheck, typos and zizmor configs. `.pre-commit-config.yaml` is the full local gate.
- Gitignored: `dist/` (packages), `secrets/` (generated CA), `Chart.lock`, `charts/*/charts/*.tgz`, `.idea/`.

## Makefile lifecycle

The root `Makefile` is the only supported entrypoint. `make help` prints the target list,
`PRINT_HELP=y make <target>` prints that target's usage without executing it, and `DBG_MAKEFILE=1` stops recipe
echoing.

Chart targets take a **repo-relative chart directory**: `CHART=charts/<name>` — the value is passed to Helm
directly and `CHART_NAME` is derived with `basename`, so a bare chart name fails. `VALUES` is a chart-local
relative path (`ci/test-values.yaml`), applied as `$(CHART)/$(VALUES)`. `RELEASE_NAME` defaults to
`<chart>-test`.

| Stage          | Command                                                                        |
| -------------- | ------------------------------------------------------------------------------ |
| Prerequisites  | `make tools-check` (then install whatever it reports missing)                  |
| Local CA       | `make secrets` — cfssl CA into `secrets/`; required before `make env`          |
| Dev cluster    | `make env` — kind + helmfile (ingress-nginx, cert-manager) + kustomize + hosts |
| Render         | `make template CHART=charts/<name> [VALUES=ci/test-values.yaml]`               |
| Dry run        | `make dry-install CHART=charts/<name> [VALUES=...]`                            |
| Deploy         | `make install` / `make upgrade CHART=charts/<name> [VALUES=...]`               |
| Codegen        | `make gen CHART=charts/<name>`                                                 |
| Full rebuild   | `make all` — `gen` + `prettier --write` + `build` for every chart              |
| Package        | `make build CHART=charts/<name>` → `dist/<name>-<version>.tgz`                 |
| Lint           | `make lint` — markdownlint, actionlint, shellcheck, shfmt, chart-testing       |
| Chart lint     | `make chart-testing [CHART=charts/<name>]` — `ct lint --all` when unset        |
| Secret scan    | `make gitleaks` — **not** part of `make lint`                                  |
| Registry login | `make registry-login REGISTRY_USER=<user>` — uses `gh auth token`              |
| Teardown       | `make prune` — deletes the kind cluster and removes hosts entries              |

Notes:

- `install`/`upgrade`/`template` do not pass `--namespace`; the release lands in the active kubeconfig namespace.
- `make gen` and `make all` need network access: `gen` runs `npx @bitnami/readme-generator-for-helm`, and `all`
  calls `prettier --write` directly, so `prettier` must be on `PATH` (pre-commit uses `bun x prettier` instead).
- `tools-check` only verifies `helm helmfile kind npx cfssl cfssljson kubectl`. `make lint` additionally needs
  `ct`, `markdownlint`, `actionlint`, `shellcheck` and `shfmt`. Pre-commit manages its own hook environments and
  only needs `pre-commit` and `bun` on `PATH` (for the local Prettier hook). `yq` is invoked whenever `CHART` is
  set, even though the computed `CHART_VERSION` is currently unused.
- `ct install` has no Make target. Run `ct install --config config/ct-config.yaml [--charts charts/<name>]` against
  a kind cluster (CI does this). It installs every `ci/*-values.yaml` fixture separately.
- The kind cluster is named `<checkout-directory-basename>-charts` (`PROJ_NAME` derives from `ROOT_DIR_NAME`, not
  the git repo name). The kind config binds host ports 80/443 and API server `0.0.0.0:6443`.
- Development hostnames are `*.charts.internal`; a chart whose fixture uses Ingress needs its hostname added to
  `scripts/hosts.sh` to be resolvable locally. A second Ingress for the same host/path fails when ingress-nginx
  admission is active — remove the conflicting install or use another hostname.
- `make secrets` writes a `kustomization.yaml` that `make env` applies via `config/k8s/kustomize`, provisioning the
  `root-ca` Secret consumed by the `development-issuer` ClusterIssuer.

## Code generation

- `make gen CHART=...` regenerates both `values.schema.json` and the `## Parameters` tables in the chart
  `README.md` from the `## @param` / `## @section` comments in `values.yaml`
  (config: `config/bitnami-readme-gen.json`).
- Never hand-edit `values.schema.json` or the generated parameter tables. Change the `values.yaml` comments and
  re-run `make gen`. Re-run after every `values.yaml` change; use `make all` for changes spanning many charts.
- Every chart change (including README-only) requires a `Chart.yaml` `version` bump — chart releases are immutable.
  New charts start at `0.1.0`; breaking changes bump MAJOR and add an `Upgrading` section to the chart README.
- Charts with subchart dependencies (e.g. `lhci`) commit neither lockfile nor vendored packages: run
  `helm dependency update charts/<name>` after cloning and before rendering or linting.

## Chart conventions that differ from Helm defaults

Full rules: [Chart Design Principles](CONTRIBUTING.md#-chart-design-principles). The most commonly missed:

- One Kubernetes resource per `templates/*.yaml`, named after the kind in camelCase (`deployment.yaml`,
  `svc.yaml`). If a chart renders multiple resources of the same kind, combine them into one pluralized file
  (`secrets.yaml`) with `---` separators. Shared logic goes in `_`-prefixed partials (`_helpers.tpl`,
  `_podSpec.tpl`) so Helm does not render them as manifests.
- `ci/test-values.yaml` is an expansive, runnable development configuration, not a minimal smoke test. Extra
  fixtures (`ci/mysql-values.yaml`, ...) must install independently, with no production credentials, paid
  services, or operator-managed resources.
- Model configuration as dedicated, typed `values.yaml` fields with `## @param` docs instead of an
  `extraEnvVars`-style passthrough; only document deliberate exceptions.
- Optional Bitnami dependencies use `oci://registry-1.docker.io/bitnamicharts`; that is separate from the Helm
  dependency repos `https://charts.bitnami.com/bitnami` and `https://apache.jfrog.io/artifactory/tika` used by
  chart-testing and release.
- Keep application logic in the container: no runtime shell/JS wrappers in charts and no Helm test pods. Prefer
  external/operator-managed databases (e.g. CloudNativePG) for production; subcharts are convenience.
- New chart: mirror a neighboring chart's structure and style, add it to the root `README.md` overview table,
  add its ingress hostname to `scripts/hosts.sh` if the fixture uses one, and add the author to
  `.github/AUTHORS` and `.github/CODEOWNERS`.
- Chart or app version bumps also update the root `README.md` overview table in the same commit; it is
  maintained by hand.

## Commit and PR conventions

- Conventional Commits: `type(scope): summary` with types `build|ci|docs|feat|fix|perf|refactor|test|chore` and
  scopes `charts|charts/<name>|k8s|make|scripts|config`. Imperative present tense, lowercase, no trailing period.
- The body is mandatory for everything except `docs` commits, must be at least 20 characters, and explains why.
  Breaking changes use a `BREAKING CHANGE:` footer with migration steps.
- PR titles must start with a valid scope (e.g. `fix(charts/linkwarden): ...`); changes to multiple charts go in
  separate PRs; push new commits instead of force-pushing during review. The checklist requires the chart version
  bump and an `.github/AUTHORS` entry for new contributors.

## CI and release

- `.github/workflows/testing.yaml` runs on `charts/**` changes: `pre-commit run --all-files`, then
  `ct list-changed` → `ct lint` → Artifact Hub `ah lint` (inside `charts/`) → `ct install` on a kind cluster.
  On a push to `main` it dispatches `release.yaml`.
- `.github/workflows/release.yaml` runs only via that dispatch: chart-releaser publishes signed GitHub releases and
  the Pages index from `config/cr-config.yaml`, then pushes packages to `oci://ghcr.io/adnoctem/charts`.
- `.github/workflows/superlint.yaml` runs Super-Linter with several validators intentionally disabled — YAML
  validation is off because Helm templates are not valid YAML, and JSON/YAML Prettier is off for the same reason.
- Renovate (`.github/renovate.json`) bumps dependencies, GitHub Actions (pinned to digests) and pre-commit hooks;
  expect `chore(deps): ...` commits from it.

## Local verification order

1. `pre-commit run --all-files` — closest match to CI's quality job; catches markdownlint, actionlint, zizmor,
   typos, gitleaks, shellcheck, shfmt and Prettier issues that `make lint` does not.
2. `make gen CHART=charts/<name>` after any `values.yaml`/README/schema edit, then `make lint`.
3. `make chart-testing CHART=charts/<name>` for a focused chart lint.
4. For install verification: `make secrets`, `make env`, then
   `ct install --config config/ct-config.yaml --charts charts/<name>` or
   `make install CHART=charts/<name> VALUES=ci/test-values.yaml`.
5. `make prune` when finished with the dev cluster.
