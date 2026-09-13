# Helm Charts Security Policy

## Reporting a Vulnerability

Report suspected vulnerabilities privately to [info+charts@adnoctem.co][report_contact]. Do not open a public issue
with exploit details, credentials or private system information before maintainers have had an opportunity to
assess the report.

Useful reports include:

- The affected chart name and version, application image tag or digest, and repository commit if relevant.
- The Kubernetes and Helm versions, affected resource or template, and relevant configuration.
- A minimal reproduction using synthetic data, expected behavior and observed behavior.
- The likely impact, required privileges and exposure through Services, Ingress or other access paths.
- A contact address for follow-up and your disclosure or acknowledgement preferences.

Remove passwords, tokens, private keys and unrelated personal information from examples and logs. If a credential
has already been exposed, revoke or rotate it through the service that issued it; deleting a file or log does not
invalidate the credential.

Maintainers will assess the report, discuss reproduction or mitigation as needed, and coordinate a fix and public
disclosure when appropriate. Please coordinate publication while the issue is being addressed. This project is
maintained on a best-effort basis and does not promise a fixed response or remediation deadline.

If a problem originates in an upstream application, container image or dependency, report it to that project as
well. Let chart maintainers know when chart defaults or a documented deployment are affected so mitigations can
be coordinated.

## Versions and Fixes

Charts are versioned independently. Identify both the chart version and the application image in reports;
maintainers may ask whether the issue reproduces with the current chart and its default image. Fixes normally
target current development and a new chart release. Backports to older chart versions are not guaranteed.

Pin chart versions for reproducible deployments and review release notes and chart-specific upgrade instructions
before updating. Image overrides and dependency versions require their own review. A pinned version still needs
deliberate updates to receive fixes. See [Contributing][contributing] for chart versioning and release policy.

## Trust and Privilege Boundaries

Review chart sources, container image sources and rendered resources before installing into a cluster. Helm
uses the permissions of the selected Kubernetes context; charts may create service accounts, RBAC rules,
operator resources or externally reachable Services depending on their configuration. CI fixtures are development
examples and are not a production security baseline.

The release workflow signs chart-releaser packages with GPG. Signature verification requires a provenance file
and a trusted publisher key; downloading or installing a package alone does not verify it. Chart signatures do
not attest to the security of container images, dependencies, user-supplied values or the running cluster.
Consult the [release workflow][release] and [chart metadata][charts] for the configured publication and signing details.

Production deployments need appropriate network access controls, TLS, authentication, resource limits, backups
and workload permissions for the selected application. Follow its chart README and upstream security guidance;
available controls and default settings differ between charts.

## Development Environment

The local kind setup binds host ports 80 and 443 and its API server to `0.0.0.0:6443`. Keep it on a trusted
development machine and network. Its generated CA and development credentials are not production credentials.
Protect CA private keys and only trust the development CA on machines where that trust is intended.

`scripts/hosts.sh` sources code from `LIBSH_DIR` and may execute it in a privileged shell to edit host files.
Use a trusted libsh installation and checkout, and review exported environment variables before sudo preserves
them. `make env` and `make prune` modify local cluster and hostname state; review the [development guide][contributing]
before running them.

## Secrets and Diagnostics

Prefer existing Kubernetes Secret references where the chart supports them. Keep credentials and private values
files out of Git. Kubernetes Secret data is encoded, not encrypted by its base64 representation; access control
and encryption at rest depend on cluster configuration.

Values, Helm release records, rendered manifests and debug output may contain credentials. Inspect and redact
them before sharing. Avoid passing secrets in command-line arguments or posting full render output to issues.
The gitignored `secrets/` directory is a convenience for local files, not an access-control or encryption mechanism.
Secret scanning does not guarantee that every sensitive value will be detected.

<!-- File references -->

[contributing]: CONTRIBUTING.md
[release]: ../.github/workflows/release.yaml
[charts]: ../charts

<!-- Contact links -->

[report_contact]: mailto:info+charts@adnoctem.co
