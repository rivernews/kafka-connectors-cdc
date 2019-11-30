set -e

# set prefix for postgres connector for each database
# NOTICE: postgres slot name can only contain [a-z0-9_]: https://github.com/zalando/patroni/pull/277
DATABASE_APPLTRACKY_LOGICAL_NAME=${DATABASE_APPLTRACKY_LOGICAL_NAME:-appl_tracky}


wait_till_es_connected() {
    URL=${1:-localhost}
    RETRY_INTERVAL=${2:-5}

    # health check es based on: https://github.com/elastic/elasticsearch-py/issues/778#issuecomment-384389668
    echo 'INFO: initial probe into elasticsearch cluster...'
    until $(curl --silent --output /dev/null --head --fail "$URL"); do
        echo 'INFO: still resolving elasticsearch host...'
        sleep ${RETRY_INTERVAL}
    done

    # First wait for ES to start...
    response=$(curl --silent $URL)

    until [ "$response" = "200" ]; do
        response=$(curl --write-out %{http_code} --silent --output /dev/null "$URL")
        >&2 echo "WARNING: Elastic Search is not 200 yet - sleeping"
        sleep ${RETRY_INTERVAL}
    done

    # next wait for ES status to turn to Green
    health="$(curl -fsSL "$URL/_cat/health?h=status")"
    health="$(echo "$health" | sed -r 's/^[[:space:]]+|[[:space:]]+$//g')" # trim whitespace (otherwise we'll have "green ")

    until [ "$health" = 'green' ]; do
        health="$(curl -fsSL "$host/_cat/health?h=status")"
        health="$(echo "$health" | sed -r 's/^[[:space:]]+|[[:space:]]+$//g')" # trim whitespace (otherwise we'll have "green ")
        >&2 echo "Elastic Search is not green yet - sleeping"
        sleep ${RETRY_INTERVAL}
    done

    >&2 echo "Elastic Search is up"
    
}


echo ""
echo ""
echo ""
echo "INFO: elasticsearch host is ${ELASTICSEARCH_HOST}"
echo "INFO: elasticsearch port is ${ELASTICSEARCH_PORT}"
echo "INFO: waiting for elasticsearch to be ready..."
wait_till_es_connected ${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}


wait_till_postgres_connected() {
    SQL_HOST=${1:-"postgres"}
    SQL_USER=${2:-"admin"}
    SQL_DATABASE=${3:-"default_database"}
    MAX_ATTEMPTS=${4:-999}
    RETRY_INTERVAL=${5:-5}

    ATTEMPTS=0
    # command based on https://stackoverflow.com/a/46862514/9814131
    # see all psql args: https://www.postgresql.org/docs/9.2/app-psql.html
    until psql --host=$SQL_HOST --username=$SQL_USER --dbname=$SQL_DATABASE --password &>/dev/null || [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; do
        ATTEMPTS=$((ATTEMPTS + 1))
        echo "WARNING: Cannot connect to ${SQL_HOST}, retrying in ${RETRY_INTERVAL} seconds...(${ATTEMPTS}/${MAX_ATTEMPTS})"
        sleep ${RETRY_INTERVAL}
    done

    if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        echo "ERROR: Cannot connect to ${SQL_HOST} and already tried too many times. "
        exit 1
    fi

    echo "INFO: Connected to ${SQL_HOST} sunccessfully."
}


echo ""
echo ""
echo ""
echo "INFO: postgres host is ${SQL_HOST}"
echo "INFO: postgres port is ${SQL_PORT}"
echo "INFO: waiting for postgres to be ready..."
wait_till_postgres_connected ${SQL_HOST} ${SQL_USER} ${SQL_DATABASE}


echo ""
echo ""
echo ""
echo "INFO: installing  connectors..."
cd /tmp
mkdir -p $KAFKA_CFG_PLUGIN_PATH

curl -sO  https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/0.10.0.Final/debezium-connector-postgres-0.10.0.Final-plugin.tar.gz &&\
tar xf debezium-connector-postgres-0.10.0.Final-plugin.tar.gz --directory $KAFKA_CFG_PLUGIN_PATH

curl -sO  https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-elasticsearch/versions/5.3.1/confluentinc-kafka-connect-elasticsearch-5.3.1.zip &&\
unzip confluentinc-kafka-connect-elasticsearch-5.3.1.zip -d $KAFKA_CFG_PLUGIN_PATH


echo ""
echo ""
echo ""
echo "INFO: writing credentials to file..."

echo "POSTGRES_HOST=${SQL_HOST}" > /tmp/credentials.properties
echo "POSTGRES_DATABASE=${SQL_DATABASE}" >> /tmp/credentials.properties
echo "POSTGRES_USER=${SQL_USER}" >> /tmp/credentials.properties
echo "POSTGRES_PASSWORD=${SQL_PASSWORD}" >> /tmp/credentials.properties
echo "POSTGRES_PORT=${SQL_PORT}" >> /tmp/credentials.properties

echo "INFO: writing more properties to file..."
echo "PLUGINS_PATH=${KAFKA_CFG_PLUGIN_PATH}" >> /tmp/credentials.properties

echo "INFO: writing additional postgres properties to file..."
echo "POSTGRES_APPLTRACKY_SERVER_LOGICAL_NAME=${DATABASE_APPLTRACKY_LOGICAL_NAME}__postgres" >> /tmp/credentials.properties
echo "POSTGRES_APPLTRACKY_SLOT_NAME=${DATABASE_APPLTRACKY_LOGICAL_NAME}__slot" >> /tmp/credentials.properties
echo "POSTGRES_APPLTRACKY_PUBLICATION_NAME=${DATABASE_APPLTRACKY_LOGICAL_NAME}__publication" >> /tmp/credentials.properties


echo ""
echo ""
echo ""
echo "INFO: configuring elasticsearch indices in 10 seconds..."
# elasticsearch put index API: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
# use HERE document with curl, based on SO: https://stackoverflow.com/questions/34847981/curl-with-multiline-of-json
# es date format: https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-date-format.html
# 
# adding mappings
# notice: if you want to specify the mapping name `mappings: { "my_mapping_name" ... }`, please make sure `my_mapping_name` mapping is already created, otherwise you could get parse error in elasticsearch.
# "mappings": {
#     "properties": {
#         "created_at": {
#             "type": "date",
#             "format": "strict_date_time"
#         }
#     }
# }
#
# configure for datetime fields using dynamic template:  
# https://github.com/confluentinc/kafka-connect-elasticsearch/issues/342#issuecomment-539034678
# "mappings": {
#     "dynamic_templates": [
#         {
#             "patch_datetime_fields_template": {
#                 "match_pattern": "regex",
#                 "match": "^(created_at|modified_at)$",
#                 "mapping": {
#                     "type": "date",
#                     "dynamic_date_formats": ["strict_date_time"]
#                 }
#             }
#         }
#     ]
# }
sleep 10
curl --silent -XPUT -H 'Content-Type: application/json' http://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_template/appl_tracky_template --data-binary @- << EOF 
{
    "index_patterns": ["appl_tracky*"],
    "settings": { 
        "index" : {
            "number_of_replicas" : 0
        }
    },
    "mappings": {
        "dynamic_date_formats": ["strict_date_time"]
    }
}
EOF
# you should get response of `{"acknowledged":true}`


echo ""
echo ""
echo ""
echo "INFO: launching kafka connect in standalone mode in 10 seconds..."
sleep 10
${KAFKA_HOME}/bin/connect-standalone.sh ${KAFKA_CONFIG}/kafka-connect.properties ${KAFKA_CONFIG}/postgres-connector.properties ${KAFKA_CONFIG}/elasticsearch-connector.properties
