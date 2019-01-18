FROM ubuntu:16.04
RUN apt-get update -y && apt-get install -y curl gnupg build-essential gnupg2 jq git openssl wget netcat && \
# all the crap needed for RVM to install uaac
gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - && \
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - && curl -sSL https://get.rvm.io | bash -s stable && /bin/bash -c "source /usr/local/rvm/scripts/rvm" && /bin/bash -l -c "rvm install ruby" && \
# install uaac
/bin/bash -l -c "gem install cf-uaac" && \
# install bosh
wget -O /usr/local/bin/bosh https://github.com/cloudfoundry/bosh-cli/releases/download/v5.4.0/bosh-cli-5.4.0-linux-amd64 && chmod +x /usr/local/bin/bosh &&\
# install cf
curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github" | tar -zx && mv cf /usr/local/bin && chmod +x /usr/local/bin/cf && \
# install pivnet
wget -O /usr/local/bin/pivnet https://github.com/pivotal-cf/pivnet-cli/releases/download/v0.0.55/pivnet-linux-amd64-0.0.55 && chmod +x /usr/local/bin/pivnet && \
# install om
wget -O /usr/local/bin/om-linux https://github.com/pivotal-cf/om/releases/download/0.49.0/om-linux && chmod +x /usr/local/bin/om-linux && \
# install mc
wget -O /usr/local/bin/mc https://dl.minio.io/client/mc/release/linux-amd64/mc && chmod +x /usr/local/bin/mc && \
# install fly
wget -O /usr/local/bin/fly https://github.com/concourse/concourse/releases/download/v4.2.2/fly_linux_amd64 && chmod +x /usr/local/bin/fly && \
# install credhub cli 
wget -O ./credhub.tgz https://github.com/cloudfoundry-incubator/credhub-cli/releases/download/2.2.0/credhub-linux-2.2.0.tgz && tar -xvf credhub.tgz && mv ./credhub /usr/local/bin/ && \
# install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
chmod +x kubectl && mv kubectl /usr/local/bin/kubectl && \
# install bbr
wget -O /usr/local/bin/bbr https://github.com/cloudfoundry-incubator/bosh-backup-and-restore/releases/download/v1.3.2/bbr-1.3.2-linux-amd64 && chmod +x /usr/local/bin/bbr && \
# install pks cli
pivnet login --api-token RyYyf5v1LUyuvKZHqxNQ && pivnet download-product-files -p pivotal-container-service -r 1.2.6 -i 277934 -d /usr/local/bin/ && \
mv /usr/local/bin/pks-linux-amd64-1.2.5-build.5 /usr/local/bin/pks && chmod +x /usr/local/bin/pks
