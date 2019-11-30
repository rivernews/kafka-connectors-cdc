# Kafka Connect CDC (Change Data Capture)

[![Build Status](https://travis-ci.com/rivernews/kafka-connectors-cdc.svg?branch=master)](https://travis-ci.com/rivernews/kafka-connectors-cdc)

Kafka connect image that includes Debezium postgres source connector and Elasticsearch sink connector.

This image is built based on [Bitnami Kafka Docker Image](https://hub.docker.com/r/bitnami/kafka). You can [go to the Dockerhub page of this image](https://hub.docker.com/repository/docker/shaungc/kafka-connectors-cdc).



## Configuration

| Environment Variable | Default | Description |
| -------------------  | ------- | ----------- |
| KAFKA_HEAP_OPTS | `'-Xmx512m -Xms512m'` | Java heap size |
| POSTGRES_DATABASE_LOGICAL_NAME | `appl_tracky` | A label that will be used as prefix across kafka topics |
| SQL_HOST | ` ` | Postgres server hostname |
| SQL_PORT | ` ` | Postgres server port |
| SQL_DATABASE | ` ` | Postgres database name |
| SQL_USER | ` ` | Postgres user |
| SQL_PASSWORD | ` ` | Postgres server password |
