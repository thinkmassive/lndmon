# Prometheus Mixins for lndmon

This directory a set of Grafana dashboards in the modular [Monitoring
Mixins](https://monitoring.mixins.dev/) format.

## Quickstart

These instructions assume you have a recent version of `go` installed.

Install tooling:
```shell
go install github.com/google/go-jsonnet/cmd/jsonnet@latest
go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
go install github.com/monitoring-mixins/mixtool/cmd/mixtool@main

jb init
jb install https://github.com/grafana/grafonnet-lib/grafonnet
```

Generate dashboards:
```shell
cd grafana/lndmon-mixin

mixtool generate dashboards mixin.libsonnet --directory dashboards_out
```
Generated dashboards are saved in [`dashboards_out/`](dashboards_out)

These can be imported into Grafana, or used to generate ConfigMaps by
your kubernetes tooling, etc.

---

## Dev Tooling
- make
- [go](https://go.dev/)
- [jsonnet](https://jsonnet.org/)
- [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler) (jb)
- [mixtool](https://github.com/monitoring-mixins/mixtool)

---

## Mixin Development Notes

Resolves [lightninglabs/lndmon #90](https://github.com/lightninglabs/lndmon/issues/90): Prometheus monitoring mixin

### Dev Environment

- [Lightning Polar](https://docs.lightning.engineering/lapps/guides/polar-lapps/local-cluster-setup-with-polar)
  - Install the appropriate [release](https://github.com/jamaljsr/polar/releases/), or download the AppImage
  - Fix "Docker not found" error ([known issue](https://github.com/jamaljsr/polar/issues/553#issuecomment-1234702655))
    - `echo 'docker compose --compatibility "$@"' > ~/.local/bin/docker-compose && chmod +x ~/.local/bin/docker-compose`
  - Add lnd v0.15.5 image (TODO document exact steps)
  - Create a new Lightning Network, then click Start
    - Name: lndmonNet
    - Containers: 2 LND 0.15.5, 0 CoreLN, 0 Eclair, 1 bitcoind
  - Perform the following steps under the Actions tab for each container:
    - `backend1` (bitcoind): mine 100 blocks
    - `alice`: deposit `1,000,000` sats, open outgoing channel channel to `bob` w/`500,000`
    - `bob`: deposit `1,000,000` sats, open private outgoing channel to `alice` w/`500,000`
    - quick mine
- [lndmon](https://github.com/lightninglabs/lndmon)
  - Clone the fork repo: `git clone https://github.com/thinkmassive/lndmon`
  - Change to that dir: `cd lndmon`
    - all remaining commands are run from here unless specified otherwise

### Define common environment variables

Adjust these variables to match your environment. They will be used
throughout this exercise.

```shell
POLAR_DIR="$HOME/.polar"
POLAR_NETWORK=2
POLAR_NETWORK_DIR="$POLAR_DIR/networks/$POLAR_NETWORK"
LND_DIR="$POLAR_NETWORK_DIR/volumes/lnd/alice"
LNDMON_DIR="$HOME/workspace/LightningLabs/lndmon"

TLS_CERT_PATH="$LND_DIR/tls.cert"
MACAROON_PATH="$LND_DIR/data/chain/bitcoin/regtest"
```

### Enable prometheus metrics endpoint for alice node

Get `alice` docker interface IP:
```
ALICE_DOCKER_IP=$(docker network inspect 2_default | \
  jq -r '.[0].Containers[] | select(.Name | contains("alice")) | .IPv4Address' | \
  awk -F/ '{print $1}')
ALICE_LND_RPC=$ALICE_DOCKER_IP:10009
```

Manually enable prometheus metrics for `polar-n1-alice` in `$POLAR_NETWORK_DIR/docker-compose.yml`
- append to `command`: `--prometheus.enable --prometheus.listen=0.0.0.0:8989`
- append to `command`: `--tlsextraip=$ALICE_DOCKER_IP`
- append to `expose`: `'8989'`
- append to `ports`: `'8989:8989'`

Restart polar containers: `cd $POLAR_NETWORK_DIR && docker-compose up`

Verification:
  - Confirm lnd metrics are available: `curl localhost:8989/metrics`
  - Confirm you can generate an invoice and pay it from the other node (use Polar "Actions")

### Configure lndmon

```shell
cd $LNDMON_DIR

# Update env vars with alice node details:
sed -i 's/LND_HOST=.*/LND_HOST=alice:10009' .env
sed -i 's/LND_NETWORK=.*/LND_NETWORK=regtest/' .env
sed -i "s|^TLS_CERT_PATH=.*|TLS_CERT_PATH=$TLS_CERT_PATH|" .env
sed -i "s|^MACAROON_PATH=.*|MACAROON_PATH=$MACAROON_PATH|" .env

# Add the docker network used by Polar:
echo -e "\nnetworks:\n  default:\n    external: true\n    name: ${POLAR_NETWORK}_default" >> docker-compose.yml
```

References
- [polar 525](https://github.com/jamaljsr/polar/issues/525): define persistent docker network

### Start lndmon

```shell
docker compose up

# Get IPs for Grafana and Prometheus
GRAFANA_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lndmon-grafana-1)
PROMETHEUS_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lndmon-prometheus-1)

echo "Grafana: http://$GRAFANA_IP:3000 (u/p: admin / admin )"
echo "Prometheus: http://$PROMETHEUS_IP:9090"
```

## Mixin development

### Scaffolding

```shell
mkdir grafana/lndmon-mixin && cd grafana/lndmon-mixin
mkdir alerts dashboards rules

cat <<EOF > mixin.libsonnet
// Prometheus Mixin
// Follows the kubernetes-mixin project pattern here: https://github.com/kubernetes-monitoring/kubernetes-mixin
// Mixin design doc: https://raw.githubusercontent.com/monitoring-mixins/docs/master/design.pdf

// This file will be imported during build for all Promethei

(import 'config.libsonnet') +
(import 'alerts/alerts.libsonnet') +
(import 'dashboards/dashboards.libsonnet') +
(import 'rules/rules.libsonnet')
EOF

cat <<EOF > config.libsonnet
// lndmon Prometheus Mixin Config
{
  _config+:: {},
}
EOF

mixtool new prometheus-alerts alerts/alerts.libsonnet
mixtool new grafana-dashboard dashboards/dashboards.libsonnet
mixtool new prometheus-rules rules/rules.libsonnet

git add {alerts,dashboards,rules}/* *.libsonnet
git commit -m 'grafana: monitoring-mixins scaffolding' -m 'https://monitoring.mixins.dev/'
```

This scaffolding does not yet produce valid output. We will comment out the
placeholder contents, so none of the files actually do anything yet, but
mixtool should return success.

```shell
mixtool generate all mixin.libsonnet
```

### Import existing dashboards

Next we populate our dashboards with the existing sample JSON. Lines produced
by the following command need to be moved up two lines, inside
`grafanaDashboards`.

```shell
cp ../provisioning/dashboards/*.json dashboards/
DASHBOARD_FILES=$(cd dashboards && ls -1 *.json)
for f in $DASHBOARD_FILES; do
  echo "    '${f}': (import '$f')," >> dashboards/dashboards.libsonnet
done

```

---

## Next Steps
- Polar: add polarlightning/lnd:0.15.5 to GUI
- Polar: add "Enable Prometheus" option for lnd nodes

---

## References
- [Grafonnet docs](https://grafana.github.io/grafonnet-lib/)
- grafana/[grafonnet-lib](https://github.com/grafana/grafonnet-lib) jsonnet library for generating Grafana dashboard files
- tutorial: [Grafana Dashboards as Code with Grafonnet](https://www.novatec-gmbh.de/en/blog/grafana-dashboards-as-code-with-grafonnet/)
- [Grafana Dashboard JSON Model](https://grafana.com/docs/grafana/latest/dashboards/build-dashboards/view-dashboard-json-model/)
- JSON diff: [website](https://jsondiff.com/), [source code](https://github.com/zgrossbart/jdd)
- rhowe/[grafonnet-lib](https://github.com/rhowe/grafonnet-lib/) fork w/support for recent Grafana features
- [grafanalib](https://grafanalib.readthedocs.io/en/stable/) alternative dashboard-as-code tool in python
- Grafana docs
  - [panel types](https://grafana.com/docs/grafana/latest/panels-visualizations/visualizations/)
