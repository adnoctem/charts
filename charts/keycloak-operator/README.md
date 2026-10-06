# Ad Noctem Collective - Keycloak Operator Helm Chart <img src="https://raw.githubusercontent.com/keycloak/keycloak-misc/main/logo/logo.png" alt="Keycloak Operator Logo" width="250" height="auto" align="right" loading="lazy"/>

Keycloak is an open source software product to allow single sign-on with identity and access management aimed at modern
applications and services. It supports various protocols such as OpenID, OAuth version 2.0 and SAML and provides
features such as user management, two-factor authentication, permissions and roles management, creating token services,
etc. The [Keycloak Operator](https://github.com/keycloak/keycloak/tree/main/operator) will allow you to deploy dedicated
instances of Keycloak at will using the newly registered
`Keycloak` [CustomResourceDefinition](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/).
This Helm chart packages the
official [upstream manifests](https://github.com/keycloak/keycloak-k8s-resources/blob/26.8.0/kubernetes/kubernetes.yml)
and closely tracks these for changes. Keycloak also provides an experimental upstream Helm chart as of 26.8.0;
this chart remains independently maintained. The Operator is available as a single Docker image
on [quay.io](https://quay.io/repository/keycloak/keycloak-operator).

> Head to the [Keycloak GitHub Repository](https://github.com/keycloak/keycloak) for
> in-depth [documentation](https://www.keycloak.org/guides).

## ✨ TL;DR

### Helm Repository Installation

```shell
helm repo add adnoctem https://adnoctem.github.io/charts
helm install keycloak-operator adnoctem/keycloak-operator --version X.Y.Z
```

### OCI Installation

```shell
helm install oci://ghcr.io/adnoctem/charts/keycloak-operator:X.Y.Z
```

## Introduction

This chart bootstraps a
Keycloak Operator [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) on
a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh/) package manager. For cluster networking
a [Service](https://kubernetes.io/docs/concepts/services-networking/service/) manifest is also created.
The chart creates the [RBAC roles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) (ClusterRoles)
`keycloakrealmimportcontroller-cluster-role`, `keycloakcontroller-cluster-role`, `keycloakoidcclientcontroller-cluster-role`
and `keycloaksamlclientcontroller-cluster-role`, each bound to the operator's ServiceAccount via a namespace-scoped
RoleBinding. These are enabled by default.

> [!IMPORTANT]
> Helm does not upgrade or delete CRDs on `helm upgrade` (see the
> [Helm documentation](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/)) - before upgrading this
> chart, apply its versioned CRDs to your cluster yourself, after reviewing the migration steps below.
> Use server-side apply (`kubectl apply --server-side -f charts/keycloak-operator/crds/` from this repository)
> to avoid the client-side annotation size limit on these large schemas. This is required for the new operator to work
> correctly. This matters most between major CRD schema changes, and whenever new CRDs are added (see the Upgrading
> notes below).

The chart supports configuring the Kubernetes manifests created for the Operator, however modifications are somewhat
discouraged, since the official release for vanilla Kubernetes uses static manifests. The Operator itself does not offer
any sort of configuration (to [my](https://github.com/mvprowess) knowledge). I will try to ensure the chart always matches
the upstream deployment at the given versions.

After deployment the Operator gives you access to the `Keycloak` CR making the deployment of Keycloak (even as a
cluster) as simple as:

```shell
kubectl apply -f - <<EOF
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: example-kc
spec:
  instances: 1
  db:
    vendor: postgres
    host: postgres-db
    usernameSecret:
      name: keycloak-db-secret
      key: username
    passwordSecret:
      name: keycloak-db-secret
      key: password
  http:
    tlsSecret: example-tls-secret
  hostname:
    hostname: test.keycloak.org
  proxy:
    headers: xforwarded
EOF
```

## Upgrading

### To 0.4.0 (Keycloak Operator 26.7.3 -> 26.8.0)

This release updates the Operator and its default managed Keycloak image to 26.8.0. Back up the Keycloak database
and your custom resources, and review the [versioned upstream migration guide][upgrading_2680] before upgrading.
Existing `Keycloak` resources without an explicit `spec.image` follow the Operator's new default server image;
plan for the server's database migrations as well as the Operator update.

Complete these steps before upgrading the Operator:

1. **Update realm-import manifests that link identity providers to organizations.** In both
   `spec.realm.identityProviders` and nested `spec.realm.organizations[].identityProviders`, replace the removed
   `organizationId` field with an `organizationLinks` list. To preserve an existing managed association:

   ```yaml
   organizationLinks:
     - organizationId: "your-organization-id"
       autoMembership: true
       membershipType: MANAGED
   ```

   The server migrates existing database links automatically, but your saved import manifests must use the new
   schema; Kubernetes can prune the removed field. Domain routing now uses each organization's
   `domains[].identityProviderAlias` and `domains[].autoRedirect`. Review domain routing and membership settings
   after the server migration. New organization links default to unmanaged membership.

2. **Label Secrets referenced by OIDC client resources.** Each Secret used by
   `KeycloakOIDCClient.spec.client.auth.secretRef` needs `operator.keycloak.org/kind: KeycloakOIDCClient`.
   Without it, the Operator reports the Secret as missing. Apply the label in the client's namespace:

   ```shell
   kubectl label secret <secret-name> -n <namespace> \
     operator.keycloak.org/kind=KeycloakOIDCClient --overwrite
   ```

3. **Review admin TLS certificates for declarative client management.** The Operator now rejects a CA certificate
   that does not cover the internal Service hostname in its admin TLS trust path. Configure an appropriate
   server certificate for the Service address. Explicitly trusted leaf certificates with an external hostname
   remain supported for TLS passthrough; that exception does not apply to CA certificates. See the
   [tagged controller implementation][client_controller_2680].
4. **Apply all four versioned CRDs before the Helm upgrade.** The Keycloak and realm-import schemas changed;
   the OIDC and SAML client schemas are unchanged but remain required:

   ```shell
   helm show crds adnoctem/keycloak-operator --version 0.4.0 | \
     kubectl apply --server-side -f -
   ```

The Operator now sets a stable cache node name from the Keycloak Pod name. If you use the `stateless` feature,
enable it explicitly (the `preview` feature set no longer enables it) and set a unique `cache-embedded-cluster-name`
through the Keycloak CR's `spec.additionalOptions`; the server refuses to start with the default `ISPN` name.
Login-failure tracking now uses the database by default, which can increase database load. Review the upstream
guide for authentication, authorization, organization and custom-provider changes affecting your deployment.

The chart's new `terminationGracePeriodSeconds` defaults to upstream's 10 seconds, replacing Kubernetes' implicit
30-second default. Set it to `30` to retain the previous shutdown window. Controller RBAC permissions and namespace
watching are unchanged. Declarative client management is now a preview feature; enable `client-admin-api:v2` in
the managed Keycloak CR when using client resources.

### To 0.3.0 (Keycloak Operator 26.0.6 -> 26.7.3)

This is a large range covering multiple Keycloak minor releases, including a heavy security-patch release
(26.7.3 alone fixes over a dozen CVEs). Review the
[upstream upgrading guide](https://www.keycloak.org/docs/latest/upgrading/) for anything affecting your own
`Keycloak`/`KeycloakRealmImport` resources - the items below cover what changed in this chart specifically.

- **Apply the updated CRDs manually before upgrading** (see the note above) - `keycloaks.k8s.keycloak.org` and
  `keycloakrealmimports.k8s.keycloak.org` both gained substantial new schema (nearly 400 new fields combined,
  across the Identity Brokering V2 API, workflows, and other 26.x features), and two entirely new CRDs are now
  bundled: `keycloakoidcclients.k8s.keycloak.org` and `keycloaksamlclients.k8s.keycloak.org`, for declarative
  OIDC/SAML client management. The operator's new controllers for these two CRDs will not start correctly if the
  CRDs aren't present in your cluster.
- RBAC was restructured to match upstream: the operator's namespaced `Role` (`keycloak-operator-role`) has been
  removed and its permissions folded into the `keycloakcontroller-cluster-role` ClusterRole (still bound only via
  a namespace-scoped RoleBinding, so the effective access granted is unchanged). Two new ClusterRoles were added
  for the OIDC/SAML client controllers, and the existing ClusterRoles gained permissions for `ServiceMonitor`,
  `NetworkPolicy`, and pod log access - all new in this operator version.
- Four new environment variables (one per controller) set each controller to watch only its own namespace
  (`QUARKUS_OPERATOR_SDK_CONTROLLERS_*_NAMESPACES: JOSDK_WATCH_CURRENT`) - required for the operator to start
  correctly with this chart's namespace-scoped RBAC; releases before 26.7.x didn't need this set explicitly.
- Fixed the pod annotations referencing an unrelated personal fork (`stianst/keycloak.git`) as the build source,
  and a stale Quarkus version/build timestamp - now reflect the actual 26.7.3 build.
- Fixed a copy-pasted `helm install vaultwarden ...` example in this README, and a stray reference to the
  `keycloak-operator-role` Role that no longer exists.

## Parameters

### Image parameters

| Name                | Description                                                         | Value                        |
| ------------------- | ------------------------------------------------------------------- | ---------------------------- |
| `image.registry`    | The Docker registry to pull the image from                          | `quay.io`                    |
| `image.repository`  | The registry repository to pull the image from                      | `keycloak/keycloak-operator` |
| `image.tag`         | The image tag to pull                                               | `26.8.0`                     |
| `image.digest`      | The image digest to pull                                            | `""`                         |
| `image.pullPolicy`  | The Kubernetes image pull policy                                    | `IfNotPresent`               |
| `image.pullSecrets` | A list of secrets to use for pulling images from private registries | `[]`                         |

### Name overrides

| Name               | Description                                      | Value |
| ------------------ | ------------------------------------------------ | ----- |
| `nameOverride`     | String to partially override kcOperator.fullname | `""`  |
| `fullnameOverride` | String to fully override kcOperator.fullname     | `""`  |

### Operator Pod parameters

| Name                            | Description                                                                           | Value |
| ------------------------------- | ------------------------------------------------------------------------------------- | ----- |
| `terminationGracePeriodSeconds` | Time in seconds for the operator to terminate gracefully, matching upstream's default | `10`  |

### Service parameters

| Name                               | Description                                                                             | Value       |
| ---------------------------------- | --------------------------------------------------------------------------------------- | ----------- |
| `service.type`                     | The type of service to create                                                           | `ClusterIP` |
| `service.port`                     | The port to use on the service                                                          | `80`        |
| `service.nodePort`                 | The Node port to use on the service                                                     | `30080`     |
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

### Service Account parameters

| Name                         | Description                                                                  | Value  |
| ---------------------------- | ---------------------------------------------------------------------------- | ------ |
| `serviceAccount.create`      | Whether a service account should be created                                  | `true` |
| `serviceAccount.automount`   | Whether to automount the service account token                               | `true` |
| `serviceAccount.annotations` | Annotations to add to the service account                                    | `{}`   |
| `serviceAccount.name`        | A custom name for the service account, otherwise kcOperator.fullname is used | `""`   |

### Liveness Probe parameters

| Name                                | Description                                                 | Value  |
| ----------------------------------- | ----------------------------------------------------------- | ------ |
| `livenessProbe.enabled`             | Enable or disable the use of liveness probes                | `true` |
| `livenessProbe.initialDelaySeconds` | Configure the initial delay seconds for the liveness probe  | `5`    |
| `livenessProbe.timeoutSeconds`      | Configure the initial delay seconds for the liveness probe  | `10`   |
| `livenessProbe.periodSeconds`       | Configure the seconds for each period of the liveness probe | `10`   |
| `livenessProbe.successThreshold`    | Configure the success threshold for the liveness probe      | `1`    |
| `livenessProbe.failureThreshold`    | Configure the failure threshold for the liveness probe      | `3`    |

### Readiness Probe parameters

| Name                                 | Description                                                  | Value  |
| ------------------------------------ | ------------------------------------------------------------ | ------ |
| `readinessProbe.enabled`             | Enable or disable the use of readiness probes                | `true` |
| `readinessProbe.initialDelaySeconds` | Configure the initial delay seconds for the readiness probe  | `5`    |
| `readinessProbe.timeoutSeconds`      | Configure the initial delay seconds for the readiness probe  | `10`   |
| `readinessProbe.periodSeconds`       | Configure the seconds for each period of the readiness probe | `10`   |
| `readinessProbe.successThreshold`    | Configure the success threshold for the readiness probe      | `1`    |
| `readinessProbe.failureThreshold`    | Configure the failure threshold for the readiness probe      | `3`    |

### Startup Probe parameters

| Name                               | Description                                                | Value  |
| ---------------------------------- | ---------------------------------------------------------- | ------ |
| `startupProbe.enabled`             | Enable or disable the use of readiness probes              | `true` |
| `startupProbe.initialDelaySeconds` | Configure the initial delay seconds for the startup probe  | `5`    |
| `startupProbe.timeoutSeconds`      | Configure the initial delay seconds for the startup probe  | `10`   |
| `startupProbe.periodSeconds`       | Configure the seconds for each period of the startup probe | `10`   |
| `startupProbe.successThreshold`    | Configure the success threshold for the startup probe      | `1`    |
| `startupProbe.failureThreshold`    | Configure the failure threshold for the startup probe      | `3`    |

<!-- Upgrade references -->

[upgrading_2680]: https://github.com/keycloak/keycloak/blob/26.8.0/docs/documentation/upgrading/topics/changes/changes-26_8_0.adoc
[client_controller_2680]: https://github.com/keycloak/keycloak/blob/26.8.0/operator/src/main/java/org/keycloak/operator/controllers/KeycloakClientBaseController.java
