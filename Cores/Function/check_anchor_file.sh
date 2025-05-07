#!/bin/bash
#VERSION="1.0.2"
#网络异常与主程序锚点检测
check_anchor_file() {
    # 初始化网络异常日志标志（如果未定义）
    if [ -z "$NETWORK_ANOMALY_LOGGED" ]; then
        NETWORK_ANOMALY_LOGGED=0
    fi
    
    # 检查 wallhaven.cc 和 v2.xxapi.cn 的网络延迟
    ping1=$(ping -c 1 wallhaven.cc 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')
    ping2=$(ping -c 1 v2.xxapi.cn 2>/dev/null | grep 'time=' | awk -F'time=' '{print $2}' | awk '{print $1}')

    # 处理空值，替换为 -1
    ping1=${ping1:- -1}
    ping2=${ping2:- -1}

    # 转换为数字
    ping1_ms=$(echo "$ping1" | bc)
    ping2_ms=$(echo "$ping2" | bc)

    # 检查网络状态
    if [[ -n "$ping1" && -n "$ping2" ]]; then
        # 网络异常：两者的延迟同时 <10ms 或 >2000ms
        if (( $(echo "$ping1_ms < 10 || $ping1_ms > 2000" | bc -l) )) && \
           (( $(echo "$ping2_ms < 10 || $ping2_ms > 2000" | bc -l) )); then
            if [ $NETWORK_ANOMALY_LOGGED -eq 0 ]; then
                echo "$(date '+%m-%d %H:%M') | 网络异常 ($ping1_ms ms, $ping2_ms ms)，进入休眠" >&2
                NETWORK_ANOMALY_LOGGED=1
            fi
            # 返回 1，通知外部休眠
            return 1
        else
            # 网络正常：至少一个延迟在 10ms 到 2000ms 之间
            if [ $NETWORK_ANOMALY_LOGGED -eq 1 ]; then
                echo "$(date '+%m-%d %H:%M') | 网络恢复 ($ping1_ms ms, $ping2_ms ms)" >&2
                NETWORK_ANOMALY_LOGGED=0
            fi
        fi
    fi

    # 检查锚点文件
    if [ -f "$ANCHOR_FILE" ]; then
        echo "$(date '+%m-%d %H:%M') | 锚点链接成功,开始链接主程序" >&2
        ANCHOR_NOT_FOUND_LOGGED=0
        return 0
    else
        if [ $ANCHOR_NOT_FOUND_LOGGED -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 锚点链接失败,进入休眠" >&2
            ANCHOR_NOT_FOUND_LOGGED=1
        fi
        return 1
    fi
}