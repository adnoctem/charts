# Ad Noctem Collective - Linkstack Helm Chart <img src="https://raw.githubusercontent.com/LinkStackOrg/branding/c22886d7585246836d5e4e597484b92b51c76f0c/logo/png/logo.png" alt="Linkstack Logo" width="175" height="175" align="right" loading="lazy"/>

LinkStack provides you with a configurable self-hosted site similar to [Linktree](https://linktr.ee/). Many social
media platforms only allow you to add one link, with this you can simply link to your LinkStack page and have all the
links you want displayed on one site. You can share all your links to your social media platform or important links to
easy accessible and hosted on your own web-server or web-hosting provider. On this site, other users can register
and create their own links, you can access other user via the Admin Panel. It delivers all of these features within a
single Docker image available on [Docker Hub](https://hub.docker.com/r/linkstackorg/linkstack).

> Head to the [Linkstack GitHub Repository](https://github.com/LinkStackOrg/LinkStack) for in-depth view at the
> implementation or to the [documentation](https://docs.linkstack.org/) for guides
> and [examples](https://docs.linkstack.org/docker/setup/).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install linkstack adnoctem/linkstack --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/linkstack:X.Y.Z
```

## Introduction

This chart bootstraps a Linkstack [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster
networking a [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) manifest is also created, whereas the
Ingress needs to be explicitly enabled. Lastly the chart configures
a [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) if
enabled. [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are enabled by default.

The chart supports the configuration of all [Linkstack environment variables](https://docs.linkstack.org/docker/setup/)
via the `linkstack` key in Helm's _values_ and makes use of the official Docker Hub container image, although this is
configurable via the Image Parameters.

> [!NOTE]
> LinkStack does not publish semver-tagged images on Docker Hub, only `latest` - the chart pins `image.digest` to a
> specific `latest` build so upgrades stay deliberate; bump `image.digest` yourself to move to a newer build.

## Upgrading

### To 0.4.0 (LinkStack 4.8.0 -> 4.8.6)

- `appVersion` bumped from `4.8.0` to `4.8.6`, and `image.digest` updated to match. All intermediate releases were
  security/dependency patches and UI additions (new social buttons, a modular blocks system) - no environment
  variables or container behavior relevant to this chart changed.
- Corrected the `artifacthub.io/license` annotation: LinkStack is licensed AGPL-3.0, not MIT as previously listed.
- Fixed the data-seeding init container, which crashed (`chown: /data: Operation not permitted`) against the new
  image build - the image now runs as `apache` by default instead of `root`, so the init container needs an
  explicit `runAsUser: 0`/`runAsGroup: 0` to retain permission to `chown` the PVC on first install.
- If your LinkStack instance was ever upgraded via its own in-app updater while running `4.8.0`-`4.8.3`, be aware
  that a since-fixed bug in that updater could corrupt or delete the contents of the themes directory - see
  [the 4.8.4 release notes](https://github.com/LinkStackOrg/LinkStack/releases/tag/v4.8.4) if that applies to your
  deployment. This chart's own upgrade path (pulling a newer image) is unaffected.

## Parameters

### Image parameters

| Name                | Description                                                         | Value                                                                     |
| ------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `docker.io`                                                               |
| `image.repository`  | The registry repository to pull the image from                      | `linkstackorg/linkstack`                                                  |
| `image.tag`         | The image tag to pull                                               | `latest`                                                                  |
| `image.digest`      | The image digest to pull                                            | `sha256:1c8b05399ee459ac601bac3eede7fbe765d1b6b7be725663b57f3220610958bf` |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`                                                            |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`                                                                      |

### Name overrides

| Name               | Description                                     | Value |
| ------------------ | ----------------------------------------------- | ----- |
| `nameOverride`     | String to partially override linkstack.fullname | `""`  |
| `fullnameOverride` | String to fully override linkstack.fullname     | `""`  |

### Linkstack Configuration parameters

| Name                               | Description                                                  | Value      |
| ---------------------------------- | ------------------------------------------------------------ | ---------- |
| `linkstack.serverAdmin`            | The admin's email address                                    | `""`       |
| `linkstack.serverName`             | The http (and HTTPS) server name for Apache2                 | `""`       |
| `linkstack.logLevel`               | The log level for Apache2                                    | `info`     |
| `linkstack.timeZone`               | A valid PHP timezone                                         | `UTC`      |
| `linkstack.phpMemoryLimit`         | The memory limit for PHP                                     | `256M`     |
| `linkstack.uploadMaxFileSize`      | The upload-max-filesize for PHP                              | `8M`       |
| `linkstack.data.rootPath`          | The data folder is used for all files by default             | `/htdocs`  |
| `linkstack.data.pvc.size`          | The size given to PVCs created from the above data           | `5Gi`      |
| `linkstack.data.pvc.storageClass`  | The storageClass given to PVCs created from the above data   | `standard` |
| `linkstack.data.pvc.reclaimPolicy` | The resourcePolicy given to PVCs created from the above data | `Retain`   |
| `linkstack.data.pvc.existingClaim` | Provide the name to an existing PVC                          | `""`       |

### ConfigMap parameters

| Name                    | Description                             | Value |
| ----------------------- | --------------------------------------- | ----- |
| `configMap.annotations` | Annotations for the ConfigMap resource  | `{}`  |
| `configMap.labels`      | Extra Labels for the ConfigMap resource | `{}`  |

### Ingress parameters

| Name                  | Description                                                                | Value   |
| --------------------- | -------------------------------------------------------------------------- | ------- |
| `ingress.enabled`     | Whether to enable Ingress                                                  | `false` |
| `ingress.className`   | The IngressClass to use for the pod's ingress                              | `""`    |
| `ingress.whitelist`   | A comma-separated list of IP addresses to whitelist                        | `""`    |
| `ingress.annotations` | Annotations for the Ingress resource                                       | `{}`    |
| `ingress.tls`         | A list of hostnames and secret names to use for TLS                        | `[]`    |
| `ingress.extraHosts`  | A list of extra hosts for the Ingress resource (with linkstack.serverName) | `[]`    |

### Service parameters

| Name                               | Description                                                                             | Value       |
| ---------------------------------- | --------------------------------------------------------------------------------------- | ----------- |
| `service.type`                     | The type of service to create                                                           | `ClusterIP` |
| `service.ports.http`               | The http port to use on the service                                                     | `80`        |
| `service.ports.https`              | The HTTPS port to use on the service                                                    | `443`       |
| `service.nodePort`                 | The Node port to use on the service                                                     | `30080`     |
| `service.extraPorts`               | Extra ports to add to the service                                                       | `[]`        |
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
| `rbac.rules`  | Extra rules to add to the Role   | `[]`   |

### Service Account parameters

| Name                         | Description                                                                 | Value   |
| ---------------------------- | --------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`      | Whether a service account should be created                                 | `true`  |
| `serviceAccount.automount`   | Whether to automount the service account token                              | `false` |
| `serviceAccount.annotations` | Annotations to add to the service account                                   | `{}`    |
| `serviceAccount.name`        | A custom name for the service account, otherwise linkstack.fullname is used | `""`    |
| `serviceAccount.secrets`     | A list of secrets mountable by this service account                         | `[]`    |

### Liveness Probe parameters

| Name                                | Description                                                 | Value   |
| ----------------------------------- | ----------------------------------------------------------- | ------- |
| `livenessProbe.enabled`             | Enable or disable the use of liveness probes                | `false` |
| `livenessProbe.initialDelaySeconds` | Configure the initial delay seconds for the liveness probe  | `5`     |
| `livenessProbe.timeoutSeconds`      | Configure the initial delay seconds for the liveness probe  | `1`     |
| `livenessProbe.periodSeconds`       | Configure the seconds for each period of the liveness probe | `10`    |
| `livenessProbe.successThreshold`    | Configure the success threshold for the liveness probe      | `1`     |
| `livenessProbe.failureThreshold`    | Configure the failure threshold for the liveness probe      | `10`    |

### Readiness Probe parameters

| Name                                 | Description                                                  | Value   |
| ------------------------------------ | ------------------------------------------------------------ | ------- |
| `readinessProbe.enabled`             | Enable or disable the use of readiness probes                | `false` |
| `readinessProbe.initialDelaySeconds` | Configure the initial delay seconds for the readiness probe  | `5`     |
| `readinessProbe.timeoutSeconds`      | Configure the initial delay seconds for the readiness probe  | `1`     |
| `readinessProbe.periodSeconds`       | Configure the seconds for each period of the readiness probe | `10`    |
| `readinessProbe.successThreshold`    | Configure the success threshold for the readiness probe      | `1`     |
| `readinessProbe.failureThreshold`    | Configure the failure threshold for the readiness probe      | `3`     |

### Startup Probe parameters

| Name                               | Description                                                | Value   |
| ---------------------------------- | ---------------------------------------------------------- | ------- |
| `startupProbe.enabled`             | Enable or disable the use of readiness probes              | `false` |
| `startupProbe.initialDelaySeconds` | Configure the initial delay seconds for the startup probe  | `5`     |
| `startupProbe.timeoutSeconds`      | Configure the initial delay seconds for the startup probe  | `1`     |
| `startupProbe.periodSeconds`       | Configure the seconds for each period of the startup probe | `10`    |
| `startupProbe.successThreshold`    | Configure the success threshold for the startup probe      | `1`     |
| `startupProbe.failureThreshold`    | Configure the failure threshold for the startup probe      | `10`    |

### PodDisruptionBudget parameters

| Name                               | Description                                           | Value  |
| ---------------------------------- | ----------------------------------------------------- | ------ |
| `podDisruptionBudget.enabled`      | Enable the pod disruption budget                      | `true` |
| `podDisruptionBudget.minAvailable` | The minimum amount of pods which need to be available | `1`    |

### Pod settings

| Name                | Description                                         | Value |
| ------------------- | --------------------------------------------------- | ----- |
| `resources`         | The resource limits/requests for the Linkstack pod  | `{}`  |
| `volumes`           | Define volumes for the Linkstack pod                | `[]`  |
| `volumeMounts`      | Define volumeMounts for the Linkstack pod           | `[]`  |
| `initContainers`    | Define initContainers for the main Linkstack server | `[]`  |
| `nodeSelector`      | Node labels for pod assignment                      | `{}`  |
| `tolerations`       | Tolerations for pod assignment                      | `[]`  |
| `affinity`          | Affinity for pod assignment                         | `{}`  |
| `strategy`          | Specify a deployment strategy for the Linkstack pod | `{}`  |
| `podAnnotations`    | Extra annotations for the Linkstack pod             | `{}`  |
| `podLabels`         | Extra labels for the Linkstack pod                  | `{}`  |
| `priorityClassName` | The name of an existing PriorityClass               | `""`  |

### Security context settings

| Name                 | Description                                     | Value |
| -------------------- | ----------------------------------------------- | ----- |
| `podSecurityContext` | Security context settings for the Linkstack pod | `{}`  |
| `securityContext`    | General security context settings for           | `{}`  |
