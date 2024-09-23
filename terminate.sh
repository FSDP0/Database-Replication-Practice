#!/bin/bash

docker-compose -f mariadb-replication-docker-compose.yaml down

sudo rm -rf $(pwd)/master/data
sudo rm -rf $(pwd)/slaves/data