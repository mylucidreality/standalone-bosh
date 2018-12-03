# Concourse
## Download
** Requires Routing v0.179.0 until bpm support.
```
PCF_ENV="xxx"
DIRECTOR_IP="x.x.x.x"
XENIAL_STEMCELL_VERSION="97.12"
GARDEN_RUNC_RELEASE="1.16.3"
CONCOURSE_RELEASE="4.2.1"
POSTGRES_RELEASE="28"
wget https://s3.amazonaws.com/bosh-core-stemcells/vsphere/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz -O /tmp/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-stemcell /tmp/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz && \
rm /tmp/bosh-stemcell-"$XENIAL_STEMCELL_VERSION"-vsphere-esxi-ubuntu-xenial-go_agent.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/garden-runc-release?v="$GARDEN_RUNC_RELEASE" -O /tmp/garden.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/garden.tgz && \
rm /tmp/garden.tgz && \
wget https://bosh.io/d/github.com/concourse/concourse?v="$CONCOURSE_RELEASE" -O /tmp/concourse.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/concourse.tgz && \
rm /tmp/concourse.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/postgres-release?v="$POSTGRES_RELEASE" -O /tmp/postgres.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/postgres.tgz && \
rm /tmp/postgres.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry-incubator/cf-routing-release?v=0.179.0 -O /tmp/routing.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/routing.tgz && \
rm /tmp/routing.tgz
```

## Deploy
*** With credhub integration, proxy, and ldap authenticatin
```
PCF_ENV="xxx"
bosh -e $PCF_ENV -d concourse deploy ./$PCF_ENV/concourse/concourse.yml -o ./$PCF_ENV/concourse/operations/credhub.yml -o ./$PCF_ENV/concourse/operations/ldap.yml -o ./$PCF_ENV/concourse/operations/proxy.yml -l ./$PCF_ENV/master-params.yml -n
```

## Inputs
- azs
- concourse_db_persistent_disk_type
- concourse_db_vm_type
- concourse_userid
- concourse_external_host
- atc_instances
- web_vm_type
- atc_static_ips
- garden_runc_version
- concourse_version

## CredHub Outputs
- concourse_pass
- worker_key
- tsa_host_key
- token_signing_key
- postgres_password
- concourse_user

# Concourse Remote workers deployments
## Inputs
- azs
- worker_instances
- remote_tsa_host
- tsa_host_key.public_key
- worker_key.private_key
- worker_static_ips* For pesky firewall rules between ATC and remote workers

```*** This may be omitted if you do not backup via concourse```

- backup_worker_static_ips* For pesky firewall rules
- backup_worker_instances
- backup_worker_cpu
- backup_worker_ephemeral_disk_size
- backup_worker_ram
