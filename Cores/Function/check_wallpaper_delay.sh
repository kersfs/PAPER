#!/bin/bash
#VERSION="1.0.2"
# 检查壁纸设置后的延迟
check_wallpaper_delay() {
    local ping_target="wallhaven.cc"
    local ping_time
    ping_time=$(get_ping_time "$ping_target")
    if [ "$ping_time" == "unknown" ]; then
        echo "$(date '+%m-%d %H:%M') | 主程序启动失败，启用子程序初始化" >&2
        return 1
    elif [ "$(echo "$ping_time < 600" | bc -l)" -eq 1 ]; then
        echo "$(date '+%m-%d %H:%M') | 壁纸设置后延迟正常（${ping_time}ms）" >&2
        return 0
    else
        echo "$(date '+%m-%d %H:%M') | 壁纸设置后延迟过高（${ping_time}ms）" >&2
        return 1
    fi
}