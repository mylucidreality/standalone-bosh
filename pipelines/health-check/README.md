fly -t xxx sp -p health-check-verbose -c pipelines/health-check/pipeline.yml -l master-params/xxx-params.yml -y trigger-schedule=false -y VERBOSE_TEST=true -n

fly -t xxx sp -p health-check -c pipelines/health-check/pipeline.yml -l master-params/xxx-params.yml -y trigger-schedule=true -y VERBOSE_TEST=false -n