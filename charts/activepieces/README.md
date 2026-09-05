# Ad Noctem Collective - Activepieces Helm Chart <img src="https://raw.githubusercontent.com/adnoctem/artwork/425046029eaed451f5ced22ddc650059dff11878/projects/activepieces/icon/color/activepieces-icon-color.png" alt="Activepieces Logo" width="175" height="175" align="right" loading="lazy">

> [!IMPORTANT]
> This Helm chart relies on the open-source _Bitnami_ Helm chart `postgresql`. Beginning on August 28th, 2025, _Bitnami_
> (_VMware_/_Broadcom_) has changed their public offering and will require a commercial license for the use of their charts and images
> (_Bitnami Secure Images_/_BSI_). The only images available to the public as of now are a small set of hardened images which are only
> available at the 'latest' tag and meant for testing and development purposes. As such, the PostgreSQL subchart included in this Helm
> chart is provided for convenience, but users are encouraged to use their own PostgreSQL instance, another PostgreSQL Helm chart or
> (preferably) an Operator-managed PostgreSQL instance like CloudnativePG, if they do not wish to obtain a Bitnami license.
>
> _ref: [`bitnami/charts` - Issue 35164](https://github.com/bitnami/charts/issues/35164)_

Activepieces is an open source all-in-one easy to use automation tool with 100+ integrations. It is designed to be
easily extensible for developers through a `type-safe` pieces framework written
in [`TypeScript`](https://www.typescriptlang.org/). The applications also
comes with an inituitive drag-and-drop Flow Builder which also supports branches and loops. Activepieces integrates
Google Sheets, OpenAI, Discord, and RSS, along with 80+ other integrations. The list
of [supported integrations](https://www.activepieces.com/pieces) continues
to grow rapidly, thanks to valuable contributions from the community. As an open-source project, Activepieces is
freely available for self-hosting.

It delivers all of these features within a single Docker image available
on [Docker Hub](https://hub.docker.com/r/activepieces/activepieces).

> Head to the [Activepieces GitHub Repository](https://github.com/activepieces/activepieces) or
> their [Website](https://www.activepieces.com/) for
> in-depth [documentation](https://www.activepieces.com/docs/getting-started/introduction)
> and [configuration guides](https://www.activepieces.com/docs/install/configurations/environment-variables).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install activepieces adnoctem/activepieces --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/activepieces:X.Y.Z
```

## Introduction

This chart bootstraps an
Activepieces [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
or [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster
networking a [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) manifest is also created, whereas the
Ingress needs to be explicitly enabled. Lastly the chart configures
a [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) if
enabled. [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are enabled by default.

The chart supports the configuration of
all [Activepieces environment variables](https://www.activepieces.com/docs/install/configurations/environment-variables)
via the `activepieces` key in Helm's _values_ and makes use of the official Docker Hub container image, although this is
configurable via the Image Parameters.

> [!NOTE]
> Activepieces is dual-licensed: the core (what this chart deploys) is MIT, but the `packages/ee/` subset of the
> source is available only under
> [Activepieces' own Enterprise license](https://github.com/activepieces/activepieces/blob/main/packages/ee/LICENSE),
> which requires a paid subscription for production use. The Docker image bundles both; using this chart alone
> doesn't grant rights to any Enterprise-only feature the image may expose.

## Upgrading

### To 0.4.0 (Activepieces 0.28.0 -> 0.90.2)

This is a very large range - the chart's previous `appVersion` predates most of Activepieces' own
[breaking-changes log](https://www.activepieces.com/docs/install/reference/breaking-changes). Review it for anything
affecting your flows, pieces, or API usage; the items below cover what changed for this chart's configuration
specifically, found by checking every environment variable this chart renders against the current
[environment variables reference](https://www.activepieces.com/docs/install/reference/environment-variables) rather
than assuming names stayed stable across 60+ releases.

**Every existing install of this chart has been silently sending removed or renamed settings** - none of these
caused a hard failure (the app appears to ignore what it doesn't recognize), but none of them were doing anything
useful either:

- `AP_QUEUE_MODE` is renamed to `AP_REDIS_TYPE` (upstream 0.70.0). `activepieces.queue.mode` keeps its values
  (`memory`/`redis`) and chart-side field name, but now renders under the new variable name and maps `redis` to
  `STANDALONE` as the new scheme expects. This was rendered **unconditionally by every install**, since `memory`
  (the default) is not an empty value.
- `AP_FLOW_WORKER_CONCURRENCY` is renamed to `AP_WORKER_CONCURRENCY` (upstream 0.69.0). `activepieces.workerConcurrency`
  now renders under the new name. Also rendered **unconditionally by every install** (default `10`).
- `AP_SANDBOX_RUN_TIME_SECONDS` is renamed to `AP_FLOW_TIMEOUT_SECONDS` (upstream 0.30.0, and now also bounds a
  single action run, not just a flow run). `activepieces.sandbox.runTimeSeconds` is renamed to
  `activepieces.sandbox.flowTimeoutSeconds` to match.
- `AP_PIECES_SOURCE` no longer exists - pieces became self-contained bundles in 0.86.0 with no configurable source.
  `activepieces.pieces.source` is no longer rendered; its default changed from `CLOUD_AND_DB` to empty, since the
  old default was **also being rendered on every install** to a setting that no longer does anything.
- `AP_TEMPLATES_SOURCE_URL` no longer exists - the templates API moved from `/flow-templates` to `/templates` in
  0.77.0 and isn't configurable via URL any more. `activepieces.templateSourceURL` is no longer rendered; its
  previous non-empty default (a URL pointing at the now-removed `/flow-templates` endpoint) meant this was
  **rendered on every install** to a value that could never have worked correctly regardless of chart version.
- `AP_COPILOT_INSTANCE_TYPE`, `AP_AZURE_OPENAI_ENDPOINT`, and `AP_AZURE_OPENAI_API_VERSION` no longer exist - Code
  Copilot itself was deprecated upstream in 0.71.0. `activepieces.copilot.instanceType` and
  `activepieces.copilot.openAI.endpoint`/`.apiVersion` are no longer rendered. **`activepieces.copilot.openAI.apiKey`
  is unaffected and still works** - upstream repurposed the same `AP_OPENAI_API_KEY` variable to fund Tool Search's
  embeddings (MCP `ap_search_actions`/`ap_search_triggers`) instead of Copilot.
- Fixed a bug (unrelated to any upstream rename) where the queue UI's enablement check compared
  `activepieces.queue.mode` against the literal string `"REDIS"` while every other reference in the chart - and the
  value's own documented options - use lowercase `redis`. The queue UI could never actually turn on, regardless of
  configuration.

**Other upstream changes worth knowing about:**

- Nginx was removed from the Docker image in 0.80.0; Fastify now serves the API and frontend directly, and the
  health-check path moved from `/v1/health` to `/api/v1/health`. This chart's own liveness/readiness/startup probes
  target `/` (the frontend root), which is unaffected by this change - no chart action was needed.
- The container no longer bundles PM2 (0.90.x); a crashed process now exits the container instead of being silently
  restarted in place. No action needed for Kubernetes/Helm deployments - Kubernetes already restarts a crashed
  container's Pod.
- "Sign in with Google" is now configured via `AP_GOOGLE_CLIENT_ID`/`AP_GOOGLE_CLIENT_SECRET` only (0.84.0/0.86.0),
  no longer from the admin panel - set these via `extraEnvVars` if you use Google SSO.
- SMTP is configured via `AP_SMTP_*` environment variables only (0.73.0) - this chart has never had a dedicated SMTP
  section, so set these via `extraEnvVars` if you send outgoing email.
- Outbound HTTP from the server (OAuth, webhooks, MCP validation) is SSRF-filtered as of 0.82.0, blocking private,
  loopback, and cloud-metadata IPs. If you point any of those at an internal service, add its IP/CIDR to
  `AP_SSRF_ALLOW_LIST` via `extraEnvVars`.
- New optional settings worth knowing about, all settable via `extraEnvVars`: `AP_PREWARM_CACHE_ON_STARTUP`
  (0.88.0, replaces the removed `AP_PRE_WARM_CACHE`, defaults to `false`), `AP_ALLOWED_EMBED_ORIGINS` (0.84.0,
  required if you embed this instance elsewhere), and `AP_DEFAULT_CONCURRENT_JOBS_LIMIT` (0.82.0).

## Parameters

### Activepieces Image parameters

| Name                | Description                                                         | Value                       |
| ------------------- | ------------------------------------------------------------------- | --------------------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `docker.io`                 |
| `image.repository`  | The registry repository to pull the image from                      | `activepieces/activepieces` |
| `image.tag`         | The image tag to pull                                               | `0.90.2`                    |
| `image.digest`      | The image digest to pull                                            | `""`                        |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`              |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`                        |

### Name overrides

| Name               | Description                                        | Value |
| ------------------ | -------------------------------------------------- | ----- |
| `nameOverride`     | String to partially override activepieces.fullname | `""`  |
| `fullnameOverride` | String to fully override activepieces.fullname     | `""`  |

### Workload overrides

| Name   | Description                                                                    | Value         |
| ------ | ------------------------------------------------------------------------------ | ------------- |
| `kind` | The kind of workload to deploy Activepieces as (`StatefulSet` or `Deployment`) | `StatefulSet` |

### Activepieces Configuration parameters

| Name                                         | Description                                                                                                              | Value                       |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | --------------------------- |
| `activepieces.domain`                        | The public facing domain name for the Activepieces service, reused in Ingress.                                           | `localhost`                 |
| `activepieces.configPath`                    | Specify the path to store SQLite3 and local settings, prefixed with activepieces.data.rootPath                           | `""`                        |
| `activepieces.database`                      | Specify the path to store SQLite3 and local settings. Values are `sqlite3` or `postgres`.                                | `sqlite3`                   |
| `activepieces.data.rootPath`                 | The root path for ntfy to store its' files                                                                               | `/var/lib/ntfy`             |
| `activepieces.data.pvc.size`                 | The size given to the new PVC                                                                                            | `5Gi`                       |
| `activepieces.data.pvc.storageClass`         | The storageClass given to the new PVC                                                                                    | `standard`                  |
| `activepieces.data.pvc.reclaimPolicy`        | The resourcePolicy given to the new PVC                                                                                  | `Retain`                    |
| `activepieces.data.pvc.existingClaim`        | Provide the name to an existing PVC                                                                                      | `""`                        |
| `activepieces.postgresql.database`           | The name of the PostgreSQL database                                                                                      | `activepieces`              |
| `activepieces.postgresql.host`               | The hostname or IP address of the PostgreSQL server                                                                      | `activepieces-postgresql`   |
| `activepieces.postgresql.port`               | The port number for the PostgreSQL server                                                                                | `5432`                      |
| `activepieces.postgresql.username`           | The username for the PostgreSQL user                                                                                     | `activepieces`              |
| `activepieces.postgresql.password`           | The password for the PostgreSQL server                                                                                   | `activepieces`              |
| `activepieces.postgresql.existingSecret`     | The name of an existing `basic-auth` Secret to use the credentials from                                                  | `""`                        |
| `activepieces.postgresql.useSSL`             | Use SSL to connect to the PostgreSQL database                                                                            | `false`                     |
| `activepieces.postgresql.sslCA`              | Use SSL Certificate to connect to the postgres database                                                                  | `""`                        |
| `activepieces.redis.database`                | The name of the Redis database                                                                                           | `0`                         |
| `activepieces.redis.host`                    | The hostname or IP address of the Redis server                                                                           | `activepieces-redis-master` |
| `activepieces.redis.port`                    | The port number for the Redis server                                                                                     | `6379`                      |
| `activepieces.redis.username`                | The username for the Redis user                                                                                          | `""`                        |
| `activepieces.redis.password`                | The password for the Redis server                                                                                        | `activepieces`              |
| `activepieces.redis.existingSecret`          | The name of an existing `basic-auth` Secret to use the credentials from                                                  | `""`                        |
| `activepieces.redis.useSSL`                  | Use SSL to connect to the Redis database                                                                                 | `false`                     |
| `activepieces.queue.mode`                    | The queue mode to use. Valid values are `memory` and `redis` - rendered as the                                           | `memory`                    |
| `activepieces.queue.enableUI`                | Enable the queue UI (only works with redis)                                                                              | `false`                     |
| `activepieces.queue.username`                | The username for the queue UI                                                                                            | `""`                        |
| `activepieces.queue.password`                | The password for the queue UI                                                                                            | `""`                        |
| `activepieces.queue.existingSecret`          | The name of an existing `basic-auth` Secret to use the credentials from                                                  | `""`                        |
| `activepieces.pieces.source`                 | Deprecated and no longer rendered - pieces are self-contained bundles as of                                              | `""`                        |
| `activepieces.pieces.syncMode`               | Define the syncing method for Activepieces to download and use pieces.                                                   | `OFFICIAL_AUTO`             |
| `activepieces.copilot.instanceType`          | Deprecated and no longer rendered - see the note above                                                                   | `""`                        |
| `activepieces.copilot.openAI.apiKey`         | Rendered as `AP_OPENAI_API_KEY`, which now funds Tool Search's embeddings rather than Copilot - see the note above       | `""`                        |
| `activepieces.copilot.openAI.endpoint`       | Deprecated and no longer rendered - see the note above                                                                   | `""`                        |
| `activepieces.copilot.openAI.apiVersion`     | Deprecated and no longer rendered - see the note above                                                                   | `""`                        |
| `activepieces.copilot.openAI.existingSecret` | The name of an existing Secret containing an `apiKey` key, for `AP_OPENAI_API_KEY` - see the note above                  | `""`                        |
| `activepieces.encryption.connection`         | The encryption key used for connections                                                                                  | `""`                        |
| `activepieces.encryption.jwt`                | Encryption key used for generating JWT tokens                                                                            | `""`                        |
| `activepieces.encryption.existingSecret`     | The name of an existing Secret containing a `connection` and `jwt` key, from which the encryption keys will be sourced   | `""`                        |
| `activepieces.sandbox.executionMode`         | Define the execution mode. Valid values are `UNSANDBOXED`, `SANDBOX_PROCESS`,                                            | `UNSANDBOXED`               |
| `activepieces.sandbox.flowTimeoutSeconds`    | Maximum allowed runtime for a flow, in seconds - rendered as                                                             | `false`                     |
| `activepieces.sandbox.propagatedEnvVars`     | Environment variables that will be propagated to the sandboxed code.                                                     | `""`                        |
| `activepieces.dataRetentionDays`             | The number of days to retain execution data, logs and events                                                             | `""`                        |
| `activepieces.workerConcurrency`             | The number of flows to be processed at the same time - rendered as                                                       | `10`                        |
| `activepieces.triggerPollInterval`           | The polling interval determines how frequently the system checks for new data updates for pieces with scheduled triggers | `5`                         |
| `activepieces.enableCloudAuth`               | Enable the utilization of oAuth2 applications                                                                            | `true`                      |
| `activepieces.telemetry`                     | Enable the collection of telemetry information                                                                           | `false`                     |
| `activepieces.templateSourceURL`             | Deprecated and no longer rendered - the templates API moved from                                                         | `""`                        |
| `activepieces.webhookTimeoutSeconds`         | The default timeout for webhooks                                                                                         | `30`                        |

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

| Name                  | Description                                                                | Value   |
| --------------------- | -------------------------------------------------------------------------- | ------- |
| `ingress.enabled`     | Whether to enable Ingress                                                  | `false` |
| `ingress.className`   | The IngressClass to use for the pod's ingress                              | `""`    |
| `ingress.whitelist`   | A comma-separated list of IP addresses to whitelist                        | `""`    |
| `ingress.annotations` | Annotations for the Ingress resource                                       | `{}`    |
| `ingress.tls`         | A list of hostnames and secret names to use for TLS                        | `[]`    |
| `ingress.extraHosts`  | A list of extra hosts for the Ingress resource (with activepieces.baseURL) | `[]`    |

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

| Name                         | Description                                                                    | Value   |
| ---------------------------- | ------------------------------------------------------------------------------ | ------- |
| `serviceAccount.create`      | Whether a service account should be created                                    | `true`  |
| `serviceAccount.automount`   | Whether to automount the service account token                                 | `false` |
| `serviceAccount.annotations` | Annotations to add to the service account                                      | `{}`    |
| `serviceAccount.name`        | A custom name for the service account, otherwise activepieces.fullname is used | `""`    |
| `serviceAccount.secrets`     | A list of secrets mountable by this service account                            | `[]`    |

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

| Name                | Description                                                                                   | Value |
| ------------------- | --------------------------------------------------------------------------------------------- | ----- |
| `resources`         | The resource limits/requests for the Activepieces pod                                         | `{}`  |
| `extraEnvVars`      | Extra environment variables for the Activepieces pod - use this for any of Activepieces' many | `[]`  |
| `volumes`           | Define volumes for the Activepieces pod                                                       | `[]`  |
| `volumeMounts`      | Define volumeMounts for the Activepieces pod                                                  | `[]`  |
| `initContainers`    | Define initContainers for the main Activepieces server                                        | `[]`  |
| `nodeSelector`      | Node labels for pod assignment                                                                | `{}`  |
| `tolerations`       | Tolerations for pod assignment                                                                | `[]`  |
| `affinity`          | Affinity for pod assignment                                                                   | `{}`  |
| `strategy`          | Specify a deployment strategy for the Activepieces pod                                        | `{}`  |
| `podAnnotations`    | Extra annotations for the Activepieces pod                                                    | `{}`  |
| `podLabels`         | Extra labels for the Activepieces pod                                                         | `{}`  |
| `priorityClassName` | The name of an existing PriorityClass                                                         | `""`  |

### Security context settings

| Name                 | Description                                        | Value |
| -------------------- | -------------------------------------------------- | ----- |
| `podSecurityContext` | Security context settings for the Activepieces pod | `{}`  |
| `securityContext`    | General security context settings for              | `{}`  |

### Bitnami&reg; PostgreSQL parameters

### PostgreSQL Global parameters

| Name                                             | Description                                                                                                                    | Value                        |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ | ---------------------------- |
| `postgresql.global.imageRegistry`                | Global Docker image registry. Force 'docker.io' - required due to BSI.                                                         | `docker.io`                  |
| `postgresql.global.security.allowInsecureImages` | Allows skipping image verification. 'bitnamisecure' images meet the charts' security requirements. Others will require 'true'. | `false`                      |
| `postgresql.image.registry`                      | PostgreSQL image registry                                                                                                      | `REGISTRY_NAME`              |
| `postgresql.image.repository`                    | PostgreSQL image repository. 'bitnamisecure' is recommended.                                                                   | `REPOSITORY_NAME/postgresql` |
| `postgresql.image.tag`                           | PostgreSQL image tag. As of August 28th, 2025, only 'latest' is available publicly due to BSI.                                 | `latest`                     |
| `postgresql.enabled`                             | Enable or disable the PostgreSQL subchart                                                                                      | `false`                      |
| `postgresql.auth.enablePostgresUser`             | Assign a password to the "postgres" admin user. Otherwise, remote access will be blocked for this user                         | `true`                       |
| `postgresql.auth.postgresPassword`               | Password for the "postgres" admin user. Ignored if `auth.existingSecret` is provided                                           | `activepieces`               |
| `postgresql.auth.username`                       | Name for a custom user to create                                                                                               | `activepieces`               |
| `postgresql.auth.password`                       | Password for the custom user to create. Ignored if `auth.existingSecret` is provided                                           | `activepieces`               |
| `postgresql.auth.database`                       | Name for a custom database to create                                                                                           | `activepieces`               |
| `postgresql.auth.usePasswordFiles`               | Mount credentials as a files instead of using an environment variable                                                          | `false`                      |
| `postgresql.primary.name`                        | Name of the primary database (eg primary, master, leader, ...)                                                                 | `primary`                    |
| `postgresql.primary.persistence.enabled`         | Enable PostgreSQL Primary data persistence using PVC                                                                           | `true`                       |
| `postgresql.primary.persistence.existingClaim`   | Name of an existing PVC to use                                                                                                 | `""`                         |
| `postgresql.primary.persistence.storageClass`    | PVC Storage Class for PostgreSQL Primary data volume                                                                           | `""`                         |
| `postgresql.primary.persistence.accessModes`     | PVC Access Mode for PostgreSQL volume                                                                                          | `["ReadWriteOnce"]`          |
| `postgresql.primary.persistence.size`            | PVC Storage Request for PostgreSQL volume                                                                                      | `5Gi`                        |

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
| `redis.auth.password`                       | Redis&reg; password                                                                                                            | `activepieces`          |
| `redis.auth.usePasswordFiles`               | Mount credentials as files instead of using an environment variable                                                            | `true`                  |
