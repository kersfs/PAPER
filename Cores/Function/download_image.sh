#!/bin/bash
#VERSION="1.0.2"
#处理壁纸更换
download_image() {
    download_retry=4
    retry_delay=3
    local category=$1
    local purity=$2
    local success=0
    local skipped_api=0
    local consecutive_failures=0
    local interval_minutes=${INTERVAL_MINUTES:-7}  # 使用全局 INTERVAL_MINUTES，默认 7
    local max_consecutive_failures=$((interval_minutes * 3))  # 动态计算
    local in_fallback_mode=0

    # 检查万化归一模式
    check_divination_mode "$MODE" "$INTERVAL_MINUTES" "$PURITY" "$CATEGORY_MODE" "$SEARCH_MODE" "$FALLBACK_MECHANISM" "$RESOLUTION_MODE" "$MIN_WIDTH" "$MIN_HEIGHT"
    if [ $? -eq 1 ]; then
        # 万化归一模式：使用覆盖后的参数
        MODE="$CURRENT_MODE"
        INTERVAL_MINUTES="$CURRENT_INTERVAL_MINUTES"
        PURITY="$CURRENT_PURITY"
        CATEGORY_MODE="$CURRENT_CATEGORY_MODE"
        SEARCH_MODE="$CURRENT_SEARCH_MODE"
        FALLBACK_MECHANISM="$CURRENT_FALLBACK_MECHANISM"
        RESOLUTION_MODE="$CURRENT_RESOLUTION_MODE"
        MIN_WIDTH="$CURRENT_MIN_WIDTH"
        MIN_HEIGHT="$CURRENT_MIN_HEIGHT"
        # 更新 category 和 purity
        category="$CURRENT_CATEGORY_MODE"
        [ "$category" = "lh" ] && category="$current_category" # 保持轮换模式
        purity="$CURRENT_PURITY"
    fi

    # 边界检查
    if [ $max_consecutive_failures -lt 5 ]; then
        max_consecutive_failures=5
        echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过低，调整为 5" >&2
    elif [ $max_consecutive_failures -gt 20 ]; then
        max_consecutive_failures=20
        echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过高，调整为 20" >&2
    fi
    set_cache_file "$purity" "$category"
    set_fallback_file "$purity" "$category"
    set_really_file "$purity" "$category"
    load_fallback_cache
    load_really_cache
    cleanup_cache

    while [ $success -eq 0 ]; do
        # 检查标定文件
        while ! check_anchor_file; do
            sleep 6
        done
        # 检查备用锚点文件
        while ! check_back_anchor; do
            sleep 6
        done
        # 如果处于备用壁纸模式，跳过壁纸切换
        if [ $IS_BACK_MODE -eq 1 ]; then
            echo "$(date '+%m-%d %H:%M') | 处于备用壁纸模式，暂停壁纸切换，等待 $INTERVAL_MINUTES 分钟" >&2
            sleep $((INTERVAL_MINUTES * 60))
            continue
        fi
        # 如果 force_bottom_pocket=1 或已进入Bottom-pocket模式，优先使用Bottom-pocket
        if [ "${force_bottom_pocket:-0}" -eq 1 ] || [ "$FALLBACK_MECHANISM" == "enabled" ] && [ $in_fallback_mode -eq 1 ]; then
            if download_fallback_image "$category" "$purity"; then
                success=1
                in_fallback_mode=0
                consecutive_failures=0
            else
                echo "$(date '+%m-%d %H:%M') | Bottom-pocket机制下载失败，继续尝试Bottom-pocket下载" >&2
                dynamic_sleep
            fi
            continue
        fi
        # 检查是否触发Bottom-pocket机制
        if [ "$FALLBACK_MECHANISM" == "enabled" ] && [ $consecutive_failures -ge $max_consecutive_failures ] && [ $in_fallback_mode -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 连续 $consecutive_failures 次关键词选择失败，触发Bottom-pocket机制" >&2
            in_fallback_mode=1
            if download_fallback_image "$category" "$purity"; then
                success=1
                in_fallback_mode=0
                consecutive_failures=0
            else
                echo "$(date '+%m-%d %H:%M') | Bottom-pocket机制下载失败，继续尝试Bottom-pocket下载" >&2
                dynamic_sleep
            fi
            continue
        fi
        # 在选择关键词前检查 wallhaven.cc 延迟
        check_wallhaven
        if [ $? -eq 0 ]; then
            # 主程序链接正常，根据延迟调整休眠
            ping_time=$(get_ping_time "wallhaven.cc")
            if [[ "$ping_time" =~ ^[0-9]+(\.[0-9]+)?$ ]] && [ -n "$ping_time" ]; then
                if [ "$(echo "$ping_time < 100" | bc -l 2>/dev/null)" -eq 1 ]; then
                    sleep_duration=0.5
                elif [ "$(echo "$ping_time < 300" | bc -l 2>/dev/null)" -eq 1 ]; then
                    sleep_duration=1
                else
                    sleep_duration=1.5
                fi
            else
                sleep_duration=1.5  # 延迟未知或超时，默认较长休眠
            fi
            echo "$(date '+%m-%d %H:%M') | 动态休眠：${sleep_duration}s（延迟：${ping_time}ms）" >&2
            sleep "$sleep_duration"
        else
            # 主程序链接失败，直接进入Bottom-pocket机制
            if [ "$FALLBACK_MECHANISM" == "enabled" ]; then
                echo "$(date '+%m-%d %H:%M') | 主程序链接失败，触发Bottom-pocket机制" >&2
                in_fallback_mode=1
                if download_fallback_image "$category" "$purity"; then
                    success=1
                    in_fallback_mode=0
                    consecutive_failures=0
                else
                    echo "$(date '+%m-%d %H:%M') | Bottom-pocket机制下载失败，继续尝试Bottom-pocket下载" >&2
                    dynamic_sleep
                fi
                continue
            else
                # 如果Bottom-pocket未启用，休眠并继续循环
                echo "$(date '+%m-%d %H:%M') | 主程序链接失败，Bottom-pocket未启用，休眠2s后重试" >&2
                sleep 2
            fi
        fi
        # 关键词选择逻辑（仅当主程序链接正常时执行）
        SORT_OPTIONS=("relevance" "relevance" "relevance" "relevance" "relevance" "relevance" "relevance" "favorites" "favorites" "favorites" "favorites" "views" "views" "views" "date_added" "date_added" "random")
        SORT_ORDER=${SORT_OPTIONS[$((RANDOM % ${#SORT_OPTIONS[@]}))]}
        if [ "$category" == "zr" ]; then
            if [ "$SEARCH_MODE" == "gjc" ]; then
                select_keyword WELFARE_QUERIES WELFARE_QUERY
                SEARCH_QUERY="${WELFARE_QUERY}"
                SEARCH_DISPLAY="${QUERY_MAP[$WELFARE_QUERY]}"
                if [ -n "${FALLBACK_CACHE[$SEARCH_QUERY]}" ]; then
                    echo "$(date '+%m-%d %H:%M') | 关键词 <$SEARCH_DISPLAY> 触发Fallback，重新选择..." >&2
                    consecutive_failures=$((consecutive_failures + 1))
                    continue
                fi
            else
                local valid_combination=0
                local retry_count=0
                local max_retries=10
                while [ $valid_combination -eq 0 ] && [ $retry_count -lt $max_retries ]; do
                    select_keyword COUNTRY_QUERIES COUNTRY_QUERY
                    select_keyword WELFARE_QUERIES WELFARE_QUERY
                    SEARCH_QUERY="${COUNTRY_QUERY}+${WELFARE_QUERY}"
                    SEARCH_DISPLAY="${QUERY_MAP[$COUNTRY_QUERY]}${QUERY_MAP[$WELFARE_QUERY]}"
                    if [ -n "${FALLBACK_CACHE[$SEARCH_QUERY]}" ]; then
                        echo "$(date '+%m-%d %H:%M') | 关键词<$SEARCH_DISPLAY>触发Fallback，重新选择..." >&2
                        retry_count=$((retry_count + 1))
                        consecutive_failures=$((consecutive_failures + 1))
                        continue
                    fi
                    valid_combination=1
                done
                if [ $valid_combination -eq 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | 无法找到有效的组合关键词，重试次数达到 $max_retries" >&2
                    consecutive_failures=$((consecutive_failures + 1))
                    continue
                fi
            fi
            CATEGORY_FILTER="categories=001"
        else
            select_keyword ANIME_QUERIES ANIME_QUERY_TERM
            SEARCH_QUERY="$ANIME_QUERY_TERM"
            SEARCH_DISPLAY="${QUERY_MAP[$ANIME_QUERY_TERM]}"
            if [ -n "${FALLBACK_CACHE[$SEARCH_QUERY]}" ]; then
                echo "$(date '+%m-%d %H:%M') | 关键词 $SEARCH_QUERY 在Fallback文件中，重新选择..." >&2
                consecutive_failures=$((consecutive_failures + 1))
                continue
            fi
            CATEGORY_FILTER="categories=010"
        fi
        echo "$(date '+%m-%d %H:%M') | 组合关键词：$SEARCH_DISPLAY" >&2
        skipped_downloaded=0  # 重置全局变量
        if download_page; then
            success=1
            add_to_really "$SEARCH_QUERY"
            consecutive_failures=0
        else
            echo "$(date '+%m-%d %H:%M') | 关键词<$SEARCH_DISPLAY>无有效图片，选择下一个关键词" >&2
            if [ $skipped_downloaded -eq 0 ]; then
                add_to_fallback "$SEARCH_QUERY"
                FALLBACK_CACHE["$SEARCH_QUERY"]=1
            else
                echo "$(date '+%m-%d %H:%M') | 关键词<$SEARCH_DISPLAY>因存在已下载图片（$skipped_downloaded 张）不添加到Fallback" >&2
            fi
            consecutive_failures=$((consecutive_failures + 1))
            sleep 1
            continue
        fi
    done
}