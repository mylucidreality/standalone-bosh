# PCF Standalone bosh-deployment
Much of this was taken from https://github.com/cloudfoundry/bosh-deployment
## Install Process
### Jumpbox requirements
- Access to the internet
- Access to destination vCenter
- bosh cli installed
- Packages installed

### CentOS
```
sudo yum install gcc gcc-c++ ruby ruby-devel mysql-devel postgresql-devel postgresql-libs sqlite-devel libxslt-devel libxml2-devel patch openssl
gem install yajl-ruby
```

### Ubuntu Trusty
```
sudo apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline7 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3
```
The official documentation is greatly lacking.  I installed the below to get it to work from my vm
```
apt-get install openssl ruby-openssl libssl-dev
```
# Install
- Set your env variable
```ENV=xxx```

Automate the pricess by running ```./build.sh```

## Create Director
```
bosh create-env ./bosh.yml \
--state=./$ENV/bosh/state.json \
--vars-store=./$ENV/bosh/director-vars-store.yml \
-l ./$ENV/master-params.yml \
-o ./vsphere/cpi.yml \
-o ./misc/dns.yml \
-o ./uaa.yml \
-o ./credhub.yml \
-o ./bbr.yml \
-o ./jumpbox-user.yml \
-o ./misc/ntp.yml \
-o ./$ENV/bosh/custom-ops.yml \
&& git add -A && git commit -m "adding director vars store and state" && git push
```

# Add generated vars into credhub

```
DIRECTOR_IP=x.x.x.x
credhub api --server $DIRECTOR_IP:8844 --skip-tls-validation
credhub login --client-name=credhub-admin --client-secret=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /credhub_admin_client_secret)
credhub set -n /credhub-admin -t user -z credhub-admin -w $(bosh int ./$ENV/bosh/director-vars-store.yml --path /credhub_admin_client_secret)
credhub set -n /ldap_user -t user -z TODO -w TODO
credhub set -n /director -t user -z director -w $(bosh int ./$ENV/bosh/director-vars-store.yml --path /director_password)
credhub set -n /gorouter_password  --type password --password=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /gorouter_password)
credhub set -n /admin_password  --type password --password=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /admin_password)
credhub set -n /blobstore_agent_password  --type password --password=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /blobstore_agent_password)
credhub set -n /blobstore_director_password  --type password --password=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /blobstore_director_password)
credhub set -n /postgres_password  --type password --password=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /postgres_password)
credhub set -n /mbus_bootstrap_password  --type password --password=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /mbus_bootstrap_password)
credhub set -n /credhub_encryption_password  --type password --password=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /credhub_encryption_password)
credhub set -n /uaa_admin_client_secret  --type password --password=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /uaa_admin_client_secret)
credhub set -n /uaa_clients_director_to_credhub  --type password --password=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /uaa_clients_director_to_credhub)
```

## Log into Director

```
unset BOSH_CLIENT
unset BOSH_CLIENT_SECRET
export BOSH_CLIENT=director
export BOSH_CLIENT_SECRET=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /director_password)
bosh alias-env $ENV -e $DIRECTOR_IP --ca-cert $(bosh int ./$ENV/bosh/director-vars-store.yml --path /director_ssl/ca) && \
bosh -e $ENV login --client=admin --client-secret=$(bosh int ./$ENV/bosh/director-vars-store.yml --path /admin_password)
```

## Add cloud-config
```
bosh -e $ENV update-cloud-config ./$ENV/bosh/cloud-config.yml
```

## Runtime-configs, releases, and stemcells
```
ENV="xxx"
# DIRECTOR_NAME (ie bosh-xxx)
DNS_RELEASE="1.10.0"
BPM_RELEASE="0.13.0"
NATS_RELEASE="26"
CF_ROUTING_RELEASE="0.180.0"
HA_PROXY_RELEASE="8.0.6"
XENIAL_STEMCELL_VERSION="97.12"
TRUSTY_STEMCELL_VERSION="3586.36"
GARDEN_RUNC_RELEASE="1.16.3"
CONCOURSE_RELEASE="4.2.1"
POSTGRES_RELEASE="28"
CF_MYSQL_RELEASE="36.16.0"
CREDHUB_RELEASE="2.1.1"
UAA_RELEASE="66.0"
OS_CONF_RELEASE="20.0.0"
MINIO_RELEASE="2018-11-17T01-23-48Z"
DOCKER_REGISTRY_RELEASE="3.3.2"
PROMETHEUS_RELEASE="23.3.0"
DIRECTOR_IP="TODO"
wget https://bosh.io/d/github.com/cloudfoundry/bosh-dns-release?v="$DNS_RELEASE" -O /tmp/dns.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/dns.tgz && \
rm /tmp/dns.tgz && bosh -e $ENV update-runtime-config runtime-configs/dns.yml --name dns -n && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/bpm-release?v="$BPM_RELEASE" -O /tmp/bpm.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/bpm.tgz && \
rm /tmp/bpm.tgz && bosh -e $ENV update-runtime-config runtime-configs/bpm.yml --name bpm -n && \
wget https://bosh.io/d/github.com/cloudfoundry/nats-release?v="$NATS_RELEASE" -O /tmp/nats.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/nats.tgz && \
rm /tmp/nats.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/cf-routing-release?v="$CF_ROUTING_RELEASE" -O /tmp/routing.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/routing.tgz && \
rm /tmp/routing.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/cf-haproxy-boshrelease?v="$HA_PROXY_RELEASE" -O /tmp/haproxy.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/haproxy.tgz && \
rm /tmp/haproxy.tgz && \
wget https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz -O /tmp/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz --no-check-certificate && \
bosh -e $ENV upload-stemcell /tmp/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz && \
rm /tmp/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz && \
wget https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-"$TRUSTY_STEMCELL_VERSION"-vsphere-esxi-ubuntu-trusty-go_agent.tgz -O /tmp/bosh-stemcell-"$TRUSTY_STEMCELL_VERSION"-vsphere-esxi-ubuntu-trusty-go_agent.tgz --no-check-certificate && \
bosh -e $ENV upload-stemcell /tmp/bosh-stemcell-"$TRUSTY_STEMCELL_VERSION"-vsphere-esxi-ubuntu-trusty-go_agent.tgz && \
rm /tmp/bosh-stemcell-"$TRUSTY_STEMCELL_VERSION"-vsphere-esxi-ubuntu-trusty-go_agent.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/garden-runc-release?v="$GARDEN_RUNC_RELEASE" -O /tmp/garden.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/garden.tgz && \
rm /tmp/garden.tgz && \
wget https://bosh.io/d/github.com/concourse/concourse?v="$CONCOURSE_RELEASE" -O /tmp/concourse.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/concourse.tgz && \
rm /tmp/concourse.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/postgres-release?v="$POSTGRES_RELEASE" -O /tmp/postgres.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/postgres.tgz && \
rm /tmp/postgres.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/cf-mysql-release?v="$CF_MYSQL_RELEASE" -O /tmp/cf-mysql.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/cf-mysql.tgz && \
rm /tmp/cf-mysql.tgz && \
wget https://bosh.io/d/github.com/pivotal-cf/credhub-release?v="$CREDHUB_RELEASE" -O /tmp/credhub.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/credhub.tgz && \
rm /tmp/credhub.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/uaa-release?v="$UAA_RELEASE" -O /tmp/uaa.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/uaa.tgz && \
rm /tmp/uaa.tgz && \
wget https://bosh.io/d/github.com/minio/minio-boshrelease?v="$MINIO_RELEASE" -O /tmp/minio.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/minio.tgz && \
rm /tmp/minio.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/docker-registry-boshrelease?v="$DOCKER_REGISTRY_RELEASE" -O /tmp/docker-registry.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/docker-registry.tgz && \
rm /tmp/docker-registry.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/prometheus-boshrelease?v="$PROMETHEUS_RELEASE" -O /tmp/prometheus.tgz && \
bosh -e $ENV upload-release /tmp/prometheus.tgz && \
rm /tmp/prometheus.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/cf-routing-release?v=0.179.0 -O /tmp/routing.tgz --no-check-certificate && \
bosh -e $ENV upload-release /tmp/routing.tgz && \
rm /tmp/routing.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/os-conf-release?v="$OS_CONF_RELEASE" -O /tmp/os-conf.tgz && \
bosh -e $ENV upload-release /tmp/os-conf.tgz && \
rm /tmp/os-conf.tgz
```

## Deploy routing
```
bosh -e $ENV -d routing deploy ./$ENV/routing/routing.yml -l ./$ENV/master-params.yml -n
```

## Deploy Credhub
```
bosh -e $ENV -d credhub deploy ./$ENV/credhub/credhub.yml -l ./$ENV/master-params.yml -n
```

## Deploy Concourse

```
bosh -e $ENV -d concourse deploy ./$ENV/concourse/concourse.yml -l ./$ENV/master-params.yml -n
```

### Deploy Remote Concourse Workers
- Log into Director Credhub
- Capture worker_key.private_key, worker_key.public_key and tsa_host_key.public_key
- Add to your master param file

```
DIRECTOR_IP="TODO"
credhub api --server $DIRECTOR_IP:8844 --skip-tls-validation
credhub login
credhub find -n worker_key
credhub find -n tsa_host_key
```

- Using data from above build your remote worker manifest and deploy

```
git -C ./pcf-tile-configurator pull && git -C ./pcf-swiss-army pull
ENV=pxa
bosh -e $ENV -d concourse-workers deploy ./pcf-tile-configurator/bosh-deployments/concourse/workers.yml -l ./pcf-swiss-army/master-params/"$ENV"-params.yml -n
```


## Prometheus
### Deploy

```
bosh -e $ENV -d prometheus deploy ./$ENV/prometheus/prometheus.yml -l ./$ENV/master-params.yml -n
```

### Configure
- Add data sources
  - Skip TLS Verification
  - Basic Auth
  - User: admin
  - Pass: see OneNote for prometheus_password
  - https://prometheus.sys.$ENV.xxx.xxx

# Final Design
<img src="/images/bosh_generic.jpg" style="width: 800px;"/>