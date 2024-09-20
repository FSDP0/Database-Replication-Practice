# MariaDB 이중화

### 1. 폴더 구조
```shell
mariadb
├─ mariadb-replication-docker-compose.yaml  # Docker Compose YAML 파일
├─ master                                   # MariaDB(Master) 관련 폴더
│  ├─ conf
│  │  └─ my.cnf           
│  └─ sql
│     └─ init.sql
├─ slaves                                   # MariaDB(Slave) 관련 폴더
│  ├─ conf
│  │  ├─ 1                                  # Slave #1
│  │  │  └─ my.cnf
│  │  └─ 2                                  # Slave #2
│  │     └─ my.cnf
│  └─ sql
│     └─ init.sql
└─ README.md
```

### 2. Docker Compose YAML 작성
`mariadb-replication-docker-compose.yaml`
```yaml
x-mariadb-config: &common_config
  image: &common_image mariadb:lts-noble
  environment: &common_env
    MYSQL_ROOT_PASSWORD: password
    TZ: Asia/Seoul
  extra_hosts: &common_hosts
    host.docker.internal: host-gateway
  restart: always

x-mariadb-slave-config: &common_slave_config
  depends_on: master1

services:
  master1: 
    <<: *common_config
    container_name: mariadb-master
    image: *common_image
    ports:
      - 3306:3306
    volumes:
      - ./master/data:/var/lib/mysql
      - ./master/conf/my.cnf/:/etc/mysql/my.cnf
      - ./master/sql:/docker-entrypoint-initdb.d
    environment: 
      <<: *common_env
    extra_hosts: 
      <<: *common_hosts

  slave1:
    <<: *common_config
    container_name: mariadb-slave-1
    image: *common_image
    user: 1000:999
    ports:
      - 3307:3306
    volumes: 
      - ./slaves/data/1:/var/lib/mysql
      - ./slaves/conf/1/my.cnf:/etc/mysql/my.cnf
      - ./slaves/sql:/docker-entrypoint-initdb.d
    environment:
      <<: *common_env
    extra_hosts:
      <<: *common_hosts
    depends_on:
      - master1

  slave2:
    container_name: mariadb-slave-2
    image: *common_image
    ports:
      - 3308:3306
    volumes:
      - ./slaves/data/2:/var/lib/mysql
      - ./slaves/conf/2/my.cnf:/etc/mysql/my.cnf
      - ./slaves/sql:/docker-entrypoint-initdb.d
    environment:
      <<: *common_env
    extra_hosts:
      <<: *common_hosts
    depends_on:
      - master1
```

### 2. Master 설정
#### a. `my.cnf`
```ini
[mysqld]
server_id=1

log-bin
log-basename=mariadb-master
binlog_format = row 
expire_logs_days = 2

bind-address=0.0.0.0
```
#### b. `init.sql`
```sql
CREATE USER 'slave'@'%' IDENTIFIED BY 'password';

GRANT REPLICATION SLAVE ON *.* TO 'slave'@'%';

CREATE DATABASE example;

GRANT SELECT ON example.* TO 'slave'@'%' IDENTIFIED BY 'password';
```

### 3. Slave 1 설정
#### a. `my.conf`
```ini
[mysqld]
server_id=2

log-bin
log-basename=mariadb-slave-1
binlog_format=row
expire_logs_days=2

bind-address=0.0.0.0

read_only=1
```

#### b. `init.sql`
```sql
CREATE DATABASE example;

CHANGE MASTER TO
    MASTER_HOST='host.docker.internal',
    MASTER_USER='slave',
    MASTER_PASSWORD='password',
    MASTER_PORT=3306,
    MASTER_LOG_FILE='mariadb-master-bin.000002',
    MASTER_LOG_POS=342,
    MASTER_CONNECT_RETRY=10;

START SLAVE;
```

### 4. Slave 2 설정
#### a. `my.conf`
```ini
[mysqld]
server_id=3

log-bin
log-basename=mariadb-slave-2
binlog_format=row
expire_logs_days=2

bind-address=0.0.0.0

read_only=1
```

#### b. `init.sql`
```sql
CREATE DATABASE example;

CHANGE MASTER TO
    MASTER_HOST='host.docker.internal',
    MASTER_USER='slave',
    MASTER_PASSWORD='password',
    MASTER_PORT=3306,
    MASTER_LOG_FILE='mariadb-master-bin.000002',
    MASTER_LOG_POS=342,
    MASTER_CONNECT_RETRY=10;

START SLAVE;
```