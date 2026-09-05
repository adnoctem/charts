# Helm Charts <img src="https://raw.githubusercontent.com/cncf/artwork/892ce913bbce895ddbd99f981917fcf93050a8ca/projects/helm/icon/color/helm-icon-color.svg" alt="Helm Logo" align="right" width="225"/>

[![License](https://img.shields.io/github/license/adnoctem/charts?label=License)](https://opensource.org/licenses/MIT)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/adnoctem)](https://artifacthub.io/packages/search?repo=adnoctem&sort=relevance)
[![CI Status](https://github.com/adnoctem/charts/actions/workflows/release.yaml/badge.svg)](https://github.com/adnoctem/charts/blob/main/.github/workflows/ci-pipeline.yml)
[![Renovate](https://img.shields.io/badge/Renovate-enabled-brightgreen?logo=renovatebot&logoColor=1DDEDD)](https://renovatebot.com/)

A collection of open-source [MIT][license]-licensed [_Helm Charts_][helm] written and maintained by `Ad Noctem Collective` for
use with [Kubernetes][kubernetes] `v1.26` and above. Have a look [at the table below](#-overview) to get a list of the
included charts, their versions and the default container images. The charts are also published
to [ArtifactHub][artifacthub], where they can be found in
the [`adnoctem`](https://artifacthub.io/packages/search?repo=adnoctem&sort=relevance) repository. This GitHub
repository relies on the _GNU Make_ build tool to ease the development workflows. The [`Makefile`](Makefile) also
includes `targets` to set up the development environment. Refer to the [CONTRIBUTING.md](docs/CONTRIBUTING.md) for more
information.

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install <RELEASE_NAME> adnoctem/<CHART_NAME>
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/<CHART_NAME>:<VERSION>
```

## 📖 Overview

<div align="center">

| Chart                                                                                                                                                                                                                                                                                   | Current Version | Default Container Images                               |
| :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :-------------: | ------------------------------------------------------ |
| [Vaultwarden <img src="https://raw.githubusercontent.com/dani-garcia/vaultwarden/890e668071cffe2833834348e19bbef3c061d014/resources/vaultwarden-icon.svg" alt="Vaultwarden Logo" width="32px" height="32px" align="right" loading="lazy">][vaultwarden_chart]                           |      0.3.0      | [vaultwarden/server][vaultwarden_images]               |
| [Uptime-Kuma <img src="https://raw.githubusercontent.com/louislam/uptime-kuma/36196f632d499fddef436a3aacf2f11a01958f07/public/icon.svg" alt="Uptime-Kuma Logo" width="32px" height="32px" align="right" loading="lazy">][uptimekuma_chart]                                              |      0.3.0      | [louislam/uptime-kuma][uptime_kuma_images]             |
| [Linkwarden <img src="https://raw.githubusercontent.com/linkwarden/linkwarden/main/assets/logo.png" alt="Linkwarden Logo" width="32px" height="32px" align="right" loading="lazy">][linkwarden_chart]                                                                                   |      0.4.0      | [linkwarden/linkwarden][linkwarden_images]             |
| [Gotenberg <img src="https://user-images.githubusercontent.com/8983173/130322857-185831e2-f041-46eb-a17f-0a69d066c4e5.png" alt="Gotenberg Logo" width="32px" height="32px" align="right" loading="lazy">][gotenberg_chart]                                                              |      0.3.0      | [gotenberg/gotenberg][gotenberg_images]                |
| [Paperless-NGX <img src="https://raw.githubusercontent.com/paperless-ngx/paperless-ngx/5842944d1ef817c11a47ed5c19ba8b7886c9fbfe/resources/logo/web/svg/square.svg" alt="Paperless-NGX Logo" width="32px" height="32px" align="right" loading="lazy">][paperless_chart]                  |      0.3.0      | [paperless-ngx/paperless-ngx][paperless_ngx_images]    |
| [LinkStack <img src="https://raw.githubusercontent.com/LinkStackOrg/branding/main/logo/svg/logo_color_bg_1.svg" alt="Linkstack Logo" width="32px" height="32px" align="right" loading="lazy">][linkstack_chart]                                                                         |      0.3.0      | [linkstackorg/linkstack][linkstack_images]             |
| [ntfy <img src="https://raw.githubusercontent.com/binwiederhier/ntfy/main/web/public/static/images/ntfy.png" alt="ntfy Logo" width="32px" height="32px" align="right" loading="lazy">][ntfy_chart]                                                                                      |      0.3.0      | [binwiederhier/ntfy][ntfy_images]                      |
| [Cachet <img src="https://raw.githubusercontent.com/cachethq/art/master/logo-mark/cachet-logomark-green.png" alt="Cachet Logo" width="32px" height="32px" align="right" loading="lazy">][cachet_chart]                                                                                  |      0.3.0      | [cachethq/docker][cachet_images]                       |
| [Kubenav <img src="https://raw.githubusercontent.com/kubenav/kubenav/290f1776b03c359b8115125fa37a4b8dd73b6464/utils/images/app-icons/android.png" alt="Kubenav Logo" width="32px" height="32px" align="right" loading="lazy">][kubenav_chart]                                           |      0.2.0      | `None`                                                 |
| [GoBackup <img src="https://user-images.githubusercontent.com/5518/205909959-12b92929-4ac5-4bb5-9111-6f9a3ed76cf6.png" alt="GoBackup Logo" width="32px" height="32px" align="right" loading="lazy">][gobackup_chart]                                                                    |      0.3.0      | [huacnlee/gobackup][gobackup_images]                   |
| [Activepieces <img src="https://raw.githubusercontent.com/adnoctem/artwork/3f3537b0377b8c95bfac77ae5cb7779c4698d659/projects/activepieces/icon/color/activepieces-icon-color.png" alt="Activepieces Logo" width="32px" height="32px" align="right" loading="lazy">][activepieces_chart] |      0.3.0      | [activepieces/activepieces][activepieces_images]       |
| [Popeye <img src="https://github.com/derailed/popeye/blob/d09ec25f3834d2c6a171486b9726b0a91793e3f0/assets/popeye_logo.png?raw=true" alt="Popeye Logo" width="32px" height="32px" align="right" loading="lazy">][popeye_chart]                                                           |      0.2.0      | [derailed/popeye][popeye_images]                       |
| [Keycloak Operator <img src="https://github.com/keycloak/keycloak-misc/blob/dee033f2d6d6b5c3a6ce8eb84e285f7e5626dbf6/logo/icon.png?raw=true" alt="Keycloak Logo" width="32px" height="32px" align="right" loading="lazy">][keycloak_operator_chart]                                     |      0.2.0      | [keycloak/keycloak-operator][keycloak_operator_images] |

[//]: # '"Stolen" from https://github.com/gabe565/charts/blob/main/README.md because I really liked the look'

</div>

### 🔃 Contributing

Refer to our [documentation for contributors](docs/CONTRIBUTING.md) for contributing guidelines, commit message
formats and versioning tips.

### 📥 Maintainers

This project is owned and maintained by [Ad Noctem Collective](https://github.com/adnoctem) refer to
the [`AUTHORS`](.github/AUTHORS) or [`CODEOWNERS`](.github/CODEOWNERS) for more information. You may also use the linked
contact details to reach out directly.

<!-- INTERNAL REFERENCES -->

<!-- Chart references -->

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

<!-- File references -->

[license]: LICENSE

<!-- General links -->

[kubernetes]: https://kubernetes.io
[helm]: https://helm.sh
[artifacthub]: https://artifacthub.io/

<!-- Overview links -->

[vaultwarden_images]: https://hub.docker.com/r/vaultwarden/server
[uptime_kuma_images]: https://hub.docker.com/r/louislam/uptime-kuma
[linkwarden_images]: https://github.com/linkwarden/linkwarden/pkgs/container/linkwarden
[gotenberg_images]: https://hub.docker.com/r/gotenberg/gotenberg
[paperless_ngx_images]: https://github.com/paperless-ngx/paperless-ngx/pkgs/container/paperless-ngx
[linkstack_images]: https://hub.docker.com/r/linkstackorg/linkstack
[ntfy_images]: https://hub.docker.com/r/binwiederhier/ntfy
[cachet_images]: https://hub.docker.com/r/cachethq/docker
[gobackup_images]: https://hub.docker.com/r/huacnlee/gobackup
[activepieces_images]: https://hub.docker.com/r/activepieces/activepieces
[popeye_images]: https://hub.docker.com/r/derailed/popeye
[keycloak_operator_images]: https://quay.io/repository/keycloak/keycloak-operator
