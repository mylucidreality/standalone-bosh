# Download

```
NATS_RELEASE="26"
CF_ROUTING_RELEASE="0.180.0"
HA_PROXY_RELEASE="8.0.6"
PCF_ENV="stratus"
wget https://bosh.io/d/github.com/cloudfoundry/nats-release?v="$NATS_RELEASE" -O /tmp/nats.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/nats.tgz && \
rm /tmp/nats.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/cf-routing-release?v="$CF_ROUTING_RELEASE" -O /tmp/routing.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/routing.tgz && \
rm /tmp/routing.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/cf-haproxy-boshrelease?v="$HA_PROXY_RELEASE" -O /tmp/haproxy.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/haproxy.tgz && \
rm /tmp/haproxy.tgz
```

# Deploy

```
PCF_ENV="stratus"
bosh -e $PCF_ENV -d routing deploy ./$PCF_ENV/routing/routing.yml -l ./$PCF_ENV/master-params.yml -n
```

# Inputs
- SSL_cn
- SSL_alt_names
- haproxy_ip
- gorouters_ips
- nats_ips
- azs

# CredHub Outputs
- /certs/default_ca
- /certs/wildcard
- router_status_password
- router_route_services_secret
- router_stats_password
- nats-credentials
- gorouter_password