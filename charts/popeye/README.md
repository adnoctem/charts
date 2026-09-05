# Ad Noctem Collective - Popeye Helm Chart <img src="https://github.com/derailed/popeye/blob/d09ec25f3834d2c6a171486b9726b0a91793e3f0/assets/popeye_logo.png?raw=true" alt="Popeye Logo" width="175" height="175" align="right" loading="lazy">

Popeye is a utility that scans live Kubernetes cluster and reports potential issues with deployed resources and
configurations. It sanitizes your cluster based on what's deployed and not what's sitting on disk. By scanning your
cluster, it detects misconfigurations and helps you to ensure that best practices are in place, thus preventing future
headaches. It aims at reducing the cognitive overload one faces when operating a Kubernetes cluster in the wild.
Furthermore, if your cluster employs a metric-server, it reports potential resources over/under allocations and attempts
to warn you should your cluster run out of capacity.

Popeye is a readonly tool, it does not alter any of your Kubernetes resources in any way!

It delivers all of these features within a single Docker image available
on [Docker Hub](https://hub.docker.com/r/derailed/popeye).

> Head to the [Popeye GitHub Repository](https://github.com/derailed/popeye) or
> their [Website](https://popeyecli.io/) for in-depth documentation
> and [configuration guides](https://popeyecli.io/#spinachyaml).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install ntfy adnoctem/popeye --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/popeye:X.Y.Z
```

## Introduction

This chart bootstraps a
Popeye [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package
manager. [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are enabled by default.

The chart supports the configuration of
all Popeye CLI arguments and [configuration files](https://popeyecli.io/#spinachyaml) via the `popeye` key in
Helm's _values_ and makes use of the official Docker Hub container image, although this is configurable via the Image
Parameters.

## Parameters

### Popeye Image parameters

| Name                | Description                                                         | Value             |
| ------------------- | ------------------------------------------------------------------- | ----------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `docker.io`       |
| `image.repository`  | The registry repository to pull the image from                      | `derailed/popeye` |
| `image.tag`         | The image tag to pull                                               | `v0.21.3`         |
| `image.digest`      | The image digest to pull                                            | `""`              |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`    |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`              |

### Name overrides

| Name               | Description                                  | Value |
| ------------------ | -------------------------------------------- | ----- |
| `nameOverride`     | String to partially override popeye.fullname | `""`  |
| `fullnameOverride` | String to fully override popeye.fullname     | `""`  |

### CronJob parameters

| Name                        | Description                                                | Value         |
| --------------------------- | ---------------------------------------------------------- | ------------- |
| `cronjob.labels`            | Labels to attach to the CronJob manifest                   | `{}`          |
| `cronjob.annotations`       | Annotations to attach to the CronJob manifest              | `{}`          |
| `cronjob.schedule`          | The schedule to for the CronJob. Once an hour per default. | `* */1 * * *` |
| `cronjob.concurrencyPolicy` | Concurrency is disabled for Popeye by default.             | `Forbid`      |
| `cronjob.restartPolicy`     | Popeye containers should exit and never be auto-recreated  | `Never`       |

### Popeye Configuration parameters

| Name                                      | Description                                                                                        | Value |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------- | ----- |
| `popeye.config`                           | The SpinachYAML configuration for popeye                                                           | `""`  |
| `popeye.args`                             | Define the CLI arguments and flags that the container's entrypoint will execute                    | `{}`  |
| `popeye.scans.destinations`               | Set Scan destinations for Popeye. Valid keys are `s3` and `push-gtwy`.                             | `[]`  |
| `popeye.scans.pushGateway.url`            | Set the URL for the Push Gateway service                                                           | `""`  |
| `popeye.scans.pushGateway.user`           | Set the HTTP Basic Auth username for the Push Gateway service                                      | `""`  |
| `popeye.scans.pushGateway.password`       | Set the HTTP Basic Auth password for the Push Gateway service                                      | `""`  |
| `popeye.scans.pushGateway.existingSecret` | Provide an existing `basic-auth` Secret to use as a credential source for the Push Gateway service | `""`  |
| `popeye.scans.s3.bucket`                  | Set the S3 bucket name                                                                             | `""`  |
| `popeye.scans.s3.region`                  | Set the S3 region to use                                                                           | `""`  |
| `popeye.scans.s3.endpoint`                | Set a custom S3 endpoint to use instead of the AWS one                                             | `""`  |
| `popeye.scans.s3.accessKey`               | Set the S3 Access Key                                                                              | `""`  |
| `popeye.scans.s3.secretKey`               | Set the S3 Secret Key                                                                              | `""`  |
| `popeye.scans.s3.existingSecret`          | Provide an existing Secret to with `accessKey` and `secretKey` keys to use as a credential source  | `""`  |
| `configMap.annotations`                   | Annotations for the ConfigMap resource                                                             | `{}`  |
| `configMap.labels`                        | Extra Labels for the ConfigMap resource                                                            | `{}`  |

### Common Secret parameters

| Name                 | Description                           | Value |
| -------------------- | ------------------------------------- | ----- |
| `secret.annotations` | Common annotations for the S3 secret  | `{}`  |
| `secret.labels`      | Common extra labels for the S3 secret | `{}`  |

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

### Pod settings

| Name                | Description                                      | Value |
| ------------------- | ------------------------------------------------ | ----- |
| `resources`         | The resource limits/requests for the Popeye pod  | `{}`  |
| `volumes`           | Define volumes for the Popeye pod                | `[]`  |
| `volumeMounts`      | Define volumeMounts for the Popeye pod           | `[]`  |
| `initContainers`    | Define initContainers for the main Popeye server | `[]`  |
| `nodeSelector`      | Node labels for pod assignment                   | `{}`  |
| `tolerations`       | Tolerations for pod assignment                   | `[]`  |
| `affinity`          | Affinity for pod assignment                      | `{}`  |
| `podAnnotations`    | Extra annotations for the Popeye pod             | `{}`  |
| `podLabels`         | Extra labels for the Popeye pod                  | `{}`  |
| `priorityClassName` | The name of an existing PriorityClass            | `""`  |

### Security context settings

| Name                 | Description                                  | Value |
| -------------------- | -------------------------------------------- | ----- |
| `podSecurityContext` | Security context settings for the Popeye pod | `{}`  |
| `securityContext`    | General security context settings for        | `{}`  |
