#!/bin/bash
#VERSION="1.0.2"
#关键词选择
select_keyword() {
    local array_name=$1
    local map_key=$2
    local retry_count=0
    local max_retries=10
    local keyword
    eval "local -a keywords=(\"\${$array_name[@]}\")"
    if [ ${#keywords[@]} -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | $array_name 数组为空，请检查对应文件" >&2
        exit 3
    fi
    while [ $retry_count -lt $max_retries ]; do
        keyword="${keywords[$((RANDOM % ${#keywords[@]}))]}"
        if [ -n "$keyword" ] && [ -n "${QUERY_MAP[$keyword]}" ]; then
            eval "$map_key='$keyword'"
            echo "$(date '+%m-%d %H:%M') | 关键词选择: ${QUERY_MAP[$keyword]}" >&2
            return 0
        fi
        retry_count=$((retry_count + 1))
    done
    echo "$(date '+%m-%d %H:%M') | 无法选择有效关键词，请检查 $array_name 和 query_map.txt" >&2
    exit 1
}