#!/bin/bash
FAILURE=false

#Create email header
cat > email/smoketestheaders.txt <<EOH
MIME-version: 1.0
Content-Type: text/html; charset="UTF-8"
EOH

#Begin the Email Body
cat > email/smoketest.html <<EOH
<html>
<body>
<p>
<pre>
EOH

cat > email/verboseresults.html <<EOH
<h3><font face=Arial>Smoke-Test results:</font></h3>
EOH

cat > email/verbosetest.html <<EOH
<h3><font face=Arial>Smoke-Test details:</font></h3>
EOH

TIME=$(date +%T)
echo "logging into  $PCF_URL"
#Create the cert to use for bosh login
echo "CERT:: $PCF_CERT"
echo -e "$PCF_CERT" > ca.cert
export BOSH_CLIENT=$BOSH_ADMIN_CLIENT
export BOSH_CLIENT_SECRET=$PCF_SCRT

#Create Bosh v2 alias-env
bosh alias-env $PCF_ENV -e $PCF_URL --ca-cert ca.cert

#log into bosh
{
    echo "logging in"
    RESULT="$(bosh -e $PCF_ENV log-in -n 2>&1 > /dev/null)"
} || {
cat >> email/smoketest.html <<EOH
<h1>ERROR!!!  CANNOT LOG INTO DIRECTOR</h1>$RESULT</p>
</body>
</html>
EOH
echo $RESULT
exit 0
}

echo "logged in"

#Writes heading
printf "<h2><font face=Arial>Test results for $PCF_ENV </font></h2>" >> email/smoketest.html

#BOSH v2
results=$(bosh -e $PCF_ENV vms|grep 'unresponsive\|failing' | grep -v bosh-health-check)

if [ -z "$results" ]; then
    printf "<h3>All VM's responding as expected</h3>" >> email/smoketest.html
else
    printf "<h3>Unresponsive $PCF_ENV VMs:</h3><p>$results</p>" >> email/smoketest.html
    FAILURE=true
fi

printf "<h3>Cloud-Check deployments results:</h3>" >> email/smoketest.html

for i in $(bosh -e $PCF_ENV deployments --column name | grep .); do
    #runs cloud check
	if [ "$i" != "bosh-health-check" ] ; then
	    bosh -e $PCF_ENV -d $i cck -r &> /dev/null
	    if [ $? == 0 ] ; then
    	        printf "<br>$i passed cloud-check" >> email/smoketest.html
    	else
        	printf "<b><p><font face=Arial color=red>$i failed cloud-check</font></b></p>" >> email/smoketest.html
        	FAILURE=true
    	fi
	fi
    #See if deployment has a smoke test.  If it does, run it.
    if $VERBOSE_TEST ; then
		case $i in
			cf*)
				ERRAND_RESULT=$(bosh -e $PCF_ENV -d $i run-errand smoke_tests)
				if [ $? == 1 ] ; then
					printf "<font face=Arial color=red>$i failed its Smoke-Test</font><br>" >> email/verboseresults.html
					echo "<h4>$i details</h4>${ERRAND_RESULT}" >> email/verbosetest.html
					FAILURE=true
				fi
				;;
			p-redis*|p-rabbitmq*|apm*|p-mysql*|p-spring*)
				ERRAND_RESULT=$(bosh -e $PCF_ENV -d $i run-errand smoke-tests)
				if [ $? == 1 ] ; then
					printf "<font face=Arial color=red>$i failed its Smoke-Test</font><br>" >> email/verboseresults.html
					echo "<h4>$i details</h4>${ERRAND_RESULT}" >> email/verbosetest.html
					FAILURE=true
				fi
				;;
			p-metrics-forwarder*)
				ERRAND_RESULT=$(bosh -e $PCF_ENV -d $i run-errand test-metrics-forwarder)
				if [ $? == 1 ] ; then
					printf "<font face=Arial color=red>$i failed its Smoke-Test</font><br>" >> email/verboseresults.html
					echo "<h4>$i details</h4>${ERRAND_RESULT}" >> email/verbosetest.html
					FAILURE=true
				fi
				;;
			redislabs-service-broker*)
				ERRAND_RESULT=$(bosh -e $PCF_ENV -d $i run-errand redislabs-smoke-test)
				if [ $? == 1 ] ; then
					printf "<font face=Arial color=red>$i failed its Smoke-Test</font><br>" >> email/verboseresults.html
					echo "<h4>$i details</h4>${ERRAND_RESULT}" >> email/verbosetest.html
					FAILURE=true
				fi
				;;
			p-scheduler*)
				ERRAND_RESULT$(bosh -e $PCF_ENV -d $i run-errand test-scheduler)
				if [ $? == 1 ] ; then
					printf "<font face=Arial color=red>$i failed its Smoke-Test</font><br>" >> email/verboseresults.html
					echo "<h4>$i details</h4>${ERRAND_RESULT}" >> email/verbosetest.html
					FAILURE=true
				fi
				;;
			p-metrics*)
				ERRAND_RESULT=$(bosh -e $PCF_ENV -d $i run-errand integration_tests)
				if [ $? == 1 ] ; then
					printf "<font face=Arial color=red>$i failed its Smoke-Test</font><br>" >> email/verboseresults.html
					echo "<h4>$i details</h4>${ERRAND_RESULT}" >> email/verbosetest.html
					FAILURE=true
				fi
				;;
		esac
	fi
done
bosh -e $PCF_ENV log-out
if $VERBOSE_TEST ; then
    cat email/verboseresults.html email/verbosetest.html >> email/smoketest.html
fi
printf "</pre></p><p><i><b>Smoketest run time: $TIME - $(date +%T)</i></b>" >> email/smoketest.html
cat >> email/smoketest.html <<EOH
</p>
</body>
</html>
EOH

if $FAILURE ; then
    if  $VERBOSE_TEST ; then
        printf " $PCF_ENV-Verbose smoketest"> email/smoketestsubject.txt
    else
        printf " $PCF_ENV-FAILED health check" > email/smoketestsubject.txt
    fi
    exit 1
else
    printf " $PCF_ENV-passed health check" > email/smoketestsubject.txt
    exit 0
fi
