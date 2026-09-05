# Ad Noctem Collective - Vaultwarden Helm Chart <img src="https://github.com/adnoctem/artwork/blob/425046029eaed451f5ced22ddc650059dff11878/projects/vaultwarden/icon/black/vaultwarden-icon-black.png" alt="Vaultwarden Logo" width="175" height="175" align="right" loading="lazy"/>

Vaultwarden is an unofficial Bitwarden server implementation written in Rust. It is compatible with
the [official Bitwarden clients](https://bitwarden.com/download/), and is ideal for self-hosted deployments where
running the official resource-heavy service is undesirable. Vaultwarden is targeted towards individuals, families, and
smaller organizations. Development of features that are mainly useful to larger organizations (e.g., single sign-on,
directory syncing, etc.) is not a priority, though high-quality PRs that implement such features would be welcome. It
delivers all of these features within a single Docker image available
on [Docker Hub](https://hub.docker.com/r/vaultwarden/server).

> Head to the [Vaultwarden GitHub Repository](https://github.com/dani-garcia/vaultwarden) for
> in-depth [documentation](https://github.com/dani-garcia/vaultwarden/wiki)
> and [configuration templates](https://github.com/dani-garcia/vaultwarden/blob/main/.env.template).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install vaultwarden adnoctem/vaultwarden --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/vaultwarden:X.Y.Z
```

## Introduction

This chart bootstraps a
Vaultwarden [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
or [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) on
a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster networking
a [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) manifest is also created, whereas the
Ingress needs to be explicitly enabled. Lastly the chart configures
a [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) if
enabled. [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are enabled by default.

The chart supports the configuration of
all [Vaultwarden environment variables](https://github.com/dani-garcia/vaultwarden/blob/main/.env.template) via
the `vaultwarden` key in Helm's _values_ and makes use of the official Docker Hub container image, although this is
configurable via the Image Parameters.

## Upgrading

### To 0.4.0 (Vaultwarden 1.30.5 -> 1.37.2)

- Corrected the `artifacthub.io/license` annotation: Vaultwarden ships under AGPL-3.0, not MIT as previously listed.
- `WEBSOCKET_ENABLED` was renamed to `ENABLE_WEBSOCKET` upstream; `vaultwarden.websocket.enabled` still controls it.
- Upstream removed the separate WebSocket port in `1.31.0` - WebSocket traffic is now served on the main Rocket
  port. `vaultwarden.websocket.port` is deprecated, no longer rendered into the ConfigMap, and no longer exposed
  as a second container port.
- Removed a broken Ingress rule that routed `/notifications/hub` to a Service port that was never actually
  defined by this chart's Service template - this was a pre-existing bug, unrelated to the WebSocket port removal
  above, and required no user action since the rule never worked.
- Added SSO (OpenID Connect) login support via the new `vaultwarden.sso` values block. `sso.clientId` /
  `sso.clientSecret` are stored in a dedicated Secret (or point at `sso.existingSecret.name`) analogous to the
  existing SMTP credentials handling.

## Parameters

### Image parameters

| Name                | Description                                                         | Value                |
| ------------------- | ------------------------------------------------------------------- | -------------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `docker.io`          |
| `image.repository`  | The registry repository to pull the image from                      | `vaultwarden/server` |
| `image.tag`         | The image tag to pull                                               | `1.37.2-alpine`      |
| `image.digest`      | The image digest to pull                                            | `""`                 |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`       |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`                 |

### Name overrides

| Name               | Description                                       | Value |
| ------------------ | ------------------------------------------------- | ----- |
| `nameOverride`     | String to partially override vaultwarden.fullname | `""`  |
| `fullnameOverride` | String to fully override vaultwarden.fullname     | `""`  |

### Workload overrides

| Name   | Description                                                                   | Value         |
| ------ | ----------------------------------------------------------------------------- | ------------- |
| `kind` | The kind of workload to deploy Vaultwarden as (`StatefulSet` or `Deployment`) | `StatefulSet` |

### Vaultwarden Configuration parameters

| Name                                                     | Description                                                                                                                                       | Value                      |
| -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| `vaultwarden.domain`                                     | The domain of the Vaultwarden installation                                                                                                        | `""`                       |
| `vaultwarden.web.enabled`                                | Whether or not to enable the Vaultwarden Web UI - enabled by default                                                                              | `true`                     |
| `vaultwarden.web.folder`                                 | A custom folder from which to load assets for the Web UI - defaults to 'web-vault/'                                                               | `""`                       |
| `vaultwarden.allowSends`                                 | Controls whether users are allowed to create Bitwarden Sends. Applies globally to all users.                                                      | `true`                     |
| `vaultwarden.allowEmergencyAccess`                       | Controls whether users can enable emergency access to their accounts. Applies globally to all users.                                              | `true`                     |
| `vaultwarden.allowEmailChange`                           | Controls whether users can change their email. Applies globally to all users.                                                                     | `true`                     |
| `vaultwarden.enableOrgEvents`                            | Controls whether event logging is enabled for organizations. Applies to organizations.                                                            | `false`                    |
| `vaultwarden.retainEventsDays`                           | Number of days to retain events stored in the database.                                                                                           | `""`                       |
| `vaultwarden.ipHeader`                                   | The Client IP Header, defaults to "X-Forwarded-For".                                                                                              | `X-Forwarded-For`          |
| `vaultwarden.disable2FARemember`                         | Disable 2FA remembrance.                                                                                                                          | `false`                    |
| `vaultwarden.orgCreationUsers`                           | Controls which users can create new orgs.                                                                                                         | `""`                       |
| `vaultwarden.enableOrgGroups`                            | Controls whether group support is enabled for organizations                                                                                       | `false`                    |
| `vaultwarden.allowedIframeAncestors`                     | Allowed iframe ancestors (Know the risks!)                                                                                                        | `""`                       |
| `vaultwarden.adminToken.value`                           | The value for the Vaultwarden admin token                                                                                                         | `""`                       |
| `vaultwarden.adminToken.disable`                         | Disable token authentication for the admin panel                                                                                                  | `false`                    |
| `vaultwarden.adminToken.existingSecret.name`             | The name of an existing Secret containing the admin token                                                                                         | `""`                       |
| `vaultwarden.adminToken.existingSecret.key`              | The key name within the previously named existingSecret                                                                                           | `""`                       |
| `vaultwarden.data.rootPath`                              | The data folder is used for all files by default                                                                                                  | `/data`                    |
| `vaultwarden.data.paths.rsaKey`                          | The file path for the RSA key, 'data/rsa_key' by default                                                                                          | `""`                       |
| `vaultwarden.data.paths.iconCache`                       | The path for icon cache, 'data/icon_cache' by default                                                                                             | `""`                       |
| `vaultwarden.data.paths.attachments`                     | The mail attachments path, 'data/attachments' by default                                                                                          | `""`                       |
| `vaultwarden.data.paths.sends`                           | The mail sends path, 'data/sends' by default                                                                                                      | `""`                       |
| `vaultwarden.data.paths.tmp`                             | The temporary data path, 'data/tmp' by default                                                                                                    | `""`                       |
| `vaultwarden.data.pvc.size`                              | The size given to PVCs created from the above data                                                                                                | `5Gi`                      |
| `vaultwarden.data.pvc.storageClass`                      | The storageClass given to PVCs created from the above data                                                                                        | `standard`                 |
| `vaultwarden.data.pvc.reclaimPolicy`                     | The resourcePolicy given to PVCs created from the above data                                                                                      | `Retain`                   |
| `vaultwarden.data.pvc.existingClaim`                     | Provide the name to an existing PVC                                                                                                               | `""`                       |
| `vaultwarden.email.attemptsLimit`                        | Maximum attempts before an email token is reset requiring a new email                                                                             | `3`                        |
| `vaultwarden.email.tokenExpirationTime`                  | Token expiration time                                                                                                                             | `600`                      |
| `vaultwarden.email.tokenSize`                            | Email token size                                                                                                                                  | `6`                        |
| `vaultwarden.email.smtp.host`                            | Hostname of the Mail server                                                                                                                       | `""`                       |
| `vaultwarden.email.smtp.from`                            | The from-address for emails sent by Vaultwarden                                                                                                   | `""`                       |
| `vaultwarden.email.smtp.fromName`                        | The from-name for emails sent by Vaultwarden                                                                                                      | `Vaultwarden`              |
| `vaultwarden.email.smtp.security`                        | Either 'starttls', 'force_tls' or 'off'                                                                                                           | `starttls`                 |
| `vaultwarden.email.smtp.port`                            | SMTP port used                                                                                                                                    | `587`                      |
| `vaultwarden.email.smtp.username`                        | SMTP user                                                                                                                                         | `""`                       |
| `vaultwarden.email.smtp.password`                        | SMTP password                                                                                                                                     | `""`                       |
| `vaultwarden.email.smtp.auth`                            | Defaults for SSL is "Plain" and "Login" and nothing for Non-SSL connections.                                                                      | `Plain`                    |
| `vaultwarden.email.smtp.existingSecret.name`             | The name of an existing BasicAuth secret                                                                                                          | `""`                       |
| `vaultwarden.email.smtp.timeout`                         | General SMTP settings                                                                                                                             | `15`                       |
| `vaultwarden.email.smtp.sendmail.enabled`                | Whether or not to use sendmail for sending emails                                                                                                 | `false`                    |
| `vaultwarden.email.smtp.sendmail.path`                   | The path to which sendmail binary to use.                                                                                                         | `""`                       |
| `vaultwarden.email.smtp.helloName`                       | Server name sent during the SMTP HELLO                                                                                                            | `""`                       |
| `vaultwarden.email.smtp.embedImages`                     | Embed images as email attachments                                                                                                                 | `false`                    |
| `vaultwarden.email.smtp.acceptInvalidHostnames`          | Accept Invalid Hostnames                                                                                                                          | `false`                    |
| `vaultwarden.email.smtp.acceptInvalidCertificates`       | Accept Invalid Certificates                                                                                                                       | `false`                    |
| `vaultwarden.email.smtp.requireDeviceEmail`              | Require new device emails.                                                                                                                        | `false`                    |
| `vaultwarden.email.smtp.debug`                           | Enable debug mode                                                                                                                                 | `false`                    |
| `vaultwarden.email.twoFactor.enforceInviteVerification`  | Setup email 2FA regardless of any organization policy                                                                                             | `false`                    |
| `vaultwarden.email.twoFactor.autoFallback`               | Automatically setup email 2FA as fallback provider when needed                                                                                    | `false`                    |
| `vaultwarden.websocket.enabled`                          | Whether to enable Websocket push notifications                                                                                                    | `true`                     |
| `vaultwarden.websocket.port`                             | Deprecated and no longer used - WebSocket traffic is served on the main port as of Vaultwarden 1.31.0                                             | `""`                       |
| `vaultwarden.sso.enabled`                                | Whether users can log in using an OpenID Connect identity provider                                                                                | `false`                    |
| `vaultwarden.sso.only`                                   | Prevent users from logging in directly without going through SSO                                                                                  | `false`                    |
| `vaultwarden.sso.signupsMatchEmail`                      | On SSO signup, associate with an existing user if the email matches                                                                               | `true`                     |
| `vaultwarden.sso.allowUnknownEmailVerification`          | Allow unknown email verification status - combined with signupsMatchEmail this can allow account takeover, only enable if you understand the risk | `false`                    |
| `vaultwarden.sso.authority`                              | Base URL of the OIDC server (auto-discovery is used) - must not include `/.well-known/openid-configuration` or a trailing slash                   | `""`                       |
| `vaultwarden.sso.scopes`                                 | Additional authorization request scopes (`openid` is always implicit) - defaults to "email profile" if unset                                      | `""`                       |
| `vaultwarden.sso.authorizeExtraParams`                   | Additional authorization URL parameters, e.g. to obtain a refresh_token with Google Auth                                                          | `""`                       |
| `vaultwarden.sso.pkce`                                   | Use PKCE for the Auth Code flow                                                                                                                   | `true`                     |
| `vaultwarden.sso.audienceTrusted`                        | Regex for additional trusted ID token audiences - by default only the client ID is trusted                                                        | `""`                       |
| `vaultwarden.sso.clientId`                               | The OIDC client ID - ignored if `existingSecret.name` is set                                                                                      | `""`                       |
| `vaultwarden.sso.clientSecret`                           | The OIDC client secret - ignored if `existingSecret.name` is set                                                                                  | `""`                       |
| `vaultwarden.sso.existingSecret.name`                    | The name of an existing Secret containing `clientId` and `clientSecret` keys                                                                      | `""`                       |
| `vaultwarden.sso.masterPasswordPolicy`                   | Optional master password policy JSON, e.g. '{"enforceOnLogin":false,"minComplexity":3,"minLength":12}'                                            | `""`                       |
| `vaultwarden.sso.authOnlyNotSession`                     | Use SSO only for authentication, not for the session lifecycle                                                                                    | `false`                    |
| `vaultwarden.database.type`                              | Choose the database type. Can be 'sqlite' or (external) 'mysql'/'postgresql'                                                                      | `"sqlite"`                 |
| `vaultwarden.database.user`                              | Provide the username to the (external) Vaultwarden database - ignored if the database type is 'sqlite'                                            | `""`                       |
| `vaultwarden.database.password`                          | Provide the password to the (external) Vaultwarden database - ignored if the database type is 'sqlite'                                            | `""`                       |
| `vaultwarden.database.host`                              | Provide the host to the (external) Vaultwarden database - ignored if the database type is 'sqlite'                                                | `""`                       |
| `vaultwarden.database.port`                              | Provide the port to the (external) Vaultwarden database - ignored if the database type is 'sqlite'                                                | `""`                       |
| `vaultwarden.database.name`                              | Provide the name to the (external) Vaultwarden database - ignored if the database type is 'sqlite'                                                | `""`                       |
| `vaultwarden.database.uri`                               | Manually provide the entire URI to the (external) Vaultwarden database - ignored if the database type is 'sqlite'                                 | `""`                       |
| `vaultwarden.database.existingSecret.name`               | The name of an existing secret                                                                                                                    | `""`                       |
| `vaultwarden.database.existingSecret.key`                | The key within the existing secret                                                                                                                | `""`                       |
| `vaultwarden.database.enableWAL`                         | Enable write-ahead logging                                                                                                                        | `false`                    |
| `vaultwarden.database.maxConnections`                    | Maximum database connections                                                                                                                      | `10`                       |
| `vaultwarden.database.timeout`                           | Database timeout                                                                                                                                  | `30`                       |
| `vaultwarden.database.connectionRetries`                 | Database connection retries                                                                                                                       | `15`                       |
| `vaultwarden.limits.logins.ratelimitSeconds`             | Number of seconds between login requests                                                                                                          | `60`                       |
| `vaultwarden.limits.logins.ratelimitMaxBurst`            | Allow bursts of requests up to this amount                                                                                                        | `10`                       |
| `vaultwarden.limits.logins.adminRatelimitSeconds`        | Number of seconds between admin login requests                                                                                                    | `300`                      |
| `vaultwarden.limits.logins.adminRatelimitMaxBurst`       | Allow bursts of admin requests up to this amount                                                                                                  | `300`                      |
| `vaultwarden.limits.logins.adminSessionLifetime`         | The lifetime of an admin session                                                                                                                  | `20`                       |
| `vaultwarden.limits.attachments.orgLimit`                | Per-organization attachment storage limit (KB)                                                                                                    | `""`                       |
| `vaultwarden.limits.attachments.userLimit`               | Per-user attachment storage limit (KB)                                                                                                            | `""`                       |
| `vaultwarden.limits.send.userLimit`                      | Per-user send storage limit (KB)                                                                                                                  | `""`                       |
| `vaultwarden.passwords.iterations`                       | Number of password hash iterations                                                                                                                | `350000`                   |
| `vaultwarden.passwords.hintsAllowed`                     | Allow sending of password hints                                                                                                                   | `false`                    |
| `vaultwarden.passwords.showHint`                         | Show hints directly on login page - disabled by default                                                                                           | `false`                    |
| `vaultwarden.signup.allowed`                             | Whether or not new users can register                                                                                                             | `true`                     |
| `vaultwarden.signup.verify`                              | Whether email verification is need to sign up                                                                                                     | `true`                     |
| `vaultwarden.signup.verifyResendTime`                    | How many seconds to wait to resend a verification email                                                                                           | `3600`                     |
| `vaultwarden.signup.verifyResendLimit`                   | How many verificatione mails will be sent in total                                                                                                | `6`                        |
| `vaultwarden.signup.domainWhitelist`                     | A comma-separated list of domains which can always register                                                                                       | `""`                       |
| `vaultwarden.auth.authenticatorDisableTimeDrift`         | Allow 2FA time drift                                                                                                                              | `false`                    |
| `vaultwarden.auth.incomplete2FATimeLimit`                | Minutes to wait before a 2FA login is considered incomplete                                                                                       | `3`                        |
| `vaultwarden.auth.yubikey.enable`                        | Whether to enable authentication via YubiKeys                                                                                                     | `false`                    |
| `vaultwarden.auth.yubikey.clientId`                      | Yubikey client ID                                                                                                                                 | `""`                       |
| `vaultwarden.auth.yubikey.clientSecret`                  | Yubikey client Secret                                                                                                                             | `""`                       |
| `vaultwarden.auth.yubikey.server`                        | Yubikey server                                                                                                                                    | `""`                       |
| `vaultwarden.auth.duo.enable`                            | Whether to enable authentication via Duo                                                                                                          | `false`                    |
| `vaultwarden.auth.duo.integrationKey`                    | Duo integration key                                                                                                                               | `""`                       |
| `vaultwarden.auth.duo.secretKey`                         | Duo secret key                                                                                                                                    | `""`                       |
| `vaultwarden.auth.duo.host`                              | Duo host                                                                                                                                          | `""`                       |
| `vaultwarden.invitations.allowed`                        | Invitations org admins to invite users, even when signups are disabled                                                                            | `true`                     |
| `vaultwarden.invitations.orgName`                        | Generic organization name for Emails                                                                                                              | `Vaultwarden`              |
| `vaultwarden.invitations.expirationHours`                | Number of hours which an email invitation lasts                                                                                                   | `120`                      |
| `vaultwarden.pushNotifications.enabled`                  | Whether to enable push notifications                                                                                                              | `false`                    |
| `vaultwarden.pushNotifications.installationId`           | Installation ID from 'https://bitwarden.com/host'                                                                                                 | `""`                       |
| `vaultwarden.pushNotifications.installationKey`          | Installation Key from 'https://bitwarden.com/host'                                                                                                | `""`                       |
| `vaultwarden.pushNotifications.relayUri`                 | Set a custom relay URI for push notifications                                                                                                     | `""`                       |
| `vaultwarden.pushNotifications.identityUri`              | Set a custom identity URI for push notifications                                                                                                  | `""`                       |
| `vaultwarden.hibpApiKey.value`                           | The HIBP API key-value                                                                                                                            | `""`                       |
| `vaultwarden.hibpApiKey.existingSecret.name`             | The name of an existing Secret containing the HIBP API key                                                                                        | `""`                       |
| `vaultwarden.hibpApiKey.existingSecret.key`              | The key within an existing Secret which contains the key                                                                                          | `""`                       |
| `vaultwarden.jobScheduler.pollIntervalMS`                | The poll interval for the job schedular in milliseconds                                                                                           | `30000`                    |
| `vaultwarden.jobScheduler.sendPurgeSchedule`             | Cron schedule to purge outdated Bitwarden Sends                                                                                                   | `'0 5 * * * *'`            |
| `vaultwarden.jobScheduler.trashPurgeSchedule`            | Cron schedule to purge trashed items                                                                                                              | `'0 5 0 * * *'`            |
| `vaultwarden.jobScheduler.incomplete2FASchedule`         | Cron schedule to check for incomplete 2FA logins                                                                                                  | `'0 5 0 * * *'`            |
| `vaultwarden.jobScheduler.emergencyNotificationReminder` | Cron schedule for expiration reminders                                                                                                            | `'0 3 * * * *'`            |
| `vaultwarden.jobScheduler.emergencyRequestTimeout`       | Cron schedule for emergency access requests                                                                                                       | `'0 7 * * * *'`            |
| `vaultwarden.jobScheduler.eventCleanup`                  | Cron schedule for event cleanups                                                                                                                  | `'0 10 0 * * *'`           |
| `vaultwarden.jobScheduler.trashAutoDeleteDays`           | Number of days to wait before auto-deleting a trashed item.                                                                                       | `""`                       |
| `vaultwarden.logs.level`                                 | The configured logging level                                                                                                                      | `info`                     |
| `vaultwarden.logs.extended`                              | Configure extended logging                                                                                                                        | `true`                     |
| `vaultwarden.logs.timestampFormat`                       | Timestamp format used in extended logging.                                                                                                        | `"%Y-%m-%d %H:%M:%S.%3f"`  |
| `vaultwarden.logs.file`                                  | Logging to a file                                                                                                                                 | `/var/log/vaultwarden.log` |
| `vaultwarden.logs.useSyslog`                             | Logging to Syslog                                                                                                                                 | `false`                    |
| `vaultwarden.templates.folder`                           | Templates data folder, by default embedded templates are used                                                                                     | `""`                       |
| `vaultwarden.templates.reload`                           | Automatically reload the templates for every request                                                                                              | `false`                    |
| `vaultwarden.icons.service`                              | Which service to use for fetching icons                                                                                                           | `internal`                 |
| `vaultwarden.icons.redirectCode`                         | The HTTP code to use for redirects to external services                                                                                           | `302`                      |
| `vaultwarden.icons.disableDownloading`                   | Disable icon downloading                                                                                                                          | `false`                    |
| `vaultwarden.icons.downloadTimeout`                      | Icon download timeout                                                                                                                             | `10`                       |
| `vaultwarden.icons.blacklistRegex`                       | Icon blacklist regular expression                                                                                                                 | `""`                       |
| `vaultwarden.icons.blacklistNonGlobalIPs`                | Any IP which is not defined as a global IP will be blacklisted.                                                                                   | `true`                     |
| `vaultwarden.icons.cache.ttl`                            | Cache time-to-live for successfully obtained icons, in seconds                                                                                    | `259200`                   |
| `vaultwarden.icons.cache.negttl`                         | Cache time-to-live for icons which weren't available, in seconds                                                                                  | `259200`                   |
| `vaultwarden.rocket.address`                             | The address Rocket should bind to                                                                                                                 | `"0.0.0.0"`                |
| `vaultwarden.rocket.port`                                | The port rocket should bind to                                                                                                                    | `80`                       |
| `vaultwarden.rocket.workers`                             | The amount of rocket workers to create                                                                                                            | `10`                       |
| `vaultwarden.rocket.tls`                                 | Rocket TLS configuration e.g.: "{certs="/path/to/certs.pem",key="/path/to/key.pem"}"                                                              | `""`                       |
| `vaultwarden.experimental.featureFlags`                  | A list of feature flags to enable                                                                                                                 | `[]`                       |

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

| Name                         | Description                                                                   | Value   |
| ---------------------------- | ----------------------------------------------------------------------------- | ------- |
| `serviceAccount.create`      | Whether a service account should be created                                   | `true`  |
| `serviceAccount.automount`   | Whether to automount the service account token                                | `false` |
| `serviceAccount.annotations` | Annotations to add to the service account                                     | `{}`    |
| `serviceAccount.name`        | A custom name for the service account, otherwise vaultwarden.fullname is used | `""`    |
| `serviceAccount.secrets`     | A list of secrets mountable by this service account                           | `[]`    |

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
| `resources`         | The resource limits/requests for the Vaultwarden pod  | `{}`  |
| `volumes`           | Define volumes for the Paperless pod                  | `[]`  |
| `volumeMounts`      | Define volumeMounts for the Paperless pod             | `[]`  |
| `initContainers`    | Define initContainers for the main Vaultwarden server | `[]`  |
| `nodeSelector`      | Node labels for pod assignment                        | `{}`  |
| `tolerations`       | Tolerations for pod assignment                        | `[]`  |
| `affinity`          | Affinity for pod assignment                           | `{}`  |
| `strategy`          | Specify a deployment strategy for the Vaultwarden pod | `{}`  |
| `podAnnotations`    | Extra annotations for the Vaultwarden pod             | `{}`  |
| `podLabels`         | Extra labels for the Vaultwarden pod                  | `{}`  |
| `priorityClassName` | The name of an existing PriorityClass                 | `""`  |

### Security context settings

| Name                 | Description                                       | Value |
| -------------------- | ------------------------------------------------- | ----- |
| `podSecurityContext` | Security context settings for the Vaultwarden pod | `{}`  |
| `securityContext`    | General security context settings for             | `{}`  |
