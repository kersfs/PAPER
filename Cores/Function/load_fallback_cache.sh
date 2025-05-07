#!/bin/bash
#VERSION="1.0.2"
#加载Fallback文件内容到缓存
load_fallback_cache() {
    if [ -z "$FALLBACK_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | FALLBACK_FILE 未定义，尝试重新设置..." >&2
        set_fallback_file "$PURITY" "$current_category"
        if [ -z "$FALLBACK_FILE" ]; then
            echo "$(date '+%m-%d %H:%M') | FALLBACK_FILE 仍然未定义，跳过加载缓存" >&2
            return 1
        fi
    fi
    echo "$(date '+%m-%d %H:%M') | 加载Fallback文件" >&2
    if [ ! -f "$FALLBACK_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | Fallback文件不存在：$FALLBACK_FILE，创建空文件" >&2
        touch "$FALLBACK_FILE"
    fi
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [ -n "$line" ]; then
            FALLBACK_CACHE["$line"]=1
        fi
    done < "$FALLBACK_FILE"
}