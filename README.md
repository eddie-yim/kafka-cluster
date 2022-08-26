# kafka-cluster
## Required Environments in ZooKeeper
```
ZK_HOSTS
ZK_MYID
DLM_ADMIN_PASSWORD
DLM_ZOOKEEPER_PASSWORD
```
## Required Environment in Kafka
```
BROKER_ID
ZOOKEEPER_CONNECT=<your_zookeeper_host_1>:2181,<your_zookeeper_host_2>:2181,<your_zookeeper_host_3>:2181
SCRAM_ADMIN_PASSWORD
SCRAM_BROKER_PASSWORD
SCRAM_CLIENT_PASSWORD
```
## Kafka test using cli in broker server
```
./bin/kafka-topics.sh --list --bootstrap-server localhost:9092 --command-config <YOUR_BROKER_AUTH_PROPERTIES>.properties
```
```
./bin/kafka-topics.sh --create --topic yourtest --replication-factor 1 --partitions 1 --bootstrap-server localhost:9092 --command-config <YOUR_BROKER_AUTH_PROPERTIES>.properties
```
