#!/bin/bash
#VERSION="1.0.2"
#万化归一模式
check_divination_mode() {
    local mode="$1"
    local interval_minutes="$2"
    local purity="$3"
    local category_mode="$4"
    local search_mode="$5"
    local fallback_mechanism="$6"
    local resolution_mode="$7"
    local min_width="$8"
    local min_height="$9"
    DIVINATION_FILE="/storage/emulated/0/Wallpaper/Cores/Cdivination/Diagram"
    THOUSAND_FILE="/storage/emulated/0/Wallpaper/Cores/Cdivination/Thousand.txt"
    OLD_THOUSAND_FILE="/storage/emulated/0/Wallpaper/Cores/Cdivination/Oldthousand.txt"

    # 保存原始参数（仅在第一次进入时保存）
    if [ -z "$ORIGINAL_MODE" ]; then
        ORIGINAL_MODE="$mode"
        ORIGINAL_INTERVAL_MINUTES="$interval_minutes"
        ORIGINAL_PURITY="$purity"
        ORIGINAL_CATEGORY_MODE="$category_mode"
        ORIGINAL_SEARCH_MODE="$search_mode"
        ORIGINAL_FALLBACK_MECHANISM="$fallback_mechanism"
        ORIGINAL_RESOLUTION_MODE="$resolution_mode"
        ORIGINAL_MIN_WIDTH="$min_width"
        ORIGINAL_MIN_HEIGHT="$min_height"
    fi

    # 初始化当前参数
    CURRENT_MODE="${CURRENT_MODE:-$ORIGINAL_MODE}"
    CURRENT_INTERVAL_MINUTES="${CURRENT_INTERVAL_MINUTES:-$ORIGINAL_INTERVAL_MINUTES}"
    CURRENT_PURITY="${CURRENT_PURITY:-$ORIGINAL_PURITY}"
    CURRENT_CATEGORY_MODE="${CURRENT_CATEGORY_MODE:-$ORIGINAL_CATEGORY_MODE}"
    CURRENT_SEARCH_MODE="${CURRENT_SEARCH_MODE:-$ORIGINAL_SEARCH_MODE}"
    CURRENT_FALLBACK_MECHANISM="${CURRENT_FALLBACK_MECHANISM:-$ORIGINAL_FALLBACK_MECHANISM}"
    CURRENT_RESOLUTION_MODE="${CURRENT_RESOLUTION_MODE:-$ORIGINAL_RESOLUTION_MODE}"
    CURRENT_MIN_WIDTH="${CURRENT_MIN_WIDTH:-$ORIGINAL_MIN_WIDTH}"
    CURRENT_MIN_HEIGHT="${CURRENT_MIN_HEIGHT:-$ORIGINAL_MIN_HEIGHT}"

    # 检查万化归一模式
    if [ -f "$DIVINATION_FILE" ]; then
        local reload_config=0
        if [ "${IS_DIVINATION_MODE:-0}" -eq 0 ]; then
            IS_DIVINATION_MODE=1
            echo "$(date '+%m-%d %H:%M') | 千变万化神莫测" >&2
            if [ -f "$THOUSAND_FILE" ]; then
                cp "$THOUSAND_FILE" "$OLD_THOUSAND_FILE" 2>/dev/null
            else
                echo "$(date '+%m-%d %H:%M') | 万化归一配置文件不存在：$THOUSAND_FILE，跳过复制" >&2
            fi
            reload_config=1
        else
            if [ -f "$THOUSAND_FILE" ] && [ -f "$OLD_THOUSAND_FILE" ]; then
                cmp -s "$THOUSAND_FILE" "$OLD_THOUSAND_FILE"
                if [ $? -ne 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | 仙无言神不语" >&2
                    reload_config=1
                fi
            elif [ -f "$THOUSAND_FILE" ] && [ ! -f "$OLD_THOUSAND_FILE" ]; then
                reload_config=1
            fi
        fi

        if [ $reload_config -eq 1 ]; then
            if [ -f "$THOUSAND_FILE" ]; then
                local valid_params=0
                while IFS='=' read -r key value; do
                    # 跳过空行或以 # 开头的行（注释）
                    if [[ -z "$key" ]] || [[ "$key" =~ ^[[:space:]]*# ]]; then
                        if [[ "$key" =~ ^[[:space:]]*# ]]; then
                            echo "$(date '+%m-%d %H:%M') | 忽略参数：$key=$value" >&2
                        fi
                        continue
                    fi
                    key=$(echo "$key" | tr -d '[:space:]')
                    value=$(echo "$value" | tr -d '[:space:]')
                    valid_params=$((valid_params + 1))
                    case "$key" in
                        MODE)
                            if [[ "$value" == "xz" || "$value" == "bz" ]]; then
                                CURRENT_MODE="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：运行模式=$CURRENT_MODE" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：MODE=$value，保持 MODE=$CURRENT_MODE" >&2
                            fi
                            ;;
                        INTERVAL_MINUTES)
                            if [[ "$value" =~ ^[0-9]+$ ]]; then
                                CURRENT_INTERVAL_MINUTES="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：更换壁纸间隔=$CURRENT_INTERVAL_MINUTES" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：INTERVAL_MINUTES=$value，保持 INTERVAL_MINUTES=$CURRENT_INTERVAL_MINUTES" >&2
                            fi
                            ;;
                        PURITY)
                            if [[ "$value" =~ ^[0-1]{3}$ ]]; then
                                CURRENT_PURITY="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：壁纸纯度=$CURRENT_PURITY" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：PURITY=$value，保持 PURITY=$CURRENT_PURITY" >&2
                            fi
                            ;;
                        CATEGORY_MODE)
                            if [[ "$value" == "zr" || "$value" == "dm" || "$value" == "lh" ]]; then
                                CURRENT_CATEGORY_MODE="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：搜索类别=$CURRENT_CATEGORY_MODE" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：CATEGORY_MODE=$value，保持 CATEGORY_MODE=$CURRENT_CATEGORY_MODE" >&2
                            fi
                            ;;
                        SEARCH_MODE)
                            if [[ "$value" == "gjc" || "$value" == "zh" ]]; then
                                CURRENT_SEARCH_MODE="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：搜索模式=$CURRENT_SEARCH_MODE" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：SEARCH_MODE=$value，保持 SEARCH_MODE=$CURRENT_SEARCH_MODE" >&2
                            fi
                            ;;
                        FALLBACK_MECHANISM)
                            if [[ "$value" == "enabled" || "$value" == "disabled" ]]; then
                                CURRENT_FALLBACK_MECHANISM="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：Bottom-pocket机制=$CURRENT_FALLBACK_MECHANISM" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：FALLBACK_MECHANISM=$value，保持 FALLBACK_MECHANISM=$CURRENT_FALLBACK_MECHANISM" >&2
                            fi
                            ;;
                        RESOLUTION_MODE)
                            if [[ "$value" == "zsy" || "$value" == "1.5k" || "$value" == "zdy" ]]; then
                                CURRENT_RESOLUTION_MODE="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：分辨率模式=$CURRENT_RESOLUTION_MODE" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：RESOLUTION_MODE=$value,保持 RESOLUTION_MODE=$CURRENT_RESOLUTION_MODE" >&2
                            fi
                            ;;
                        MIN_WIDTH)
                            if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
                                CURRENT_MIN_WIDTH="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：最低宽度=$CURRENT_MIN_WIDTH" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：MIN_WIDTH=$value，保持 MIN_WIDTH=$CURRENT_MIN_WIDTH" >&2
                            fi
                            ;;
                        MIN_HEIGHT)
                            if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -gt 0 ]; then
                                CURRENT_MIN_HEIGHT="$value"
                                echo "$(date '+%m-%d %H:%M') | 覆写：最低高度=$CURRENT_MIN_HEIGHT" >&2
                            else
                                echo "$(date '+%m-%d %H:%M') | 无效参数：MIN_HEIGHT=$value，保持 MIN_HEIGHT=$CURRENT_MIN_HEIGHT" >&2
                            fi
                            ;;
                        *)
                            echo "$(date '+%m-%d %H:%M') | 未知参数：$key=$value，忽略" >&2
                            ;;
                    esac
                done < "$THOUSAND_FILE"
                cp "$THOUSAND_FILE" "$OLD_THOUSAND_FILE" 2>/dev/null
                if [ $valid_params -eq 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | 万化归一配置文件无有效参数，使用当前参数" >&2
                fi
            else
                echo "$(date '+%m-%d %H:%M') | 万化归一配置文件不存在：$THOUSAND_FILE，使用当前参数" >&2
            fi
            DIVINATION_LOGGED=1
        fi
        return 1
    else
        if [ "${IS_DIVINATION_MODE:-0}" -eq 1 ]; then
            IS_DIVINATION_MODE=0
            DIVINATION_LOGGED=0
            CURRENT_MODE="$ORIGINAL_MODE"
            CURRENT_INTERVAL_MINUTES="$ORIGINAL_INTERVAL_MINUTES"
            CURRENT_PURITY="$ORIGINAL_PURITY"
            CURRENT_CATEGORY_MODE="$ORIGINAL_CATEGORY_MODE"
            CURRENT_SEARCH_MODE="$ORIGINAL_SEARCH_MODE"
            CURRENT_FALLBACK_MECHANISM="$ORIGINAL_FALLBACK_MECHANISM"
            CURRENT_RESOLUTION_MODE="$ORIGINAL_RESOLUTION_MODE"
            CURRENT_MIN_WIDTH="$ORIGINAL_MIN_WIDTH"
            CURRENT_MIN_HEIGHT="$ORIGINAL_MIN_HEIGHT"
            echo "$(date '+%m-%d %H:%M') | 万灵归一鸿蒙启" >&2
            echo "$(date '+%m-%d %H:%M') | 参数恢复：运行模式=$CURRENT_MODE, 壁纸更换间隔=$CURRENT_INTERVAL_MINUTES, 壁纸纯度=$CURRENT_PURITY, 搜索类别=$CURRENT_CATEGORY_MODE, 搜索模式=$CURRENT_SEARCH_MODE, Bottom-pocket机制=$CURRENT_FALLBACK_MECHANISM, 分辨率模式=$CURRENT_RESOLUTION_MODE, 最低分辨率=${CURRENT_MIN_WIDTH}x${CURRENT_MIN_HEIGHT}" >&2
        fi
        return 0
    fi
}