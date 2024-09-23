#!/bin/bash

sudo chmod 644 $(pwd)/master/conf/my.cnf
sudo chmod 644 $(pwd)/slaves/conf/1/my.cnf
sudo chmod 644 $(pwd)/slaves/conf/2/my.cnf

docker-compose -f mariadb-replication-docker-compose.yaml up -d