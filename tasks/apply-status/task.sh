#!/bin/bash

function the_check() {
    echo "Checking dem deets on Ops Manager @ ${OPSMAN_DOMAIN_OR_IP_ADDRESS}"
  local apply_last_state=$(om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    installations|head -4|tail -1)
  echo "Here is the state $apply_last_state"
  apply_last_state=$apply_last_state | grep "FAILED"
  if [[ $did_it_fail -eq 0 ]]; then
    echo "Last apply was successful.  Nothing to see here.  Move along now. HugIsSoftPop"
    exit 0
  else
    send_dat_email
    exit 1
  fi
}

function send_dat_email() {
    echo "HugIsSoftPop--Checking dem deets on Ops Manager @ ${OPSMAN_DOMAIN_OR_IP_ADDRESS}"
    TIME=$(date +%T)
cat > email/emailheaders.txt <<EOH
MIME-version: 1.0
Content-Type: text/html; charset="UTF-8"
EOH

#Begin the Email Body
cat > email/emailbody.html <<EOH
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

printf "<h2><font face=Arial>Apply State:</font></h2>$apply_last_state" \
>> email/emailbody.html

printf "</table></body></html>" >> email/emailbody.html

printf "${ENV}-Last Apply Failed"> email/emailsubject.txt
}

the_check