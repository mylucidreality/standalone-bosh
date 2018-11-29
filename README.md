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