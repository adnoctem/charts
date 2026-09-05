# Ad Noctem Collective - Cachet Helm Chart <img src="https://raw.githubusercontent.com/cachethq/art/1a545d3ae52df6ee4d22677acfcc6ab4a90ef231/logo-mark/cachet-logomark-green.png" alt="Cachet Logo" width="175" height="175" align="right" loading="lazy">

> [!IMPORTANT]
> This Helm chart relies on the open-source _Bitnami_ Helm chart `postgresql`. Beginning on August 28th, 2025, _Bitnami_
> (_VMware_/_Broadcom_) has changed their public offering and will require a commercial license for the use of their charts and images
> (_Bitnami Secure Images_/_BSI_). The only images available to the public as of now are a small set of hardened images which are only
> available at the 'latest' tag and meant for testing and development purposes. As such, the PostgreSQL subchart included in this Helm
> chart is provided for convenience, but users are encouraged to use their own PostgreSQL instance, another PostgreSQL Helm chart or
> (preferably) an Operator-managed PostgreSQL instance like CloudnativePG, if they do not wish to obtain a Bitnami license.
>
> _ref: [`bitnami/charts` - Issue 35164](https://github.com/bitnami/charts/issues/35164)_

Cachet is an open-source status page system designed to help you keep track of your system status and share it with your
user base. It is built to be responsive and works seamlessly across different devices. It is perfect for businesses and
organizations of all sizes that want to maintain transparency about their system's status with their users, especially
in cases of downtime or maintenance. As an open-source project, Cachet is freely available for self-hosting.

It delivers all of these features within a single Docker image available
on [Docker Hub](https://hub.docker.com/r/cachethq/docker/).

> Head to the [Cachet GitHub Repository](https://github.com/cachethq/cachet) or
> their [Website](https://cachethq.io/) for in-depth [documentation](https://docs.cachethq.io/introduction.html)
> and [configuration guides](https://docs.cachethq.io/installation/docker.html).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install cachet adnoctem/cachet --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/cachet:X.Y.Z
```

## Introduction

This chart bootstraps a Cachet [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) on
a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster networking
a [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) manifest is also created, whereas the
Ingress needs to be explicitly enabled. Lastly the chart configures
a [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) if
enabled. [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are enabled by default.

The chart supports the configuration of
all [Cachet environment variables](https://docs.cachethq.io/installation/docker.html)
via the `cachet` key in Helm's _values_ and makes use of the official Docker Hub container image, although this is
configurable via the Image
Parameters.

> [!NOTE]
> Cachet ships under a custom license (see
> [the upstream LICENSE](https://github.com/cachethq/cachet/blob/2.4/LICENSE.md)), not a common OSS license like MIT
> or Apache-2.0 - review it before redistributing this chart or the underlying image as a standalone product.
>
> Cachet's own GitHub releases go up to `v2.4.1`, but
> [no Docker image has been published for `2.4.x`](https://github.com/CachetHQ/Docker/issues/267) - the last image
> on Docker Hub is `2.3.18`, which this chart targets. Upstream is also rebuilding Cachet as a new `3.x` release on
> Laravel/Tailwind/Filament (currently the repository's default branch), but it has no tagged releases or images yet
> and isn't production-ready - worth knowing about, not something to chase in this chart today.

## Upgrading

### To 0.4.0 (Cachet 2.3.15 -> 2.3.18)

- `appVersion` bumped from `2.3.15` to `2.3.18` - the last image cachethq has published to Docker Hub (see the note
  above). No environment variables or configuration changed between these versions.
- Corrected the `artifacthub.io/license` annotation: Cachet ships under its own custom license, not MIT as
  previously listed.

## Parameters

### Image parameters

| Name                | Description                                                         | Value             |
| ------------------- | ------------------------------------------------------------------- | ----------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `docker.io`       |
| `image.repository`  | The registry repository to pull the image from                      | `cachethq/docker` |
| `image.tag`         | The image tag to pull                                               | `2.3.18`          |
| `image.digest`      | The image digest to pull                                            | `""`              |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`    |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`              |

### Name overrides

| Name               | Description                                     | Value |
| ------------------ | ----------------------------------------------- | ----- |
| `nameOverride`     | String to partially override linkstack.fullname | `""`  |
| `fullnameOverride` | String to fully override linkstack.fullname     | `""`  |

### Cachet Configuration parameters

| Name                                     | Description                                                               | Value        |
| ---------------------------------------- | ------------------------------------------------------------------------- | ------------ |
| `cachet.url`                             | The public facing URL for the application. Reused in Ingress if set.      | `""`         |
| `cachet.env`                             | Set the environment the application should run within                     | `production` |
| `cachet.debug`                           | Whether the app should be run in debug mode                               | `false`      |
| `cachet.emoji`                           | Enable GitHub Emoji's                                                     | `false`      |
| `cachet.beacon`                          | Whether or not to enable Cachet's telemetry                               | `true`       |
| `cachet.githubToken.value`               | The GitHub API token                                                      | `""`         |
| `cachet.githubToken.existingSecret.name` | The name of an existing Secret containing the token                       | `""`         |
| `cachet.githubToken.existingSecret.key`  | The key name within the previously named existingSecret                   | `""`         |
| `cachet.drivers.cache`                   | The driver used to support caching. `apc`, `file` or `database`.          | `apc`        |
| `cachet.drivers.session`                 | The driver used to support sessions. `apc`, `file` or `database`.         | `apc`        |
| `cachet.drivers.queue`                   | The driver used to support queues. `sync` or `database`.                  | `sync`       |
| `cachet.drivers.mail`                    | The driver used to support queues                                         | `smtp`       |
| `cachet.key.value`                       | The application key for encryption (do not change after installation)     | `""`         |
| `cachet.key.existingSecret.name`         | The name of an existing Secret containing the app key                     | `""`         |
| `cachet.key.existingSecret.key`          | The key name within the previously named existingSecret                   | `""`         |
| `cachet.database.driver`                 | The database driver to use `sqlite`, `mysql` or `pgsql`                   | `pgsql`      |
| `cachet.database.host`                   | The database host, or path in case of `sqlite`                            | `""`         |
| `cachet.database.port`                   | The database port, ignored in case of `sqlite`                            | `""`         |
| `cachet.database.name`                   | The database name                                                         | `""`         |
| `cachet.database.user`                   | The database user                                                         | `""`         |
| `cachet.database.password`               | The database user password                                                | `""`         |
| `cachet.database.existingSecret`         | The name of an existing secret containing a `username` and `password` key | `""`         |
| `cachet.mail.host`                       | The host of an SMTP server                                                | `""`         |
| `cachet.mail.port`                       | The port of an SMTP server                                                | `""`         |
| `cachet.mail.address`                    | The sender address for emails sent by Cachet                              | `""`         |
| `cachet.mail.name`                       | The name for emails sent by Cachet                                        | `""`         |
| `cachet.mail.encryption`                 | The encryption to use for interactions with the SMTP server               | `tls`        |
| `cachet.mail.user`                       | The SMTP user                                                             | `""`         |
| `cachet.mail.password`                   | The SMTP user password                                                    | `""`         |
| `cachet.mail.existingSecret`             | The name of an existing secret containing a `username` and `password` key | `""`         |
| `cachet.redis.host`                      | The Redis host, or path in case of `sqlite`                               | `""`         |
| `cachet.redis.port`                      | The Redis port, ignored in case of `sqlite`                               | `""`         |
| `cachet.redis.database`                  | The Redis database name                                                   | `""`         |

### ConfigMap parameters

| Name                    | Description                             | Value |
| ----------------------- | --------------------------------------- | ----- |
| `configMap.annotations` | Annotations for the ConfigMap resource  | `{}`  |
| `configMap.labels`      | Extra Labels for the ConfigMap resource | `{}`  |

### Common Secret parameters

| Name                 | Description                                                        | Value |
| -------------------- | ------------------------------------------------------------------ | ----- |
| `secret.annotations` | Common annotations for the SMTP, HIBP, Admin and Database secrets  | `{}`  |
| `secret.labels`      | Common extra labels for the SMTP, HIBP, Admin and Database secrets | `{}`  |

### Ingress parameters

| Name                  | Description                                         | Value   |
| --------------------- | --------------------------------------------------- | ------- |
| `ingress.enabled`     | Whether to enable Ingress                           | `false` |
| `ingress.className`   | The IngressClass to use for the pod's ingress       | `""`    |
| `ingress.whitelist`   | A comma-separated list of IP addresses to whitelist | `""`    |
| `ingress.annotations` | Annotations for the Ingress resource                | `{}`    |
| `ingress.tls`         | A list of hostnames and secret names to use for TLS | `[]`    |
| `ingress.extraHosts`  | A list of extra hosts for the Ingress resource      | `[]`    |

### Service parameters

| Name                               | Description                                                                             | Value       |
| ---------------------------------- | --------------------------------------------------------------------------------------- | ----------- |
| `service.type`                     | The type of service to create                                                           | `ClusterIP` |
| `service.port`                     | The port to use on the service                                                          | `80`        |
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

| Name                         | Description                                                              | Value   |
| ---------------------------- | ------------------------------------------------------------------------ | ------- |
| `serviceAccount.create`      | Whether a service account should be created                              | `true`  |
| `serviceAccount.automount`   | Whether to automount the service account token                           | `false` |
| `serviceAccount.annotations` | Annotations to add to the service account                                | `{}`    |
| `serviceAccount.name`        | A custom name for the service account, otherwise cachet.fullname is used | `""`    |
| `serviceAccount.secrets`     | A list of secrets mountable by this service account                      | `[]`    |

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

| Name                | Description                                      | Value |
| ------------------- | ------------------------------------------------ | ----- |
| `resources`         | The resource limits/requests for the Cachet pod  | `{}`  |
| `volumes`           | Define volumes for the Cachet pod                | `[]`  |
| `volumeMounts`      | Define volumeMounts for the Cachet pod           | `[]`  |
| `initContainers`    | Define initContainers for the main Cachet server | `[]`  |
| `nodeSelector`      | Node labels for pod assignment                   | `{}`  |
| `tolerations`       | Tolerations for pod assignment                   | `[]`  |
| `affinity`          | Affinity for pod assignment                      | `{}`  |
| `strategy`          | Specify a deployment strategy for the Cachet pod | `{}`  |
| `podAnnotations`    | Extra annotations for the Cachet pod             | `{}`  |
| `podLabels`         | Extra labels for the Cachet pod                  | `{}`  |
| `priorityClassName` | The name of an existing PriorityClass            | `""`  |

### Security context settings

| Name                 | Description                                  | Value |
| -------------------- | -------------------------------------------- | ----- |
| `podSecurityContext` | Security context settings for the Cachet pod | `{}`  |
| `securityContext`    | General security context settings for        | `{}`  |

### Bitnami&reg; PostgreSQL parameters

### PostgreSQL Global parameters

| Name                                             | Description                                                                                                                    | Value                        |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------- |
| `postgresql.global.imageRegistry`                | Global Docker image registry. Force 'docker.io' - required due to BSI.                                                         | `docker.io`                  |
| `postgresql.global.security.allowInsecureImages` | Allows skipping image verification. 'bitnamisecure' images meet the charts' security requirements. Others will require 'true'. | `false`                      |
| `postgresql.image.registry`                      | PostgreSQL image registry                                                                                                      | `REGISTRY_NAME`              |
| `postgresql.image.repository`                    | PostgreSQL image repository. 'bitnamisecure' is recommended.                                                                   | `REPOSITORY_NAME/postgresql` |
| `postgresql.image.tag`                           | PostgreSQL image tag. As of August 28th, 2025, only 'latest' is available publicly due to BSI.                                 | `latest`                     |
| `postgresql.enabled`                             | Enable or disable the PostgreSQL subchart                                                                                      | `true`                       |
| `postgresql.auth.enablePostgresUser`             | Assign a password to the "postgres" admin user. Otherwise, remote access will be blocked for this user                         | `true`                       |
| `postgresql.auth.postgresPassword`               | Password for the "postgres" admin user. Ignored if `auth.existingSecret` is provided                                           | `postgres`                   |
| `postgresql.auth.username`                       | Name for a custom user to create                                                                                               | `cachet`                     |
| `postgresql.auth.password`                       | Password for the custom user to create. Ignored if `auth.existingSecret` is provided                                           | `cachet`                     |
| `postgresql.auth.database`                       | Name for a custom database to create                                                                                           | `cachet`                     |
| `postgresql.auth.usePasswordFiles`               | Mount credentials as a files instead of using an environment variable                                                          | `false`                      |

### PostgreSQL Primary parameters

| Name                                           | Description                                                    | Value               |
| ---------------------------------------------- | -------------------------------------------------------------- | ------------------- |
| `postgresql.primary.name`                      | Name of the primary database (eg primary, master, leader, ...) | `primary`           |
| `postgresql.primary.persistence.enabled`       | Enable PostgreSQL Primary data persistence using PVC           | `true`              |
| `postgresql.primary.persistence.existingClaim` | Name of an existing PVC to use                                 | `""`                |
| `postgresql.primary.persistence.storageClass`  | PVC Storage Class for PostgreSQL Primary data volume           | `""`                |
| `postgresql.primary.persistence.accessModes`   | PVC Access Mode for PostgreSQL volume                          | `["ReadWriteOnce"]` |
| `postgresql.primary.persistence.size`          | PVC Storage Request for PostgreSQL volume                      | `5Gi`               |

### Bitnami&reg; Redis parameters

### Redis Global parameters

| Name                                        | Description                                                                                                                    | Value                   |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ----------------------- |
| `redis.global.imageRegistry`                | Global Docker image registry. Force 'docker.io' - required due to BSI.                                                         | `docker.io`             |
| `redis.global.security.allowInsecureImages` | Allows skipping image verification. 'bitnamisecure' images meet the charts' security requirements. Others will require 'true'. | `false`                 |
| `redis.image.registry`                      | Redis image registry                                                                                                           | `REGISTRY_NAME`         |
| `redis.image.repository`                    | Redis image repository. 'bitnamisecure' is recommended.                                                                        | `REPOSITORY_NAME/redis` |
| `redis.image.tag`                           | Redis image tag. As of August 28th, 2025, only 'latest' is available publicly due to BSI.                                      | `latest`                |
| `redis.enabled`                             | Enable or disable the Redis&reg; subchart                                                                                      | `false`                 |
| `redis.architecture`                        | Redis&reg; architecture. Allowed values: `standalone` or `replication`                                                         | `standalone`            |
| `redis.auth.password`                       | Redis&reg; password                                                                                                            | `""`                    |
