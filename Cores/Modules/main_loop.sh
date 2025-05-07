#!/bin/bash
#VERSION="1.0.2"
#========主程序===========
if [ "$MODE" == "bz" ]; then
    # 确保 TMP_DIR 和 CONFIG_DIR 可写
    mkdir -p "$TMP_DIR" "$CONFIG_DIR"
    chmod 755 "$TMP_DIR" "$CONFIG_DIR"
    consecutive_failures=0
    max_consecutive_failures=$((INTERVAL_MINUTES * 3))
    if [ $max_consecutive_failures -lt 5 ]; then
        max_consecutive_failures=5
        echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过低，调整为 5" >&2
    elif [ $max_consecutive_failures -gt 20 ]; then
        max_consecutive_failures=20
        echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过高，调整为 20" >&2
    fi
    IS_INITIAL_PRELOAD=1 # 标记第一次预下载

    while true; do
        # 检查万化归一模式
        check_divination_mode "$MODE" "$INTERVAL_MINUTES" "$PURITY" "$CATEGORY_MODE" "$SEARCH_MODE" "$FALLBACK_MECHANISM" "$RESOLUTION_MODE" "$MIN_WIDTH" "$MIN_HEIGHT"
        if [ $? -eq 1 ]; then
            MODE="$CURRENT_MODE"
            INTERVAL_MINUTES="$CURRENT_INTERVAL_MINUTES"
            PURITY="$CURRENT_PURITY"
            CATEGORY_MODE="$CURRENT_CATEGORY_MODE"
            SEARCH_MODE="$CURRENT_SEARCH_MODE"
            FALLBACK_MECHANISM="$CURRENT_FALLBACK_MECHANISM"
            RESOLUTION_MODE="$CURRENT_RESOLUTION_MODE"
            MIN_WIDTH="$CURRENT_MIN_WIDTH"
            MIN_HEIGHT="$CURRENT_MIN_HEIGHT"
            # 更新 current_category
            if [ "$CATEGORY_MODE" == "zr" ]; then
                current_category="zr"
            elif [ "$CATEGORY_MODE" == "dm" ]; then
                current_category="dm"
            fi
            # 更新 max_consecutive_failures
            max_consecutive_failures=$((INTERVAL_MINUTES * 3))
            if [ $max_consecutive_failures -lt 5 ]; then
                max_consecutive_failures=5
            elif [ $max_consecutive_failures -gt 20 ]; then
                max_consecutive_failures=20
            fi
        fi

        # 检查是否有预下载的壁纸
        if [ -f "$TMP_DIR/wallpaper_ready" ]; then
            CACHED_WALLPAPER=$(cat "$TMP_DIR/wallpaper_ready" 2>/dev/null)
            rm -f "$TMP_DIR/wallpaper_ready"
            if [ -n "$CACHED_WALLPAPER" ] && [ -f "$CACHED_WALLPAPER" ]; then
                echo "$(date '+%m-%d %H:%M') | 检测到预下载壁纸：$(basename "$CACHED_WALLPAPER")" >&2
            else
                CACHED_WALLPAPER=""
            fi
        else
            CACHED_WALLPAPER=""
        fi

        # 检查 CACHED_WALLPAPER 是否有效
        if [ -n "$CACHED_WALLPAPER" ] && [ -f "$CACHED_WALLPAPER" ]; then
            read width height < <(identify -format "%w %h" "$CACHED_WALLPAPER" 2>/dev/null)
            if [ -n "$width" ] && [ "$width" -ge "$MIN_WIDTH" ] && [ "$height" -ge "$MIN_HEIGHT" ] && [ "$height" -ge "$width" ]; then
                aspect_ratio=$(echo "scale=4; $width / $height" | bc -l 2>/dev/null)
                if [ -z "$aspect_ratio" ] || ! [[ "$aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
                    echo "$(date '+%m-%d %H:%M') | 宽高比计算失败，删除：$(basename "$CACHED_WALLPAPER")" >&2
                    rm -f "$CACHED_WALLPAPER"
                    CACHED_WALLPAPER=""
                else
                    formatted_aspect_ratio=$(printf "0.%02d" $(echo "$aspect_ratio * 100" | bc -l | cut -d'.' -f1))
                    if (($(echo "$aspect_ratio <= 0.8" | bc -l))); then
                        if set_wallpaper "$CACHED_WALLPAPER"; then
                            echo "$(date '+%m-%d %H:%M') | 壁纸设置成功，清除旧缓存" >&2
                            rm -f "$TMP_DIR/wallpaper_ready" # 在设置壁纸成功后清除
                            consecutive_failures=0
                            force_bottom_pocket=0
                            CACHED_WALLPAPER=""
                            # 更新类别（如果需要）
                            if [ "$CATEGORY_MODE" == "lh" ]; then
                                if [ "$current_category" == "zr" ]; then
                                    current_category="dm"
                                else
                                    current_category="zr"
                                fi
                                set_fallback_file "$PURITY" "$current_category"
                                set_really_file "$PURITY" "$current_category"
                                set_cache_file "$PURITY" "$current_category"
                                load_fallback_cache
                                load_really_cache
                            fi
                            # 异步预下载下一张壁纸
                            (
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
                                CACHED_WALLPAPER=""
                                download_image "$current_category" "$PURITY"
                                if [ -z "$CACHED_WALLPAPER" ] || [ ! -f "$CACHED_WALLPAPER" ]; then
                                    echo "$(date '+%m-%d %H:%M') | 预下载失败，将在下一周期重试" >&2
                                    CACHED_WALLPAPER=""
                                else
                                    # 使用临时文件写入，避免并发冲突
                                    tmp_file="$TMP_DIR/wallpaper_ready_tmp_$$"
                                    echo "$CACHED_WALLPAPER" > "$tmp_file"
                                    if mv "$tmp_file" "$TMP_DIR/wallpaper_ready" 2>/dev/null; then
                                        echo "$(date '+%m-%d %H:%M') | 预下载成功，写入缓存：$(basename "$CACHED_WALLPAPER")" >&2
                                    else
                                        echo "$(date '+%m-%d %H:%M') | 写入缓存失败：$(basename "$CACHED_WALLPAPER")" >&2
                                        rm -f "$tmp_file"
                                    fi
                                fi
                            ) &
                            IS_INITIAL_PRELOAD=0 # 重置初始化预下载标志
                            # 等待 INTERVAL_MINUTES 分钟
                            echo "$(date '+%m-%d %H:%M') | 等待 $INTERVAL_MINUTES 分钟" >&2
                            sleep $((INTERVAL_MINUTES * 60))
                            count=$((count + 1))
                            continue # 跳过同步下载
                        else
                            echo "$(date '+%m-%d %H:%M') | 壁纸设置失败：$(basename "$CACHED_WALLPAPER")" >&2
                            rm -f "$CACHED_WALLPAPER"
                            CACHED_WALLPAPER=""
                        fi
                    else
                        echo "$(date '+%m-%d %H:%M') | 壁纸宽高比大于0.8，删除：$(basename "$CACHED_WALLPAPER") (分辨率: ${width}x${height}, 宽高比: $formatted_aspect_ratio)" >&2
                        rm -f "$CACHED_WALLPAPER"
                        CACHED_WALLPAPER=""
                    fi
                fi
            else
                echo "$(date '+%m-%d %H:%M') | 壁纸分辨率小于过低或横屏，删除：$(basename "$CACHED_WALLPAPER") (分辨率: ${width}x${height})" >&2
                rm -f "$CACHED_WALLPAPER"
                CACHED_WALLPAPER=""
            fi
        fi

        # 如果没有有效壁纸，同步下载
        echo "$(date '+%m-%d %H:%M') | 无有效壁纸，尝试下载新壁纸" >&2
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
        download_image "$current_category" "$PURITY"
        if [ -n "$CACHED_WALLPAPER" ] && [ -f "$CACHED_WALLPAPER" ]; then
            echo "$(date '+%m-%d %H:%M') | 同步下载成功，壁纸已缓存：$(basename "$CACHED_WALLPAPER")" >&2
            # 写入 wallpaper_ready 以供下一次循环使用
            tmp_file="$TMP_DIR/wallpaper_ready_tmp_$$"
            echo "$CACHED_WALLPAPER" > "$tmp_file"
            if mv "$tmp_file" "$TMP_DIR/wallpaper_ready" 2>/dev/null; then
                echo "$(date '+%m-%d %H:%M') | 同步下载后写入 wallpaper_ready：$(basename "$CACHED_WALLPAPER")" >&2
            else
                echo "$(date '+%m-%d %H:%M') | 同步下载后写入 wallpaper_ready 失败：$(basename "$CACHED_WALLPAPER")" >&2
                rm -f "$tmp_file"
            fi
        else
            echo "$(date '+%m-%d %H:%M') | 下载失败，清除 CACHED_WALLPAPER" >&2
            CACHED_WALLPAPER=""
            consecutive_failures=$((consecutive_failures + 1))
            echo "$(date '+%m-%d %H:%M') | 下载失败计数：$consecutive_failures/$max_consecutive_failures" >&2
            if [ "$FALLBACK_MECHANISM" == "enabled" ] && [ $consecutive_failures -ge $max_consecutive_failures ]; then
                echo "$(date '+%m-%d %H:%M') | 连续 $consecutive_failures 次下载失败，触发 Bottom-pocket" >&2
                force_bottom_pocket=1
                if download_fallback_image "$current_category" "$PURITY"; then
                    if [ -n "$CACHED_WALLPAPER" ] && [ -f "$CACHED_WALLPAPER" ]; then
                        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载成功，壁纸已缓存：$(basename "$CACHED_WALLPAPER")" >&2
                        tmp_file="$TMP_DIR/wallpaper_ready_tmp_$$"
                        echo "$CACHED_WALLPAPER" > "$tmp_file"
                        if mv "$tmp_file" "$TMP_DIR/wallpaper_ready" 2>/dev/null; then
                            echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载后写入 wallpaper_ready：$(basename "$CACHED_WALLPAPER")" >&2
                        else
                            echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载后写入 wallpaper_ready 失败：$(basename "$CACHED_WALLPAPER")" >&2
                            rm -f "$tmp_file"
                        fi
                    else
                        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 下载失败，清除 CACHED_WALLPAPER" >&2
                        CACHED_WALLPAPER=""
                    fi
                fi
            fi
        fi

        # 检查是否需要清理数据库
        if [ $((count % 777)) -eq 0 ]; then
            cleanup_database
        fi
    done
else
    while [ "$downloaded" -lt "$TARGET_COUNT" ]; do
        # 检查万化归一模式
        check_divination_mode "$MODE" "$INTERVAL_MINUTES" "$PURITY" "$CATEGORY_MODE" "$SEARCH_MODE" "$FALLBACK_MECHANISM" "$RESOLUTION_MODE" "$MIN_WIDTH" "$MIN_HEIGHT"
        if [ $? -eq 1 ]; then
            MODE="$CURRENT_MODE"
            INTERVAL_MINUTES="$CURRENT_INTERVAL_MINUTES"
            PURITY="$CURRENT_PURITY"
            CATEGORY_MODE="$CURRENT_CATEGORY_MODE"
            SEARCH_MODE="$CURRENT_SEARCH_MODE"
            FALLBACK_MECHANISM="$CURRENT_FALLBACK_MECHANISM"
            RESOLUTION_MODE="$CURRENT_RESOLUTION_MODE"
            MIN_WIDTH="$CURRENT_MIN_WIDTH"
            MIN_HEIGHT="$CURRENT_MIN_HEIGHT"
            # 更新 current_category
            if [ "$CATEGORY_MODE" == "zr" ]; then
                current_category="zr"
            elif [ "$CATEGORY_MODE" == "dm" ]; then
                current_category="dm"
            fi
            # 更新 max_consecutive_failures
            max_consecutive_failures=$((INTERVAL_MINUTES * 3))
            if [ $max_consecutive_failures -lt 5 ]; then
                max_consecutive_failures=5
            elif [ $max_consecutive_failures -gt 20 ]; then
                max_consecutive_failures=20
            fi
        fi

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
        download_image "$current_category" "$PURITY"
        if [ "$CATEGORY_MODE" == "lh" ] && [ "$current_count" -ge "$SWITCH_THRESHOLD" ]; then
            if [ "$current_category" == "zr" ]; then
                current_category="dm"
            else
                current_category="zr"
            fi
            current_count=0
        fi
    done
    echo "下载完成，共下载 $downloaded 张，保存在 $SAVE_DIR"
fi