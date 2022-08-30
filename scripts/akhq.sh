#!/bin/bash

if [ ! -e /usr/local/akhq ]; then
    sudo mkdir /usr/local/akhq
    sudo wget -P /usr/local/akhq https://github.com/tchiotludo/akhq/releases/download/0.21.0/akhq-0.21.0-all.jar
fi

echo "
micronaut:
  server:
    port: 8080
  security:
    enabled: true
akhq:
  connections:
    dev:
      properties:
        bootstrap.servers: \"192.168.64.9:9092\"
        security.protocol: SASL_PLAINTEXT
        sasl.mechanism: SCRAM-SHA-512
        sasl.jaas.config: org.apache.kafka.common.security.scram.ScramLoginModule required username=\"client\" password=\"${SCRAM_CLIENT_PASSWORD}\";
  security:
    basic-auth:
      - username: admin
        password: \"8D0AB724A7B65D8E1F823473A0349710F4B4015227F51E163F4634D0468DAD33\"
        groups:
        - admin
" > /usr/local/akhq/application.yml

nohup java -Dmicronaut.config.files=/usr/local/akhq/application.yml -jar /usr/local/akhq/akhq-0.21.0-all.jar 1> /dev/null 2>&1 &
