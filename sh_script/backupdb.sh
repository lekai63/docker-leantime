#!/bin/bash

# 设置变量
DOCKER_BACKUP_DIR="/var/lib/mysql-backup"
HOST_BACKUP_DIR="/home/lighthouse/data/mysql-backup"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE=backup_${DATE}.sql
# COMPRESSED_FILE=${BACKUP_FILE}.gz

# 执行备份命令
docker exec -u mysql:mysql mysql mysqldump \
  --quick \
  --column-statistics=0 \
  --no-tablespaces \
  --user=admin \
  --password=kksqladmin \
  --host=mysql leantime \
  --port=3306 \
  --result-file=${DOCKER_BACKUP_DIR}/${BACKUP_FILE}



# 可选:删除旧的备份文件(例如,保留最近28次备份)
docker exec -u mysql:mysql mysql find $DOCKER_BACKUP_DIR -name "backup_*.sql" -type f | sort -r | tail -n +29 | xargs rm -f
