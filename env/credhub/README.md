# Deploying Credhub
You have 2 options here.  You can either choose a cenrtalized database to be shared among compatable reployments or you can deploy the MySQL cluster to the credhub deployment.

I don't think the LDAP option does any good if ACLs are enabled.

No bpm in this deployment.  You must use routing version 0.179.0 as latest.

This is assuming no ACLs will be used.  If you choose to use ACLs LDAP will not work.

## Components
### All-in-one
Credhub deployment consists of a Credhub/UAA cell, MySQLProxy, 3 or more MySQL database servers, and an arbirtator.

### Centralized database
Credhub deployment consists of a Credhub/UAA cell.  MySQL Cdeployment must already be present.

## Prerequisites
### Releases
#### All-in-one
```
wget https://bosh.io/d/github.com/cloudfoundry/cf-mysql-release?v=36.16.0 -O /tmp/cf-mysql.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/cf-mysql.tgz && \
rm /tmp/cf-mysql.tgz && \
wget https://bosh.io/d/github.com/pivotal-cf/credhub-release?v=2.1.1 -O /tmp/credhub.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/credhub.tgz && \
rm /tmp/credhub.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/uaa-release?v=66.0 -O /tmp/uaa.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/uaa.tgz && \
rm /tmp/uaa.tgz
```

#### Centralized database
```
wget https://bosh.io/d/github.com/pivotal-cf/credhub-release?v=2.1.1 -O /tmp/credhub.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/credhub.tgz && \
rm /tmp/credhub.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/uaa-release?v=66.0 -O /tmp/uaa.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/uaa.tgz && \
rm /tmp/uaa.tgz
```
### IPs
Credhub and MySQLProxy* require static IP addresses in the Bosh deploy network

### Bosh Credhub Items
Wildcard certificate present in Credhub as /certs/wildcard
LDAP username and password in Credhub as /ldap_user

### Certificates
Credhub will utulize the wildcard cert.  If this is not already present, add to:
/certs/wildcard.ca
/certs/wildcard.certificate
/certs/wildcard.private_key

MySQLProxy* will generate and use its own cert contianing its IP address.  This will be automatically stored in Director Credhub.


# Deploy

```
PCF_ENV="xxx"
bosh -e $PCF_ENV -d credhub deploy ./"$PCF_ENV"/credhub/credhub.yml -o ./"$PCF_ENV"/credhub/ops/ldap.yml -o ./"$PCF_ENV"/credhub/ops/central-db.yml -l ./"$PCF_ENV"/master-params.yml -n
```

# Inputs
## All-in-one
credhub_mySQL_proxy_ip
credhub_static_ips
### Centralized database
mySQL_proxy_ip
credhub_static_ips

# CredHub Outputs
uaa-jwt
uaa-users-admin
credhub_uaa_admin_password
uaa-login
uaa_encryption_password
credhub-encryption-password
credhub-admin-client-password

## All-in-one
mysql_smoke_tests_db_password
mysql_proxy_api_password
galera_healthcheck_endpoint_password
galera_healthcheck_db_password
cluster_health_password
db_admin_password
credhub_db_password
credhub_uaa_db_password
/concourse/concourse_to_credhub_secret