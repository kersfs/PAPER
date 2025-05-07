#!/bin/bash
#VERSION="1.0.2"
#清理Really文件
cleanup_really() {
    local retention_days=7
    if [ -z "$REALLY_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | REALLY_DIR 未定义，默认使用 /storage/emulated/0/Wallpaper/Cores/Reallys" >&2
        REALLY_DIR="/storage/emulated/0/Wallpaper/Cores/Reallys"
    fi
    if [ ! -d "$REALLY_DIR" ]; then
        mkdir -p "$REALLY_DIR"
        echo "$(date '+%m-%d %H:%M') | 创建Reallys目录：$REALLY_DIR" >&2
    fi
    if [ ! -w "$REALLY_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | Reallys目录 $REALLY_DIR 无写权限，尝试修复" >&2
        chmod -R 755 "$REALLY_DIR" 2>/dev/null
        if [ ! -w "$REALLY_DIR" ]; then
            echo "$(date '+%m-%d %H:%M') | 无法修复 $REALLY_DIR 权限，跳过Really文件清理" >&2
            return 1
        fi
    fi
    echo "$(date '+%m-%d %H:%M') | 执行清理Really文件" >&2
    find "$REALLY_DIR" -type f -mtime +$retention_days -delete 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | 清理超过 $retention_days 天的Really文件成功" >&2
    else
        echo "$(date '+%m-%d %H:%M') | Really文件清理失败，请检查 $REALLY_DIR 权限或 find 命令" >&2
        return 1
    fi
}