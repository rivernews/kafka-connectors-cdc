# Kafka Connect CDC (Change Data Capture)

[![Build Status](https://travis-ci.com/rivernews/kafka-connectors-cdc.svg?branch=master)](https://travis-ci.com/rivernews/kafka-connectors-cdc)

Kafka connect image that includes Debezium postgres source connector and Elasticsearch sink connector.

This image is built based on [Bitnami Kafka Docker Image](https://hub.docker.com/r/bitnami/kafka). You can [go to the Dockerhub page of this image](https://hub.docker.com/repository/docker/shaungc/kafka-connectors-cdc).

## Configuration

| Environment Variable | Default | Description |
| -------------------  | ------- | ----------- |
| KAFKA_HEAP_OPTS | `'-Xmx512m -Xms512m'` | Java heap size |