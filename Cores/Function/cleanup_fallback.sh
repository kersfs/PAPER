#!/bin/bash
#VERSION="1.0.2"
#清理Fallback文件
cleanup_fallback() {
    local retention_days=7
    if [ -z "$FALLBACK_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | FALLBACK_DIR 未定义，默认使用 /storage/emulated/0/Wallpaper/Cores/Fallbacks" >&2
        FALLBACK_DIR="/storage/emulated/0/Wallpaper/Cores/Fallbacks"
    fi
    if [ ! -d "$FALLBACK_DIR" ]; then
        mkdir -p "$FALLBACK_DIR"
        echo "$(date '+%m-%d %H:%M') | 创建Fallback目录：$FALLBACK_DIR" >&2
    fi
    if [ ! -w "$FALLBACK_DIR" ]; then
        echo "$(date '+%m-%d %H:%M') | Fallback目录 $FALLBACK_DIR 无写权限，尝试修复" >&2
        chmod -R 755 "$FALLBACK_DIR" 2>/dev/null
        if [ ! -w "$FALLBACK_DIR" ]; then
            echo "$(date '+%m-%d %H:%M') | 无法修复 $FALLBACK_DIR 权限，跳过Fallback文件清理" >&2
            return 1
        fi
    fi
    echo "$(date '+%m-%d %H:%M') | 执行清理Fallback文件" >&2
    find "$FALLBACK_DIR" -type f -mtime +$retention_days -delete 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | 清理超过 $retention_days 天的Fallback文件成功" >&2
    else
        echo "$(date '+%m-%d %H:%M') | Fallback文件清理失败，请检查 $FALLBACK_DIR 权限或 find 命令" >&2
        return 1
    fi
}