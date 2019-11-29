FROM bitnami/kafka:2.3.1-debian-9-r0
# FROM wurstmeister/kafka:2.12-2.3.0
# FROM debezium/connect:0.10

# bitnami dockerhub: https://hub.docker.com/r/bitnami/kafka
# version follows k8's helm chart: https://github.com/bitnami/charts/blob/master/bitnami/kafka/values.yaml

# wurstmeister's kafka image repo: https://github.com/wurstmeister/kafka-docker

# debezium connect image repo: https://github.com/debezium/docker-images/tree/master/connect/0.10

# we need access to run entrypoint script hence using root here
# there are other ways doing this, including 
# (1) use a init container to change script permission
# (2) use other stuff recommended in doc, see bitnami's doc: https://docs.bitnami.com/containers/how-to/work-with-non-root-containers/
USER root

# our custom image dockerhub page: https://hub.docker.com/repository/docker/shaungc/kafka-connectors-cdc

ENV KAFKA_HOME=/opt/bitnami/kafka
ENV KAFKA_CONFIG="${KAFKA_HOME}/config"
ENV KAFKA_CFG_PLUGIN_PATH="${KAFKA_HOME}/connectors"
# ENV KAFKA_CFG_PLUGIN_PATH="${KAFKA_CONNECT_PLUGINS_DIR}"

ENV KAFKA_CONNECT_ES_DIR=$KAFKA_CFG_PLUGIN_PATH/kafka-connect-elasticsearch
ENV KAFKA_CONNECT_POSTGRES_DIR=$KAFKA_CFG_PLUGIN_PATH/kafka-connect-postgres

# default ENV values: https://vsupalov.com/docker-arg-env-variable-guide/#setting-env-values
ENV KAFKA_HEAP_OPTS='-Xmx512m -Xms512m'
# ENV HEAP_OPTS='-Xmx512m -Xms512m'
ENV ALLOW_PLAINTEXT_LISTENER=yes
# ENV ADVERTISED_PORT 8083


# install psql based on https://wiki.debian.org/PostgreSql#Installation
RUN apt-get update -y && apt-get install -y jq postgresql postgresql-client unzip


# Install connectors by copying over the jars as below
# or, using confluent cli: https://docs.confluent.io/current/connect/managing/extending.html#create-a-docker-image-containing-c-hub-connectors
# RUN confluent-hub install --no-prompt debezium/debezium-connector-postgresql:0.10.0 \
#     && confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:5.3.1

# debezium postgres connector: https://www.confluent.io/hub/debezium/debezium-connector-postgresql
# RUN mkdir -p ${KAFKA_CONNECT_POSTGRES_DIR} &&\
#     curl -sO  https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/0.10.0.Final/debezium-connector-postgres-0.10.0.Final-plugin.tar.gz &&\
#     tar xf debezium-connector-postgres-0.10.0.Final-plugin.tar.gz --directory ${KAFKA_CONNECT_POSTGRES_DIR}

# # COPY ./debezium-connector-postgres/. ${KAFKA_CFG_PLUGIN_PATH}/debezium-connector-postgres/


# # es connector jar hub page: https://www.confluent.io/hub/confluentinc/kafka-connect-elasticsearch
# # RUN mkdir -p ${KAFKA_CFG_PLUGIN_PATH}/confluentinc-kafka-connect-elasticsearch
# RUN mkdir -p ${KAFKA_CONNECT_ES_DIR} &&\
#     curl -sO  https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-elasticsearch/versions/5.3.1/confluentinc-kafka-connect-elasticsearch-5.3.1.zip &&\
#     unzip confluentinc-kafka-connect-elasticsearch-5.3.1.zip -d ${KAFKA_CONNECT_ES_DIR}

# COPY ./confluentinc-kafka-connect-elasticsearch-5.3.1/. $KAFKA_CONNECT_ES_DIR/


# we replace the default connect-standalone.properties so we can properly resolve to our local Kafka docker development
COPY kafka-connect.properties ${KAFKA_CONFIG}/

# configure connectors: https://docs.confluent.io/current/connect/managing/configuring.html#configuring-connectors
COPY postgres-connector.properties ${KAFKA_CONFIG}/
COPY elasticsearch-connector.properties ${KAFKA_CONFIG}/


# standalone mode args: https://docs.confluent.io/5.1.2/connect/userguide.html#standalone-mode
# RUN mkdir -p /tmp
COPY entrypoint.sh /tmp/entrypoint.sh
RUN chmod +x /tmp/entrypoint.sh
ENTRYPOINT ["sh", "-c", "/tmp/entrypoint.sh"]