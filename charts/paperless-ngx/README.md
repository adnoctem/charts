# Ad Noctem Collective - Paperless-NGX Helm Chart <img src="https://github.com/adnoctem/artwork/blob/425046029eaed451f5ced22ddc650059dff11878/projects/paperless-ngx/icon/color/paperless-ngx-icon-color.png" alt="Paperless-NGX Logo" width="175" height="175" align="right" loading="lazy"/>

> [!IMPORTANT]
> This Helm chart relies on the open-source _Bitnami_ Helm chart `postgresql`. Beginning on August 28th, 2025, _Bitnami_
> (_VMware_/_Broadcom_) has changed their public offering and will require a commercial license for the use of their charts and images
> (_Bitnami Secure Images_/_BSI_). The only images available to the public as of now are a small set of hardened images which are only
> available at the 'latest' tag and meant for testing and development purposes. As such, the PostgreSQL subchart included in this Helm
> chart is provided for convenience, but users are encouraged to use their own PostgreSQL instance, another PostgreSQL Helm chart or
> (preferably) an Operator-managed PostgreSQL instance like CloudnativePG, if they do not wish to obtain a Bitnami license.
>
> _ref: [`bitnami/charts` - Issue 35164](https://github.com/bitnami/charts/issues/35164)_

Paperless-ngx is a community-supported open-source document management system that transforms your physical documents
into a searchable online archive so you can keep, well, less paper. Paperless-NGX is the official successor to the
original [Paperless](https://github.com/the-paperless-project/paperless) & [Paperless-ng](https://github.com/jonaswinkler/paperless-ng)
projects and is designed to distribute the responsibility of advancing and supporting the project among a team of
people. The application organizes and indexes your documents with tags, correspondents, types and more, performs OCR on
your documents, making their text searchable and selectable and due its' use of the Tesseract engine - recognizes more
than 100 languages. On top of all that it features a beautiful modern web application and is accompanied by a plethora
of mobile applications for iOS and Android, provided by the open-source community around the project. It delivers all of
these features within a single Docker image available
on [GitHub Container Registry](https://github.com/paperless-ngx/paperless-ngx/pkgs/container/paperless-ngx).

> Head to the [Paperless-NGX GitHub Repository](https://github.com/paperless-ngx/paperless-ngx/tree/dev) or
> their [Website](https://docs.paperless-ngx.com/) for in-depth [documentation](https://docs.paperless-ngx.com/)
> and [configuration guides](https://docs.paperless-ngx.com/configuration/).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install paperless-ngx adnoctem/paperless-ngx --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/paperless-ngx:X.Y.Z
```

## Introduction

This chart bootstraps a
Paperless-NGX [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) on
a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster networking
a [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) manifest is also created, whereas the
Ingress needs to be explicitly enabled. Lastly the chart configures
a [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) if
enabled. [RBAC manifests](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) are enabled by default.

The chart supports the configuration of
all [Paperless-NGX environment variables](https://docs.paperless-ngx.com/configuration/) via the `paperless` key in
Helm's _values_ and makes use of the official Docker Hub container image, although this is configurable via the Image
Parameters.

## Upgrading

### To 0.4.0 (Paperless-ngx 2.10.1 -> 3.1.3)

> [!WARNING]
> **Upgrading to v3 can only be performed from v2.20.15** - this is an upstream requirement, not a chart limitation.
> If you're running an existing installation older than `2.20.15`, first upgrade this chart's `appVersion` to
> `2.20.15`, let it run its migrations, and only then upgrade further to `3.1.3`. Skipping this step is unsupported
> by upstream and may leave your database in an inconsistent state.
>
> If you have any documents with encryption enabled (deprecated since `paperless-ng 0.9.3`), decrypt them with the
> `decrypt_documents` management command **before** upgrading - encryption support is removed entirely in v3.

This is a major version upgrade with many breaking changes - the full details are in
[upstream's v3 migration guide](https://docs.paperless-ngx.com/migration-v3/). The items below cover what's
relevant to this chart specifically.

- **Fixed a bug where the generated Paperless secret key rotated on every `helm upgrade`** (when
  `paperless.secretKey.value`/`.existingSecret` weren't set), invalidating every active session and other signed
  token each time the chart was upgraded, completely independent of this version bump. The generated key is now
  preserved across upgrades.
- `PAPERLESS_SECRET_KEY` is now a required setting upstream; this chart has always generated one automatically if
  you don't set `paperless.secretKey.value` yourself, so no action is needed on that front.
- **Duplicate handling behavior changed by default:** v3 no longer rejects duplicate documents outright - they're
  consumed and flagged as duplicates in the UI instead. `paperless.consume.deleteDuplicates` (default `false`,
  unchanged) now controls this rejection behavior itself, not just whether the duplicate file gets cleaned up
  afterwards as it did in v2. Set it to `true` if you want the old reject-on-duplicate behavior back.
- `paperless.ocr.mode`'s `skip` value is gone, replaced by the new default `auto` - if you had `mode: skip`
  explicitly set, change it to `auto`.
- `paperless.ocr.skipArchiveFile` has been renamed to `paperless.ocr.archiveFileGeneration` (the old
  `PAPERLESS_OCR_SKIP_ARCHIVE_FILE` setting is removed upstream). The new default (`always`) preserves this
  chart's previous archiving behavior exactly - **the value `never` means the opposite thing in the new setting**
  (never skip archiving vs. never generate one), so if you had `skipArchiveFile` set to anything, don't carry the
  literal value over - see the mapping in `values.yaml`'s comments or the upstream migration guide.
- `paperless.consume.barcodeScanner` is deprecated and no longer has any effect - zxing-cpp is the only barcode
  backend now. The value is left in `values.yaml` for backward compatibility but is no longer rendered as an
  environment variable regardless of what it's set to.
- `paperless.consume.ignorePatterns` is now matched as a regex, not the previous fnmatch/glob syntax - review any
  existing patterns before upgrading.
- If you're running behind a reverse proxy (which includes anyone using this chart's Ingress), allauth's login
  rate limiting now determines the client IP differently and **may reject logins with `403 Forbidden`** until you
  set `PAPERLESS_TRUSTED_PROXIES`, `PAPERLESS_ALLAUTH_TRUSTED_PROXY_COUNT`, and/or
  `PAPERLESS_ALLAUTH_TRUSTED_CLIENT_IP_HEADER` via the new `extraEnvVars` - see the
  [migration guide's section on this](https://docs.paperless-ngx.com/migration-v3/#reverse-proxy-and-login-rate-limiting).
- Added `extraEnvVars` for the many settings above and others without a dedicated value (`PAPERLESS_DB_OPTIONS`,
  the renamed `PAPERLESS_CONSUMER_POLLING_INTERVAL`/`STABILITY_DELAY`, `PAPERLESS_TRAIN_TASK_CRON`, etc.).
- The full-text search backend changed from Whoosh to Tantivy - the index is rebuilt automatically on first
  startup, no action needed. If you have saved views with a plain search term that happened to match note or
  custom field content, review them - unqualified queries aren't migrated the way `note:`/`custom_field:`-prefixed
  ones are (now `notes.note:`/`custom_fields.value:`).
- If you're on unusually old x86_64 hardware (roughly pre-2008 Intel / pre-2011 AMD, lacking SSE4.2), the document
  classifier can crash the Celery worker with `SIGILL` due to a NumPy 2.4.0 CPU baseline requirement - if you hit
  this, set `PAPERLESS_TRAIN_TASK_CRON=disable` via `extraEnvVars`.
- All task history is cleared during the upgrade (the task tracking system was redesigned) - no action needed.
- Fixed a stale `artifacthub.io/images` annotation that still referenced `2.4.0` even though `appVersion` was
  already `2.10.1`, and corrected the license annotation - Paperless-ngx is GPL-3.0, not MIT.
- The `gotenberg` subchart dependency now points at its current location
  (`oci://ghcr.io/adnoctem/charts/gotenberg`) - it previously referenced a path from before this repository was
  renamed, which had never been updated since.

## Parameters

### Image parameters

| Name                | Description                                                         | Value                         |
| ------------------- | ------------------------------------------------------------------- | ----------------------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `ghcr.io`                     |
| `image.repository`  | The registry repository to pull the image from                      | `paperless-ngx/paperless-ngx` |
| `image.tag`         | The image tag to pull                                               | `3.1.3`                       |
| `image.digest`      | The image digest to pull                                            | `""`                          |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`                |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`                          |

### Name overrides

| Name               | Description                                     | Value |
| ------------------ | ----------------------------------------------- | ----- |
| `nameOverride`     | String to partially override paperless.fullname | `""`  |
| `fullnameOverride` | String to fully override paperless.fullname     | `""`  |

### Paperless Configuration parameters

| Name                                               | Description                                                                                                                                                                                                   | Value            |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| `paperless.domain`                                 | Define the domain name for Paperless - will be reused in Ingress                                                                                                                                              | `""`             |
| `paperless.appTitle`                               | If set, overrides the default name "Paperless-ngx"                                                                                                                                                            | `""`             |
| `paperless.appLogo`                                | Path to an image file in the `/media/logo` directory, must include 'logo', e.g. `/logo/Atari_logo.svg`                                                                                                        | `""`             |
| `paperless.secretKey.value`                        | Define a custom secret key for Paperless                                                                                                                                                                      | `""`             |
| `paperless.secretKey.existingSecret.name`          | Define the name of an existing Secret containing the secret key                                                                                                                                               | `""`             |
| `paperless.secretKey.existingSecret.key`           | Define the key within the existing Secret containing the secret key                                                                                                                                           | `""`             |
| `paperless.address`                                | The address Paperless should bind to                                                                                                                                                                          | `"::"`           |
| `paperless.port`                                   | The port Paperless should bind to                                                                                                                                                                             | `8000`           |
| `paperless.uid`                                    | The user ID Paperless should use                                                                                                                                                                              | `1000`           |
| `paperless.gid`                                    | The group ID Paperless should use                                                                                                                                                                             | `1000`           |
| `paperless.enableFlower`                           | Enable the 'Flower' monitoring tool for 'Celery' (Paperless' task queue)                                                                                                                                      | `false`          |
| `paperless.webserverWorkers`                       | The amount of Nginx worker processes to spawn for the server within the container                                                                                                                             | `1`              |
| `paperless.taskWorkers`                            | The amount for task worker processes to spawn within the container                                                                                                                                            | `""`             |
| `paperless.threadsPerWorker`                       | The amount of threads to assign each task worker process within the container                                                                                                                                 | `""`             |
| `paperless.workerTimeout`                          | The amount of threads to assign each task worker process within the container                                                                                                                                 | `""`             |
| `paperless.timeZone`                               | Set the time zone here                                                                                                                                                                                        | `UTC`            |
| `paperless.enableNLTK`                             | Enables or disables the advanced natural language processing used during                                                                                                                                      | `""`             |
| `paperless.enableAuditLog`                         | Enables the audit trail for documents, document types, correspondents, and tags                                                                                                                               | `true`           |
| `paperless.enableCompression`                      | Enables compression of the responses from the webserver. Defaults to 1, enabling compression.                                                                                                                 | `"1"`            |
| `paperless.apps`                                   | A comma-separated list of Django apps to be included in Django's INSTALLED_APPS                                                                                                                               | `""`             |
| `paperless.maxImagePixels`                         | Configures the maximum size of an image PIL will allow to load without warning or error                                                                                                                       | `""`             |
| `paperless.emptyTrashDelay`                        | Sets how long in days documents remain in the 'trash' before they are permanently deleted                                                                                                                     | `30`             |
| `paperless.auth.autoLoginUsername`                 | Specify a username so that paperless will automatically perform login with the selected user                                                                                                                  | `""`             |
| `paperless.auth.adminUser`                         | If this environment variable is specified, Paperless automatically creates a superuser with the provided username at start                                                                                    | `""`             |
| `paperless.auth.adminPassword`                     | Only used when PAPERLESS_ADMIN_USER is set. This will be the password of the automatically created superuser                                                                                                  | `""`             |
| `paperless.auth.existingSecret`                    | Specify an existing secret with a `username` and `password` key                                                                                                                                               | `""`             |
| `paperless.auth.adminMail`                         | Specify superuser email address. Only used when PAPERLESS_ADMIN_USER is set                                                                                                                                   | `""`             |
| `paperless.auth.allowSignups`                      | Allow users to sign up for a new Paperless-ngx account                                                                                                                                                        | `""`             |
| `paperless.auth.disableRegularLogin`               | Disables the regular frontend username / password login, i.e. once you have setup SSO                                                                                                                         | `false`          |
| `paperless.auth.sessionRemember`                   | Controls the lifetime of the session. `None`, `False` or `True`                                                                                                                                               | `""`             |
| `paperless.auth.defaultHTTPProtocol`               | The protocol used when generating URLs, e.g. login callback URLs                                                                                                                                              | `""`             |
| `paperless.auth.emailVerification`                 | Determines whether email addresses are verified during signup (as performed by Django allauth)                                                                                                                | `""`             |
| `paperless.auth.social.accountProviders`           | This variable is used to set up login and signup via social account providers which are compatible with django-allauth.                                                                                       | `""`             |
| `paperless.auth.social.existingSecret`             | The name of existing secret containing a `accountProviders` key to configure Django AllAuth                                                                                                                   | `""`             |
| `paperless.auth.social.allowSignups`               | Allow users to signup for a new Paperless-ngx account using any setup third party authentication systems                                                                                                      | `false`          |
| `paperless.auth.social.autoSignup`                 | Attempt to sign up the user using retrieved email, username etc from the third party authentication system                                                                                                    | `false`          |
| `paperless.hosting.trustedOrigins`                 | A list of trusted origins for unsafe requests (e.g. POST). As of Django 4.0 this is required to access the Django admin via the web                                                                           | `""`             |
| `paperless.hosting.allowedHosts`                   | If you're planning on putting Paperless on the open internet, then you really should set this value to the domain name you're using                                                                           | `""`             |
| `paperless.hosting.corsAllowedHosts`               | You need to add your servers to the list of allowed hosts that can do CORS calls. Set this to your public domain name                                                                                         | `""`             |
| `paperless.hosting.trustedProxies`                 | This may be needed to prevent IP address spoofing if you are using e.g. fail2ban with log entries for failed authorization attempts                                                                           | `""`             |
| `paperless.hosting.forceScriptName`                | To host paperless under a subpath URL like example.com/paperless you set this value to /paperless. No trailing slash!                                                                                         | `""`             |
| `paperless.hosting.staticURL`                      | Unless you're hosting Paperless off a subdomain like /paperless/, you probably don't need to change this                                                                                                      | `""`             |
| `paperless.hosting.cookiePrefix`                   | Specify a prefix that is added to the cookies used by paperless to identify the currently logged in user                                                                                                      | `""`             |
| `paperless.hosting.enableHTTPRemoteUser`           | Allows authentication via HTTP_REMOTE_USER which is used by some SSO applications                                                                                                                             | `false`          |
| `paperless.hosting.enableHTTPRemoteUserAPI`        | AAllows authentication via HTTP_REMOTE_USER directly against the API                                                                                                                                          | `false`          |
| `paperless.hosting.HTTPRemoteUserHeaderName`       | If "PAPERLESS_ENABLE_HTTP_REMOTE_USER" or PAPERLESS_ENABLE_HTTP_REMOTE_USER_API are enabled, this property allows to customize the name of the HTTP header from which the authenticated username is extracted | `""`             |
| `paperless.hosting.logoutRedirectURL`              | URL to redirect the user to after a logout                                                                                                                                                                    | `""`             |
| `paperless.hosting.useXForwardHost`                | Configures the Django setting USE_X_FORWARDED_HOST which may be needed for hosting behind a proxy                                                                                                             | `false`          |
| `paperless.hosting.useXForwardPort`                | Configures the Django setting USE_X_FORWARDED_PORT which may be needed for hosting behind a proxy                                                                                                             | `false`          |
| `paperless.hosting.proxySSLHeader`                 | Configures the Django setting SECURE_PROXY_SSL_HEADER which may be needed for hosting behind a proxy                                                                                                          | `""`             |
| `paperless.cron.emailTask`                         | Configures the scheduled email fetching frequency. The value should be a valid crontab(5) expression describing when to run.                                                                                  | `"*/10 * * * *"` |
| `paperless.cron.trainTask`                         | Configures the scheduled automatic classifier training frequency. May also be "disabled".                                                                                                                     | `"5 */1 * * *"`  |
| `paperless.cron.indexTask`                         | Configures the scheduled search index update frequency. May also be "disabled".                                                                                                                               | `"0 0 * * *"`    |
| `paperless.cron.sanityTask`                        | Configures the scheduled sanity checker frequency. May also be "disabled".                                                                                                                                    | `"30 0 * *"`     |
| `paperless.cron.emptyTrashTask`                    | Configures the schedule to empty the trash of expired deleted documents                                                                                                                                       | `"0 1 * * *"`    |
| `paperless.redis.host`                             | Specify a custom hostname for the Redis instance.                                                                                                                                                             | `""`             |
| `paperless.redis.port`                             | The port for the Redis instance                                                                                                                                                                               | `6379`           |
| `paperless.redis.username`                         | The username for the Redis instance                                                                                                                                                                           | `""`             |
| `paperless.redis.password`                         | The password for the Redis instance                                                                                                                                                                           | `""`             |
| `paperless.redis.existingSecret`                   | The name of an existing Secret with a `uri` key containing the full Redis URI                                                                                                                                 | `""`             |
| `paperless.redis.prefix`                           |                                                                                                                                                                                                               | `""`             |
| `paperless.postgresql.host`                        | Specify a custom hostname for the PostgreSQL database                                                                                                                                                         | `""`             |
| `paperless.postgresql.port`                        | The port for the PostgreSQL database                                                                                                                                                                          | `5432`           |
| `paperless.postgresql.name`                        | The database name for the PostgreSQL database                                                                                                                                                                 | `""`             |
| `paperless.postgresql.user`                        | The username for the PostgreSQL database                                                                                                                                                                      | `""`             |
| `paperless.postgresql.password`                    | The password for the PostgreSQL database                                                                                                                                                                      | `""`             |
| `paperless.postgresql.existingSecret`              | An existing BasicAuth secret containing the PostgreSQL credentials                                                                                                                                            | `""`             |
| `paperless.postgresql.sslMode`                     | The SSL Mode for the PostgreSQL database                                                                                                                                                                      | `prefer`         |
| `paperless.postgresql.timeout`                     | Define a timeout for the database connection                                                                                                                                                                  | `""`             |
| `paperless.postgresql.certs.rootCert`              | The path to a mounted TLS root certificate                                                                                                                                                                    | `""`             |
| `paperless.postgresql.certs.cert`                  | The path to a mounted TLS certificate                                                                                                                                                                         | `""`             |
| `paperless.postgresql.certs.key`                   | The path to a mounted TLS certificate key                                                                                                                                                                     | `""`             |
| `paperless.tika.enabled`                           | Enable or disable the Apache&reg; Tika integration                                                                                                                                                            | `true`           |
| `paperless.tika.endpoint`                          | Define the Apache Tika endpoint                                                                                                                                                                               | `""`             |
| `paperless.gotenberg.endpoint`                     | Define the Apache Gotenberg endpoint                                                                                                                                                                          | `""`             |
| `paperless.smtp.host`                              | The host to an SMTP server                                                                                                                                                                                    | `""`             |
| `paperless.smtp.port`                              | The port for an SMTP server                                                                                                                                                                                   | `""`             |
| `paperless.smtp.user`                              | An SMTP username                                                                                                                                                                                              | `""`             |
| `paperless.smtp.password`                          | The password for an SMTP user                                                                                                                                                                                 | `""`             |
| `paperless.smtp.existingSecret`                    | A secret containing `username` and `password` key SMTP authentication                                                                                                                                         | `""`             |
| `paperless.smtp.from`                              | The `from` address for emails sent by Paperless                                                                                                                                                               | `""`             |
| `paperless.smtp.useTLS`                            | Whether to use TLS for contacting the SMTP server                                                                                                                                                             | `false`          |
| `paperless.smtp.useSSL`                            | Whether to use SSL for contacting the SMTP server                                                                                                                                                             | `false`          |
| `paperless.data.paths.consumptionDir`              | Define a custom consumption directory                                                                                                                                                                         | `""`             |
| `paperless.data.paths.dataDir`                     | Define a custom data directory                                                                                                                                                                                | `""`             |
| `paperless.data.paths.trashDir`                    | Define a custom trash directory                                                                                                                                                                               | `""`             |
| `paperless.data.paths.emptyTrashDir`               | Define a custom trash directory                                                                                                                                                                               | `""`             |
| `paperless.data.paths.mediaRoot`                   | Define a custom media directory                                                                                                                                                                               | `""`             |
| `paperless.data.paths.staticDir`                   | Define a custom static directory                                                                                                                                                                              | `""`             |
| `paperless.data.paths.filenameFormat`              | Define a custom filename format                                                                                                                                                                               | `""`             |
| `paperless.data.paths.filenameFormatRemoveNone`    | Omit placeholders that would resolve to 'none' in filenameFormat                                                                                                                                              | `false`          |
| `paperless.data.paths.loggingDir`                  | Define a custom logging directory                                                                                                                                                                             | `""`             |
| `paperless.data.paths.nltkDir`                     | Define a custom NLTK processing directory                                                                                                                                                                     | `""`             |
| `paperless.data.paths.emailCertificateLocation`    | Define a path to a certificate (chain) for TLS verification for mail servers                                                                                                                                  | `""`             |
| `paperless.data.paths.modelFile`                   | This is where paperless will store the classification model. Default is PAPERLESS_DATA_DIR/classification_model.pickle                                                                                        | `""`             |
| `paperless.data.paths.supervisordWorkingDir`       | If this environment variable is defined, the supervisord.log and supervisord.pid file will be created under the specified path                                                                                | `""`             |
| `paperless.data.pvc.size`                          | The size given to PVCs created from the above data                                                                                                                                                            | `10Gi`           |
| `paperless.data.pvc.storageClass`                  | The storageClass given to PVCs created from the above data                                                                                                                                                    | `standard`       |
| `paperless.data.pvc.reclaimPolicy`                 | The resourcePolicy given to PVCs created from the above data                                                                                                                                                  | `Retain`         |
| `paperless.data.pvc.existingClaim`                 | Provide the name to an existing PVC                                                                                                                                                                           | `""`             |
| `paperless.logging.logrotateMaxSize`               | Maximum file size for log files before they're rotated                                                                                                                                                        | `""`             |
| `paperless.logging.logrotateMaxBackups`            | The number of rotated log files to keep                                                                                                                                                                       | `""`             |
| `paperless.ocr.language`                           | Customize the language that paperless will attempt to use when parsing documents                                                                                                                              | `eng`            |
| `paperless.ocr.additionalLanguages`                | Additional languages that paperless will attempt to use when parsing documents                                                                                                                                | `""`             |
| `paperless.ocr.mode`                               | Tell paperless when and how to perform ocr on your documents: `auto`, `force`, `redo` or `off`                                                                                                                | `auto`           |
| `paperless.ocr.archiveFileGeneration`              | Controls when paperless generates an archived version of your documents: `auto`, `always` or `never`                                                                                                          | `always`         |
| `paperless.ocr.clean`                              | Tells paperless to use unpaper to clean any input document before sending it to tesseract                                                                                                                     | `true`           |
| `paperless.ocr.deskew`                             | Tells paperless to correct skewing (slight rotation of input images mainly due to improper scanning)                                                                                                          | `true`           |
| `paperless.ocr.rotatePages`                        | Tells paperless to correct page rotation (90°, 180° and 270° rotation)                                                                                                                                        | `true`           |
| `paperless.ocr.rotatePagesThreshold`               | Adjust the threshold for automatic page rotation by paperless.ocr.rotatePages                                                                                                                                 | `12`             |
| `paperless.ocr.outputType`                         | Specify the type of PDF documents that paperless should produce                                                                                                                                               | `pdfa`           |
| `paperless.ocr.pages`                              | Tells paperless to use only the specified amount of pages for OCR. Documents with less than the specified amount of pages get OCR'ed completely                                                               | `""`             |
| `paperless.ocr.imageDPI`                           | Paperless will OCR any images you put into the system and convert them into PDF documents                                                                                                                     | `""`             |
| `paperless.ocr.maxImagePixels`                     | Paperless will raise a warning when OCRing images which are over this limit and will not OCR images which are more than twice this limit                                                                      | `""`             |
| `paperless.ocr.colorConversionStrategy`            | Controls the Ghostscript color conversion strategy when creating the archive file                                                                                                                             | `""`             |
| `paperless.ocr.userArgs`                           | OCRmyPDF offers many more options. Use this parameter to specify any additional arguments you wish to pass to OCRmyPDF                                                                                        | `""`             |
| `paperless.conversion.memoryLimit`                 | On smaller systems, or even in the case of Very Large Documents, the consumer may explode, complaining about how it's "unable to extend pixel cache"                                                          | `""`             |
| `paperless.conversion.tmpDir`                      | Similar to the memory limit, if you've got a small system and your OS mounts /tmp as tmpfs, you should set this to a path that's on a physical disk                                                           | `""`             |
| `paperless.consume.deleteDuplicates`               | Reject and delete duplicate documents on consumption. As of Paperless-ngx 3.0 this is the only thing that                                                                                                     | `false`          |
| `paperless.consume.recursive`                      | Enable recursive watching of the consumption directory                                                                                                                                                        | `false`          |
| `paperless.consume.subdirsAsTags`                  | Set the names of subdirectories as tags for consumed files. E.g. <CONSUMPTION_DIR>/foo/bar/file.pdf will add the tags "foo"                                                                                   | `false`          |
| `paperless.consume.ignorePatterns`                 | By default, paperless ignores certain files and folders in the consumption directory                                                                                                                          | `""`             |
| `paperless.consume.barcodeScanner`                 | Deprecated and has no effect as of Paperless-ngx 3.0 - zxing-cpp is now the only backend                                                                                                                      | `PYZBAR`         |
| `paperless.consume.preConsumeScript`               | After some initial validation, Paperless can trigger an arbitrary script if you like before beginning consumption                                                                                             | `""`             |
| `paperless.consume.postConsumeScript`              | After a document is consumed, Paperless can trigger an arbitrary script if you like                                                                                                                           | `""`             |
| `paperless.consume.filenameDateOrder`              | Paperless will check the document text for document date information                                                                                                                                          | `""`             |
| `paperless.consume.numberOfSuggestedDates`         | Paperless searches an entire document for dates. The first date found will be used as the initial value for the created date                                                                                  | `3`              |
| `paperless.consume.thumbnailFontName`              | Paperless creates thumbnails for plain text files by rendering the content of the file on an image                                                                                                            | `""`             |
| `paperless.consume.ignoreDates`                    | Paperless parses a document's creation date from filename and file content. You may specify a comma separated list of dates that should be ignored during this process                                        | `""`             |
| `paperless.consume.dateOrder`                      | Paperless will try to determine the document creation date from its contents. Specify the date format Paperless should expect to see within your documents                                                    | `""`             |
| `paperless.consume.polling.enabled`                | If paperless won't find documents added to your consume folder, it might not be able to automatically detect filesystem changes                                                                               | `0`              |
| `paperless.consume.polling.retryCount`             | If consumer polling is enabled, sets the maximum number of times paperless will check for a file to remain unmodified                                                                                         | `5`              |
| `paperless.consume.polling.delay`                  | If consumer polling is enabled, sets the delay in seconds between each check (above) paperless will do while waiting for a file to remain unmodified                                                          | `5`              |
| `paperless.consume.iNotify.delay`                  | Sets the time in seconds the consumer will wait for additional events from inotify before the consumer will consider a file ready and begin consumption                                                       | `0.5`            |
| `paperless.consume.barcodes.enabled`               | Enables the scanning and page separation based on detected barcodes                                                                                                                                           | `false`          |
| `paperless.consume.barcodes.tiffSupport`           | Whether TIFF image files should be scanned for barcodes                                                                                                                                                       | `false`          |
| `paperless.consume.barcodes.string`                | Defines the string to be detected as a separator barcode                                                                                                                                                      | `PATCHT`         |
| `paperless.consume.barcodes.enableASNBarcode`      | Enables the detection of barcodes in the scanned document and setting the ASN (archive serial number) if a properly formatted barcode is detected                                                             | `false`          |
| `paperless.consume.barcodes.ASNBarcodePrefix`      | Defines the prefix that is used to identify a barcode as an ASN barcode                                                                                                                                       | `ASN`            |
| `paperless.consume.barcodes.upscale`               | Defines the upscale factor used in barcode detection                                                                                                                                                          | `0.0`            |
| `paperless.consume.barcodes.dpi`                   | During barcode detection every page from a PDF document needs to be converted to an image                                                                                                                     | `300`            |
| `paperless.consume.barcodes.enableTagBarcode`      | Enables the detection of barcodes in the scanned document and assigns or creates tags if a properly formatted barcode is detected                                                                             | `300`            |
| `paperless.consume.barcodes.tagBarcodeMapping`     | Override the default dictionary of filter regular expression and substitute expressions                                                                                                                       | `""`             |
| `paperless.consume.collate.enableDoubleSided`      | Enables automatic collation of two single-sided scans into a double-sided document                                                                                                                            | `false`          |
| `paperless.consume.collate.doubleSidedSubdirName`  | The name of the subdirectory that the collate feature expects documents to arrive                                                                                                                             | `double-sided`   |
| `paperless.consume.collate.doubleSidedTiffSupport` | Whether TIFF image files should be supported when collating documents                                                                                                                                         | `false`          |
| `paperless.binaries.convert`                       | The binary name for `convert`                                                                                                                                                                                 | `convert`        |
| `paperless.binaries.gs`                            | The binary name for `gs`                                                                                                                                                                                      | `convert`        |

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
| `service.port`                     | The port to use on the service                                                          | `8000`      |
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
| `serviceAccount.name`        | A custom name for the service account, otherwise paperless.fullname is used | `""`    |
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

| Name                | Description                                                                                  | Value |
| ------------------- | -------------------------------------------------------------------------------------------- | ----- |
| `resources`         | The resource limits/requests for the Paperless pod                                           | `{}`  |
| `extraEnvVars`      | Extra environment variables for the Paperless pod - use this for any of Paperless-ngx's many | `[]`  |
| `volumes`           | Define volumes for the Paperless pod                                                         | `[]`  |
| `volumeMounts`      | Define volumeMounts for the Paperless pod                                                    | `[]`  |
| `initContainers`    | Define initContainers for the main Paperless server                                          | `[]`  |
| `nodeSelector`      | Node labels for pod assignment                                                               | `{}`  |
| `tolerations`       | Tolerations for pod assignment                                                               | `[]`  |
| `affinity`          | Affinity for pod assignment                                                                  | `{}`  |
| `strategy`          | Specify a deployment strategy for the Paperless pod                                          | `{}`  |
| `podAnnotations`    | Extra annotations for the Paperless pod                                                      | `{}`  |
| `podLabels`         | Extra labels for the Paperless pod                                                           | `{}`  |
| `priorityClassName` | The name of an existing PriorityClass                                                        | `""`  |

### Security context settings

| Name                 | Description                                     | Value |
| -------------------- | ----------------------------------------------- | ----- |
| `podSecurityContext` | Security context settings for the Paperless pod | `{}`  |
| `securityContext`    | General security context settings for           | `{}`  |

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
| `postgresql.auth.username`                       | Name for a custom user to create                                                                                               | `paperless`                  |
| `postgresql.auth.password`                       | Password for the custom user to create. Ignored if `auth.existingSecret` is provided                                           | `paperless`                  |
| `postgresql.auth.database`                       | Name for a custom database to create                                                                                           | `paperless`                  |
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
| `redis.enabled`                             | Enable or disable the Redis&reg; subchart                                                                                      | `true`                  |
| `redis.architecture`                        | Redis&reg; architecture. Allowed values: `standalone` or `replication`                                                         | `standalone`            |
| `redis.auth.password`                       | Redis&reg; password                                                                                                            | `paperless`             |

### Apache&reg; Tika parameters

| Name           | Description                                | Value  |
| -------------- | ------------------------------------------ | ------ |
| `tika.enabled` | Enable or disable the Apache Tika subchart | `true` |

### Ad Noctem Collective Gotenberg parameters

| Name                                             | Description                                                                      | Value   |
| ------------------------------------------------ | -------------------------------------------------------------------------------- | ------- |
| `gotenberg.enabled`                              | Enable or disable the Gotenberg subchart                                         | `true`  |
| `gotenberg.gotenberg.chromium.disableJavaScript` | Disable JavaScript                                                               | `false` |
| `gotenberg.gotenberg.chromium.allowList`         | Set the allowed URLs for Chromium using a regular expression - defaults to 'All' | `""`    |
| `gotenberg.gotenberg.logging.level`              | Choose the level of logging detail                                               | `info`  |
