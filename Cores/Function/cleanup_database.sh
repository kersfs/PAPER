#!/bin/bash
#VERSION="1.0.2"
# 清理数据库
cleanup_database() {
    local max_records=777
    local record_count=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM downloaded;")
    if [ "$record_count" -gt "$max_records" ]; then
        echo "$(date '+%m-%d %H:%M') | 清理数据库，记录数 $record_count 超过 $max_records" >&2
        sqlite3 "$DB_FILE" "DELETE FROM downloaded WHERE rowid IN (SELECT rowid FROM downloaded ORDER BY rowid LIMIT (SELECT COUNT(*) - $max_records));"
    fi
}