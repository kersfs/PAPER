#!/bin/bash
#VERSION="1.0.2"
#延迟提取
get_ping_time() {
    local target="$1"
    local ping_output
    # 执行 ping 并提取 time= 后面的数字（支持浮点数）
    ping_output=$(ping -c 1 "$target" 2>/dev/null | grep -i 'time' | grep -oE 'time[=: ]*[0-9]+(\.[0-9]+)?' | grep -oE '[0-9]+(\.[0-9]+)?' | head -n 1)
    # 检查是否提取到有效数字
    if [ -z "$ping_output" ] || ! [[ "$ping_output" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "-1"
        return
    fi  
    # 检查延迟是否小于无效
    if [[ $(echo "$ping_output < 10" | bc -l 2>/dev/null) -eq 1 ]]; then
        echo "-1"
        return
    fi    
    echo "$ping_output"
}