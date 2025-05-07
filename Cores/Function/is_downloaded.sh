#!/bin/bash
#VERSION="1.0.2"
#初始化数据库
is_downloaded() {
    sqlite3 "$DB_FILE" "SELECT 1 FROM downloaded WHERE url='$1'" | grep -q 1
}