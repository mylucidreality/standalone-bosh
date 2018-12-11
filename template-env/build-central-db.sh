#!/bin/bash

set -e
PCF_ENV="stratus"
DIRECTOR_IP="xx.xx.xx.xx"
# DIRECTOR_NAME (ie bosh-pxems)
DNS_RELEASE="1.10.0"
BPM_RELEASE="1.0.0"
NATS_RELEASE="26"
CF_ROUTING_RELEASE="0.183.0"
HA_PROXY_RELEASE="8.0.6"
XENIAL_STEMCELL_VERSION="97.12"
TRUSTY_STEMCELL_VERSION="3586.36"
GARDEN_RUNC_RELEASE="1.16.3"
CONCOURSE_RELEASE="4.2.1"
POSTGRES_RELEASE="32"
CF_MYSQL_RELEASE="36.16.0"
CREDHUB_RELEASE="2.1.1"
UAA_RELEASE="66.0"
OS_CONF_RELEASE="20.0.0"
MINIO_RELEASE="2018-11-17T01-23-48Z"
DOCKER_REGISTRY_RELEASE="3.3.2"
PROMETHEUS_RELEASE="23.4.0"
GOGS_RELEASE="5.4.0"

BLACK='\033[0;30m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

echo -e "$(tput rev)"
echo -e "======================================================="
echo -e " Hold on, here we go.                                  "
echo -e "                                                       "
echo -e " Creating bosh Director manifest for archival purposes "
echo -e "======================================================="
echo -e "$(tput sgr0)"
# create something to look at
bosh init ./bosh.yml \
--vars-store=./customizations/"$PCF_ENV"-director-vars-store.yml \
-l ./customizations/"$PCF_ENV"-params.yml \
-o ./vsphere/cpi.yml \
-o ./misc/dns.yml \
-o ./uaa.yml \
-o ./credhub.yml \
-o ./bbr.yml \
-o ./jumpbox-user.yml \
-o ./misc/ntp.yml \
-o ./customizations/director-ops.yml \
-o ./env/bosh/ops/add-bosh-exporter-uaa-clients.yml \
-o ./env/bosh/ops/add-credhub-exporter-uaa-clients.yml \
> ./env/bosh/director.yml \
&& git add -A && git commit -m "a director manifest" && git push

echo -e "$(tput rev)"
echo -e "======================================================"
echo -e "  Deploying bosh Director with DNS, UAA, credhub, bbr,"
echo -e "  ntp, jumpbox-user and components defined within     "
echo -e "  ./env/bosh/director-ops.yml                      "
echo -e "======================================================"
echo -e "$(tput sgr0)"
# Create Director
bosh create-env ./bosh.yml \
--state=./customizations/"$PCF_ENV"-state.json \
--vars-store=./customizations/"$PCF_ENV"-director-vars-store.yml \
-l ./customizations/"$PCF_ENV"-params.yml \
-o ./vsphere/cpi.yml \
-o ./misc/dns.yml \
-o ./uaa.yml \
-o ./credhub.yml \
-o ./bbr.yml \
-o ./jumpbox-user.yml \
-o ./misc/ntp.yml \
-o ./customizations/director-ops.yml \
-o ./env/bosh/ops/add-bosh-exporter-uaa-clients.yml \
-o ./env/bosh/ops/add-credhub-exporter-uaa-clients.yml \
&& git add -A && git commit -m "adding director vars store and state" && git push

echo -e "$(tput rev)"
echo -e "==========================================================================="
echo -e "  Adding generated creds to director's credhub for use by other deployments"
echo -e "==========================================================================="
echo -e "$(tput sgr0)"
# Add stuff to director credhub
credhub api --server $DIRECTOR_IP:8844 --skip-tls-validation
credhub login --client-name=credhub-admin --client-secret=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /credhub_admin_client_secret)
credhub set -n /credhub-admin -t user -z credhub-admin -w $(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /credhub_admin_client_secret)
credhub set -n /ldap_user -t user -z REPLACE_ME -w 'REPLACE_ME'
credhub set -n /director -t user -z director -w $(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /director_password)
credhub set -n /gorouter_password  --type password --password=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /gorouter_password)
credhub set -n /admin_password  --type password --password=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /admin_password)
credhub set -n /blobstore_agent_password  --type password --password=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /blobstore_agent_password)
credhub set -n /blobstore_director_password  --type password --password=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /blobstore_director_password)
credhub set -n /postgres_password  --type password --password=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /postgres_password)
credhub set -n /mbus_bootstrap_password  --type password --password=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /mbus_bootstrap_password)
credhub set -n /credhub_encryption_password  --type password --password=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /credhub_encryption_password)
credhub set -n /uaa_admin_client_secret  --type password --password=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /uaa_admin_client_secret)
credhub set -n /uaa_clients_director_to_credhub  --type password --password=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /uaa_clients_director_to_credhub)

echo -e "$(tput rev)"
echo -e "================================="
echo -e "boshing into the new environment "
echo -e "================================="
echo -e "$(tput sgr0)"
# Log into Director
unset BOSH_CLIENT
unset BOSH_CLIENT_SECRET
export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /admin_password)
bosh alias-env $PCF_ENV -e $DIRECTOR_IP --ca-cert "$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /director_ssl/ca)"
bosh -e $PCF_ENV login --client=admin --client-secret=$(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /admin_password)

echo -e "$(tput rev)"
echo -e "======================="
echo -e "Pushing a cloud-config "
echo -e "======================="
echo -e "$(tput sgr0)"
# Add cloud-config
bosh -e $PCF_ENV update-cloud-config ./env/bosh/cloud-config.yml -n

echo -e "$(tput rev)"
echo -e "=========================================================================="
echo -e "Downloading/Uploading/deploying stemcells, releases, and runtime-configs  "
echo -e "=========================================================================="
echo -e "$(tput sgr0)"
# Runtime-configs, releases, and stemcells
wget https://bosh.io/d/github.com/cloudfoundry/bosh-dns-release?v="$DNS_RELEASE" -O /tmp/dns.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/dns.tgz && \
rm /tmp/dns.tgz && bosh -e $PCF_ENV update-runtime-config runtime-configs/dns.yml --name dns -n && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/bpm-release?v="$BPM_RELEASE" -O /tmp/bpm.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/bpm.tgz && \
rm /tmp/bpm.tgz && bosh -e $PCF_ENV update-runtime-config runtime-configs/bpm.yml --name bpm -n && \
wget https://bosh.io/d/github.com/cloudfoundry/nats-release?v="$NATS_RELEASE" -O /tmp/nats.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/nats.tgz && \
rm /tmp/nats.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/cf-routing-release?v="$CF_ROUTING_RELEASE" -O /tmp/routing.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/routing.tgz && \
rm /tmp/routing.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/cf-haproxy-boshrelease?v="$HA_PROXY_RELEASE" -O /tmp/haproxy.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/haproxy.tgz && \
rm /tmp/haproxy.tgz && \
wget https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz -O /tmp/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-stemcell /tmp/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz && \
rm /tmp/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz && \
wget https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-"$TRUSTY_STEMCELL_VERSION"-vsphere-esxi-ubuntu-trusty-go_agent.tgz -O /tmp/bosh-stemcell-"$TRUSTY_STEMCELL_VERSION"-vsphere-esxi-ubuntu-trusty-go_agent.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-stemcell /tmp/bosh-stemcell-"$TRUSTY_STEMCELL_VERSION"-vsphere-esxi-ubuntu-trusty-go_agent.tgz && \
rm /tmp/bosh-stemcell-"$TRUSTY_STEMCELL_VERSION"-vsphere-esxi-ubuntu-trusty-go_agent.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/garden-runc-release?v="$GARDEN_RUNC_RELEASE" -O /tmp/garden.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/garden.tgz && \
rm /tmp/garden.tgz && \
wget https://bosh.io/d/github.com/concourse/concourse?v="$CONCOURSE_RELEASE" -O /tmp/concourse.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/concourse.tgz && \
rm /tmp/concourse.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/postgres-release?v="$POSTGRES_RELEASE" -O /tmp/postgres.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/postgres.tgz && \
rm /tmp/postgres.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/cf-mysql-release?v="$CF_MYSQL_RELEASE" -O /tmp/cf-mysql.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/cf-mysql.tgz && \
rm /tmp/cf-mysql.tgz && \
wget https://bosh.io/d/github.com/pivotal-cf/credhub-release?v="$CREDHUB_RELEASE" -O /tmp/credhub.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/credhub.tgz && \
rm /tmp/credhub.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/uaa-release?v="$UAA_RELEASE" -O /tmp/uaa.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/uaa.tgz && \
rm /tmp/uaa.tgz && \
wget https://bosh.io/d/github.com/minio/minio-boshrelease?v="$MINIO_RELEASE" -O /tmp/minio.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/minio.tgz && \
rm /tmp/minio.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/docker-registry-boshrelease?v="$DOCKER_REGISTRY_RELEASE" -O /tmp/docker-registry.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/docker-registry.tgz && \
rm /tmp/docker-registry.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/prometheus-boshrelease?v="$PROMETHEUS_RELEASE" -O /tmp/prometheus.tgz && \
bosh -e $PCF_ENV upload-release /tmp/prometheus.tgz && \
rm /tmp/prometheus.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/cf-routing-release?v=0.179.0 -O /tmp/routing.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/routing.tgz && \
rm /tmp/routing.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v="$OS_CONF_RELEASE" -O /tmp/os-conf.tgz && \
bosh -e $PCF_ENV upload-release /tmp/os-conf.tgz && \
rm /tmp/os-conf.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/gogs-boshrelease?v="$GOGS_RELEASE" -O /tmp/gogs.tgz && \
bosh -e $PCF_ENV upload-release /tmp/gogs.tgz && \
rm /tmp/gogs.tgz


# Deploy routing
echo -e "$(tput rev)"
echo -e "=============================="
echo -e "Deploying Routing components  "
echo -e "=============================="
echo -e "$(tput sgr0)"
bosh -e $PCF_ENV -d routing deploy ./$PCF_ENV/routing/routing.yml -l ./$PCF_ENV/master-params.yml -n


# Deploy MySQL
echo -e "$(tput rev)"
echo -e "=============================="
echo -e "Deploying MySQL Cluster       "
echo -e "=============================="
echo -e "$(tput sgr0)"
bosh -e $PCF_ENV -d mysql deploy ./$PCF_ENV/mysql/mysql.yml -l ./$PCF_ENV/master-params.yml -n

# Deploy Credhub
echo -e "$(tput rev)"
echo -e "=============================="
echo -e "Deploying Credhub             "
echo -e "=============================="
echo -e "$(tput sgr0)"
bosh -e $PCF_ENV -d credhub deploy ./$PCF_ENV/credhub/credhub.yml -o ./$PCF_ENV/credhub/ops/ldap.yml -o ./$PCF_ENV/credhub/ops/central-db.yml -l ./$PCF_ENV/master-params.yml -n

#Deploy Concourse
echo -e "$(tput rev)"
echo -e "=============================="
echo -e "Deploying Concourse           "
echo -e "=============================="
echo -e "$(tput sgr0)"
bosh -e $PCF_ENV -d concourse deploy ./$PCF_ENV/concourse/concourse.yml -o ./$PCF_ENV/concourse/ops/credhub.yml -o ./$PCF_ENV/concourse/ops/proxy.yml -o ./$PCF_ENV/concourse/ops/ldap.yml -l ./$PCF_ENV/master-params.yml -n

#Deploy Minio/Docker-Registry
echo -e "$(tput rev)"
echo -e "====================================="
echo -e "Deploying Minio and Docker-Registry  "
echo -e "====================================="
echo -e "$(tput sgr0)"
bosh -e $PCF_ENV deploy -d minio ./$PCF_ENV/minio/minio.yml -l ./$PCF_ENV/master-params.yml -n && \
bosh -e $PCF_ENV deploy -d docker-registry ./$PCF_ENV/docker-registry/docker.yml -l ./$PCF_ENV/master-params.yml -n

#Deploy Prometheus and Grafana With LDAP and HTTP Probe
echo -e "$(tput rev)"
echo -e "======================"
echo -e "Deploying Prometheus  "
echo -e "======================"
echo -e "$(tput sgr0)"
# Central DB not working right now -o ./$PCF_ENV/prometheus/ops/central-db.yml \
#  bosh -e $PCF_ENV -d prometheus deploy ./env/prometheus/prometheus.yml \
#  -o ./env/prometheus/ops/monitor-bosh.yml \
#  -o ./env/prometheus/ops/monitor-http-probe.yml \
#  -o ./env/prometheus/ops/ldap.yml \
#  -o ./env/prometheus/ops/proxy.yml \
#  -o ./env/prometheus/ops/enable-bosh-uaa.yml \
#  -o ./env/prometheus/ops/monitor-mysql.yml \
#  -l ./customizations/"$PCF_ENV"-params.yml \
#  -l ./customizations/"$PCF_ENV"-director-vars-store.yml -n 


 bosh -e $PCF_ENV -d prometheus deploy ./env/prometheus/prometheus.yml \
 -o ./env/prometheus/ops/monitor-bosh.yml \
 -o ./env/prometheus/ops/monitor-http-probe.yml \
 -o ./env/prometheus/ops/ldap.yml \
 -l ./customizations/"$PCF_ENV"-params.yml \
 -l ./customizations/"$PCF_ENV"-director-vars-store.yml -n 


unset BOSH_CLIENT
unset BOSH_CLIENT_SECRET

echo -e "DONE"
