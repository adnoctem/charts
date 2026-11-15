# Ad Noctem Collective - Glance Helm Chart <img src="https://github.com/glanceapp/glance/blob/main/docs/logo.png?raw=true" alt="Glance Logo" width="128" height="128" align="right" loading="lazy">

Glance is a self-hosted dashboard for feeds, bookmarks, services and homelab monitoring. It supports customizable
page layouts, themes, authentication and a wide range of widgets, including RSS feeds, calendars, repository
releases and custom API integrations. It delivers all of these features within a single Docker image available
on [Docker Hub](https://hub.docker.com/r/glanceapp/glance).

> Head to the [Glance GitHub Repository](https://github.com/glanceapp/glance) for
> in-depth documentation
> and [configuration guides](https://github.com/glanceapp/glance/blob/main/docs/configuration.md).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install glance adnoctem/glance --version X.Y.Z
```

### OCI Installation

```shell
helm install glance oci://ghcr.io/adnoctem/charts/glance --version X.Y.Z
```

## Introduction

This chart bootstraps a Glance [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) on
a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster networking
a [Service](https://kubernetes.io/docs/concepts/services-networking/service/)
and [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) manifest is also created, whereas the
Ingress needs to be explicitly enabled. Lastly the chart configures
a [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) if enabled.
The chart requires Kubernetes 1.26 or later and Helm 3.

The chart supports all documented [Glance configuration options](https://github.com/glanceapp/glance/blob/main/docs/configuration.md)
via the `glance` key in Helm's _values_ and makes use of the official Docker Hub container image, although this is
configurable via the Image Parameters. The default application version is Glance v0.8.8.

## Application configuration

Set application configuration under `glance`, using upstream's native property names.
All 28 documented widget types and their nested configuration fields are supported.
See the [widget reference](#widget-configuration-reference), the commented examples in [values.yaml](values.yaml), and
[Glance's configuration documentation](https://github.com/glanceapp/glance/blob/v0.8.8/docs/configuration.md).
The image is pinned to a release; review upstream configuration changes before overriding it with another version.

Pages, columns and widget lists retain their order. Helm replaces lists rather than merging individual entries.
Each page has one to three columns, including one or two `full` columns. A `slim` page allows at most two columns.
Groups cannot contain other groups or split columns; split columns may contain groups.
YAML anchors work within a values file. Unknown top-level Glance keys may hold anchor definitions.
Widget configuration is passed through to Glance, which validates it at startup.

Custom API templates, HTML, CSS and included files are emitted literally: the chart never calls Helm's `tpl` on them.
Arbitrary custom API request bodies, options and subrequests retain their data types, including null, false and zero.
Glance variable substitutions are preserved in widget fields and resolved by Glance at runtime.
`glance.server.port` must be a literal integer and `assets-path` a literal container path because they also configure Kubernetes resources.

### Authentication and secrets

Authentication is disabled until `glance.auth.users` contains users. Each user requires exactly one of `password` or `password-hash`.
Generate a signing key with `glance secret:make`, and hashes with `glance password:hash <password>`.
Use an existing Secret for credentials:

```yaml
glance:
  auth:
    secret-key: ${secret:auth-key}
    users:
      admin:
        password-hash: ${secret:admin-password-hash}
secretFiles:
  - name: glance-credentials
    items:
      - key: signing-key
        path: auth-key
      - key: admin-hash
        path: admin-password-hash
```

Create `glance-credentials` separately in the release namespace. Selected keys are projected under `/run/secrets`.
Paths must be unique across all projected Secrets. This mechanism works for every widget token/password field.
`extraEnvVars` accepts Kubernetes `valueFrom` references for `${NAME}` substitutions; `extraEnvVarsSecret` and
`extraEnvVarsConfigMap` expose whole resources via `envFrom`. `${readFileFromEnv:NAME}` works with an environment
variable holding a file path and a corresponding entry in `volumes`/`volumeMounts`.

The chart renders `glance` into a ConfigMap: literal credentials placed there are not automatically moved to a Secret.
Keep credential values in external Secrets. Helm also stores supplied values in its release history.
The chart creates no credentials and performs no cluster lookups.

### Included and external configuration

For `$include`, add literal files to `config.files`:

```yaml
glance:
  pages:
    - $include: home.yml
config:
  files:
    home.yml: |
      - name: Home
        columns:
          - size: full
            widgets:
              - type: calendar
```

Included list fragments must contain their own leading dashes. Glance performs inclusion before YAML parsing.
Includes are supported in page, column and widget lists; included contents are validated by Glance rather than Helm.
Use `config.existingConfigMap` or `config.existingSecret` for a complete configuration, including more complex include arrangements.
Either source must contain `glance.yml` and every referenced sibling file. Only one external source is allowed;
`config.files` cannot be combined with an external source. Generated `glance` configuration is bypassed in this mode.
Keep `glance.server.port` and `glance.server.assets-path` aligned with the external file so probes, ports and mounts match.

Configuration is mounted as a directory. Chart-managed configuration and asset changes roll pods on Helm upgrades.
External ConfigMap, Secret and PVC content changes do not alter the pod checksum; explicitly restart the Deployment after changing them:

```shell
kubectl --namespace glance rollout restart deployment/glance
```

Glance supports file watching, but Kubernetes projected-volume update behavior is not guaranteed to trigger its watcher.
Environment changes require a restart. Glance validates configuration at startup and rejects invalid configurations.

### Assets and persistence

`assets.files` creates a ConfigMap for text assets such as CSS, JavaScript and SVG. Set
`glance.theme.custom-css-file: /assets/user.css` to use a `user.css` entry.
Alternatively use `assets.existingConfigMap` (including `binaryData` for binary assets) or `assets.existingClaim`.
Only one asset source is allowed. Files mount at `glance.server.assets-path` and are served under `/assets/`.
With no asset source, an empty directory is mounted so the default assets path exists.
Use an existing PVC for large asset collections; ConfigMaps have Kubernetes size limits.

Glance requires no database or application data PVC. Widget caches and authentication rate limits are per process.
To-do items live in the browser's local storage; mounting a server volume does not synchronize them.
Multiple replicas have independent caches and rate limits. Use a shared signing key when authentication is enabled.

### Networking and monitoring

Set `glance.server.proxied: true` when a trusted reverse proxy supplies forwarded headers.
For a subpath, set `glance.server.base-url` and configure the ingress controller to strip the prefix before forwarding.
The chart does not infer controller-specific rewrite annotations. Direct port-forwarding reaches the backend at `/`;
subpath deployments should be accessed through their configured reverse proxy.
Ingress TLS terminates at the ingress controller; Glance serves HTTP inside the pod.

TCP startup, readiness and liveness probes use the named HTTP port and work independently of authentication and URL prefixes.
They check the listener, not individual widget data sources. Glance needs network access to whichever feeds/APIs its widgets use.

Docker monitoring is opt-in via `dockerSocket.enabled`. It requires a Docker daemon on the selected node and matching
widget `sock-path`. It does not discover Kubernetes pods on containerd or CRI-O. A Docker socket grants host control,
even through a read-only mount. Configure scheduling and socket permissions for your environment.
Local server statistics reflect the container's visible environment. Remote statistics require a separately deployed
[Glance Agent](https://github.com/glanceapp/agent); configure its URL and token in a `server-stats` widget.

## Local installation

To install from this checkout and access the dashboard locally:

```shell
helm install glance ./charts/glance --namespace glance --create-namespace
kubectl --namespace glance port-forward svc/glance 8080:8080
```

Open <http://localhost:8080>. Repository and OCI installation become available after the chart is published.

## Upgrading

### To 0.2.0 (Glance v0.8.6 -> v0.8.8)

[Glance v0.8.7](https://github.com/glanceapp/glance/releases/tag/v0.8.7) restores Reddit feeds after upstream API
changes, but Reddit widget `search` now requires `app-auth`. Configure the Reddit application's `name`, `id` and
`secret` in each affected widget, using environment or Secret-file substitutions for credentials as described
above. Alternatively, remove `search` to display the unfiltered subreddit feed. Check included files and external
configuration sources as well as widgets in `glance.pages`.

[Glance v0.8.8](https://github.com/glanceapp/glance/releases/tag/v0.8.8) fixes release, search, markets,
change-detection and Docker widgets and adds security hardening. Across these releases, authentication request
bodies are limited to 512 KiB, and several widget response readers (including RSS, custom API, extension and shared
JSON requests) reject responses larger than 10 MiB. If a widget reports a response-size error, reduce the upstream
payload, for example through pagination or filtering. The HTTP server now limits header reads to five seconds
and request reads to ten seconds; unusually slow clients or proxies may need adjustment.

The chart's values interface, ports and mounts are unchanged, and no database migration is required. The optional
search widget also accepts `brave` as a search engine. `image.tag` remains empty by default, selecting `Chart.appVersion`;
existing explicit tag or digest overrides still take precedence.

## Widget configuration reference

Place widgets in `glance.pages[].columns[].widgets` or `glance.pages[].head-widgets`.
All 28 documented widget types are supported, including nested widgets.
Glance resolves `${NAME}`, `${secret:name}` and `${readFileFromEnv:NAME}` substitutions at runtime.

See [upstream configuration](https://github.com/glanceapp/glance/blob/v0.8.8/docs/configuration.md)
for behavior, defaults and examples. The commented examples in `values.yaml` cover every widget.

Every widget accepts `title`, `title-url`, `hide-header`, `cache` and `css-class`.

### rss

| Field                | Type                                                                  | Required |
| -------------------- | --------------------------------------------------------------------- | -------- |
| `thumbnail-height`   | number                                                                | no       |
| `card-height`        | number                                                                | no       |
| `limit`              | integer                                                               | no       |
| `preserve-order`     | boolean                                                               | no       |
| `single-line-titles` | boolean                                                               | no       |
| `collapse-after`     | integer                                                               | no       |
| `style`              | vertical-list / detailed-list / horizontal-cards / horizontal-cards-2 | no       |
| `feeds`              | array of feed                                                         | yes      |

### videos

| Field                 | Type                                          | Required |
| --------------------- | --------------------------------------------- | -------- |
| `channels`            | array of string                               | no       |
| `playlists`           | array of string                               | no       |
| `limit`               | integer                                       | no       |
| `collapse-after`      | integer                                       | no       |
| `collapse-after-rows` | integer                                       | no       |
| `include-shorts`      | boolean                                       | no       |
| `video-url-template`  | string                                        | no       |
| `style`               | horizontal-cards / grid-cards / vertical-list | no       |

### hacker-news

| Field                   | Type             | Required |
| ----------------------- | ---------------- | -------- |
| `limit`                 | integer          | no       |
| `collapse-after`        | integer          | no       |
| `comments-url-template` | string           | no       |
| `extra-sort-by`         | string           | no       |
| `sort-by`               | top / new / best | no       |

### lobsters

| Field            | Type            | Required |
| ---------------- | --------------- | -------- |
| `instance-url`   | string          | no       |
| `custom-url`     | string          | no       |
| `limit`          | integer         | no       |
| `collapse-after` | integer         | no       |
| `sort-by`        | string          | no       |
| `tags`           | array of string | no       |

### reddit

`search` requires `app-auth`; use Secret-file or environment substitutions for the application credentials.

| Field                   | Type                                              | Required |
| ----------------------- | ------------------------------------------------- | -------- |
| `subreddit`             | string                                            | yes      |
| `show-thumbnails`       | boolean                                           | no       |
| `show-flairs`           | boolean                                           | no       |
| `limit`                 | integer                                           | no       |
| `collapse-after`        | integer                                           | no       |
| `comments-url-template` | string                                            | no       |
| `request-url-template`  | string                                            | no       |
| `sort-by`               | string                                            | no       |
| `top-period`            | string                                            | no       |
| `search`                | string                                            | no       |
| `extra-sort-by`         | string                                            | no       |
| `style`                 | vertical-list / horizontal-cards / vertical-cards | no       |
| `proxy`                 | string or object                                  | no       |
| `app-auth`              | object                                            | no       |

### search

| Field           | Type          | Required |
| --------------- | ------------- | -------- |
| `search-engine` | string        | no       |
| `new-tab`       | boolean       | no       |
| `autofocus`     | boolean       | no       |
| `target`        | string        | no       |
| `placeholder`   | string        | no       |
| `bangs`         | array of bang | no       |

### group

| Field     | Type                | Required |
| --------- | ------------------- | -------- |
| `widgets` | array of groupChild | yes      |
| `define`  | any                 | no       |

### split-column

| Field         | Type            | Required |
| ------------- | --------------- | -------- |
| `max-columns` | integer         | no       |
| `widgets`     | array of widget | yes      |
| `define`      | any             | no       |

### custom-api

| Field                  | Type                                               | Required |
| ---------------------- | -------------------------------------------------- | -------- |
| `frameless`            | boolean                                            | no       |
| `template`             | string                                             | yes      |
| `options`              | object                                             | no       |
| `url`                  | string                                             | no       |
| `headers`              | object                                             | no       |
| `body`                 | any                                                | no       |
| `allow-insecure`       | boolean                                            | no       |
| `skip-json-validation` | boolean                                            | no       |
| `method`               | GET / POST / PUT / PATCH / DELETE / OPTIONS / HEAD | no       |
| `body-type`            | json / string                                      | no       |
| `basic-auth`           | basicAuth                                          | no       |
| `parameters`           | object                                             | no       |
| `subrequests`          | object                                             | no       |

### extension

| Field                              | Type    | Required |
| ---------------------------------- | ------- | -------- |
| `url`                              | string  | yes      |
| `fallback-content-type`            | string  | no       |
| `allow-potentially-dangerous-html` | boolean | no       |
| `headers`                          | object  | no       |
| `parameters`                       | object  | no       |

### weather

| Field            | Type              | Required |
| ---------------- | ----------------- | -------- |
| `location`       | string            | yes      |
| `hide-location`  | boolean           | no       |
| `show-area-name` | boolean           | no       |
| `units`          | metric / imperial | no       |
| `hour-format`    | 12h / 24h         | no       |

### to-do

| Field | Type   | Required |
| ----- | ------ | -------- |
| `id`  | string | no       |

### monitor

| Field               | Type          | Required |
| ------------------- | ------------- | -------- |
| `style`             | string        | no       |
| `show-failing-only` | boolean       | no       |
| `sites`             | array of site | yes      |

### releases

| Field              | Type             | Required |
| ------------------ | ---------------- | -------- |
| `show-source-icon` | boolean          | no       |
| `token`            | string           | no       |
| `gitlab-token`     | string           | no       |
| `limit`            | integer          | no       |
| `collapse-after`   | integer          | no       |
| `repositories`     | array of release | yes      |

### docker-containers

| Field                    | Type    | Required |
| ------------------------ | ------- | -------- |
| `hide-by-default`        | boolean | no       |
| `format-container-names` | boolean | no       |
| `sock-path`              | string  | no       |
| `category`               | string  | no       |
| `running-only`           | boolean | no       |
| `containers`             | object  | no       |

### dns-stats

| Field              | Type                         | Required |
| ------------------ | ---------------------------- | -------- |
| `allow-insecure`   | boolean                      | no       |
| `url`              | string                       | yes      |
| `username`         | string                       | no       |
| `password`         | string                       | no       |
| `token`            | string                       | no       |
| `hide-graph`       | boolean                      | no       |
| `hide-top-domains` | boolean                      | no       |
| `service`          | pihole / pihole-v6 / adguard | no       |
| `hour-format`      | 12h / 24h                    | no       |

### server-stats

| Field     | Type            | Required |
| --------- | --------------- | -------- |
| `servers` | array of server | no       |

### repository

| Field                 | Type    | Required |
| --------------------- | ------- | -------- |
| `repository`          | string  | yes      |
| `token`               | string  | no       |
| `pull-requests-limit` | integer | no       |
| `issues-limit`        | integer | no       |
| `commits-limit`       | integer | no       |

### bookmarks

| Field    | Type                   | Required |
| -------- | ---------------------- | -------- |
| `groups` | array of bookmarkGroup | yes      |

### change-detection

| Field            | Type            | Required |
| ---------------- | --------------- | -------- |
| `instance-url`   | string          | no       |
| `token`          | string          | no       |
| `limit`          | integer         | no       |
| `collapse-after` | integer         | no       |
| `watches`        | array of string | no       |

### clock

| Field         | Type              | Required |
| ------------- | ----------------- | -------- |
| `hour-format` | 12h / 24h         | no       |
| `timezones`   | array of timezone | no       |

### calendar

| Field               | Type                                                                 | Required |
| ------------------- | -------------------------------------------------------------------- | -------- |
| `first-day-of-week` | monday / tuesday / wednesday / thursday / friday / saturday / sunday | no       |

### calendar-legacy

| Field          | Type    | Required |
| -------------- | ------- | -------- |
| `start-sunday` | boolean | no       |

### markets

| Field                  | Type            | Required |
| ---------------------- | --------------- | -------- |
| `sort-by`              | string          | no       |
| `chart-link-template`  | string          | no       |
| `symbol-link-template` | string          | no       |
| `markets`              | array of market | yes      |

### twitch-channels

| Field            | Type            | Required |
| ---------------- | --------------- | -------- |
| `channels`       | array of string | yes      |
| `collapse-after` | integer         | no       |
| `sort-by`        | string          | no       |

### twitch-top-games

| Field            | Type            | Required |
| ---------------- | --------------- | -------- |
| `exclude`        | array of string | no       |
| `limit`          | integer         | no       |
| `collapse-after` | integer         | no       |

### iframe

| Field    | Type    | Required |
| -------- | ------- | -------- |
| `source` | string  | yes      |
| `height` | integer | no       |

### html

| Field    | Type   | Required |
| -------- | ------ | -------- |
| `source` | string | yes      |

### basicAuth

| Field      | Type   | Required |
| ---------- | ------ | -------- |
| `username` | string | yes      |
| `password` | string | yes      |

### feed

| Field                   | Type    | Required |
| ----------------------- | ------- | -------- |
| `url`                   | string  | yes      |
| `title`                 | string  | no       |
| `hide-categories`       | boolean | no       |
| `hide-description`      | boolean | no       |
| `limit`                 | integer | no       |
| `item-link-prefix`      | string  | no       |
| `thumbnail-link-prefix` | string  | no       |
| `headers`               | object  | no       |

### bang

| Field      | Type   | Required |
| ---------- | ------ | -------- |
| `title`    | string | no       |
| `shortcut` | string | yes      |
| `url`      | string | yes      |

### site

| Field              | Type             | Required |
| ------------------ | ---------------- | -------- |
| `title`            | string           | yes      |
| `url`              | string           | yes      |
| `check-url`        | string           | no       |
| `error-url`        | string           | no       |
| `icon`             | string           | no       |
| `timeout`          | string           | no       |
| `allow-insecure`   | boolean          | no       |
| `same-tab`         | boolean          | no       |
| `alt-status-codes` | array of integer | no       |
| `basic-auth`       | basicAuth        | no       |

### link

| Field         | Type    | Required |
| ------------- | ------- | -------- |
| `title`       | string  | yes      |
| `url`         | string  | yes      |
| `description` | string  | no       |
| `icon`        | string  | no       |
| `same-tab`    | boolean | no       |
| `hide-arrow`  | boolean | no       |
| `target`      | string  | no       |

### bookmarkGroup

| Field        | Type          | Required |
| ------------ | ------------- | -------- |
| `title`      | string        | no       |
| `color`      | string        | no       |
| `same-tab`   | boolean       | no       |
| `hide-arrow` | boolean       | no       |
| `target`     | string        | no       |
| `links`      | array of link | yes      |

### market

| Field         | Type   | Required |
| ------------- | ------ | -------- |
| `symbol`      | string | yes      |
| `name`        | string | no       |
| `symbol-link` | string | no       |
| `chart-link`  | string | no       |

### timezone

| Field      | Type   | Required |
| ---------- | ------ | -------- |
| `timezone` | string | yes      |
| `label`    | string | no       |

### dockerContainer

| Field         | Type    | Required |
| ------------- | ------- | -------- |
| `name`        | string  | no       |
| `icon`        | string  | no       |
| `url`         | string  | no       |
| `same-tab`    | boolean | no       |
| `description` | string  | no       |
| `hide`        | boolean | no       |
| `id`          | string  | no       |
| `parent`      | string  | no       |
| `category`    | string  | no       |

### mountpoint

| Field  | Type    | Required |
| ------ | ------- | -------- |
| `name` | string  | no       |
| `hide` | boolean | no       |

### request

| Field                  | Type                                               | Required |
| ---------------------- | -------------------------------------------------- | -------- |
| `url`                  | string                                             | no       |
| `headers`              | object                                             | no       |
| `body`                 | any                                                | no       |
| `allow-insecure`       | boolean                                            | no       |
| `skip-json-validation` | boolean                                            | no       |
| `method`               | GET / POST / PUT / PATCH / DELETE / OPTIONS / HEAD | no       |
| `body-type`            | json / string                                      | no       |
| `basic-auth`           | basicAuth                                          | no       |
| `parameters`           | object                                             | no       |

### themePreset

| Field                        | Type    | Required |
| ---------------------------- | ------- | -------- |
| `light`                      | boolean | no       |
| `background-color`           | string  | no       |
| `primary-color`              | string  | no       |
| `positive-color`             | string  | no       |
| `negative-color`             | string  | no       |
| `contrast-multiplier`        | number  | no       |
| `text-saturation-multiplier` | number  | no       |

### user

| Field           | Type   | Required |
| --------------- | ------ | -------- |
| `password`      | string | no       |
| `password-hash` | string | no       |

### Server statistics entries

Local servers accept `type: local`, `name`, `hide-swap`, `cpu-temp-sensor`,
`hide-mountpoints-by-default` and a `mountpoints` map. Each mountpoint accepts `name` and `hide`.

Remote servers accept `type: remote`, `name`, `hide-swap`, `url`, `token` and `timeout`.
A remote URL is required. Deploy Glance Agent separately.

## Parameters

### Image parameters

| Name                | Description                            | Value              |
| ------------------- | -------------------------------------- | ------------------ |
| `image.registry`    | Container image registry               | `docker.io`        |
| `image.repository`  | Glance image repository                | `glanceapp/glance` |
| `image.tag`         | Image tag; empty uses Chart.appVersion | `""`               |
| `image.digest`      | Image digest override                  | `""`               |
| `image.pullPolicy`  | Kubernetes image pull policy           | `IfNotPresent`     |
| `image.pullSecrets` | Existing image pull secret names       | `[]`               |

### Name overrides

| Name               | Description                        | Value |
| ------------------ | ---------------------------------- | ----- |
| `nameOverride`     | Partially override glance.fullname | `""`  |
| `fullnameOverride` | Fully override glance.fullname     | `""`  |

### Glance configuration parameters

| Name                                      | Description                                                                         | Value         |
| ----------------------------------------- | ----------------------------------------------------------------------------------- | ------------- |
| `glance.server.host`                      | Listen address inside the pod                                                       | `0.0.0.0`     |
| `glance.server.port`                      | HTTP listen port; also used for the container port and probes                       | `8080`        |
| `glance.server.proxied`                   | Trust forwarded request headers; enable behind a correctly configured reverse proxy | `false`       |
| `glance.server.base-url`                  | External URL prefix, e.g. /glance; the reverse proxy must strip this prefix         | `""`          |
| `glance.server.assets-path`               | Directory served at /assets/; must match the assets mount path                      | `/app/assets` |
| `glance.auth.secret-key`                  | Session signing secret or Glance substitution; required when users are configured   | `""`          |
| `glance.auth.users`                       | Username-keyed users; each has password OR password-hash (strings)                  | `{}`          |
| `glance.document.head`                    | HTML inserted into the head of every page                                           | `""`          |
| `glance.branding.hide-footer`             | Hide the application footer                                                         | `false`       |
| `glance.branding.custom-footer`           | Footer HTML                                                                         | `""`          |
| `glance.branding.logo-text`               | Navigation logo text                                                                | `G`           |
| `glance.branding.logo-url`                | Navigation logo URL; takes precedence over logo-text                                | `""`          |
| `glance.branding.favicon-url`             | Browser favicon URL                                                                 | `""`          |
| `glance.branding.app-name`                | Browser and progressive web app name                                                | `Glance`      |
| `glance.branding.app-icon-url`            | Progressive web app icon URL (512 by 512 PNG); empty retains upstream icon          | `""`          |
| `glance.branding.app-background-color`    | Progressive web app CSS background color; empty retains upstream color              | `""`          |
| `glance.theme.light`                      | Use text colors suited to a light background                                        | `false`       |
| `glance.theme.background-color`           | Background color as space-separated HSL components                                  | `240 8 9`     |
| `glance.theme.primary-color`              | Primary HSL color                                                                   | `43 50 70`    |
| `glance.theme.positive-color`             | Positive HSL color; null inherits primary-color                                     | `nil`         |
| `glance.theme.negative-color`             | Negative HSL color                                                                  | `0 70 70`     |
| `glance.theme.contrast-multiplier`        | Text contrast multiplier                                                            | `1`           |
| `glance.theme.text-saturation-multiplier` | Text saturation multiplier                                                          | `1`           |
| `glance.theme.custom-css-file`            | External CSS URL or an /assets/ URL                                                 | `""`          |
| `glance.theme.disable-picker`             | Disable theme switching                                                             | `false`       |
| `glance.theme.presets`                    | Named themes, including default-dark/default-light overrides                        | `{}`          |
| `glance.pages`                            | ] Ordered pages, each with one to three columns and one or two full columns         | `""`          |

### Configuration file parameters

| Name                       | Description                                                                   | Value |
| -------------------------- | ----------------------------------------------------------------------------- | ----- |
| `config.existingConfigMap` | Existing ConfigMap containing glance.yml and optional included files          | `""`  |
| `config.existingSecret`    | Existing Secret containing glance.yml and optional included files             | `""`  |
| `config.files`             | Additional filename-to-string entries for $include, mounted beside glance.yml | `{}`  |

### Asset parameters

| Name                       | Description                                                                                     | Value  |
| -------------------------- | ----------------------------------------------------------------------------------------------- | ------ |
| `assets.files`             | Filename-to-string assets (CSS, JavaScript, SVG), mounted at glance.server.assets-path          | `{}`   |
| `assets.existingConfigMap` | Existing assets ConfigMap (data or binaryData); mutually exclusive with files and existingClaim | `""`   |
| `assets.existingClaim`     | Existing PVC containing assets; mutually exclusive with files and existingConfigMap             | `""`   |
| `assets.readOnly`          | Mount assets read-only                                                                          | `true` |

### Secret substitution parameters

| Name                    | Description                                                                                 | Value |
| ----------------------- | ------------------------------------------------------------------------------------------- | ----- |
| `secretFiles`           | Existing Secrets projected together under /run/secrets for ${secret:filename}               | `[]`  |
| `extraEnvVars`          | Kubernetes EnvVar entries for user-defined ${NAME} or ${readFileFromEnv:NAME} substitutions | `[]`  |
| `extraEnvVarsSecret`    | Existing Secret to expose using envFrom                                                     | `""`  |
| `extraEnvVarsConfigMap` | Existing ConfigMap to expose using envFrom                                                  | `""`  |

### Docker integration parameters

| Name                     | Description                                                | Value                  |
| ------------------------ | ---------------------------------------------------------- | ---------------------- |
| `dockerSocket.enabled`   | Mount a node's Docker socket for docker-containers widgets | `false`                |
| `dockerSocket.hostPath`  | Docker socket path on the selected node                    | `/var/run/docker.sock` |
| `dockerSocket.mountPath` | Docker socket path inside Glance                           | `/var/run/docker.sock` |

### ConfigMap parameters

| Name                    | Description                                                      | Value |
| ----------------------- | ---------------------------------------------------------------- | ----- |
| `configMap.annotations` | Annotations for chart-managed configuration and asset ConfigMaps | `{}`  |
| `configMap.labels`      | Labels for chart-managed configuration and asset ConfigMaps      | `{}`  |

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
| `service.ports.http`               | HTTP Service port; targets glance.server.port            | `8080`      |
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

| Name                | Description                                                                       | Value |
| ------------------- | --------------------------------------------------------------------------------- | ----- |
| `replicaCount`      | Deployment replicas; caches and authentication rate limits are per process        | `1`   |
| `strategy`          | Deployment update strategy                                                        | `{}`  |
| `resources`         | Container resource requests and limits                                            | `{}`  |
| `volumes`           | Additional pod volumes, e.g. secret files, certificates or host statistics mounts | `[]`  |
| `volumeMounts`      | Additional Glance container mounts                                                | `[]`  |
| `initContainers`    | Init containers, e.g. to populate an asset volume                                 | `[]`  |
| `nodeSelector`      | Node labels for pod placement                                                     | `{}`  |
| `tolerations`       | Pod tolerations                                                                   | `[]`  |
| `affinity`          | Pod affinity and anti-affinity                                                    | `{}`  |
| `podAnnotations`    | Extra pod annotations                                                             | `{}`  |
| `podLabels`         | Extra pod labels                                                                  | `{}`  |
| `priorityClassName` | Existing PriorityClass name                                                       | `""`  |

### Security context settings

| Name                 | Description                                                          | Value |
| -------------------- | -------------------------------------------------------------------- | ----- |
| `podSecurityContext` | Pod security context; adjust for asset and Docker socket permissions | `{}`  |
| `securityContext`    | Container security context                                           | `{}`  |

### Probe parameters

| Name                                 | Description                                                  | Value  |
| ------------------------------------ | ------------------------------------------------------------ | ------ |
| `livenessProbe.enabled`              | Enable TCP liveness checking                                 | `true` |
| `livenessProbe.initialDelaySeconds`  | Initial liveness delay                                       | `0`    |
| `livenessProbe.timeoutSeconds`       | Liveness timeout                                             | `1`    |
| `livenessProbe.periodSeconds`        | Liveness interval                                            | `10`   |
| `livenessProbe.successThreshold`     | Successful checks required                                   | `1`    |
| `livenessProbe.failureThreshold`     | Failed checks before restart                                 | `3`    |
| `readinessProbe.enabled`             | Enable TCP readiness checking                                | `true` |
| `readinessProbe.initialDelaySeconds` | Initial readiness delay                                      | `0`    |
| `readinessProbe.timeoutSeconds`      | Readiness timeout                                            | `1`    |
| `readinessProbe.periodSeconds`       | Readiness interval                                           | `10`   |
| `readinessProbe.successThreshold`    | Successful checks required                                   | `1`    |
| `readinessProbe.failureThreshold`    | Failed checks before removing the pod from Service endpoints | `3`    |
| `startupProbe.enabled`               | Enable TCP startup checking                                  | `true` |
| `startupProbe.initialDelaySeconds`   | Initial startup delay                                        | `0`    |
| `startupProbe.timeoutSeconds`        | Startup timeout                                              | `1`    |
| `startupProbe.periodSeconds`         | Startup interval                                             | `5`    |
| `startupProbe.successThreshold`      | Successful checks required                                   | `1`    |
| `startupProbe.failureThreshold`      | Failed checks allowed during startup                         | `30`   |

### PodDisruptionBudget parameters

| Name                                 | Description                                                    | Value   |
| ------------------------------------ | -------------------------------------------------------------- | ------- |
| `podDisruptionBudget.enabled`        | Create a PodDisruptionBudget                                   | `false` |
| `podDisruptionBudget.minAvailable`   | Minimum available pods; set null when using maxUnavailable     | `1`     |
| `podDisruptionBudget.maxUnavailable` | Maximum unavailable pods; mutually exclusive with minAvailable | `nil`   |
