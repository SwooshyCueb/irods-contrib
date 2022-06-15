#!/bin/bash

if [ -f /var/lib/irods-elk/.firstrun_done ]; then
	exit 0
fi

curl http://localhost:9200
curl -XPUT "http://localhost:9200/irods_audit"
rabbitmqctl add_user test test
rabbitmqctl set_user_tags test administrator
rabbitmqctl set_permissions -p / test ".*" ".*" ".*"
curl -XPUT http://localhost:9200/irods_audit/_settings -H 'Content-Type: application/json' -d'{"index.mapping.total_fields.limit": 2000}'

#curl -XPOST "http://localhost:5601/api/saved_objects/index-pattern/irods-audit-pattern" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d '{ "attributes": { "title": "irods_audit*", "timeFieldName": "@timestamp" } }'
curl -X POST "http://localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@/var/lib/irods-elk/example_kibana_dashboard.ndjson

touch /var/lib/irods-elk/.firstrun_done
systemctl disable elk-firstrun.service
