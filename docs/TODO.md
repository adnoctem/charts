# ✅ Ad Noctem Collective Helm Charts - `TODOs`

## ➕ Additions

- [ ] [Karma (Alertmanager Dashboard)](https://github.com/prymitive/karma) chart
- [ ] [BookStack](https://www.bookstackapp.com/) chart
- [ ] [Mailpit](https://mailpit.axllent.org/) chart
- [x] [GoBackup](https://gobackup.github.io/) chart
- [x] [Kubenav](https://github.com/kubenav/kubenav) chart
- [ ] [Shopware 6](https://github.com/shopware/shopware) chart
- [ ] [Shlink](https://shlink.io/) chart
- [ ] [AnonAddy](https://addy.io/) chart
- [ ] [OpenGist](https://github.com/thomiceli/opengist) chart
- [ ] [FreshRSS](https://freshrss.org/index.html) chart
- [x] [Outline](https://www.getoutline.com/) chart
- [ ] [Metabase](https://metabase.com) chart
- [ ] [DBGate](https://github.com/dbgate/dbgate) chart
- [ ] [Statping-ng](https://github.com/statping-ng/statping-ng/wiki) chart
- [x] [Activepieces](https://www.activepieces.com/docs/install/configurations/environment-variables) chart

> [!NOTE]
> Next charts are `Mailpit`, `Shopware 6`, `Outline` and `Shlink`

## ✏️ Planned Changes

- [ ] Add [Pod/ServiceMonitor and PrometheusRule manifests](https://prometheus-operator.dev/docs/operator/api/) for each
      chart
- [ ] `outline` chart: add an `existingSecret` option for `outline.ssl.key` - currently value-only since this chart
      terminates TLS at the Ingress by default and the setting is a narrow, rarely-used escape hatch, but a real
      private key deserves the same existingSecret pattern every other credential in this chart gets
- [ ] `outline` chart: `outline.redis.collaborationUrl` can't currently be combined with `outline.redis.existingSecret` -
      when an existingSecret is set for the main Redis connection, the chart's own combined Redis Secret (which is
      where `REDIS_COLLABORATION_URL` currently lives) is never created. Needs its own independent existingSecret
      or to be decoupled from the main Redis secret entirely

## 💡 Ideas

- [x] Use [official **Shopware AG** base Docker image](https://github.com/shopware/docker?tab=readme-ov-file) for
      Helm
      chart reference (`shopware-cli`)
- [ ] Support Reverse HTTP Cache for `Shopware 6` chart
      with [prebuilt image](https://github.com/shopware/varnish-shopware/tree/main)
- [ ] Use the [`AUTHORS`](../.github/AUTHORS) file as base for a [`.all-contributorsrc`](https://allcontributors.org/docs/en/overview) file
- [ ] Potentially [install Keycloak Operators CRDs with Hooks](https://handbook.giantswarm.io/docs/dev-and-releng/app-developer-processes/handle_crds_with_helm_3/)

## 🔗 Links
