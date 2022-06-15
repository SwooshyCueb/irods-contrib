#!/bin/bash

if [ ! -f /var/lib/irods-elk/.firstrun_rmq_done ]; then
	echo "<5>Performing rabbitmq first-run setup..."

	rabbitmqctl add_user test test
	rabbitmqctl set_user_tags test administrator
	rabbitmqctl set_permissions -p / test ".*" ".*" ".*"

	echo "<5>Completed rabbitmq first-run setup"
	touch /var/lib/irods-elk/.firstrun_rmq_done
else
	echo "<5>Skipping rabbitmq first-run setup (already done)..."
fi

if [ ! -f /var/lib/irods-elk/.firstrun_es_done ]; then
	echo "<5>Performing elasticsearch first-run setup..."

	curl -sLS http://localhost:9200
	curl -sLS -XPUT "http://localhost:9200/irods_audit"
	curl -sLS -XPUT http://localhost:9200/irods_audit/_settings -H 'Content-Type: application/json' -d'{"index.mapping.total_fields.limit": 2000}'

	echo "<5>Completed elasticsearch first-run setup"
	touch /var/lib/irods-elk/.firstrun_es_done
else
	echo "<5>Skipping elasticsearch first-run setup (already done)..."
fi

if [ ! -f /var/lib/irods-elk/.firstrun_kb_done ]; then
	while true; do
		echo "<5>Checking kibana status..."

		status_code="$(curl -sLSI -w "%{http_code}" -o /dev/null "http://localhost:5601/api/features" -H 'kbn-xsrf: true')"
		curl_ret=$?

		if [[ "$curl_ret" != "0" ]]; then
			echo "<4>Could not reach kibana (curl return code ${curl_ret})"
		elif [[ "$status_code" != "200" ]]; then
			echo "<4>Kibana is unhappy (got HTTP status ${status_code})"
		else
			echo "<5>Kibana seems ready"
			break
		fi
		echo "<5>Waiting 3 seconds and trying again..."
		sleep 3s
	done

	echo "<5>Performing kibana first-run setup..."

	#curl -sLS -XPOST "http://localhost:5601/api/saved_objects/index-pattern/irods-audit-pattern" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{ "attributes": { "title": "irods_audit*", "timeFieldName": "@timestamp" } }'
	curl -sLS -X POST "http://localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@/var/lib/irods-elk/example_kibana_dashboard.ndjson

	echo "<5>Completed kibana first-run setup"
	touch /var/lib/irods-elk/.firstrun_kb_done
else
	echo "<5>Skipping kibana first-run setup (already done)..."
fi
