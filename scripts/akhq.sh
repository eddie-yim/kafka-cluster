#!/bin/bash

if [ ! -e /usr/local/akhq ]; then
    sudo mkdir /usr/local/akhq
    sudo wget -P /usr/local/akhq https://github.com/tchiotludo/akhq/releases/download/0.21.0/akhq-0.21.0-all.jar
fi

echo "
micronaut:
  server:
    port: 8080
akhq:
  connections:
    dev:
      properties:
        bootstrap.servers: \"192.168.64.9:9092\"
        security.protocol: SASL_PLAINTEXT
        sasl.mechanism: SCRAM-SHA-512
        sasl.jaas.config: org.apache.kafka.common.security.scram.ScramLoginModule required username=\"client\" password=\"${SCRAM_CLIENT_PASSWORD}\";

" > /usr/local/akhq/application-dev.yml

java -Dmicronaut.config.files=/usr/local/akhq/application-dev.yml -jar /usr/local/akhq/akhq-0.21.0-all.jar &
