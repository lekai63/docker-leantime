#!/bin/bash

DOCKER_BACKUP_DIR="/var/lib/mysql-backup"
HOST_BACKUP_DIR="/home/lighthouse/data/mysql-backup"
LATEST_BACKUP=$(ls -t ${HOST_BACKUP_DIR}/backup_*.sql | head -n1)
LATEST_BACKUP_FILE="$(basename ${LATEST_BACKUP})"
COMPRESSED_FILE="$(basename ${HOST_BACKUP_DIR}/${LATEST_BACKUP}).gz"

# 压缩最新的备份文件
docker exec -u mysql:mysql mysql gzip -k ${DOCKER_BACKUP_DIR}/${LATEST_BACKUP_FILE}

# 上传到腾讯云对象存储
/home/lighthouse/app/coscli cp ${HOST_BACKUP_DIR}/${COMPRESSED_FILE} cos://backup/backupdb/leantime_${COMPRESSED_FILE}

# 删除压缩文件
docker exec -u mysql:mysql mysql rm ${DOCKER_BACKUP_DIR}/${COMPRESSED_FILE} -f
