#!/bin/bash
set -x
eval $(ssh-agent -s)

if [ ! -d "~/.ssh" ]; then
    mkdir ~/.ssh
    chmod 700 ~/.ssh
fi

touch ~/.ssh/known_hosts
#echo "$GIT_CERT"
echo "StrictHostKeyChecking=no" > ~/.ssh/config
echo -e "$GIT_CERT" > ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa
echo "IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config
#ssh-add ~/.ssh/id_rsa
#ssh-agent bash -c 'ssh-add ~/.ssh/id_rsa'
#echo "URL::"$RPT_GIT
git config --global user.email "Concourse@me.com"
git config --global user.name "Concourse"

git clone $RPT_GIT
cd pcf-env-report

if [ ! -d "./$PCF_ENV" ]; then
    mkdir ./$PCF_ENV
fi

cd $PCF_ENV

if [ ! -d "./manifests" ]; then
    mkdir ./manifests
fi

touch README.md

export BOSH_CLIENT=$BOSH_ADMIN_CLIENT
export BOSH_CLIENT_SECRET=$PCF_SCRT

echo -e "$PCF_CERT" > ca.cert
RESULT="$(bosh -e $PCF_DIRECTOR log-in --ca-cert ca.cert -n 2>&1 > /dev/null)"
echo $RESULT
bosh -e $PCF_DIRECTOR --ca-cert ca.cert alias-env $PCF_ENV
bosh -e $PCF_ENV vms > vms.txt
bosh -e $PCF_ENV stemcells > stemcells.txt
bosh -e $PCF_ENV releases > releases.txt
bosh -e $PCF_ENV runtime-config > runtime-config.txt

for i in $(bosh -e $PCF_ENV deployments --column name | grep .); do
	bosh -e $PCF_ENV -d $i manifest > ./manifests/$i.yml
done

bosh -e $PCF_ENV log-out

cf login -a ${CF_API} --skip-ssl-validation -u reportuser -p REPLACE_ME
cf buildpacks > buildpacks.txt
cf quotas > quotas.txt

#om-linux \
om \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    deployed-products | tail -n +3 > Deployed_Products.txt

#Build the README.md
echo "# ${PCF_ENV} Environmental Report" > README.md
echo "This report is designed to provide a quick glance into the PCF ${PCF_ENV} environment" >> README.md

#Deployed Products
echo "## Deployed Products" >> README.md
echo "|Deployment |Version |" >> README.md
echo "|---- |---- |" >> README.md
#om-linux \
om \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    deployed-products | tail -n +4 | head -n -1 >> README.md

#BOSH Releases
# echo "## Uploaded BOSH releases" >> README.md
# cat releases.txt >> README.md

#QUOTAS
echo "## Quotas" >> README.md
echo "| Quota Name | Total RAM | Instance RAM | routes | Service Instances | paid plans | App Instances | Route Ports |" >> README.md
echo "| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |" >> README.md
cf quotas | awk -vOFC="\t" '{print "|" $1 " | " $2 " | " $3 " | " $4 " | " $5 " | " $6 " | " $7 " | " $8 }' | tail -n +5 >> README.md

#BUILDPACKS
echo "## BuildPacks" >> README.md
# echo "Buildpacks provide framework and runtime support for apps. Buildpacks typically examine your apps to determine what dependencies to download and how to configure the apps to communicate with bound services." >> README.md
echo "|BuildPack | Version |" >> README.md
echo "| --------- | ------- |" >> README.md
cf buildpacks | awk -vOFC="\t" '{sub(/.*-/,"",$5);sub(/.zip/,"",$5); print "| " $1 " | " $5 " | "}' | tail -n +4 >> README.md

# echo "## Marketplace" >> README.md
# echo "| Service | Plans |" >> README.md
# echo "| ---- | ---- |" >> README.md
# cf marketplace | awk -vOFC="\t" '{print "|" $1 " | " $2 " |"}' | tail -n +4 >> README.md

#Stemcells
echo "## Stemcells" >> README.md
echo "| Stemcell | Version | VM Name |" >> README.md
echo "| ---- | ---- | ---- |" >> README.md
bosh -e $PCF_ENV stemcells  | awk -vOFC="\t" '{print "|" $1 " | " $2 " | " $5 }' >> README.md

cf logout
bosh -e $PCF_ENV log-out


git add .
git commit -m "Updated for TIME=$(date)"
git push
