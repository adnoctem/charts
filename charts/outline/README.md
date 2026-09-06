# Ad Noctem Collective - Outline Helm Chart <img src="https://www.getoutline.com/images/logo.svg" alt="Outline Logo" width="175" height="175" align="right" loading="lazy">

> [!IMPORTANT]
> This Helm chart relies on the open-source _Bitnami_ Helm charts `postgresql` and `redis`. Beginning on August 28th, 2025, _Bitnami_
> (_VMware_/_Broadcom_) has changed their public offering and will require a commercial license for the use of their charts and images
> (_Bitnami Secure Images_/_BSI_). The only images available to the public as of now are a small set of hardened images which are only
> available at the 'latest' tag and meant for testing and development purposes. As such, the PostgreSQL and Redis subcharts included in
> this Helm chart are provided for convenience, but users are encouraged to use their own instances, another Helm chart, or (preferably)
> Operator-managed instances like CloudNativePG, if they do not wish to obtain a Bitnami license.
>
> _ref: [`bitnami/charts` - Issue 35164](https://github.com/bitnami/charts/issues/35164)_

Outline is a fast, collaborative, open-source knowledge base for your team. It combines a distraction-free markdown
editor with a well-organized structure for documents, wikis and knowledge sharing, real-time collaborative editing,
and integrations with tools like Slack, GitHub, GitLab, Figma and Notion. As an open-source project, Outline is
freely available for self-hosting.

It delivers all of these features within a single Docker image available
on [Docker Hub](https://hub.docker.com/r/outlinewiki/outline).

> Head to the [Outline GitHub Repository](https://github.com/outline/outline) or
> their [Website](https://www.getoutline.com/) for
> in-depth [documentation](https://docs.getoutline.com/)
> and [configuration guides](https://docs.getoutline.com/s/hosting/doc/environment-variables).
>
> [!NOTE]
> Outline ships under the [Business Source License 1.1](https://github.com/outline/outline/blob/main/LICENSE)
> (`BUSL-1.1`), not a permissive OSS license like MIT or Apache-2.0. Self-hosting for your own team is explicitly
> permitted, but the license's Additional Use Grant prohibits using Outline to operate a "Document Service" - a
> commercial offering that lets third parties outside your own organization create their own teams and documents
> within your deployment. Review the license before offering this chart's deployment as a multi-tenant service to
> others.

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install outline adnoctem/outline --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/outline:X.Y.Z
```

## Introduction

This chart bootstraps an
Outline [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
or [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster
networking a [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) manifest is also created, whereas the
Ingress needs to be explicitly enabled. Lastly the chart configures
a [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) if
enabled. [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are enabled by default.

The chart models every setting documented in
Outline's own [`.env.sample`](https://github.com/outline/outline/blob/main/.env.sample) as a dedicated,
typed `values.yaml` field under the `outline` key - database, Redis, file storage (local or S3-compatible), SMTP,
rate limiting, and every sign-in provider and third-party integration Outline supports each get their own values
section, rather than a generic environment-variable passthrough. See the Parameters tables below for the full
list.

> [!NOTE]
> Outline's official Docker Compose quick-start additionally runs [`steveltn/https-portal`](https://github.com/steveltn/https-portal)
> in front of the application, to get automatic Let's Encrypt HTTPS for a bare Compose stack. This chart doesn't need
> it - TLS termination and certificate management are handled by the cluster's own Ingress controller
> and [cert-manager](https://cert-manager.io/), which is why this chart has no equivalent component.

## Parameters

### Outline Image parameters

| Name                | Description                                                         | Value                 |
| ------------------- | ------------------------------------------------------------------- | --------------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `docker.io`           |
| `image.repository`  | The registry repository to pull the image from                      | `outlinewiki/outline` |
| `image.tag`         | The image tag to pull                                               | `1.10.0`              |
| `image.digest`      | The image digest to pull                                            | `""`                  |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`        |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`                  |

### Name overrides

| Name               | Description                                   | Value |
| ------------------ | --------------------------------------------- | ----- |
| `nameOverride`     | String to partially override outline.fullname | `""`  |
| `fullnameOverride` | String to fully override outline.fullname     | `""`  |

### Workload overrides

| Name   | Description                                                               | Value         |
| ------ | ------------------------------------------------------------------------- | ------------- |
| `kind` | The kind of workload to deploy Outline as (`StatefulSet` or `Deployment`) | `StatefulSet` |

### Outline Configuration parameters

| Name                                                    | Description                                                                                                                                                                                                                    | Value                    |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| `outline.url`                                           | The fully qualified, publicly accessible URL Outline is served on - if using a proxy this is the proxy's URL                                                                                                                   | `""`                     |
| `outline.port`                                          | The port for Outline to listen on, also used as the container port and health check target                                                                                                                                     | `3000`                   |
| `outline.collaborationUrl`                              | The URL of a separately-run collaboration server - only needed for horizontal scaling, see https://docs.getoutline.com/s/hosting/doc/horizontal-scaling-hkfU5Stao7                                                             | `""`                     |
| `outline.cdnUrl`                                        | A CDN (e.g. CloudFront/Cloudflare) URL to serve static assets (javascript/stylesheets/images) from - the CDN origin should point back at `outline.url`                                                                         | `""`                     |
| `outline.webConcurrency`                                | How many processes should be spawned. Roughly: available memory / 512                                                                                                                                                          | `1`                      |
| `outline.defaultLanguage`                               | The default interface language - see translate.getoutline.com for available codes                                                                                                                                              | `en_US`                  |
| `outline.secretKey.value`                               | A hex-encoded 32-byte random key, e.g. generated with `openssl rand -hex 32` - ignored if `existingSecret.name` is set, auto-generated if left empty                                                                           | `""`                     |
| `outline.secretKey.existingSecret.name`                 | The name of an existing Secret containing the secret key                                                                                                                                                                       | `""`                     |
| `outline.secretKey.existingSecret.key`                  | The key name within the previously named existingSecret                                                                                                                                                                        | `SECRET_KEY`             |
| `outline.utilsSecret.value`                             | A unique random key used to protect utility endpoints - ignored if `existingSecret.name` is set, auto-generated if left empty                                                                                                  | `""`                     |
| `outline.utilsSecret.existingSecret.name`               | The name of an existing Secret containing the utils secret                                                                                                                                                                     | `""`                     |
| `outline.utilsSecret.existingSecret.key`                | The key name within the previously named existingSecret                                                                                                                                                                        | `UTILS_SECRET`           |
| `outline.database.host`                                 | The hostname or IP address of the PostgreSQL server                                                                                                                                                                            | `outline-postgresql`     |
| `outline.database.port`                                 | The port number for the PostgreSQL server                                                                                                                                                                                      | `5432`                   |
| `outline.database.name`                                 | The name of the PostgreSQL database                                                                                                                                                                                            | `outline`                |
| `outline.database.username`                             | The username for the PostgreSQL user                                                                                                                                                                                           | `outline`                |
| `outline.database.password`                             | The password for the PostgreSQL user - ignored if `existingSecret.name` is set                                                                                                                                                 | `""`                     |
| `outline.database.connectionPoolMin`                    | The in-memory database pool minimum size per process                                                                                                                                                                           | `""`                     |
| `outline.database.connectionPoolMax`                    | The in-memory database pool maximum size per process - ensure this does not exceed your database's maximum connections                                                                                                         | `""`                     |
| `outline.database.sslMode`                              | Set to `disable` if not using SSL to connect to Postgres (acceptable if the database and application are co-located)                                                                                                           | `""`                     |
| `outline.database.existingSecret.name`                  | The name of an existing Secret containing the full `DATABASE_URL` connection string                                                                                                                                            | `""`                     |
| `outline.database.existingSecret.key`                   | The key within the previously named existingSecret                                                                                                                                                                             | `DATABASE_URL`           |
| `outline.redis.host`                                    | The hostname or IP address of the Redis server                                                                                                                                                                                 | `outline-redis-master`   |
| `outline.redis.port`                                    | The port number for the Redis server                                                                                                                                                                                           | `6379`                   |
| `outline.redis.username`                                | The username for the Redis user, if using Redis ACLs                                                                                                                                                                           | `""`                     |
| `outline.redis.password`                                | The password for the Redis server - ignored if `existingSecret.name` is set                                                                                                                                                    | `""`                     |
| `outline.redis.useTLS`                                  | Use a `rediss://` (TLS) URL to connect to Redis                                                                                                                                                                                | `false`                  |
| `outline.redis.existingSecret.name`                     | The name of an existing Secret containing the full `REDIS_URL` connection string                                                                                                                                               | `""`                     |
| `outline.redis.existingSecret.key`                      | The key within the previously named existingSecret                                                                                                                                                                             | `REDIS_URL`              |
| `outline.redis.collaborationUrl`                        | A separate Redis URL for the collaboration service, to enable horizontal scaling - leave empty to reuse the main Redis connection                                                                                              | `""`                     |
| `outline.fileStorage.type`                              | The storage backend for images and attachments. Valid values are `local` or `s3`                                                                                                                                               | `local`                  |
| `outline.fileStorage.uploadMaxSize`                     | The maximum allowed size, in bytes, for an uploaded attachment                                                                                                                                                                 | `262144000`              |
| `outline.fileStorage.importMaxSize`                     | Override the maximum size, in bytes, of document imports - generally lower than the attachment maximum                                                                                                                         | `""`                     |
| `outline.fileStorage.workspaceImportMaxSize`            | Override the maximum size, in bytes, of workspace imports - these are temporary and auto-deleted after a period of time                                                                                                        | `""`                     |
| `outline.fileStorage.local.rootDir`                     | The parent directory under which all attachments/images are stored - also used as the PVC mount path                                                                                                                           | `/var/lib/outline/data`  |
| `outline.fileStorage.s3.accessKeyId`                    | The S3 access key ID - ignored if `existingSecret.name` is set                                                                                                                                                                 | `""`                     |
| `outline.fileStorage.s3.secretAccessKey`                | The S3 secret access key - ignored if `existingSecret.name` is set                                                                                                                                                             | `""`                     |
| `outline.fileStorage.s3.existingSecret.name`            | The name of an existing Secret containing `accessKeyId` and `secretAccessKey` keys                                                                                                                                             | `""`                     |
| `outline.fileStorage.s3.region`                         | The AWS (or S3-compatible provider) region, e.g. `us-east-1`                                                                                                                                                                   | `""`                     |
| `outline.fileStorage.s3.accelerateUrl`                  | An S3 Transfer Acceleration URL, if using a Cloudfront/Cloudflare distribution or similar                                                                                                                                      | `""`                     |
| `outline.fileStorage.s3.uploadBucketUrl`                | The S3-compatible endpoint URL, e.g. `https://s3.amazonaws.com` or a MinIO/R2 endpoint                                                                                                                                         | `""`                     |
| `outline.fileStorage.s3.uploadBucketName`               | The S3 bucket name                                                                                                                                                                                                             | `""`                     |
| `outline.fileStorage.s3.forcePathStyle`                 | Use path-style S3 URLs rather than virtual-hosted-style - required for most S3-compatible providers (MinIO, etc.)                                                                                                              | `true`                   |
| `outline.fileStorage.s3.acl`                            | The S3 ACL applied to uploaded objects                                                                                                                                                                                         | `private`                |
| `outline.fileStorage.s3.uploadMethod`                   | The HTTP method used for presigned uploads. `post` uses a presigned POST with multipart form data, `put` uses a single presigned PUT request - set to `put` for providers like Cloudflare R2 that don't support presigned POST | `post`                   |
| `outline.fileStorage.s3.cloudfront.url`                 | The CloudFront distribution URL                                                                                                                                                                                                | `""`                     |
| `outline.fileStorage.s3.cloudfront.keyPairId`           | The CloudFront key pair ID, used for generating signed URLs                                                                                                                                                                    | `""`                     |
| `outline.fileStorage.s3.cloudfront.privateKey`          | The CloudFront private key, used for generating signed URLs - ignored if `existingSecret.name` is set                                                                                                                          | `""`                     |
| `outline.fileStorage.s3.cloudfront.existingSecret.name` | The name of an existing Secret containing a `privateKey` key                                                                                                                                                                   | `""`                     |
| `outline.ssl.forceHttps`                                | Auto-redirect to HTTPS - set to `false` if SSL is terminated at an external load balancer/Ingress                                                                                                                              | `true`                   |
| `outline.ssl.key`                                       | Base64-encoded private key for HTTPS termination inside the container - not needed when SSL is terminated at the Ingress, as is the default for this chart                                                                     | `""`                     |
| `outline.ssl.cert`                                      | Base64-encoded certificate for HTTPS termination inside the container - not needed when SSL is terminated at the Ingress, as is the default for this chart                                                                     | `""`                     |
| `outline.proxy.headersTrusted`                          | Whether to trust `X-Forwarded-*` headers set by an upstream proxy - this chart always runs behind the cluster's Ingress, so this defaults to `true`                                                                            | `true`                   |
| `outline.proxy.ipHeader`                                | The header used to identify the client IP when behind a proxy, e.g. `X-Real-IP` or `X-Client-IP` - defaults to `X-Forwarded-For` upstream if left empty                                                                        | `""`                     |
| `outline.smtp.service`                                  | A well-known Nodemailer service name (see https://community.nodemailer.com/2-0-0-beta/setup-smtp/well-known-services/) - leave empty to configure a generic SMTP server via `extraEnvVars`                                     | `""`                     |
| `outline.smtp.username`                                 | The SMTP authentication username - ignored if `existingSecret.name` is set                                                                                                                                                     | `""`                     |
| `outline.smtp.password`                                 | The SMTP authentication password - ignored if `existingSecret.name` is set                                                                                                                                                     | `""`                     |
| `outline.smtp.fromEmail`                                | The from-address for emails sent by Outline                                                                                                                                                                                    | `""`                     |
| `outline.smtp.existingSecret.name`                      | The name of an existing Secret containing `username` and `password` keys                                                                                                                                                       | `""`                     |
| `outline.rateLimiter.enabled`                           | Whether the rate limiter is enabled                                                                                                                                                                                            | `true`                   |
| `outline.rateLimiter.requests`                          | The number of requests allowed within the duration window, across all requests                                                                                                                                                 | `1000`                   |
| `outline.rateLimiter.durationWindow`                    | The rate limiter duration window, in seconds                                                                                                                                                                                   | `60`                     |
| `outline.rateLimiter.multiplier`                        | Multiplier applied to the hardcoded per-endpoint API rate limits - greater than 1 is more lenient, less than 1 is stricter                                                                                                     | `1`                      |
| `outline.auth.oidc.clientId`                            | The OIDC client ID                                                                                                                                                                                                             | `""`                     |
| `outline.auth.oidc.clientSecret`                        | The OIDC client secret - ignored if `existingSecret.name` is set                                                                                                                                                               | `""`                     |
| `outline.auth.oidc.existingSecret.name`                 | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                                                                                                   | `""`                     |
| `outline.auth.oidc.authUri`                             | The OIDC provider's authorization endpoint URI                                                                                                                                                                                 | `""`                     |
| `outline.auth.oidc.tokenUri`                            | The OIDC provider's token endpoint URI                                                                                                                                                                                         | `""`                     |
| `outline.auth.oidc.userinfoUri`                         | The OIDC provider's userinfo endpoint URI                                                                                                                                                                                      | `""`                     |
| `outline.auth.oidc.logoutUri`                           | The OIDC provider's logout endpoint URI                                                                                                                                                                                        | `""`                     |
| `outline.auth.oidc.usernameClaim`                       | The claim to derive the username from - supports any valid JSON path within the JWT payload                                                                                                                                    | `preferred_username`     |
| `outline.auth.oidc.displayName`                         | The display name shown for OIDC authentication on the sign-in page                                                                                                                                                             | `OpenID Connect`         |
| `outline.auth.oidc.scopes`                              | Space-separated OIDC auth scopes                                                                                                                                                                                               | `"openid profile email"` |
| `outline.auth.google.clientId`                          | The Google OAuth client ID                                                                                                                                                                                                     | `""`                     |
| `outline.auth.google.clientSecret`                      | The Google OAuth client secret - ignored if `existingSecret.name` is set                                                                                                                                                       | `""`                     |
| `outline.auth.google.existingSecret.name`               | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                                                                                                   | `""`                     |
| `outline.auth.slack.clientId`                           | The Slack OAuth client ID                                                                                                                                                                                                      | `""`                     |
| `outline.auth.slack.clientSecret`                       | The Slack OAuth client secret - ignored if `existingSecret.name` is set                                                                                                                                                        | `""`                     |
| `outline.auth.slack.existingSecret.name`                | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                                                                                                   | `""`                     |
| `outline.auth.azure.clientId`                           | The Azure AD application (client) ID                                                                                                                                                                                           | `""`                     |
| `outline.auth.azure.clientSecret`                       | The Azure AD client secret - ignored if `existingSecret.name` is set                                                                                                                                                           | `""`                     |
| `outline.auth.azure.existingSecret.name`                | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                                                                                                   | `""`                     |
| `outline.auth.azure.resourceAppId`                      | The Azure AD resource application ID                                                                                                                                                                                           | `""`                     |
| `outline.auth.discord.clientId`                         | The Discord OAuth client ID                                                                                                                                                                                                    | `""`                     |
| `outline.auth.discord.clientSecret`                     | The Discord OAuth client secret - ignored if `existingSecret.name` is set                                                                                                                                                      | `""`                     |
| `outline.auth.discord.existingSecret.name`              | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                                                                                                   | `""`                     |
| `outline.auth.discord.serverId`                         | Restrict sign-in to members of this Discord server ID                                                                                                                                                                          | `""`                     |
| `outline.auth.discord.serverRoles`                      | Comma-separated Discord role IDs allowed to sign in, when `serverId` is set                                                                                                                                                    | `""`                     |
| `outline.integrations.github.clientId`                  | The GitHub OAuth app client ID                                                                                                                                                                                                 | `""`                     |
| `outline.integrations.github.clientSecret`              | The GitHub OAuth app client secret - ignored if `existingSecret.name` is set                                                                                                                                                   | `""`                     |
| `outline.integrations.github.webhookSecret`             | The GitHub webhook secret - ignored if `existingSecret.name` is set                                                                                                                                                            | `""`                     |
| `outline.integrations.github.existingSecret.name`       | The name of an existing Secret containing `clientId`, `clientSecret`, `webhookSecret` and `appPrivateKey` keys                                                                                                                 | `""`                     |
| `outline.integrations.github.appName`                   | The GitHub App name                                                                                                                                                                                                            | `""`                     |
| `outline.integrations.github.appId`                     | The GitHub App ID                                                                                                                                                                                                              | `""`                     |
| `outline.integrations.github.appPrivateKey`             | The GitHub App private key - ignored if `existingSecret.name` is set                                                                                                                                                           | `""`                     |
| `outline.integrations.gitlab.clientId`                  | The GitLab OAuth application ID                                                                                                                                                                                                | `""`                     |
| `outline.integrations.gitlab.clientSecret`              | The GitLab OAuth application secret - ignored if `existingSecret.name` is set                                                                                                                                                  | `""`                     |
| `outline.integrations.gitlab.existingSecret.name`       | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                                                                                                   | `""`                     |
| `outline.integrations.linear.clientId`                  | The Linear OAuth application client ID                                                                                                                                                                                         | `""`                     |
| `outline.integrations.linear.clientSecret`              | The Linear OAuth application client secret - ignored if `existingSecret.name` is set                                                                                                                                           | `""`                     |
| `outline.integrations.linear.existingSecret.name`       | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                                                                                                   | `""`                     |
| `outline.integrations.slack.verificationToken`          | The Slack app verification token - ignored if `existingSecret.name` is set                                                                                                                                                     | `""`                     |
| `outline.integrations.slack.existingSecret.name`        | The name of an existing Secret containing a `verificationToken` key                                                                                                                                                            | `""`                     |
| `outline.integrations.slack.appId`                      | The Slack App ID (distinct from the OAuth client ID configured under `outline.auth.slack`)                                                                                                                                     | `""`                     |
| `outline.integrations.slack.messageActions`             | Whether to enable Slack message actions                                                                                                                                                                                        | `true`                   |
| `outline.integrations.figma.clientId`                   | The Figma OAuth application client ID                                                                                                                                                                                          | `""`                     |
| `outline.integrations.figma.clientSecret`               | The Figma OAuth application client secret - ignored if `existingSecret.name` is set                                                                                                                                            | `""`                     |
| `outline.integrations.figma.existingSecret.name`        | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                                                                                                   | `""`                     |
| `outline.integrations.dropbox.appKey`                   | The Dropbox app key - remember to also whitelist your domain in the Dropbox app settings                                                                                                                                       | `""`                     |
| `outline.integrations.notion.clientId`                  | The Notion OAuth application client ID                                                                                                                                                                                         | `""`                     |
| `outline.integrations.notion.clientSecret`              | The Notion OAuth application client secret - ignored if `existingSecret.name` is set                                                                                                                                           | `""`                     |
| `outline.integrations.notion.existingSecret.name`       | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                                                                                                   | `""`                     |
| `outline.integrations.iframely.url`                     | The Iframely instance URL                                                                                                                                                                                                      | `""`                     |
| `outline.integrations.iframely.apiKey`                  | The Iframely API key - ignored if `existingSecret.name` is set                                                                                                                                                                 | `""`                     |
| `outline.integrations.iframely.existingSecret.name`     | The name of an existing Secret containing an `apiKey` key                                                                                                                                                                      | `""`                     |
| `outline.integrations.sentry.dsn`                       | The Sentry DSN                                                                                                                                                                                                                 | `""`                     |
| `outline.integrations.sentry.tunnel`                    | An optional Sentry tunnel URL, to proxy events through your own domain                                                                                                                                                         | `""`                     |
| `outline.debug.enableUpdates`                           | Whether the installation checks for updates by sending anonymized statistics to the maintainers                                                                                                                                | `true`                   |
| `outline.debug.categories`                              | Debugging categories to enable - remove the default `http` value if your Ingress already logs incoming requests                                                                                                                | `http`                   |
| `outline.debug.logLevel`                                | The lowest severity level for server logs. One of `error`, `warn`, `info`, `http`, `verbose`, `debug` or `silly`                                                                                                               | `info`                   |
| `outline.data.pvc.size`                                 | The size given to the new PVC                                                                                                                                                                                                  | `10Gi`                   |
| `outline.data.pvc.storageClass`                         | The storageClass given to the new PVC                                                                                                                                                                                          | `standard`               |
| `outline.data.pvc.reclaimPolicy`                        | The resourcePolicy given to the new PVC                                                                                                                                                                                        | `Retain`                 |
| `outline.data.pvc.existingClaim`                        | Provide the name of an existing PVC                                                                                                                                                                                            | `""`                     |

### ConfigMap parameters

| Name                    | Description                             | Value |
| ----------------------- | --------------------------------------- | ----- |
| `configMap.annotations` | Annotations for the ConfigMap resource  | `{}`  |
| `configMap.labels`      | Extra Labels for the ConfigMap resource | `{}`  |

### Common Secret parameters

| Name                 | Description                                 | Value |
| -------------------- | ------------------------------------------- | ----- |
| `secret.annotations` | Common annotations for the Outline secrets  | `{}`  |
| `secret.labels`      | Common extra labels for the Outline secrets | `{}`  |

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

| Name                         | Description                                                               | Value   |
| ---------------------------- | ------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`      | Whether a service account should be created                               | `true`  |
| `serviceAccount.automount`   | Whether to automount the service account token                            | `false` |
| `serviceAccount.annotations` | Annotations to add to the service account                                 | `{}`    |
| `serviceAccount.name`        | A custom name for the service account, otherwise outline.fullname is used | `""`    |
| `serviceAccount.secrets`     | A list of secrets mountable by this service account                       | `[]`    |

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
| `startupProbe.enabled`             | Enable or disable the use of startup probes                | `false` |
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

| Name                | Description                                                                          | Value |
| ------------------- | ------------------------------------------------------------------------------------ | ----- |
| `resources`         | The resource limits/requests for the Outline pod                                     | `{}`  |
| `extraEnvVars`      | Extra environment variables for the Outline pod - this chart models every setting in | `[]`  |
| `volumes`           | Define volumes for the Outline pod                                                   | `[]`  |
| `volumeMounts`      | Define volumeMounts for the Outline pod                                              | `[]`  |
| `initContainers`    | Define initContainers for the main Outline server                                    | `[]`  |
| `nodeSelector`      | Node labels for pod assignment                                                       | `{}`  |
| `tolerations`       | Tolerations for pod assignment                                                       | `[]`  |
| `affinity`          | Affinity for pod assignment                                                          | `{}`  |
| `strategy`          | Specify a deployment strategy for the Outline pod                                    | `{}`  |
| `podAnnotations`    | Extra annotations for the Outline pod                                                | `{}`  |
| `podLabels`         | Extra labels for the Outline pod                                                     | `{}`  |
| `priorityClassName` | The name of an existing PriorityClass                                                | `""`  |

### Security context settings

| Name                 | Description                                                 | Value |
| -------------------- | ----------------------------------------------------------- | ----- |
| `podSecurityContext` | Security context settings for the Outline pod               | `{}`  |
| `securityContext`    | General security context settings for the Outline container | `{}`  |

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
| `postgresql.auth.postgresPassword`               | Password for the "postgres" admin user. Ignored if `auth.existingSecret` is provided                                           | `outline`                    |
| `postgresql.auth.username`                       | Name for a custom user to create                                                                                               | `outline`                    |
| `postgresql.auth.password`                       | Password for the custom user to create. Ignored if `auth.existingSecret` is provided                                           | `outline`                    |
| `postgresql.auth.database`                       | Name for a custom database to create                                                                                           | `outline`                    |
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
| `redis.auth.password`                       | Redis&reg; password                                                                                                            | `outline`               |
| `redis.auth.usePasswordFiles`               | Mount credentials as files instead of using an environment variable                                                            | `true`                  |
