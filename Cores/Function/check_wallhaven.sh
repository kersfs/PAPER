#!/bin/bash
#VERSION="1.0.2"
#主程序测试
check_wallhaven() {
    local ping_time
    ping_time=$(get_ping_time "wallhaven.cc")
    if [[ "$ping_time" =~ ^[0-9]+(\.[0-9]+)?$ ]] && [ -n "$ping_time" ]; then
        if [ "$(echo "$ping_time >= 10 && $ping_time <= 600" | bc -l 2>/dev/null)" -eq 1 ]; then
            if test_api_key; then
                echo "$(date '+%m-%d %H:%M') | 主程序链接成功，开启关键词搜索" >&2
                return 0
            else
                return 1
            fi
        else
            return 1
        fi
    else
        return 1
    fi
}