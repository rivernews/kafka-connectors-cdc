# dockerhub page https://hub.docker.com/repository/docker/shaungc/kafka-connectors-cdc

# docker build -f debezium.Dockerfile -t shaungc/kafka-connectors-cdc:2.3.1-r29 .
docker build -f Dockerfile -t shaungc/kafka-connectors-cdc:2.3.1-r71 .
docker push shaungc/kafka-connectors-cdc