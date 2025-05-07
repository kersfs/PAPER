#!/bin/bash
# 初始化数据库
#VERSION="1.0.2"
if [ -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS downloaded (url TEXT PRIMARY KEY);"
fi