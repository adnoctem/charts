# Ad Noctem Collective Helm Charts

A collection of open-source [MIT-licensed Helm charts](https://github.com/adnoctem/charts/blob/main/LICENSE)
maintained by [Ad Noctem Collective](https://github.com/adnoctem) for Kubernetes `v1.26` and above.
The charts deploy self-hosted applications and operators, with configuration for workloads, networking,
storage and application settings. Application images and dependencies retain their own licenses.

Packages are published to this Helm repository and `oci://ghcr.io/adnoctem/charts`, and indexed in the
[adnoctem Artifact Hub repository](https://artifacthub.io/packages/search?repo=adnoctem&sort=relevance).

## Find a chart

- [Chart overview](https://github.com/adnoctem/charts#-overview): the charts maintained in this repository,
  their chart and application versions, and default container images.
- [Published releases](https://github.com/adnoctem/charts/releases): released packages and release notes.
- [Chart guides](https://github.com/adnoctem/charts/tree/main/charts): installation instructions,
  configuration references and upgrade notes for each chart.
- [Helm repository index](index.yaml): the machine-readable catalog of published chart versions.

The source overview may include changes awaiting publication. Choose an available **chart version** from
Artifact Hub, the published releases or `helm search repo adnoctem --versions` before installing.
The application version describes the bundled application release; it does not select the chart package.

## Install from the Helm repository

Replace the placeholders with your release name, chart name, published chart version and namespace.

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm repo update adnoctem
helm search repo adnoctem --versions
helm install <RELEASE_NAME> adnoctem/<CHART_NAME> --version <CHART_VERSION> \
  --namespace <NAMESPACE> --create-namespace
```

## Install from the OCI registry

OCI packages do not require `helm repo add`. Use the same chart version and configuration as for a
repository install.

```shell
helm install <RELEASE_NAME> oci://ghcr.io/adnoctem/charts/<CHART_NAME> \
  --version <CHART_VERSION> --namespace <NAMESPACE> --create-namespace
```

## Configure and upgrade

Read the selected chart's README before installing. Depending on the configuration, you may need storage
classes, an Ingress controller, external databases or operators in addition to Helm and a Kubernetes cluster.

```shell
helm show readme adnoctem/<CHART_NAME> --version <CHART_VERSION>
helm show values adnoctem/<CHART_NAME> --version <CHART_VERSION> > my-values.yaml
```

Keep deployment values private and use existing Secret references where supported. Before changing versions,
review the chart's upgrade notes and back up persistent application data.

**Charts with a version of `0.x.y` are in pre-1.0 development.** Breaking changes may ship in minor chart
releases (`0.x.y` to `0.(x+1).0`), with migration steps in the chart's Upgrading section. Pin chart versions
and review the release notes before updating. Each chart reaches stable `1.0.0` independently; a stable
application version does not make its chart stable. See the
[chart versioning policy](https://github.com/adnoctem/charts/blob/main/docs/CONTRIBUTING.md#versioning).

## Contribute and get support

- [Repository and issues](https://github.com/adnoctem/charts)
- [Contributing and development setup](https://github.com/adnoctem/charts/blob/main/docs/CONTRIBUTING.md)
- [Security policy](https://github.com/adnoctem/charts/blob/main/docs/SECURITY.md)
- [Code of Conduct](https://github.com/adnoctem/charts/blob/main/docs/CODE_OF_CONDUCT.md)
- [Authors](https://github.com/adnoctem/charts/blob/main/.github/AUTHORS) and
  [code owners](https://github.com/adnoctem/charts/blob/main/.github/CODEOWNERS)

This project is owned and maintained by [Ad Noctem Collective](https://github.com/adnoctem).
Contact [info+charts@adnoctem.co](mailto:info+charts@adnoctem.co).
