#!/bin/bash

function check_for_pending_changes() {
    echo "Checking dem pending changes on Ops Manager @ ${OPSMAN_DOMAIN_OR_IP_ADDRESS}"
  local pending_changes_count=$(om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    curl -path /api/v0/staged/pending_changes | jq -r '.[][] | select(.action | startswith("update","install")) | .guid' | sed -e 's/-[^\-]*$//' | uniq)
    #jq ".product_changes | length")
  if [[ $pending_changes_count -eq 0 ]]; then
    echo "Detected $pending_changes_count pending changes. No need to apply."
    exit 1
  else
    send_email
    exit 0
  fi
}

function send_email (){
    TIME=$(date +%T)
echo "sending email for pending changes"

cat > email/pendingheaders.txt <<EOH
MIME-version: 1.0
Content-Type: text/html; charset="UTF-8"
EOH

#Begin the Email Body
cat > email/pending.html <<EOH
<html>
<body>
<p>
<pre>
EOH

  pending_list=$(om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    pending-changes)

echo "Here they are $pending_list"

printf "<p> Pending changes were detected in ${ENV}. An apply will be run.<h2><font face=Arial>Pending Installs:</font></h2>$pending_list</body></html>" \
>> email/pending.html

printf "${ENV}-Pending Changes detected"> email/pendingsubject.txt
}

check_for_pending_changes