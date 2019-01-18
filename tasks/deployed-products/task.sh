#!/bin/bash

function env_report() {
    echo "Checking dem product deets on Ops Manager @ ${OPSMAN_DOMAIN_OR_IP_ADDRESS}"
    echo "CF_API ${CF_API}"

    TIME=$(date +%T)
cat > email/pendingheaders.txt <<EOH
MIME-version: 1.0
Content-Type: text/html; charset="UTF-8"
EOH

#Begin the Email Body
cat > email/pending.html <<EOH
<html>
<style>
table {
    font-family: arial, sans-serif;
    border-collapse: collapse;
}

td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

tr:nth-child(even) {
    background-color: #dddddd;
}
</style>
<body>
<p>
<pre>
EOH


cf login -a ${CF_API} --skip-ssl-validation -u reportuser -p P@ssW0rd
#buildpack_names=$(cf buildpacks | awk '{print $1}')
BUILDPACKS="<tr><th>BUILDPACK</th><th>VERSION</th></tr>"
BUILDPACKS+=$(cf buildpacks | awk -vOFC="\t" '{sub(/.*-/,"",$5);sub(/.zip/,"",$5); print "<tr><td>" $1 "</td><td>" $5 "</td></tr>"}' | tail -n +4)

#hwc_buildpack	hwc_buildpack-cached-v2.3.13.zip


# for BUILDPACK_NAME in $(cf buildpacks | awk '{print $1}')
# do
#   if [[ "$BUILDPACK_NAME" == 'Getting' ]]; then
#   continue
#   fi
#   BUILDPACK_NAME_HTML+="<tr><td>$BUILDPACK_NAME</td>"
# done

# for BUILDPACK_FILES in $(cf buildpacks | awk '{print $1 $5}')
# do
#   if [[ "$BUILDPACK_FILES" == 'Getting' ]]; then
#   continue
#   fi
#   BUILDPACK_FILES_HTML+="<td>$BUILDPACK_FILES</td></tr>"
# done

#buildpack_files=$(cf buildpacks | awk '{print $5}')
echo $BUILDPACKS

  deployment_list=$(om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    deployed-products)

  pending_list=$(om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    pending-changes)

  installations_list=$(om-linux \
    --target "https://${OPSMAN_DOMAIN_OR_IP_ADDRESS}" \
    --skip-ssl-validation \
    --username "${OPSMAN_USERNAME}" \
    --password "${OPSMAN_PASSWORD}" \
    installations|head -4)

# echo "Here they are 1 $deployment_list"
# echo "Here they are 3 $installations_list"
# echo "Here they are 5 $pending_list"


printf "<h2><font face=Arial>Deployed Products:</font></h2>$deployment_list \
<h2><font face=Arial>Buildpacks:</font></h2><table>$BUILDPACKS</table> \
<h2><font face=Arial>Pending Installs:</font></h2>$pending_list \
<h2><font face=Arial>Last apply change result:</font></h2>$installations_list" \
>> email/pending.html

printf "</table></body></html>" >> email/pending.html

printf "${ENV}-Environmental Report"> email/pendingsubject.txt
}

env_report