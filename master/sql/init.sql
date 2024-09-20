CREATE USER 'slave'@'%' IDENTIFIED BY 'password';

GRANT REPLICATION SLAVE ON *.* TO 'slave'@'%';

CREATE DATABASE example;

GRANT SELECT ON example.* TO 'slave'@'%' IDENTIFIED BY 'password';