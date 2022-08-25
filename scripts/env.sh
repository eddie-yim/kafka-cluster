echo -e "export ZK_HOSTS=localhost
export ZK_MYID=1
export DLM_ADMIN_PASSWORD=apassword
export DLM_ZOOKEEPER_PASSWORD=zpassword
export BROKER_ID=1
export ZOOKEEPER_CONNECT=localhost:2181
export SCRAM_ADMIN_PASSWORD=apassword
export SCRAM_BROKER_PASSWORD=bpassword
export SCRAM_CLIENT_PASSWORD" >> /etc/profile

source /etc/profile
