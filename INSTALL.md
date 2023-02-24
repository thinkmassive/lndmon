# Table of Contents
1. [Setup](#setup)
   1. [Requirements](#requirements)
   2. [Lnd](#lnd)
   3. [Lndmon](#lndmon)
   4. [Nginx (optional: requires domain name)](#nginx-optional-requires-domain-name)
2. [Usage](#usage)
    1. [Option 1: Nginx Proxy Usage](#option-1-nginx-proxy-usage)
    2. [Option 2: Local Usage](#option-2-local-usage)
    3. [Connecting to Remote Lnd Node](#connecting-to-remote-lnd-node)
    4. [Customizing Grafana Metrics](#customizing-grafana-metrics)

## Setup

### Requirements
* docker >= 18.09.6
* docker-compose >= 1.24

### Lnd
- Build lnd with the build tag `monitoring`.

    * Utilizing the `monitoring` build tag requires building lnd from source. To build lnd from source, follow the instructions [here](https://github.com/lightningnetwork/lnd/blob/master/docs/INSTALL.md) except instead of running `make && make install`, run `make && make install tags=monitoring`.
- In `lndmon/.env`, fill in the `TLS_CERT_PATH` and `MACAROON_PATH` variables. By default, `.lnd` lives in your home directory.
   * for macaroon, `readonly` permission is sufficient for `lndmon`
- If you wish to run `lndmon` connecting to an lnd node on testnet or simnet:
   * modify the `lndmon/.env` `LND_NETWORK` variable to match your desired network.
   * make sure the `MACAROON_PATH` matches the desired network as well.
- Make sure lnd ports are reachable.
- Start lnd with the flags: `--rpclisten=0.0.0.0 --prometheus.enable --prometheus.listen=0.0.0.0:8989 --tlsextraip=172.17.0.1`.
   * You may need to delete the existing `tls.cert` and `tls.key` in your lnd directory first.
   * If your docker interface has a non-default IP, replace `172.17.0.1` with the docker interface's IP.
- Start lnd *before* `lndmon`.

### Lndmon
If you want to just run `lndmon` and view your monitoring dashboard locally, all that is needed for setup is to clone the repository and install `docker` + `docker-compose`.

### Nginx (optional: requires domain name)
If you want to enable the built-in nginx proxy feature in order to access your Prometheus and Grafana dashboards remotely, these are the steps:
1. In the `lndmon` repository, edit the `.env` file and fill in the email, FQDN, and (optionally) timezone fields.
2. Ensure ports 80 and 443 are exposed on your server.
3. (Optional) Basic auth setup for your Prometheus dashboard:
   - Install `apache2-utils` package.
   - Run `htpasswd -c nginx/etc/.htpasswd <YOUR_USERNAME>` and follow the prompts to enter and confirm your desired password.
   - In `lndmon/nginx/etc/service.conf`, uncomment the lines indicated in the file to enable basic auth.


Note that these steps will result in TLS certs being generated for your domain, so your dashboards will be accessible over HTTPS. The certs will automatically renew when they expire.

**How to use your own TLS certs:**
* Uncomment the lines beginning with `SSL_`  in `lndmon/.env` and fill in the paths to your cert files.
* Uncomment the lines beginning with `- SSL_` in `lndmon/docker-compose.nginx.yml`.
   
## Usage
### Option 1: Nginx Proxy Usage
These instructions assume you've gone through the setup process for `nginx` specified above.
1. `docker-compose -f docker-compose.yml -f docker-compose.nginx.yml up`

   This will result in the automatic generation of TLS certificates through Let's Encrypt if they haven't been generated already, or their renewal if the current certs have expired.
2. Grafana is located at `https://<YOUR_DOMAIN>/grafana/`
3. Prometheus's expression browser is located at `https://<YOUR_DOMAIN>/prometheus/graph`.

### Option 2: Local Usage
1. `docker-compose up` from the `lndmon` repository.
    * If you get the error "transport: Error while dialing dial tcp 172.17.0.1:10009: i/o timeout", your docker interface may not have the default IP. Make sure your docker interface's IP matches the IP for `LND_HOST` in `.env` and the lnd target's IP in `prometheus.yml`.
2. Access Grafana dashboard: 

   Get Grafana's IP:

   ```
   docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lndmon_grafana_1
   ```
 Grafana's dashboard is located at `http://<GRAFANA_IP>:3000/`. The default password for the admin user is also admin (you can change it after the first login).
3. Access Prometheus expression browser:
   
   Get Prometheus's IP:

   ```
   docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lndmon_prometheus_1
   ```
Prometheus's expression browser is located at `http://<PROMETHEUS_IP>:9090/graph`.

### Connecting to Remote Lnd Node
* Edit the `lndmon/.env` `LND_HOST` variable to match your lnd node's IP and port.
* Ensure the other lnd variables are also up-to-date in `lndmon/.env`.
* Edit `prometheus.yml` `lnd` `targets` section to match your IP.
* Run lnd with the `--tlsextraip=<IP>` flag.

### Customizing Grafana Metrics
`lndmon`'s Grafana instance comes with a set of basic dashboards. Add additional dashboards by clicking the `+' sign on the left.
