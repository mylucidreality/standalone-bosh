# Download

```
CF_MYSQL_RELEASE="36.16.0"
PCF_ENV="xxx"
bosh -e $PCF_ENV upload-release /tmp/cf-mysql.tgz && \
rm /tmp/cf-mysql.tgz
```

# Deploy

```
PCF_ENV="xxx"
bosh -e $PCF_ENV -d mysql deploy ./env/mysql/mysql.yml -l ./customizations/"$PCF_ENV"-params.yml -n
```

# Inputs
azs
mySQL_proxy_ip

# CredHub Outputs
/database/credhub_db_password
/database/credhub_uaa_db_password
/database/grafana_db_password
/database/gogs_db_password
db_admin_password
cluster_health_password
galera_healthcheck_db_password
galera_healthcheck_endpoint_password
mysql_proxy_api_password
mysql_smoke_tests_db_password

