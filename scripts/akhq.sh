#!/bin/bash

if [ ! -e /usr/local/akhq ]; then
    sudo wget -P /opt https://github.com/tchiotludo/akhq/releases/download/0.21.0/akhq-0.21.0.tar
    sudo tar xvf /opt/akhq-0.21.0.tar -C /usr/local
    sudo ln -s /usr/local/akhq-0.21.0 /usr/local/akhq
fi

echo "
akhq:
  connections:
    dev:
      properties:
        bootstrap.servers: \"192.168.64.9:9092\"
        security.protocol: SASL_PLAINTEXT
        sasl.mechanism: SCRAM-SHA-512
        sasl.jaas.config: org.apache.kafka.common.security.scram.ScramLoginModule required username="client" password="${SCRAM_CLIENT_PASSWORD}";

" > /usr/local/akhq/application-dev.yml

java -Dmicronaut.config.files=/usr/local/akhq/application-dev.yml -jar /usr/local/akhq/lib/akhq.jar
