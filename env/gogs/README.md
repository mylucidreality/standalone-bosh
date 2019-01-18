# Download
```
GOGS_RELEASE="5.4.0"
PCF_ENV=xxx
wget https://bosh.io/d/github.com/cloudfoundry-community/gogs-boshrelease?v="$GOGS_RELEASE" -O /tmp/gogs.tgz && \
bosh -e $PCF_ENV upload-release /tmp/gogs.tgz && \
rm /tmp/gogs.tgz && \

```

# Deploy
```
bosh -e $PCF_ENV -d gogs deploy ./env/gogs/gogs.yml -o ./env/gogs/ops/routing.yml -o ./env/gogs/ops/central-db.yml -l ./customizations/"$PCF_ENV"-params.yml
```