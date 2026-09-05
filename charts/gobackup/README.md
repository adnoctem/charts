# Ad Noctem Collective - GoBackup Helm Chart <img src="https://user-images.githubusercontent.com/5518/205909959-12b92929-4ac5-4bb5-9111-6f9a3ed76cf6.png" alt="GoBackup Logo" width="175" height="175" align="right" loading="lazy"/>

GoBackup is a CLI and Web UI for database backups to local, cloud or remote storage (FTP, SCP, S3, GCS, Aliyun
OSS ...) with encryption support. It supports running these tasks on a schedule defined within a configuration file.
Sending automatic notifications to a wide array of services (Slack, SMTP, Discord, GitHub, ...) is also supported. It
delivers all of these features within a single Docker image available
on [Docker Hub](https://hub.docker.com/r/huacnlee/gobackup).

> Head to the [GoBackup Homepage](https://gobackup.github.io/) for
> in-depth documentation
> and [configuration guides](https://gobackup.github.io/configuration).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install gobackup adnoctem/gobackup --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/gobackup:X.Y.Z
```

## Introduction

This chart bootstraps a GoBackup [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) on
a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster networking
a [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) manifest is also created, whereas the
Ingress needs to be explicitly enabled. Lastly the chart configures
a [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) if
enabled. [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are enabled by default.

The chart supports the configuration of all [GoBackup configuration options](https://gobackup.github.io/configuration)
via the `gobackup` key in Helm's _values_ and makes use of the official Docker Hub container image, although this is
configurable via the Image Parameters.

> [!NOTE]
> This chart passes most `gobackup.models[].databases[].config`, `.storages[].config`, and `.notifiers[].config`
> keys straight through to GoBackup's YAML config, but the `username`/`password` keys of every entry are always
> wired to a generated environment variable backed by a Secret (see Common Secret parameters below) - a database,
> storage, or notifier type that authenticates without a username/password pair (e.g. `sqlite`, or a `local`
> storage) is not currently supported by this chart, even though GoBackup itself doesn't require credentials for
> those types.

## Upgrading

### To 0.4.0 (GoBackup 2.11.2 -> 3.1.1)

- `appVersion` bumped from `2.11.2` to `3.1.1`. Review the
  [upstream changelog](https://github.com/gobackup/gobackup/releases) for anything between those versions that
  affects your configuration; notably, MSSQL database config keys switched to snake_case
  (e.g. `trust_server_certificate`, `all_databases`, `skip_databases`) somewhere in that range - update your
  `gobackup.models[].databases[].config` accordingly if you use MSSQL.
- Added support for the `firebird` database type and the `googlechat` notifier type, both added upstream since
  2.16.0/2.13.0 respectively.
- Added `gobackup.web.enabled` to allow disabling the built-in Web UI entirely; it defaults to `true`, matching
  previous behavior.
- Fixed two internal validation helpers that checked for the wrong model key (dead code - neither is currently
  invoked from any template, so this has no behavioral effect).

## Parameters

### Image parameters

| Name                | Description                                                         | Value               |
| ------------------- | ------------------------------------------------------------------- | ------------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `docker.io`         |
| `image.repository`  | The registry repository to pull the image from                      | `huacnlee/gobackup` |
| `image.tag`         | The image tag to pull                                               | `v3.1.1`            |
| `image.digest`      | The image digest to pull                                            | `""`                |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`      |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`                |

### Name overrides

| Name               | Description                                    | Value |
| ------------------ | ---------------------------------------------- | ----- |
| `nameOverride`     | String to partially override gobackup.fullname | `""`  |
| `fullnameOverride` | String to fully override gobackup.fullname     | `""`  |

### GoBackup Configuration parameters

| Name                                | Description                                                                                           | Value                    |
| ----------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------ |
| `gobackup.workdir`                  | Define a working directory for GoBackup to generate temporary files                                   | `/tmp`                   |
| `gobackup.web.enabled`              | Whether to enable the built-in Web UI at all                                                          | `true`                   |
| `gobackup.web.host`                 | The host the network socket should bind to. You will most likely never change this.                   | `""`                     |
| `gobackup.web.port`                 | The port to bind the network socket to                                                                | `2703`                   |
| `gobackup.web.username`             | The HTTP Basic Auth username                                                                          | `""`                     |
| `gobackup.web.password`             | The HTTP Basic Auth password                                                                          | `""`                     |
| `gobackup.web.existingSecret`       | The name of a `basic-auth` secret containing aforementioned credentials                               | `""`                     |
| `gobackup.models[0].name`           | The name of the model to create (the YAML keys everything is nested under, e.g. `model_name1` in ref) | `default`                |
| `gobackup.models[0].description`    | Define a description for this GoBackup model                                                          | `Default GoBackup model` |
| `gobackup.models[0].default`        | Set a default storage name                                                                            | `default`                |
| `gobackup.models[0].schedule`       | Configure a schedule on which the model should run                                                    | `{}`                     |
| `gobackup.models[0].scripts.before` | A script to be executed before the backup                                                             | `""`                     |
| `gobackup.models[0].scripts.after`  | A script to be executed after the backup                                                              | `""`                     |
| `gobackup.models[0].databases`      | Configure the databases in the model                                                                  | `[]`                     |
| `gobackup.models[0].storages`       | Configure the storages in the model                                                                   | `[]`                     |
| `gobackup.models[0].notifiers`      | Configure the notifiers in the model                                                                  | `[]`                     |
| `gobackup.models[0].compression`    | The compression format used for created backups (e.g. `tgz`)                                          | `""`                     |
| `gobackup.models[0].encryption`     | The encryption configuration (locked to type `openssl`)                                               | `{}`                     |
| `gobackup.models[0].archive`        | Configure archival of directories                                                                     | `{}`                     |
| `gobackup.models[0].splitter`       | Configure backup chunking                                                                             | `{}`                     |
| `configMap.annotations`             | Annotations for the ConfigMap resource                                                                | `{}`                     |
| `configMap.labels`                  | Extra Labels for the ConfigMap resource                                                               | `{}`                     |

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
| `ingress.hosts`       | A list of hosts for the Ingress resource            | `[]`    |

### Service parameters

| Name                               | Description                                                                             | Value       |
| ---------------------------------- | --------------------------------------------------------------------------------------- | ----------- |
| `service.type`                     | The type of service to create                                                           | `ClusterIP` |
| `service.port`                     | The port to use on the service                                                          | `8273`      |
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

| Name                         | Description                                                                | Value   |
| ---------------------------- | -------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`      | Whether a service account should be created                                | `true`  |
| `serviceAccount.automount`   | Whether to automount the service account token                             | `false` |
| `serviceAccount.annotations` | Annotations to add to the service account                                  | `{}`    |
| `serviceAccount.name`        | A custom name for the service account, otherwise gobackup.fullname is used | `""`    |
| `serviceAccount.secrets`     | A list of secrets mountable by this service account                        | `[]`    |

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

| Name                | Description                                              | Value |
| ------------------- | -------------------------------------------------------- | ----- |
| `replicas`          | The amount of replicas GoBackup deployment should create | `1`   |
| `resources`         | The resource limits/requests for the GoBackup pod        | `{}`  |
| `volumes`           | Define volumes for the GoBackup pod                      | `[]`  |
| `volumeMounts`      | Define volumeMounts for the GoBackup pod                 | `[]`  |
| `initContainers`    | Define initContainers for the main GoBackup server       | `[]`  |
| `nodeSelector`      | Node labels for pod assignment                           | `{}`  |
| `tolerations`       | Tolerations for pod assignment                           | `[]`  |
| `affinity`          | Affinity for pod assignment                              | `{}`  |
| `strategy`          | Specify a deployment strategy for the GoBackup pod       | `{}`  |
| `podAnnotations`    | Extra annotations for the GoBackup pod                   | `{}`  |
| `podLabels`         | Extra labels for the GoBackup pod                        | `{}`  |
| `priorityClassName` | The name of an existing PriorityClass                    | `""`  |

### Security context settings

| Name                 | Description                                    | Value |
| -------------------- | ---------------------------------------------- | ----- |
| `podSecurityContext` | Security context settings for the GoBackup pod | `{}`  |
| `securityContext`    | General security context settings for          | `{}`  |
