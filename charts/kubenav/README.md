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

> **This chart does not deploy Kubenav itself, and there is no server, dashboard, or web UI to visit afterwards.**
> Since [Kubenav v4](https://github.com/kubenav/kubenav/releases), the project is a mobile-only app for
> [iOS](https://apps.apple.com/app/kubenav/id1494512160) and
> [Android](https://play.google.com/store/apps/details?id=io.kubenav.kubenav); there is no Docker image or web
> version to run in your cluster. What this chart provides instead is the credentials the mobile app needs to
> authenticate against your cluster's API server directly from your device.

This chart bootstraps the [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) needed for
the Kubenav mobile app to connect to your cluster. It creates
a [ServiceAccount](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/service-account-v1/)
(including the required `kubernetes.io/service-account-token` Secret)
alongside a [ClusterRole](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-v1/)
and [ClusterRoleBinding](https://kubernetes.io/docs/reference/kubernetes-api/authorization-resources/cluster-role-binding-v1/).
By default the ClusterRole only grants enough access to read back its own ServiceAccount token (via `rbac.rules` you
can grant it whatever additional access - read-only, namespace-scoped, full admin - you want the app to have; see the
[NOTES.txt](templates/NOTES.txt) output after installing for the exact commands to build a kubeconfig from the
resulting token).

If you're looking for a self-hosted, web-accessible Kubernetes dashboard instead, this chart isn't it - consider the
official [Kubernetes Dashboard](https://github.com/kubernetes/dashboard) or [Headlamp](https://headlamp.dev/), both
of which have their own actively maintained Helm charts.

## Parameters

### Name overrides

| Name               | Description                                   | Value |
| ------------------ | --------------------------------------------- | ----- |
| `nameOverride`     | String to partially override kubenav.fullname | `""`  |
| `fullnameOverride` | String to fully override kubenav.fullname     | `""`  |

### Secret parameters

| Name                 | Description                                        | Value |
| -------------------- | -------------------------------------------------- | ----- |
| `secret.annotations` | Annotations for the `service-account-token` Secret | `{}`  |
| `secret.labels`      | Labels for the `service-account-token` Secret      | `{}`  |

### RBAC parameters

| Name          | Description                           | Value  |
| ------------- | ------------------------------------- | ------ |
| `rbac.create` | Whether to create RBAC resources      | `true` |
| `rbac.rules`  | Extra rules to add to the ClusterRole | `[]`   |

### Service Account parameters

| Name                         | Description                                                               | Value   |
| ---------------------------- | ------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`      | Whether a service account should be created                               | `true`  |
| `serviceAccount.automount`   | Whether to automount the service account token                            | `false` |
| `serviceAccount.annotations` | Annotations to add to the service account                                 | `{}`    |
| `serviceAccount.name`        | A custom name for the service account, otherwise kubenav.fullname is used | `""`    |
| `serviceAccount.secrets`     | A list of secrets mountable by this service account                       | `[]`    |
