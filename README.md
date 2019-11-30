# Kafka Connect CDC (Change Data Capture)

[![Build Status](https://travis-ci.com/rivernews/kafka-connectors-cdc.svg?branch=master)](https://travis-ci.com/rivernews/kafka-connectors-cdc)

Kafka connect image that includes Debezium postgres source connector and Elasticsearch sink connector.

This image is built based on [Bitnami Kafka Docker Image](https://hub.docker.com/r/bitnami/kafka). You can [go to the Dockerhub page of this image](https://hub.docker.com/repository/docker/shaungc/kafka-connectors-cdc).



## Configuration

Environment variables listed here without a non-empty default are all required and need you to supply them during either runtime, or build time if you are building your own docker based on this image. 

The entrypoint will check connection for postgres database and elaticsearch service before running Kafka Connect. Before it can connect to them, it will keep waiting. Therefore, if you don't configure the `SQL_*` variables here for postgres and the elasticsearch hostname/port, the script will not proceed.

This image is originally intended for use in Kubernetes cluster, hence it does not apply any SSL security since connections within the cluster should be safe from external connectin attempt. If you require SSL, however, you can refer to the bitnami base image we are using as well as the `entrypoint.sh` script to see how to alter the behavior based on your needs.

| Environment Variable | Default | Description |
| -------------------  | ------- | ----------- |
| KAFKA_HEAP_OPTS | `'-Xmx512m -Xms512m'` | Java heap size |
| POSTGRES_DATABASE_LOGICAL_NAME | `appl_tracky` | A label that will be used as prefix across kafka topics |
| SQL_HOST | `(empty)` | Postgres server hostname |
| SQL_PORT | `(empty)` | Postgres server port |
| SQL_DATABASE | `(empty)` | Postgres database name |
| SQL_USER | `(empty)` | Postgres user |
| SQL_PASSWORD | `(empty)` | Postgres server password |
| ELASTICSEARCH_HOST | `(empty)` | Elasticsearch hostname |
| ELASTICSEARCH_PORT | `(empty)` | Elasticsearch port |


