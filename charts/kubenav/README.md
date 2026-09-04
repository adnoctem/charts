# Ad Noctem Collective - Kubenav Helm Chart <img src="https://raw.githubusercontent.com/kubenav/kubenav/290f1776b03c359b8115125fa37a4b8dd73b6464/utils/images/app-icons/android.png" alt="Kubenav Logo" width="175" height="175" align="right" loading="lazy">

_Kubenav_ is a mobile app to manage Kubernetes clusters. The app provides an overview of all resources in a Kubernetes
cluster, including current status information for workloads. The details view for resources provides additional
information. It is possible to view logs and events or to get a shell into a container. You can also edit and delete
resources or scale your workloads within the app.

The app is developed using [Flutter](https://flutter.dev) and [Go](https://go.dev). For more information you can read
through our [contribution guidelines](https://github.com/kubenav/kubenav/blob/main/CONTRIBUTING.md) for development.

> Head to the [Kubenav GitHub Repository](https://github.com/kubenav/kubenav) or
> their [Website](https://kubenav.io/) for more information.

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install kubenav adnoctem/kubenav --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/kubenav:X.Y.Z
```

## Introduction

This chart bootstraps the [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) required to
run Kubenav. It creates
a [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
(including the required `kubernetes.io/service-account-token` Secret)
alongside a [ClusterRole](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-v1/)
and [ClusterRoleBinding](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-binding-v1/).

## Parameters

### Name overrides

| Name               | Description                                     | Value |
| ------------------ | ----------------------------------------------- | ----- |
| `nameOverride`     | String to partially override linkstack.fullname | `""`  |
| `fullnameOverride` | String to fully override linkstack.fullname     | `""`  |

### Secret parameters

| Name                 | Description                                        | Value |
| -------------------- | -------------------------------------------------- | ----- |
| `secret.annotations` | Annotations for the `service-account-token` Secret | `{}`  |
| `secret.labels`      | Labels for the `service-account-token` Secret      | `{}`  |

### RBAC parameters

| Name          | Description                      | Value  |
| ------------- | -------------------------------- | ------ |
| `rbac.create` | Whether to create RBAC resources | `true` |
| `rbac.rules`  | Extra rules to add to the Role   | `[]`   |

### Service Account parameters

| Name                         | Description                                                               | Value   |
| ---------------------------- | ------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`      | Whether a service account should be created                               | `true`  |
| `serviceAccount.automount`   | Whether to automount the service account token                            | `false` |
| `serviceAccount.annotations` | Annotations to add to the service account                                 | `{}`    |
| `serviceAccount.name`        | A custom name for the service account, otherwise kubenav.fullname is used | `""`    |
| `serviceAccount.secrets`     | A list of secrets mountable by this service account                       | `[]`    |
