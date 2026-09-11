# Ad Noctem Collective - lhci Helm Chart <img src="https://raw.githubusercontent.com/GoogleChrome/lighthouse/main/assets/lighthouse-logo_512px.png" alt="Lighthouse CI Logo" width="175" height="175" align="right" loading="lazy">

Lighthouse CI Server stores historical Lighthouse reports and provides dashboards and build comparisons.
This chart uses [Ad Noctem's LHCI container](https://github.com/adnoctem/lhci), version **1.0.1**, containing
**upstream LHCI 0.15.1**. `appVersion` tracks the container release.

> The optional **Bitnami PostgreSQL and MySQL subcharts** are provided for convenience. Their Helm packages
> remain available under `oci://registry-1.docker.io/bitnamicharts`, but the original `bitnami/*` container tags
> may no longer be available following the catalog changes. This chart does not integrate Bitnami Secure Images.
> Use your own compatible image mirror, an external database, or preferably an operator-managed database such as
> **CloudNativePG** for production. Helm chart repositories and container image repositories are separate settings.
> See [Bitnami's catalog announcement](https://github.com/bitnami/charts/issues/35164).
>
> Head to the [container repository](https://github.com/adnoctem/lhci) and
> [upstream configuration reference](https://github.com/GoogleChrome/lighthouse-ci/blob/v0.15.1/docs/configuration.md#server)
> for further documentation.

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install lhci adnoctem/lhci --version 0.1.0
```

### OCI Installation

```shell
helm install lhci oci://ghcr.io/adnoctem/charts/lhci --version 0.1.0
```

## Introduction

The default installation creates a single-replica Deployment, Service, ServiceAccount and a 5 GiB PVC for SQLite.
A default StorageClass must be available, or configure `persistence.storageClass` / `persistence.existingClaim`.
Ingress and PodDisruptionBudget are optional. No Kubernetes API permissions are needed, and service account tokens
are not mounted. The image runs as UID/GID 10001 with a read-only root filesystem and writable data and temporary volumes.

All supported LHCI server configuration has dedicated values. SQLite, PostgreSQL and MySQL use `storageMethod: sql`;
Spanner is not implemented upstream. The chart preserves the container's environment bootstrap and database wait logic.
Scalar options use environment variables; structured Sequelize and cron options use a native `lighthouserc.yaml` in the ConfigMap.
The chart supplies configuration only: it does not override the container entrypoint or ship runtime scripts.
The image's `*_FILE` inputs handle external database URIs and basic-auth credentials. Subchart passwords, PSI API keys
and database TLS material use native LHCI environment variables populated from Kubernetes Secret references.

## Workloads and persistence

`kind: Deployment` is the default. Its default `Recreate` strategy stops the previous pod before starting the next,
so SQLite has only one application writer during a normal rollout. `kind: StatefulSet` is also supported through a
shared pod specification and a governing headless Service. Neither workload kind makes SQLite safe for multiple replicas;
`replicaCount` must remain `1` with SQLite. External SQL can use either workload type.

Both workloads mount the same standalone SQLite PVC. Reports survive pod deletion, rescheduling when the storage supports it,
and upgrades. `persistence.keep: true` retains chart-created SQLite claims on uninstall. Back up the database before upgrades;
retention does not replace backups. After uninstall, reuse the retained claim with `persistence.existingClaim` when reinstalling.
Existing claims are never managed by this chart. Disabling persistence uses `emptyDir` and loses reports on pod replacement.

SQLite files must remain inside `persistence.mountPath` (default `/data`). External SQL uses an `emptyDir` for the container's
home directory and creates no LHCI data claim; database subcharts manage their own PVCs. Changing the workload kind or backend
requires a planned migration and does not move report data automatically. Do not run both workload kinds against the same
SQLite file during migration. Database PVC retention follows the selected database subchart's behavior.

The server initializes/migrates its schema at startup. Keep `sqlDangerouslyResetDatabase: false`: enabling it deletes all LHCI
data on every startup. For external SQL, start with one replica for initial schema creation and upgrades. Increase replicas only
after migration completes, and do not enable built-in cron jobs on multiple replicas; they have no distributed scheduling lock.

## Database configuration

### External PostgreSQL and CloudNativePG

Keep both subcharts disabled. An existing Secret with a full connection URI is the preferred integration; the Secret must be
in the release namespace. For a CNPG application Secret containing `uri`:

```yaml
lhci:
  storage:
    sqlDialect: postgres
    existingSecret:
      name: lhci-db-app
      key: uri
```

CNPG's operator remains responsible for creating the database, credentials, backups, replication and upgrades.
A MySQL operator or an independently managed MySQL server uses the same interface with `sqlDialect: mysql`.
The URI must include the protocol, credentials, host, port if nonstandard, and database name. Percent-encode reserved characters
in credentials before placing a URI in a Secret. `sqlConnectionUrl` can create a chart-managed Secret for development, but its
value is then also stored in Helm release history.

### Database TLS

Supply a CA and optional client certificate/private key from a Secret. Kubernetes injects their contents through native
LHCI environment variables into Sequelize's SSL configuration. `certKey` and `keyKey` must be configured together. Set `caKey: ""` to use the runtime's trust store.

```yaml
lhci:
  storage:
    sqlDialect: postgres
    existingSecret:
      name: lhci-db-app
      key: uri
    tls:
      existingSecret: lhci-db-client-tls
      caKey: ca.crt
      certKey: tls.crt
      keyKey: tls.key
      rejectUnauthorized: true
```

Avoid conflicting SSL settings in the URI, `sqlDialectOptions.ssl` and `storage.tls`; `storage.tls` replaces the dialect's SSL
object when enabled. Keep hostname/certificate verification enabled for production. `sqlConnectionSsl` exposes upstream's
boolean switch; use the explicit TLS configuration when providing custom certificates.

### Optional Bitnami subcharts

Enable **one** subchart to select its LHCI dialect automatically. Do not also provide an external database URI/Secret.
Both subcharts default to `standalone` topology. Configure images that are compatible with the dependency's entrypoint,
paths, probes and UID requirements: Docker Official Images are not drop-in replacements for Bitnami containers.

```yaml
postgresql:
  enabled: true
  auth:
    username: lhci
    database: lhci
    existingSecret: lhci-postgresql-credentials
```

For PostgreSQL, the Secret requires `password` and `postgres-password` by default; key names are configurable via
`postgresql.auth.secretKeys`. MySQL uses `mysql-password` and `mysql-root-password`:

```yaml
mysql:
  enabled: true
  auth:
    username: lhci
    database: lhci
    existingSecret: lhci-mysql-credentials
```

Without `auth.existingSecret`, the subchart uses supplied passwords or generates them. LHCI receives the actual application
password from that Secret through `LHCI_STORAGE__SEQUELIZE_OPTIONS__PASSWORD`. The generated connection URI contains only
the host, port and database; the username and password are separate native Sequelize options. Passwords containing
`:`, `@`, `/`, `?`, `#` and `%` therefore need no URI escaping. Database service names, ports and `fullnameOverride` are resolved from the selected dependency.
Use the dedicated `postgresql.auth.*` / `mysql.auth.*` values rather than global authentication overrides.

In container `1.0.1`, upstream yargs coerces numeric-looking nested environment values to numbers. Use nonnumeric
application usernames/passwords with subcharts (including existing Secrets). A full external URI avoids this password
coercion. This limitation applies to container `1.0.1`.

The dependencies follow this repository's Bitnami OCI conventions (`postgresql ~15.5`, `mysql ~11.1`). Their original image tags
are retained as defaults, but availability must be checked before enabling them. Override `image.registry`, `image.repository`,
`image.tag` and optionally `image.digest` under the dependency for a compatible mirror.

## Authentication and ingress

Basic auth is off by default, matching upstream. Enable it for access through an untrusted network:

```yaml
lhci:
  basicAuth:
    enabled: true
    existingSecret:
      name: lhci-basic-auth
      usernameKey: username
      passwordKey: password
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
  hosts:
    - host: lhci.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: lhci-tls
      hosts:
        - lhci.example.com
```

Serve LHCI at a hostname root; upstream has no base-path setting. Configure your ingress controller's upload limit to allow
Lighthouse report JSON (the server permits 10 MB). The example annotation is specific to ingress-nginx.
Basic auth protects the UI and API; `/healthz` deliberately remains unauthenticated. Probes verify the HTTP server and startup
initialization, not continued database availability. The default startup allowance is ten minutes; increase it if database
wait retries/timeouts are raised substantially.

## Scheduled collection and retention

Configure `lhci.psiCollectCron.sites` after creating the referenced projects. Each entry requires `projectSlug`, `schedule`
and `urls`; optional fields are `label`, `branch`, `numberOfRuns`, `maxNumberOfParallelUrls`, `strategy` (`mobile`/`desktop`)
and `categories`. `lhci.psiCollectCron.psiApiEndpoint` exposes a custom upstream endpoint and `cachebustTimeoutMs` controls
the delay between repeated runs. Keep `replicaCount: 1` when either built-in scheduler is enabled.

```yaml
lhci:
  psiCollectCron:
    existingSecret:
      name: lhci-psi
      key: apiKey
    sites:
      - projectSlug: example
        label: Production
        urls:
          - https://example.com
        schedule: "0 * * * *"
        numberOfRuns: 3
        maxNumberOfParallelUrls: 1
        strategy: mobile
        categories:
          - performance
  deleteOldBuildsCron:
    - schedule: "0 0 * * *"
      maxAgeInDays: 30
      skipBranches:
        - main
```

Retention entries accept `skipBranches` and `onlyBranches` arrays. Omit `onlyBranches` to consider all branches; an empty
`onlyBranches: []` matches none. Retention permanently removes matching old builds.

`lhci.storage.sqlDialectOptions` and `sequelizeOptions` are native option objects for TLS, driver options and connection pools.
Keep credentials out of these ConfigMap-backed objects. Socket-only database connections cannot satisfy the image's TCP wait
logic; use a reachable TCP URI. Embedding LHCI in another Express server is outside this container chart's scope; normally
leave `useBodyParser: true`. Global CLI help/version/config-discovery flags are not server settings: the chart owns `LHCI_CONFIG`.
`extraEnvVars`, `extraEnvVarsSecret` and `extraEnvVarsConfigMap` are escape hatches for Node.js runtime settings such as `NODE_OPTIONS`
and `DEBUG`, not substitutes for the dedicated server values. Avoid overriding chart-managed environment names.

Chart-managed configuration/Secret changes trigger a rollout. Existing Secret changes require a manual rollout, including
operator-managed credential rotation; neither LHCI nor its entrypoint rereads credentials in a running process.

## First project and CI uploads

Forward the service and use the upstream wizard to create a project. The wizard returns a build token for uploads and an
admin token for administration; store these outside the chart rather than creating projects on each Helm install.

```shell
kubectl port-forward svc/lhci 9001:9001
# In another terminal, using your installed LHCI CLI:
lhci wizard
```

Configure your pipeline's LHCI client with the server URL and build token, plus basic-auth credentials if enabled:

```yaml
ci:
  upload:
    target: lhci
    serverBaseUrl: https://lhci.example.com
```

Pass `LHCI_TOKEN`, `LHCI_BASIC_AUTH__USERNAME` and `LHCI_BASIC_AUTH__PASSWORD` as CI secrets. These client upload settings are
separate from this chart's server settings. The image provides `lhctl health` for local diagnostics; `lhctl env` displays
resolved configuration and may expose credentials, so do not copy its output into public logs.

## Parameters

### Image parameters

| Name                | Description                            | Value           |
| ------------------- | -------------------------------------- | --------------- |
| `image.registry`    | Container image registry               | `ghcr.io`       |
| `image.repository`  | LHCI image repository                  | `adnoctem/lhci` |
| `image.tag`         | Image tag; empty uses Chart.appVersion | `""`            |
| `image.digest`      | Image digest override                  | `""`            |
| `image.pullPolicy`  | Kubernetes image pull policy           | `IfNotPresent`  |
| `image.pullSecrets` | Existing image pull secret names       | `[]`            |

### Name and workload overrides

| Name               | Description                              | Value        |
| ------------------ | ---------------------------------------- | ------------ |
| `nameOverride`     | Partially override lhci.fullname         | `""`         |
| `fullnameOverride` | Fully override lhci.fullname             | `""`         |
| `kind`             | Workload kind; Deployment or StatefulSet | `Deployment` |

### Lighthouse CI configuration

| Name                                         | Description                                                                                                                                                 | Value           |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `lhci.port`                                  | HTTP listen port, also used by container ports and probes                                                                                                   | `9001`          |
| `lhci.host`                                  | HTTP listen address inside the pod                                                                                                                          | `0.0.0.0`       |
| `lhci.logLevel`                              | Request logging; verbose or silent                                                                                                                          | `verbose`       |
| `lhci.useBodyParser`                         | Enable upstream JSON request parsing; normally required by the API                                                                                          | `true`          |
| `lhci.storage.storageMethod`                 | Storage implementation; only sql is supported                                                                                                               | `sql`           |
| `lhci.storage.sqlDialect`                    | SQLite or external database dialect; sqlite, postgres or mysql. An enabled subchart selects its dialect automatically                                       | `sqlite`        |
| `lhci.storage.sqlDatabasePath`               | SQLite file path; must be under persistence.mountPath                                                                                                       | `/data/lhci.db` |
| `lhci.storage.sqlConnectionUrl`              | External PostgreSQL/MySQL URI; prefer existingSecret for production                                                                                         | `""`            |
| `lhci.storage.existingSecret.name`           | Existing Secret containing the external database URI, e.g. a CNPG application Secret                                                                        | `""`            |
| `lhci.storage.existingSecret.key`            | Secret key containing the connection URI                                                                                                                    | `uri`           |
| `lhci.storage.sqlConnectionSsl`              | Force SSL for the SQL connection                                                                                                                            | `false`         |
| `lhci.storage.sqlDangerouslyResetDatabase`   | Delete all LHCI data and recreate the schema on startup; leave false for normal operation                                                                   | `false`         |
| `lhci.storage.sqlMigrationOptions.tableName` | Sequelize migration metadata table                                                                                                                          | `SequelizeMeta` |
| `lhci.storage.sqlDialectOptions`             | Native Sequelize dialect options; credentials belong in Secrets                                                                                             | `{}`            |
| `lhci.storage.sequelizeOptions`              | Native Sequelize options such as pool settings; credentials belong in Secrets                                                                               | `{}`            |
| `lhci.storage.tls.existingSecret`            | Secret supplying database CA and optional client certificate and key through native LHCI environment variables                                              | `""`            |
| `lhci.storage.tls.caKey`                     | CA certificate key; empty omits the CA                                                                                                                      | `ca.crt`        |
| `lhci.storage.tls.certKey`                   | Client certificate key; empty disables client certificate authentication                                                                                    | `""`            |
| `lhci.storage.tls.keyKey`                    | Client private key key; required with certKey                                                                                                               | `""`            |
| `lhci.storage.tls.rejectUnauthorized`        | Verify the database certificate                                                                                                                             | `true`          |
| `lhci.basicAuth.enabled`                     | Protect the UI and API with HTTP basic authentication                                                                                                       | `false`         |
| `lhci.basicAuth.username`                    | Basic authentication username; ignored with existingSecret                                                                                                  | `""`            |
| `lhci.basicAuth.password`                    | Basic authentication password; ignored with existingSecret                                                                                                  | `""`            |
| `lhci.basicAuth.existingSecret.name`         | Existing Secret containing HTTP basic authentication credentials                                                                                            | `""`            |
| `lhci.basicAuth.existingSecret.usernameKey`  | Username key in the existing Secret                                                                                                                         | `username`      |
| `lhci.basicAuth.existingSecret.passwordKey`  | Password key in the existing Secret                                                                                                                         | `password`      |
| `lhci.dbWait.retries`                        | Container database TCP connection attempts before exiting                                                                                                   | `60`            |
| `lhci.dbWait.timeout`                        | Timeout in seconds for each database connection attempt                                                                                                     | `5`             |
| `lhci.psiCollectCron.psiApiKey`              | PageSpeed Insights API key; prefer existingSecret                                                                                                           | `""`            |
| `lhci.psiCollectCron.existingSecret.name`    | Existing Secret containing the PSI API key                                                                                                                  | `""`            |
| `lhci.psiCollectCron.existingSecret.key`     | PSI API key Secret key                                                                                                                                      | `apiKey`        |
| `lhci.psiCollectCron.psiApiEndpoint`         | Optional custom PSI API endpoint; empty uses upstream default                                                                                               | `""`            |
| `lhci.psiCollectCron.sites`                  | Scheduled collections; each requires projectSlug, urls and schedule. Optional label, branch, numberOfRuns, maxNumberOfParallelUrls, strategy and categories | `[]`            |
| `lhci.psiCollectCron.cachebustTimeoutMs`     | Delay between repeated PSI collections of the same URL in milliseconds (PSI_CACHEBUST_TIMEOUT_MS)                                                           | `60000`         |
| `lhci.deleteOldBuildsCron`                   | Retention schedules; each requires schedule and maxAgeInDays, with optional skipBranches and onlyBranches arrays                                            | `[]`            |

### Persistence parameters

| Name                        | Description                                                              | Value               |
| --------------------------- | ------------------------------------------------------------------------ | ------------------- |
| `persistence.enabled`       | Persist SQLite using a PVC; false loses reports when the pod is replaced | `true`              |
| `persistence.existingClaim` | Existing SQLite PVC name                                                 | `""`                |
| `persistence.mountPath`     | Writable data directory; the image uses /data as HOME                    | `/data`             |
| `persistence.size`          | SQLite PVC capacity                                                      | `5Gi`               |
| `persistence.storageClass`  | Storage class; empty uses the default, '-' disables dynamic provisioning | `""`                |
| `persistence.accessModes`   | SQLite PVC access modes                                                  | `["ReadWriteOnce"]` |
| `persistence.keep`          | Retain the chart-created SQLite PVC on helm uninstall                    | `true`              |
| `persistence.annotations`   | Extra PVC annotations                                                    | `{}`                |

### Environment parameters

| Name                    | Description                                                            | Value |
| ----------------------- | ---------------------------------------------------------------------- | ----- |
| `extraEnvVars`          | Extra environment entries; do not override chart-managed LHCI settings | `[]`  |
| `extraEnvVarsSecret`    | Existing Secret exposed with envFrom                                   | `""`  |
| `extraEnvVarsConfigMap` | Existing ConfigMap exposed with envFrom                                | `""`  |

### Ingress parameters

| Name                  | Description                                                         | Value   |
| --------------------- | ------------------------------------------------------------------- | ------- |
| `ingress.enabled`     | Create an Ingress                                                   | `false` |
| `ingress.className`   | Ingress class name                                                  | `""`    |
| `ingress.whitelist`   | Comma-separated ingress-nginx source IP allowlist                   | `""`    |
| `ingress.annotations` | Ingress annotations, including controller-specific prefix rewriting | `{}`    |
| `ingress.tls`         | TLS hostnames and existing certificate Secret names                 | `[]`    |
| `ingress.hosts`       | Hosts with paths and pathType                                       | `[]`    |

### Service parameters

| Name                               | Description                                              | Value       |
| ---------------------------------- | -------------------------------------------------------- | ----------- |
| `service.type`                     | Kubernetes Service type                                  | `ClusterIP` |
| `service.ports.http`               | HTTP Service port; targets lhci.port                     | `9001`      |
| `service.nodePort`                 | HTTP node port when using NodePort or LoadBalancer       | `30080`     |
| `service.extraPorts`               | Additional Service ports                                 | `[]`        |
| `service.annotations`              | Service annotations                                      | `{}`        |
| `service.labels`                   | Service labels                                           | `{}`        |
| `service.externalTrafficPolicy`    | External traffic routing policy                          | `Cluster`   |
| `service.internalTrafficPolicy`    | Internal traffic routing policy                          | `Cluster`   |
| `service.clusterIP`                | Static cluster IP; empty lets Kubernetes allocate one    | `""`        |
| `service.loadBalancerIP`           | Requested load balancer IP, if supported by the provider | `""`        |
| `service.loadBalancerClass`        | Load balancer implementation                             | `""`        |
| `service.loadBalancerSourceRanges` | Allowed load balancer client CIDRs                       | `[]`        |
| `service.externalIPs`              | External IP addresses                                    | `[]`        |
| `service.sessionAffinity`          | None or ClientIP                                         | `None`      |
| `service.sessionAffinityConfig`    | Session affinity settings                                | `{}`        |
| `service.ipFamilyPolicy`           | IP family policy; empty uses the cluster default         | `""`        |

### Service Account parameters

| Name                         | Description                            | Value   |
| ---------------------------- | -------------------------------------- | ------- |
| `serviceAccount.create`      | Create a ServiceAccount                | `true`  |
| `serviceAccount.automount`   | Automount Kubernetes API credentials   | `false` |
| `serviceAccount.annotations` | ServiceAccount annotations             | `{}`    |
| `serviceAccount.name`        | Existing or custom ServiceAccount name | `""`    |
| `serviceAccount.secrets`     | ServiceAccount Secret references       | `[]`    |

### Pod settings

| Name                | Description                                                                                       | Value |
| ------------------- | ------------------------------------------------------------------------------------------------- | ----- |
| `replicaCount`      | Workload replicas; SQLite and built-in cron jobs require exactly one                              | `1`   |
| `strategy`          | Workload update strategy; empty chooses Recreate for Deployment and RollingUpdate for StatefulSet | `{}`  |
| `resources`         | Container resource requests and limits                                                            | `{}`  |
| `volumes`           | Additional pod volumes, e.g. secret files, certificates or host statistics mounts                 | `[]`  |
| `volumeMounts`      | Additional LHCI container mounts                                                                  | `[]`  |
| `initContainers`    | Init containers, e.g. to populate an asset volume                                                 | `[]`  |
| `nodeSelector`      | Node labels for pod placement                                                                     | `{}`  |
| `tolerations`       | Pod tolerations                                                                                   | `[]`  |
| `affinity`          | Pod affinity and anti-affinity                                                                    | `{}`  |
| `podAnnotations`    | Extra pod annotations                                                                             | `{}`  |
| `podLabels`         | Extra pod labels                                                                                  | `{}`  |
| `priorityClassName` | Existing PriorityClass name                                                                       | `""`  |

### Security context settings

| Name                 | Description                                                             | Value |
| -------------------- | ----------------------------------------------------------------------- | ----- |
| `podSecurityContext` | Pod security context; fsGroup makes the mounted data directory writable | `{}`  |
| `securityContext`    | Container security context                                              | `{}`  |

### Probe parameters

| Name                                 | Description                                                  | Value  |
| ------------------------------------ | ------------------------------------------------------------ | ------ |
| `livenessProbe.enabled`              | Enable HTTP liveness checking                                | `true` |
| `livenessProbe.initialDelaySeconds`  | Initial liveness delay                                       | `0`    |
| `livenessProbe.timeoutSeconds`       | Liveness timeout                                             | `1`    |
| `livenessProbe.periodSeconds`        | Liveness interval                                            | `10`   |
| `livenessProbe.successThreshold`     | Successful checks required                                   | `1`    |
| `livenessProbe.failureThreshold`     | Failed checks before restart                                 | `3`    |
| `readinessProbe.enabled`             | Enable HTTP readiness checking                               | `true` |
| `readinessProbe.initialDelaySeconds` | Initial readiness delay                                      | `0`    |
| `readinessProbe.timeoutSeconds`      | Readiness timeout                                            | `1`    |
| `readinessProbe.periodSeconds`       | Readiness interval                                           | `10`   |
| `readinessProbe.successThreshold`    | Successful checks required                                   | `1`    |
| `readinessProbe.failureThreshold`    | Failed checks before removing the pod from Service endpoints | `3`    |
| `startupProbe.enabled`               | Enable HTTP startup checking                                 | `true` |
| `startupProbe.initialDelaySeconds`   | Initial startup delay                                        | `0`    |
| `startupProbe.timeoutSeconds`        | Startup timeout                                              | `1`    |
| `startupProbe.periodSeconds`         | Startup interval                                             | `5`    |
| `startupProbe.successThreshold`      | Successful checks required                                   | `1`    |
| `startupProbe.failureThreshold`      | Failed checks allowed during startup                         | `120`  |

### PodDisruptionBudget parameters

| Name                                 | Description                                                    | Value   |
| ------------------------------------ | -------------------------------------------------------------- | ------- |
| `podDisruptionBudget.enabled`        | Create a PodDisruptionBudget                                   | `false` |
| `podDisruptionBudget.minAvailable`   | Minimum available pods; set null when using maxUnavailable     | `1`     |
| `podDisruptionBudget.maxUnavailable` | Maximum unavailable pods; mutually exclusive with minAvailable | `nil`   |

### Bitnami&reg; postgresql parameters

| Name                                             | Description                                                               | Value                  |
| ------------------------------------------------ | ------------------------------------------------------------------------- | ---------------------- |
| `postgresql.enabled`                             | Deploy the optional postgresql subchart and select its LHCI SQL dialect   | `false`                |
| `postgresql.fullnameOverride`                    | Override the database subchart resource name                              | `""`                   |
| `postgresql.architecture`                        | Database topology; this chart supports standalone                         | `standalone`           |
| `postgresql.global.imageRegistry`                | Global database image registry                                            | `docker.io`            |
| `postgresql.global.security.allowInsecureImages` | Allow custom images where supported by the dependency                     | `false`                |
| `postgresql.image.registry`                      | Database image registry                                                   | `docker.io`            |
| `postgresql.image.repository`                    | Database image repository; ensure compatibility with the selected chart   | `bitnami/postgresql`   |
| `postgresql.image.tag`                           | Database image tag; ensure the selected tag is available in your registry | `16.4.0-debian-12-r14` |
| `postgresql.image.digest`                        | Optional database image digest                                            | `""`                   |
| `postgresql.auth.username`                       | Application database username                                             | `lhci`                 |
| `postgresql.auth.password`                       | Application database password; generated by the subchart if empty         | `""`                   |
| `postgresql.auth.database`                       | Application database name                                                 | `lhci`                 |
| `postgresql.auth.existingSecret`                 | Existing subchart credential Secret                                       | `""`                   |
| `postgresql.auth.postgresPassword`               | PostgreSQL administrative password; generated if empty                    | `""`                   |
| `postgresql.auth.secretKeys.userPasswordKey`     | Application password key in the credential Secret                         | `password`             |
| `postgresql.auth.secretKeys.adminPasswordKey`    | Administrative password key in the credential Secret                      | `postgres-password`    |
| `postgresql.primary.service.ports.postgresql`    | Database service port                                                     | `5432`                 |
| `postgresql.primary.persistence.enabled`         | Persist the database using a PVC                                          | `true`                 |
| `postgresql.primary.persistence.existingClaim`   | Existing database PVC name                                                | `""`                   |
| `postgresql.primary.persistence.storageClass`    | Database PVC storage class                                                | `""`                   |
| `postgresql.primary.persistence.accessModes`     | Database PVC access modes                                                 | `["ReadWriteOnce"]`    |
| `postgresql.primary.persistence.size`            | Database PVC capacity                                                     | `5Gi`                  |

### Bitnami&reg; mysql parameters

| Name                                        | Description                                                               | Value                |
| ------------------------------------------- | ------------------------------------------------------------------------- | -------------------- |
| `mysql.enabled`                             | Deploy the optional mysql subchart and select its LHCI SQL dialect        | `false`              |
| `mysql.fullnameOverride`                    | Override the database subchart resource name                              | `""`                 |
| `mysql.architecture`                        | Database topology; this chart supports standalone                         | `standalone`         |
| `mysql.global.imageRegistry`                | Global database image registry                                            | `docker.io`          |
| `mysql.global.security.allowInsecureImages` | Allow custom images where supported by the dependency                     | `false`              |
| `mysql.image.registry`                      | Database image registry                                                   | `docker.io`          |
| `mysql.image.repository`                    | Database image repository; ensure compatibility with the selected chart   | `bitnami/mysql`      |
| `mysql.image.tag`                           | Database image tag; ensure the selected tag is available in your registry | `8.4.3-debian-12-r0` |
| `mysql.image.digest`                        | Optional database image digest                                            | `""`                 |
| `mysql.auth.username`                       | Application database username                                             | `lhci`               |
| `mysql.auth.password`                       | Application database password; generated by the subchart if empty         | `""`                 |
| `mysql.auth.database`                       | Application database name                                                 | `lhci`               |
| `mysql.auth.existingSecret`                 | Existing subchart credential Secret                                       | `""`                 |
| `mysql.auth.rootPassword`                   | MySQL root password; generated if empty                                   | `""`                 |
| `mysql.primary.service.ports.mysql`         | Database service port                                                     | `3306`               |
| `mysql.primary.persistence.enabled`         | Persist the database using a PVC                                          | `true`               |
| `mysql.primary.persistence.existingClaim`   | Existing database PVC name                                                | `""`                 |
| `mysql.primary.persistence.storageClass`    | Database PVC storage class                                                | `""`                 |
| `mysql.primary.persistence.accessModes`     | Database PVC access modes                                                 | `["ReadWriteOnce"]`  |
| `mysql.primary.persistence.size`            | Database PVC capacity                                                     | `5Gi`                |
