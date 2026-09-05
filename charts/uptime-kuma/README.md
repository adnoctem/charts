# Ad Noctem Collective - Uptime-Kuma Helm Chart <img src="https://raw.githubusercontent.com/louislam/uptime-kuma/953058c6a5047c82a58606e442c6e572e215e3ff/public/icon-512x512.png" alt="Uptime-Kuma Logo" width="175" height="175" align="right" loading="lazy"/>

Uptime-Kuma is an open-source, is an easy-to-use self-hosted monitoring tool. It supports monitoring uptime for HTTP(
s) / TCP / HTTP(s) Keyword / HTTP(s) Json Query / Ping / DNS Record / Push / Steam Game Server / Docker Containers,
sports a fancy reactive and fast UI and features notifications via Telegram, Discord, Gotify, Slack, Pushover, Email (
SMTP),
and [90+ notification services](https://github.com/louislam/uptime-kuma/tree/master/src/components/notifications).
Additionally the application is available
in [multiple languages](https://github.com/louislam/uptime-kuma/tree/master/src/lang), can map status pages to specific
domains and supports proxies and 2FA. It delivers all of these features within a single Docker image available
on [Docker Hub](https://hub.docker.com/r/louislam/uptime-kuma).

> Head to the [Uptime-Kuma GitHub Repository](https://github.com/louislam/uptime-kuma/tree/master) for
> in-depth [documentation](https://github.com/louislam/uptime-kuma/wiki)
> and [configuration guides](https://github.com/louislam/uptime-kuma/wiki/Environment-Variables).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install uptime-kuma adnoctem/uptime-kuma --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/uptime-kuma:X.Y.Z
```

## Introduction

This chart bootstraps an
Uptime-Kuma [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
or [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) on
a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster networking
a [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) manifest is also created, whereas the
Ingress needs to be explicitly enabled. Lastly the chart configures
a [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) if
enabled. [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are enabled by default.

The chart supports the configuration of
all [Uptime-Kuma environment variables](https://github.com/louislam/uptime-kuma/wiki/Environment-Variables) via the
`uptimeKuma` key in Helm's _values_ and makes use of the official Docker Hub container image, although this is
configurable via the Image Parameters.

## Upgrading

### To 0.4.0 (Uptime-Kuma 1.23.13 -> 2.5.3)

This is a major upstream version bump. Read the
[official v1 to v2 migration guide](https://github.com/louislam/uptime-kuma/wiki/Migration-From-v1-To-v2) before
upgrading - on first start with the new image, Uptime-Kuma migrates its SQLite database in place, which can take
anywhere from minutes to hours depending on how much monitor history you have, and **must not be interrupted**.
Back up your PVC first.

- Fixed three pre-existing, version-independent template bugs found while testing this bump:
  - The `readinessProbe` and `startupProbe` blocks both incorrectly rendered a second/third `livenessProbe` instead
    of their own probe type, so enabling more than one of the three probes only ever actually configured one of
    them on the container.
  - All three probes checked an `/alive` path that has never existed in Uptime-Kuma's HTTP server, in v1 or v2.
    Switched to `/`, which is what the image's own bundled Docker healthcheck script checks for a redirect on.
  - `uptimeKuma.node.tlsRejectUnauthorized` rendered into the `NODE_EXTRA_CA_CERTS` ConfigMap key (a duplicate of
    the unrelated CA-bundle setting) instead of `NODE_TLS_REJECT_UNAUTHORIZED`.
- No values were renamed or removed - every environment variable this chart already configures is still valid and
  unchanged in v2.
- Operational notes, no chart changes required for these:
  - Uptime-Kuma's own log line format changed between v1 and v2 - if you ship or parse container logs externally,
    expect to update those rules.
  - Badge endpoint duration parameters (`/api/badge/:monitorID/{ping,uptime}/:duration`) are now restricted to
    `24`, `24h`, `30d`, `1y`-style values.
  - Legacy browser support was dropped from the bundled web UI.
  - v2 adds `-slim` and `-rootless` image tag variants, but upstream explicitly recommends against using
    `-rootless` for the v1 -> v2 migration itself due to known startup issues - this chart's default `image.tag`
    stays on the standard (non-slim, non-rootless) variant.

## Parameters

### Uptime-Kuma Image parameters

| Name                | Description                                                         | Value                  |
| ------------------- | ------------------------------------------------------------------- | ---------------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `docker.io`            |
| `image.repository`  | The registry repository to pull the image from                      | `louislam/uptime-kuma` |
| `image.tag`         | The image tag to pull                                               | `2.5.3`                |
| `image.digest`      | The image digest to pull                                            | `""`                   |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`         |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`                   |

### Uptime-Kuma Name overrides

| Name               | Description                                      | Value |
| ------------------ | ------------------------------------------------ | ----- |
| `nameOverride`     | String to partially override uptimeKuma.fullname | `""`  |
| `fullnameOverride` | String to fully override uptimeKuma.fullname     | `""`  |

### Uptime-Kuma Configuration parameters

| Name                                              | Description                                                                                         | Value         |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------- | ------------- |
| `uptimeKuma.host`                                 | The host address to bind Uptime-Kuma to                                                             | `"::"`        |
| `uptimeKuma.port`                                 | The port for Uptime-Kuma to listen on                                                               | `3001`        |
| `uptimeKuma.disableFrameSameOrigin`               | Allow Uptime-Kuma to be embedded inside HTML 'iframes' of other origins                             | `false`       |
| `uptimeKuma.websocketOriginCheck`                 | Configures Uptime-Kuma to check whether the websocket 'ORIGIN' header matches the server's hostname | `"cors-like"` |
| `uptimeKuma.allowAllChromeExecutables`            | Allow to specify any executables as Chromium                                                        | `"0"`         |
| `uptimeKuma.data.path`                            | The relative path to store data in                                                                  | `data`        |
| `uptimeKuma.data.pvc.size`                        | The size given to PVCs created from the above data                                                  | `5Gi`         |
| `uptimeKuma.data.pvc.storageClass`                | The storageClass given to PVCs created from the above data                                          | `standard`    |
| `uptimeKuma.data.pvc.reclaimPolicy`               | The resourcePolicy given to PVCs created from the above data                                        | `Retain`      |
| `uptimeKuma.data.pvc.existingClaim`               | Provide the name to an existing PVC                                                                 | `""`          |
| `uptimeKuma.certs.key`                            | The path to an TLS certificate key - ignored if 'existingSecret' is set                             | `""`          |
| `uptimeKuma.certs.cert`                           | The path to an TLS certificate cert - ignored if 'existingSecret' is set                            | `""`          |
| `uptimeKuma.certs.passphrase.value`               | The passphrase for the TLS certificate key                                                          | `""`          |
| `uptimeKuma.certs.passphrase.existingSecret.name` | The name of an existing Kubernetes secret                                                           | `""`          |
| `uptimeKuma.certs.passphrase.existingSecret.key`  | The key within the existing Kubernetes secret                                                       | `""`          |
| `uptimeKuma.cloudflaredToken.value`               | The Cloudflare Tunnel token                                                                         | `""`          |
| `uptimeKuma.cloudflaredToken.existingSecret.name` | The name of an existing Kubernetes secret                                                           | `""`          |
| `uptimeKuma.cloudflaredToken.existingSecret.key`  | The key within the existing Kubernetes secret                                                       | `""`          |
| `uptimeKuma.node.extraCaCerts`                    | The path to CA bundle for Node.js to use - in order to verify self-signed certificates              | `""`          |
| `uptimeKuma.node.tlsRejectUnauthorized`           | Ignore all TLS verification errors                                                                  | `""`          |
| `uptimeKuma.node.options`                         | Specify extra CLI options to pass to Node.js                                                        | `[]`          |

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

| Name                  | Description                                                              | Value   |
| --------------------- | ------------------------------------------------------------------------ | ------- |
| `ingress.enabled`     | Whether to enable Ingress                                                | `false` |
| `ingress.className`   | The IngressClass to use for the pod's ingress                            | `""`    |
| `ingress.whitelist`   | A comma-separated list of IP addresses to whitelist                      | `""`    |
| `ingress.annotations` | Annotations for the Ingress resource                                     | `{}`    |
| `ingress.tls`         | A list of hostnames and secret names to use for TLS                      | `[]`    |
| `ingress.extraHosts`  | A list of extra hosts for the Ingress resource (with vaultwarden.domain) | `[]`    |

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

| Name                         | Description                                                                  | Value   |
| ---------------------------- | ---------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`      | Whether a service account should be created                                  | `true`  |
| `serviceAccount.automount`   | Whether to automount the service account token                               | `false` |
| `serviceAccount.annotations` | Annotations to add to the service account                                    | `{}`    |
| `serviceAccount.name`        | A custom name for the service account, otherwise uptimeKuma.fullname is used | `""`    |
| `serviceAccount.secrets`     | A list of secrets mountable by this service account                          | `[]`    |

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

| Name                | Description                                           | Value |
| ------------------- | ----------------------------------------------------- | ----- |
| `resources`         | The resource limits/requests for the Uptime-Kuma pod  | `{}`  |
| `volumes`           | Define volumes for the Paperless pod                  | `[]`  |
| `volumeMounts`      | Define volumeMounts for the Paperless pod             | `[]`  |
| `initContainers`    | Define initContainers for the main Uptime-Kuma server | `[]`  |
| `nodeSelector`      | Node labels for pod assignment                        | `{}`  |
| `tolerations`       | Tolerations for pod assignment                        | `[]`  |
| `affinity`          | Affinity for pod assignment                           | `{}`  |
| `strategy`          | Specify a deployment strategy for the Uptime-Kuma pod | `{}`  |
| `podAnnotations`    | Extra annotations for the Uptime-Kuma pod             | `{}`  |
| `podLabels`         | Extra labels for the Uptime-Kuma pod                  | `{}`  |
| `priorityClassName` | The name of an existing PriorityClass                 | `""`  |

### Security context settings

| Name                 | Description                                       | Value |
| -------------------- | ------------------------------------------------- | ----- |
| `podSecurityContext` | Security context settings for the Uptime-Kuma pod | `{}`  |
| `securityContext`    | General security context settings for             | `{}`  |
