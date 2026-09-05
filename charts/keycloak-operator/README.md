# Ad Noctem Collective - Keycloak Operator Helm Chart <img src="https://raw.githubusercontent.com/keycloak/keycloak-misc/main/logo/logo.png" alt="Keycloak Operator Logo" width="250" height="auto" align="right" loading="lazy"/>

Keycloak is an open source software product to allow single sign-on with identity and access management aimed at modern
applications and services. It supports various protocols such as OpenID, OAuth version 2.0 and SAML and provides
features such as user management, two-factor authentication, permissions and roles management, creating token services,
etc. The [Keycloak Operator](https://github.com/keycloak/keycloak/tree/main/operator) will allow you to deploy dedicated
instances of Keycloak at will using the newly registered
`Keycloak` [CustomResourceDefinition](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/).
Unfortunately the [Keycloak Project](https://www.keycloak.org/) does not provide a way to [install
the Operator via a Helm Chart](https://www.keycloak.org/operator/installation#_installing_by_using_kubectl_without_operator_lifecycle_manager),
thus making it challenging to manage. This Helm Chart is built from the
official [upstream sources](https://github.com/keycloak/keycloak-k8s-resources/blob/26.0.6/kubernetes/kubernetes.yml)
and closely tracks these for changes. It delivers all of these features within a single Docker image available
on [quay.io](https://quay.io/repository/keycloak/keycloak-operator).

> Head to the [Keycloak GitHub Repository](https://github.com/keycloak/keycloak) for
> in-depth [documentation](https://www.keycloak.org/guides).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install vaultwarden adnoctem/keycloak-operator --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/keycloak-operator:X.Y.Z
```

## Introduction

This chart bootstraps a
Keycloak Operator [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) on
a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster networking
a [Service](https://kubernetes.io/docs/concepts/services-networking/service/) manifest is also created.
The chart creates the [RBAC roles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) (ClusterRoles)
`keycloakrealmimportcontroller-cluster-role`, `keycloakcontroller-cluster-role` and (Roles) `keycloak-operator-role`.
These are enabled by default.

The chart supports configuring the Kubernetes manifests created for the Operator, however modifications are somewhat
discouraged, since the official release for vanilla Kubernetes uses static manifests. The Operator itself does not offer
any sort of configuration (to [my](https://github.com/mvprowess) knowledge). I will try to ensure the chart always matches
the upstream deployment at the given versions.

After deployment the Operator gives you access to the `Keycloak` CR making the deployment of Keycloak (even as a
cluster) as simple as:

```shell
kubectl apply -f - <<EOF
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: example-kc
spec:
  instances: 1
  db:
    vendor: postgres
    host: postgres-db
    usernameSecret:
      name: keycloak-db-secret
      key: username
    passwordSecret:
      name: keycloak-db-secret
      key: password
  http:
    tlsSecret: example-tls-secret
  hostname:
    hostname: test.keycloak.org
  proxy:
    headers: xforwarded
EOF
```

## Parameters

### Image parameters

| Name                | Description                                                         | Value                        |
| ------------------- | ------------------------------------------------------------------- | ---------------------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `quay.io`                    |
| `image.repository`  | The registry repository to pull the image from                      | `keycloak/keycloak-operator` |
| `image.tag`         | The image tag to pull                                               | `26.0.6`                     |
| `image.digest`      | The image digest to pull                                            | `""`                         |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`               |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`                         |

### Name overrides

| Name               | Description                                      | Value |
| ------------------ | ------------------------------------------------ | ----- |
| `nameOverride`     | String to partially override kcOperator.fullname | `""`  |
| `fullnameOverride` | String to fully override kcOperator.fullname     | `""`  |

### Service parameters

| Name                               | Description                                                                             | Value       |
| ---------------------------------- | --------------------------------------------------------------------------------------- | ----------- |
| `service.type`                     | The type of service to create                                                           | `ClusterIP` |
| `service.port`                     | The port to use on the service                                                          | `80`        |
| `service.nodePort`                 | The Node port to use on the service                                                     | `30080`     |
| `service.annotations`              | Annotations for the service resource                                                    | `{}`        |
| `service.labels`                   | Labels for the service resource                                                         | `{}`        |
| `service.externalTrafficPolicy`    | The external traffic policy for the service                                             | `Cluster`   |
| `service.internalTrafficPolicy`    | The internal traffic policy for the service                                             | `Cluster`   |
| `service.clusterIP`                | Define a static cluster IP for the service                                              | `""`        |
| `service.loadBalancerIP`           | Set the Load Balancer IP                                                                | `""`        |
| `service.loadBalancerClass`        | Define Load Balancer class if service type is `LoadBalancer` (optional, cloud specific) | `""`        |
| `service.loadBalancerSourceRanges` | Service Load Balancer source ranges                                                     | `[]`        |
| `service.externalIPs`              | Service External IPs                                                                    | `[]`        |
| `service.sessionAffinity`          | Session Affinity for Kubernetes service, can be "None" or "ClientIP"                    | `None`      |
| `service.sessionAffinityConfig`    | Additional settings for the sessionAffinity                                             | `{}`        |
| `service.ipFamilyPolicy`           | The ipFamilyPolicy                                                                      | `{}`        |

### RBAC parameters

| Name          | Description                      | Value  |
| ------------- | -------------------------------- | ------ |
| `rbac.create` | Whether to create RBAC resources | `true` |

### Service Account parameters

| Name                         | Description                                                                  | Value  |
| ---------------------------- | ---------------------------------------------------------------------------- | ------ |
| `serviceAccount.create`      | Whether a service account should be created                                  | `true` |
| `serviceAccount.automount`   | Whether to automount the service account token                               | `true` |
| `serviceAccount.annotations` | Annotations to add to the service account                                    | `{}`   |
| `serviceAccount.name`        | A custom name for the service account, otherwise kcOperator.fullname is used | `""`   |

### Liveness Probe parameters

| Name                                | Description                                                 | Value  |
| ----------------------------------- | ----------------------------------------------------------- | ------ |
| `livenessProbe.enabled`             | Enable or disable the use of liveness probes                | `true` |
| `livenessProbe.initialDelaySeconds` | Configure the initial delay seconds for the liveness probe  | `5`    |
| `livenessProbe.timeoutSeconds`      | Configure the initial delay seconds for the liveness probe  | `10`   |
| `livenessProbe.periodSeconds`       | Configure the seconds for each period of the liveness probe | `10`   |
| `livenessProbe.successThreshold`    | Configure the success threshold for the liveness probe      | `1`    |
| `livenessProbe.failureThreshold`    | Configure the failure threshold for the liveness probe      | `3`    |

### Readiness Probe parameters

| Name                                 | Description                                                  | Value  |
| ------------------------------------ | ------------------------------------------------------------ | ------ |
| `readinessProbe.enabled`             | Enable or disable the use of readiness probes                | `true` |
| `readinessProbe.initialDelaySeconds` | Configure the initial delay seconds for the readiness probe  | `5`    |
| `readinessProbe.timeoutSeconds`      | Configure the initial delay seconds for the readiness probe  | `10`   |
| `readinessProbe.periodSeconds`       | Configure the seconds for each period of the readiness probe | `10`   |
| `readinessProbe.successThreshold`    | Configure the success threshold for the readiness probe      | `1`    |
| `readinessProbe.failureThreshold`    | Configure the failure threshold for the readiness probe      | `3`    |

### Startup Probe parameters

| Name                               | Description                                                | Value  |
| ---------------------------------- | ---------------------------------------------------------- | ------ |
| `startupProbe.enabled`             | Enable or disable the use of readiness probes              | `true` |
| `startupProbe.initialDelaySeconds` | Configure the initial delay seconds for the startup probe  | `5`    |
| `startupProbe.timeoutSeconds`      | Configure the initial delay seconds for the startup probe  | `10`   |
| `startupProbe.periodSeconds`       | Configure the seconds for each period of the startup probe | `10`   |
| `startupProbe.successThreshold`    | Configure the success threshold for the startup probe      | `1`    |
| `startupProbe.failureThreshold`    | Configure the failure threshold for the startup probe      | `3`    |
