# PCF Standalone bosh-deployment
Much of this was taken from https://github.com/cloudfoundry/bosh-deployment
## Install Process
### Jumpbox requirements
- Access to the internet
- Access to destination vCenter
- bosh cli installed
- uaac cli installed
- Required OS packages installed

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
# Automate Install
## Create Director
```
PCF_ENV="stratus"
bosh  ./bosh.yml \
--state=./env/bosh/state.json \
--vars-store=./customizations/"$PCF_ENV"-director-vars-store.yml \
-l ./$PCF_ENV/master-params.yml \
-o ./vsphere/cpi.yml \
-o ./misc/dns.yml \
-o ./uaa.yml \
-o ./credhub.yml \
-o ./bbr.yml \
-o ./jumpbox-user.yml \
-o ./misc/ntp.yml \
-o ./env/bosh/director-ops.yml \
&& git add -A && git commit -m "adding director vars store and state" && git push
```

## Log into Director

```
unset BOSH_CLIENT
unset BOSH_CLIENT_SECRET
bosh alias-env $PCF_ENV -e 10.14.168.22 --ca-cert <(bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /director_ssl/ca)
export BOSH_CLIENT=admin && \
export BOSH_CLIENT_SECRET=`bosh int ./customizations/"$PCF_ENV"-director-vars-store.yml --path /admin_password` && \
bosh -e $PCF_ENV login
```

## Add cloud-config
```
bosh -e $PCF_ENV update-cloud-config ./env/bosh/"$PCF_ENV"-cloud-config.yml
```

## Runtime-configs, releases, and stemcells
```
wget https://bosh.io/d/github.com/cloudfoundry/bosh-dns-release?v=1.10.0 -O /tmp/dns.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/dns.tgz && \
rm /tmp/dns.tgz && bosh -e $PCF_ENV update-runtime-config runtime-configs/dns.yml --name dns -n && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/bpm-release?v=0.13.0 -O /tmp/bpm.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/bpm.tgz && \
rm /tmp/bpm.tgz && bosh -e $PCF_ENV update-runtime-config runtime-configs/bpm.yml --name bpm -n && \
wget https://bosh.io/d/github.com/cloudfoundry/nats-release?v=26 -O /tmp/nats.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/nats.tgz && \
rm /tmp/nats.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/cf-routing-release?v=0.180.0 -O /tmp/routing.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/routing.tgz && \
rm /tmp/routing.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/cf-haproxy-boshrelease?v=8.0.6 -O /tmp/haproxy.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/haproxy.tgz && \
rm /tmp/haproxy.tgz && \
wget https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-97.12-vsphere-esxi-ubuntu-xenial-go_agent.tgz -O /tmp/bosh-stemcell-97.12-vsphere-esxi-ubuntu-xenial-go_agent.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-stemcell /tmp/bosh-stemcell-97.12-vsphere-esxi-ubuntu-xenial-go_agent.tgz && \
rm /tmp/bosh-stemcell-97.12-vsphere-esxi-ubuntu-xenial-go_agent.tgz && \
wget https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-3586.36-vsphere-esxi-ubuntu-trusty-go_agent.tgz -O /tmp/bosh-stemcell-3586.36.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-stemcell /tmp/bosh-stemcell-3586.36.tgz && \
rm /tmp/bosh-stemcell-3586.36.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/garden-runc-release?v=1.16.0 -O /tmp/garden.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/garden.tgz && \
rm /tmp/garden.tgz && \
wget https://bosh.io/d/github.com/concourse/concourse?v=4.2.1 -O /tmp/concourse.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/concourse.tgz && \
rm /tmp/concourse.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/postgres-release?v=28 -O /tmp/postgres.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/postgres.tgz && \
rm /tmp/postgres.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/cf-mysql-release?v=36.16.0 -O /tmp/cf-mysql.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/cf-mysql.tgz && \
rm /tmp/cf-mysql.tgz && \
wget https://bosh.io/d/github.com/pivotal-cf/credhub-release?v=2.1.1 -O /tmp/credhub.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/credhub.tgz && \
rm /tmp/credhub.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/uaa-release?v=66.0 -O /tmp/uaa.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/uaa.tgz && \
rm /tmp/uaa.tgz && \
wget https://bosh.io/d/github.com/minio/minio-boshrelease?v=2018-11-17T01-23-48Z -O /tmp/minio.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/minio.tgz && \
rm /tmp/minio.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-community/docker-registry-boshrelease?v=3.3.2 -O /tmp/docker-registry.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/docker-registry.tgz && \
rm /tmp/docker-registry.tgz
```

## Deploy routing
```
bosh -e $PCF_ENV -d routing deploy ./$PCF_ENV/routing/routing.yml -l $PCF_ENV/master-params.yml -n
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

```
DIRECTOR_IP="10.14.168.22"
credhub api --server $DIRECTOR_IP:8844 --skip-tls-validation
credhub login
credhub find -n worker_key
credhub find -n tsa_host_key
```

- Using data from above build your remote worker manifest and deploy

```
git -C ./pcf-tile-configurator pull && git -C ./pcf-swiss-army pull
PCF_ENV=pxa
bosh -e $PCF_ENV -d concourse-workers deploy ./pcf-tile-configurator/bosh-deployments/concourse/workers.yml -l ./pcf-swiss-army/master-params/"$PCF_ENV"-params.yml -n
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

#Post-deploy
### Create and configure concourse teams
- Get username and password
credhub get -n /REPLACE_ME/concourse/concourse_user
- log into main team
fly -t REPLACE_ME login -c https://concourse.xxx.xxx.xxx -n main -u concourse -p REPLACE_ME
- Create new team for remote workers
fly st -t pxe -n REPLACE_ME --local-user=concourse --ldap-group=REPLACE_ME
- Verify your teams are there
fly teams -t REPLACE_ME

### Push pipelines
- Monitor certificate
fly sp -t pxe -n pxa sp -p monitor-platform-certs -c ./pipelines/monitor-expiring-certificates/pipeline.yml -l ./master-params/pxa-params.yml

## Key points
### Access standalone credhub
You will need to retrieve the standalone credhub admin password
	- Log into director
```credhub login --client-name=credhub-admin --client-secret="PASSWORD FOUND IN DIRECTOR VARS FILE" -s DIRECTOR:8844 --skip-tls-validation```
	- Find the location of the creds
```credhub find -n credhub-admin-client-password```
	- copy the password
```credhub get -n /stratus/credhub/credhub-admin-client-password```
	- log into standalone credhub
```credhub login --client-name=credhub_admin_client --client-secret="PASSWORD FROM ABOVE" -s CREDHUB_IP:8844 --skip-tls-validation```
	- Test access
```credhub set -t value -n /test```
```credhub delete -n /test```

# Final Design
<img src="/pxe/images/PXE.jpg" style="width: 800px;"/>


# DELETE IT ALL!!!!!!

```
PCF_ENV="stratus"
bosh delete-env ./env/bosh/director.yml --state=./env/bosh/state.json && \
rm ./env/bosh/director.yml && \
rm ./env/bosh/state.json && \
&& git add -A && \
git commit -m "Its gone... its all gone" && \
git push
```