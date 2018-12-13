# Download
```
PROMETHEUS_RELEASE="23.4.0"
POSTGRES_RELEASE="32"
wget https://bosh.io/d/github.com/cloudfoundry-community/prometheus-boshrelease?v="$PROMETHEUS_RELEASE" -O /tmp/prometheus.tgz && \
bosh -e $PCF_ENV upload-release /tmp/prometheus.tgz && \
rm /tmp/prometheus.tgz && \
wget https://bosh.io/d/github.com/cloudfoundry/postgres-release?v="$POSTGRES_RELEASE" -O /tmp/postgres.tgz --no-check-certificate && \
bosh -e $PCF_ENV upload-release /tmp/postgres.tgz && \
rm /tmp/postgres.tgz
```

# Deploy
I am currently having issues getting prometheus to work with mySQL.  Until I figure this out we will use the default postgres db
I have decided not to add any dashboards.  See operator files to add dashboards

```
bosh -e $PCF_ENV -d prometheus deploy ./env/prometheus/prometheus.yml -o ./env/prometheus/ops/monitor-bosh.yml -o ./env/prometheus/ops/monitor-http-probe.yml -o ./env/prometheus/ops/ldap.yml -o ./env/prometheus/ops/monitor-mysql.yml -l ./customizations/"$PCF_ENV"-params.yml -l ./customizations/"$PCF_ENV"-director-vars-store.yml -n
```