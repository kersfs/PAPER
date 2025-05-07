#!/bin/bash
#VERSION="1.0.2"
#加载Really文件内容到缓存
load_really_cache() {
    if [ -z "$REALLY_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | REALLY_FILE 未定义，尝试重新设置..." >&2
        set_really_file "$PURITY" "$current_category"
        if [ -z "$REALLY_FILE" ]; then
            echo "$(date '+%m-%d %H:%M') | REALLY_FILE 仍然未定义，跳过加载缓存" >&2
            return 1
        fi
    fi
    echo "$(date '+%m-%d %H:%M') | 加载Really文件" >&2
    if [ ! -f "$REALLY_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | Really文件不存在：$REALLY_FILE，创建空文件" >&2
        touch "$REALLY_FILE"
    fi
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [ -n "$line" ]; then
            REALLY_CACHE["$line"]=1
        fi
    done < "$REALLY_FILE"
}