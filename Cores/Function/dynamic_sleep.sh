#!/bin/bash
#VERSION="1.0.2"
# 动态休眠
dynamic_sleep() {
    local ping_target="v2.xxapi.cn"
    local ping_time
    local sleep_duration
    ping_time=$(get_ping_time "$ping_target")
    if [[ "$ping_time" =~ ^[0-9]+(\.[0-9]+)?$ ]] && [ -n "$ping_time" ]; then
        bc_result=$(echo "$ping_time < 100" | bc 2>/dev/null)
        if [ "$bc_result" = "1" ]; then
            sleep_duration=0.5
        else
            bc_result=$(echo "$ping_time < 300" | bc 2>/dev/null)
            if [ "$bc_result" = "1" ]; then
                sleep_duration=1
            else
                sleep_duration=1.5
            fi
        fi
    else
        sleep_duration=1.5
    fi
    echo "$(date '+%m-%d %H:%M') | 动态休眠：${sleep_duration}s（延迟：${ping_time}ms）" >&2
    sleep "$sleep_duration"
}