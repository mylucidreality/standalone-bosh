# bosh-deployment
This project is based on the original repo located at https://github.com/cloudfoundry/bosh-deployment.

This solution requires manual definitions of variables, but is otherwise completely automated.

# Firewall Requirements
## Inbound
| source                   | destination            |  port |                          description |
|--------------------------|------------------------|:-----:|-------------------------------------:|
| Consumer Network         | HA Proxy IP            |  443  |   Connection to all published routes |
| Consumer Network         | Director IP Jumpbox IP |   22  |                                  SSH |
| Consumer Network         | Director IP            |  6868 | Agent for bootstraping bosh director |
| Consumer Network         | Director IP            | 25555 |                         Director API |
| Consumer Network         | Director IP Credhub IP | 8844  |                          Credhub API |
| Consumer Network         | Director IP Credhub IP | 8443  |                              UAA API |
| Consumer Network         | Windows Jumpbox IP     | 3389  |                                  RDP |
| Remote Concourse Workers | Concourse TSA IP       | 2222  |                  Worker registration |

## Outbound
| source                   | destination              | port |                          description |
|--------------------------|--------------------------|:----:|-------------------------------------:|
| Concourse TSA IP(s)      | Remote Concourse Workers | 7777 |          API to allow ATC management |
| Concourse TSA IP(s)      | Remote Concourse Workers | 7788 | API to allow ATC resource management |
| Full BOSH Network        | front-end PCF VIPs       |  443 |         Access to published services |
| Full BOSH Network        | DNS IP                   |  53  |                                  DNS |
| Full BOSH Network        | NTP IP                   |  123 |                                  NTP |
| Full BOSH Network        | LDAP VIP/IP              |  389 |                  LDAP Authentication |
| Full BOSH Network        | Proxy Server             | 8080 |                     Web Proxy Access |
| Full BOSH Network        | SMTP Server              |  25  |                                Email |
| Director IP              | vCenter                  |  443 |                  Resource management |

# Install Process
## Jumpbox requirements
- Access to the internet
- Access to destination vCenter
- bosh cli installed
- uaac cli installed
- Required OS packages installed

## CentOS
```
sudo yum install gcc gcc-c++ ruby ruby-devel mysql-devel postgresql-devel postgresql-libs sqlite-devel libxslt-devel libxml2-devel patch openssl
gem install yajl-ruby
```

## Ubuntu Trusty
```
sudo apt-get install -y build-essential zlibc zlib1g-dev ruby ruby-dev openssl libxslt-dev libxml2-dev libssl-dev libreadline7 libreadline6-dev libyaml-dev libsqlite3-dev sqlite3
```

# Automate Install
The goal of this projewct was to produce an entire bosh environemnt using infrastructure as code.
- add your customizations to "REPLACE_ME" in
 - ./env/build-central-db.sh
 - ./env/build.sh
- Make a copy of the files in ./customizations to match your environment name (ie. MyCloud-cloud-config.yml)
- Update with your environemtn details
- Decide if you want a central MySQL db or dispersed DB instances
- Run either ./env/build.sh or ./env/build-central-db.sh

#Post-deploy
## Prometheus
Confiure your remote Prometheus data sources

## Concourse
### Create and configure concourse teams
- Get username and password from credhub
credhub get -n /REPLACE_ME/concourse/concourse_user
- log into main team
fly -t REPLACE_ME login -c https://concourse.xxx.xxx.xxx -n main -u concourse -p REPLACE_ME
- Create new team for remote workers
fly st -t REPLACE_ME -n REPLACE_ME --local-user=concourse --ldap-group=REPLACE_ME
- Verify your teams are there
fly teams -t REPLACE_ME

### Push pipelines
- Monitor certificate
fly sp -t REPLACE_ME -n pxa sp -p monitor-platform-certs -c ./pipelines/monitor-expiring-certificates/pipeline.yml -l ./master-params/pxa-params.yml

## Key points
### Access standalone credhub
You will need to retrieve the standalone credhub admin password
	- Log into director
```credhub login --client-name=credhub-admin --client-secret="PASSWORD FOUND IN DIRECTOR VARS FILE" -s DIRECTOR:8844 --skip-tls-validation```
	- Find the location of the creds
```credhub find -n credhub-admin-client-password```
	- copy the password
```credhub get -n /xxx/credhub/credhub-admin-client-password```
	- log into standalone credhub
```credhub login --client-name=credhub_admin_client --client-secret="PASSWORD FROM ABOVE" -s CREDHUB_IP:8844 --skip-tls-validation```
	- Test access
```credhub set -t value -n /test```
```credhub delete -n /test```

# Final Design
## DB's remain with their deployments
<img src="/images/bosh_generic.jpg" style="width: 800px;"/>

## Central MySQL DB
<img src="/images/bosh_generic_mysql.jpg" style="width: 800px;"/>


# DELETE IT ALL!!!!!!
Delete it and trt again

# TODO
I still need to add gogs
I need to get the central MySQL DB to work with Prometheus
I need to add a bosh deployed jumpbox to the process
I need to add BBR into deployments where its an option
I need to see where bosh DNS can improve my design