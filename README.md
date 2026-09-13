<p align="center">
    <!-- Helm -->
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/cncf/artwork/892ce913bbce895ddbd99f981917fcf93050a8ca/projects/helm/icon/color/helm-icon-color.svg">
      <img src="https://raw.githubusercontent.com/cncf/artwork/892ce913bbce895ddbd99f981917fcf93050a8ca/projects/helm/icon/color/helm-icon-color.svg" alt="Helm Logo" width="225">
    </picture>
    <h1 align="center">Helm Charts</h1>
</p>

[![GitHub top language][badge_language]][helm]
[![GitHub License][badge_license]][license]
[![Latest GitHub Tag][badge_version]][gh_repo_releases]
[![Artifact Hub][badge_artifacthub]][artifacthub_repo]
[![Testing][badge_testing]][gh_repo_workflow_testing]
[![GitHub Activity][badge_activity]][gh_repo_commits]
[![Renovate][badge_renovate]][renovate]
[![PreCommit][badge_precommit]][precommit]

A collection of open-source [MIT][license]-licensed [Helm charts][helm] maintained by
[Ad Noctem Collective][gh_org] for [Kubernetes][kubernetes] `v1.26` and above. The charts deploy self-hosted
applications and operators, with configuration for workloads, networking, storage and application settings.
See the [overview][overview] for the included charts, their versions and default container images.
Application images and dependencies retain their own licenses.

Each directory under [`charts`][dir_charts] is an independently versioned chart with its own installation guide,
configuration reference and upgrade notes. Packages are published to the [Helm repository][helm_repo] and
`oci://ghcr.io/adnoctem/charts`, and indexed in the [`adnoctem` Artifact Hub repository][artifacthub_repo].
The chart version selects the package; the application version describes the bundled application release.

Installing a published chart requires Helm and access to a compatible Kubernetes cluster. Storage classes,
Ingress controllers, external databases and operators may also be required by the selected configuration;
check the chart's README before installing. The repository's [Makefile][makefile] supports contributor workflows,
including a local kind environment. Development setup is covered in [Contributing][doc_contributing].

## ✨ TL;DR

### Helm Repository Installation

Choose a chart and an explicit **chart version** from the overview and published releases. Replace the placeholders
below with your release name, chart name, chart version and namespace.

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm repo update adnoctem
helm install <RELEASE_NAME> adnoctem/<CHART_NAME> --version <CHART_VERSION> \
  --namespace <NAMESPACE> --create-namespace
```

### OCI Installation

OCI packages do not require `helm repo add`. Use the same chart version and configuration as for a repository install.

```shell
helm install <RELEASE_NAME> oci://ghcr.io/adnoctem/charts/<CHART_NAME> \
  --version <CHART_VERSION> --namespace <NAMESPACE> --create-namespace
```

### Inspect and Configure a Chart

For example, inspect Uptime-Kuma's documented settings and save its defaults for editing. Use a private values file
for your deployment and existing Secret references where supported; keep credentials out of version control.

```shell
helm show readme adnoctem/uptime-kuma --version 0.4.1
helm show values adnoctem/uptime-kuma --version 0.4.1 > my-values.yaml

# Edit my-values.yaml, then preview the resources locally.
helm template uptime-kuma adnoctem/uptime-kuma --version 0.4.1 \
  --namespace monitoring --values my-values.yaml

# Install, or upgrade an existing release with the reviewed configuration.
helm upgrade --install uptime-kuma adnoctem/uptime-kuma --version 0.4.1 \
  --namespace monitoring --create-namespace --values my-values.yaml
helm status uptime-kuma --namespace monitoring
```

Rendered output can include Secrets; handle it accordingly. Before changing versions, read the chart's upgrade notes
and back up persistent application data. Chart installation and application data migration have different requirements.

## 📖 Overview

<div align="center">

| Chart                                                                                                                                                                                                                                                                                   | Chart Version | Application Version | Default Container Images                               |
| :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-----------: | :-----------------: | ------------------------------------------------------ |
| [Vaultwarden <img src="https://raw.githubusercontent.com/dani-garcia/vaultwarden/890e668071cffe2833834348e19bbef3c061d014/resources/vaultwarden-icon.svg" alt="Vaultwarden Logo" width="32px" height="32px" align="right" loading="lazy">][vaultwarden_chart]                           |     0.5.0     |       1.37.3        | [vaultwarden/server][vaultwarden_images]               |
| [Uptime-Kuma <img src="https://raw.githubusercontent.com/louislam/uptime-kuma/36196f632d499fddef436a3aacf2f11a01958f07/public/icon.svg" alt="Uptime-Kuma Logo" width="32px" height="32px" align="right" loading="lazy">][uptimekuma_chart]                                              |     0.4.1     |        2.5.4        | [louislam/uptime-kuma][uptime_kuma_images]             |
| [Linkwarden <img src="https://raw.githubusercontent.com/linkwarden/linkwarden/main/assets/logo.png" alt="Linkwarden Logo" width="32px" height="32px" align="right" loading="lazy">][linkwarden_chart]                                                                                   |     0.5.1     |       2.16.3        | [linkwarden/linkwarden][linkwarden_images]             |
| [Glance <img src="https://github.com/glanceapp/glance/blob/main/docs/logo.png?raw=true" alt="Glance Logo" width="32px" height="32px" align="right" loading="lazy">][glance_chart]                                                                                                       |     0.1.0     |       v0.8.6        | [glanceapp/glance][glance_images]                      |
| [Gotenberg <img src="https://user-images.githubusercontent.com/8983173/130322857-185831e2-f041-46eb-a17f-0a69d066c4e5.png" alt="Gotenberg Logo" width="32px" height="32px" align="right" loading="lazy">][gotenberg_chart]                                                              |     0.5.0     |       8.37.0        | [gotenberg/gotenberg][gotenberg_images]                |
| [Paperless-NGX <img src="https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/5842944d1ef817c11a47ed5c19ba8b7886c9fbfe/resources/logo/web/svg/square.svg" alt="Paperless-NGX Logo" width="32px" height="32px" align="right" loading="lazy">][paperless_chart]                  |     0.4.2     |        3.1.3        | [paperless-ngx/paperless-ngx][paperless_ngx_images]    |
| [LinkStack <img src="https://raw.githubusercontent.com/LinkStackOrg/branding/main/logo/svg/logo_color_bg_1.svg" alt="Linkstack Logo" width="32px" height="32px" align="right" loading="lazy">][linkstack_chart]                                                                         |     0.4.0     |        4.8.6        | [linkstackorg/linkstack][linkstack_images]             |
| [ntfy <img src="https://raw.githubusercontent.com/binwiederhier/ntfy/main/web/public/static/images/ntfy.png" alt="ntfy Logo" width="32px" height="32px" align="right" loading="lazy">][ntfy_chart]                                                                                      |     0.4.0     |       2.28.0        | [binwiederhier/ntfy][ntfy_images]                      |
| [Cachet <img src="https://raw.githubusercontent.com/cachethq/art/master/logo-mark/cachet-logomark-green.png" alt="Cachet Logo" width="32px" height="32px" align="right" loading="lazy">][cachet_chart]                                                                                  |     0.3.3     |       2.3.15        | [cachethq/docker][cachet_images]                       |
| [Kubenav <img src="https://raw.githubusercontent.com/kubenav/kubenav/290f1776b03c359b8115125fa37a4b8dd73b6464/utils/images/app-icons/android.png" alt="Kubenav Logo" width="32px" height="32px" align="right" loading="lazy">][kubenav_chart]                                           |     0.2.3     |         `—`         | `None`                                                 |
| [GoBackup <img src="https://user-images.githubusercontent.com/5518/205909959-12b92929-4ac5-4bb5-9111-6f9a3ed76cf6.png" alt="GoBackup Logo" width="32px" height="32px" align="right" loading="lazy">][gobackup_chart]                                                                    |     0.4.0     |        3.1.1        | [huacnlee/gobackup][gobackup_images]                   |
| [Activepieces <img src="https://raw.githubusercontent.com/adnoctem/artwork/425046029eaed451f5ced22ddc650059dff11878/projects/activepieces/icon/color/activepieces-icon-color.png" alt="Activepieces Logo" width="32px" height="32px" align="right" loading="lazy">][activepieces_chart] |     0.4.2     |       0.90.2        | [activepieces/activepieces][activepieces_images]       |
| [Popeye <img src="https://github.com/derailed/popeye/blob/d09ec25f3834d2c6a171486b9726b0a91793e3f0/assets/popeye_logo.png?raw=true" alt="Popeye Logo" width="32px" height="32px" align="right" loading="lazy">][popeye_chart]                                                           |     0.3.0     |       0.22.1        | [derailed/popeye][popeye_images]                       |
| [Keycloak Operator <img src="https://github.com/keycloak/keycloak-misc/blob/dee033f2d6d6b5c3a6ce8eb84e285f7e5626dbf6/logo/icon.png?raw=true" alt="Keycloak Logo" width="32px" height="32px" align="right" loading="lazy">][keycloak_operator_chart]                                     |     0.3.0     |       26.7.3        | [keycloak/keycloak-operator][keycloak_operator_images] |
| [Outline <img src="https://www.getoutline.com/images/logo.svg" alt="Outline Logo" width="32px" height="32px" align="right" loading="lazy">][outline_chart]                                                                                                                              |     0.1.2     |       1.10.1        | [outlinewiki/outline][outline_images]                  |
| [Lighthouse CI <img src="https://raw.githubusercontent.com/GoogleChrome/lighthouse/main/assets/lighthouse-logo_512px.png" alt="Lighthouse CI Logo" width="32px" height="32px" align="right" loading="lazy">][lhci_chart]                                                                |     0.1.0     |        1.0.1        | [adnoctem/lhci][lhci_images]                           |

</div>

## 📚 Documentation

| Document                                    | What you will find                                                                       |
| ------------------------------------------- | ---------------------------------------------------------------------------------------- |
| [Chart guides][dir_charts]                  | Installation, configuration parameters and upgrade notes in each chart's README.         |
| [Architecture][doc_architecture]            | Repository layout, chart boundaries, code generation, local development and publication. |
| [Contributing guidelines][doc_contributing] | Development setup, chart design, verification, conventional commits and versioning.      |
| [Agent guidance][doc_agents]                | Repository-specific instructions for coding agents and required checks.                  |
| [Security policy][doc_security]             | Private vulnerability reporting, version support, deployment trust and handling secrets. |
| [Code of Conduct][doc_conduct]              | Participation expectations, private conduct reporting and maintainer enforcement.        |
| [TODO][doc_todo]                            | Remaining work and ideas under consideration.                                            |

### 🔃 Contributing

Contributions are welcome through GitHub pull requests. Refer to the [contributing guidelines][doc_contributing]
for development commands, chart design principles, commit messages and versioning. Submit changes to different
charts in separate pull requests.

Participation follows the [Code of Conduct][doc_conduct]. Report suspected vulnerabilities privately using the
[Security policy][doc_security].

### 📥 Maintainers

This project is owned and maintained by [Ad Noctem Collective][gh_org]. Refer to
[`AUTHORS`][authors] and [`CODEOWNERS`][codeowners] for more information, or contact
[info+charts@adnoctem.co][contact].

<!-- INTERNAL REFERENCES -->

<!-- Chart references -->

[glance_chart]: charts/glance
[gotenberg_chart]: charts/gotenberg
[linkwarden_chart]: charts/linkwarden
[paperless_chart]: charts/paperless-ngx
[uptimekuma_chart]: charts/uptime-kuma
[vaultwarden_chart]: charts/vaultwarden
[linkstack_chart]: charts/linkstack
[ntfy_chart]: charts/ntfy
[cachet_chart]: charts/cachet
[kubenav_chart]: charts/kubenav
[gobackup_chart]: charts/gobackup
[activepieces_chart]: charts/activepieces
[popeye_chart]: charts/popeye
[keycloak_operator_chart]: ./charts/keycloak-operator
[outline_chart]: charts/outline
[lhci_chart]: charts/lhci

<!-- File references -->

[license]: LICENSE

<!-- General links -->

[kubernetes]: https://kubernetes.io
[helm]: https://helm.sh

<!-- Overview links -->

[vaultwarden_images]: https://hub.docker.com/r/vaultwarden/server
[uptime_kuma_images]: https://hub.docker.com/r/louislam/uptime-kuma
[linkwarden_images]: https://github.com/linkwarden/linkwarden/pkgs/container/linkwarden
[glance_images]: https://hub.docker.com/r/glanceapp/glance
[gotenberg_images]: https://hub.docker.com/r/gotenberg/gotenberg
[paperless_ngx_images]: https://github.com/paperless-ngx/paperless-ngx/pkgs/container/paperless-ngx
[linkstack_images]: https://hub.docker.com/r/linkstackorg/linkstack
[ntfy_images]: https://hub.docker.com/r/binwiederhier/ntfy
[cachet_images]: https://hub.docker.com/r/cachethq/docker
[gobackup_images]: https://hub.docker.com/r/huacnlee/gobackup
[activepieces_images]: https://hub.docker.com/r/activepieces/activepieces
[popeye_images]: https://hub.docker.com/r/derailed/popeye
[keycloak_operator_images]: https://quay.io/repository/keycloak/keycloak-operator
[outline_images]: https://hub.docker.com/r/outlinewiki/outline
[lhci_images]: https://github.com/adnoctem/lhci/pkgs/container/lhci

<!-- Documentation and repository links -->

[overview]: #-overview
[dir_charts]: charts
[makefile]: Makefile
[authors]: .github/AUTHORS
[codeowners]: .github/CODEOWNERS
[doc_architecture]: docs/ARCHITECTURE.md
[doc_contributing]: docs/CONTRIBUTING.md
[doc_agents]: docs/AGENTS.md
[doc_security]: docs/SECURITY.md
[doc_conduct]: docs/CODE_OF_CONDUCT.md
[doc_todo]: docs/TODO.md
[helm_repo]: https://adnoctem.github.io/charts
[artifacthub_repo]: https://artifacthub.io/packages/search?repo=adnoctem&sort=relevance
[gh_org]: https://github.com/adnoctem
[gh_repo_releases]: https://github.com/adnoctem/charts/releases
[gh_repo_workflow_testing]: https://github.com/adnoctem/charts/actions/workflows/testing.yaml
[gh_repo_commits]: https://github.com/adnoctem/charts/commits/main/
[renovate]: https://renovatebot.com/
[precommit]: https://pre-commit.com/
[contact]: mailto:info+charts@adnoctem.co

<!-- Badge images -->

[badge_language]: https://img.shields.io/github/languages/top/adnoctem/charts
[badge_license]: https://img.shields.io/github/license/adnoctem/charts?label=License
[badge_version]: https://img.shields.io/github/v/tag/adnoctem/charts?label=Latest
[badge_artifacthub]: https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/adnoctem
[badge_testing]: https://github.com/adnoctem/charts/actions/workflows/testing.yaml/badge.svg
[badge_activity]: https://img.shields.io/github/last-commit/adnoctem/charts?label=Activity
[badge_renovate]: https://img.shields.io/badge/Renovate-enabled-brightgreen?logo=renovatebot&logoColor=1DDEDD
[badge_precommit]: https://img.shields.io/badge/PreCommit-enabled-brightgreen?logo=precommit&logoColor=FAB040
