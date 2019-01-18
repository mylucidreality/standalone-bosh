#!/bin/bash

set -eu

POLL_INTERVAL=30

function apply-changes() {
echo "Applying changes on Ops Manager @ ${OPSMAN_DOMAIN_OR_IP_ADDRESS}"
{
om-linux \
  --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
  --skip-ssl-validation \
  --username "${OPSMAN_USERNAME}" \
  --password "${OPSMAN_PASSWORD}" \
  apply-changes \
  --ignore-warnings && send_dat_email "COMPLETED"
} || {
  send_dat_email "FAILED"
}

}

# function check_result() {
#     echo "HugIsSoftPop--Checking dem deets on Ops Manager @ ${OPSMAN_DOMAIN_OR_IP_ADDRESS}"
#   local apply_last_state=$(om-linux \
#     --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
#     --skip-ssl-validation \
#     --username "${OPSMAN_USERNAME}" \
#     --password "${OPSMAN_PASSWORD}" \
#     installations|head -4|tail -1)
#   echo "Here is the state $apply_last_state"
#   apply_last_state=$apply_last_state | grep "FAILED"
#   if [[ $did_it_fail -eq 0 ]]; then
#     send_dat_email "SUCCESS"
#     exit 0
#   else
#     send_dat_email "FAILED"
#     exit 1
#   fi
# }

function send_dat_email() {
status="${1}"
echo "Status detected ${status}"
TIME=$(date +%T)
cat > email/headers.txt <<EOH
MIME-version: 1.0
Content-Type: text/html; charset="UTF-8"
EOH

#Begin the Email Body
cat > email/body.html <<EOH
<html>
<style>
table, th, td {
    border: 1px solid black;
}
</style>
<body>
<p>
<pre>
EOH

  apply_last_state=$(om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    installations|head -4|tail -1)

echo "Here is the state $apply_last_state"

printf "<h2><font face=Arial>Apply change result:</font></h2>$apply_last_state" \
>> email/body.html

printf "</table></body></html>" >> email/body.html

printf "${ENV} ${status} Last Apply"> email/subject.txt
}

apply-changes