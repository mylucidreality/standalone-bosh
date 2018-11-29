# Deploying Credhub
## Components
Credhub deployment consists of a Credhub/UAA cell, MySQLProxy, 3 or more MySQL database servers, and an arbirtator.
## Prerequisites
Update manifest replacing "/bosh-xxx" with your environment
### Releases
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
### IPs
Credhub and MySQL Proxy require static IP addresses in the Bosh deploy network

### Bosh Credhub Items
Wildcard certificate present in Credhub as /wildcard_certificate
LDAP username and password in Credhub as /ldap_user

### Certificates
Credhub will utulize the wildcard cert.  If this is not already present, add to:
/wildcard_certificate.ca
/wildcard_certificate.certificate
/wildcard_certificate.private_key

MySQLProxy will generate and use its own cert contianing its IP address.  This will be automatically stored in Director Credhub.
