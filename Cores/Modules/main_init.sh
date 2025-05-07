#!/bin/bash
#VERSION="1.0.2"
#======初始化=========
count=1
downloaded=0
current_count=0
PREVIOUS_WALLPAPER=""
CACHED_WALLPAPER=""
skipped_downloaded=0

# 清理可能的残留标志文件
rm -f $TMP_DIR/wallpaper_ready

# 初始化逻辑
INITIALIZED=0
consecutive_failures=0
max_consecutive_failures=$((INTERVAL_MINUTES * 3))

# 检查万化归一模式（初始化时）
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
fi
if [ $max_consecutive_failures -lt 5 ]; then
    max_consecutive_failures=5
    echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过低，调整为 5" >&2
elif [ $max_consecutive_failures -gt 20 ]; then
    max_consecutive_failures=20
    echo "$(date '+%m-%d %H:%M') | max_consecutive_failures 过高，调整为 20" >&2
fi
echo "$(date '+%m-%d %H:%M') | Bottom-pocket触发阈值$max_consecutive_failures" >&2
# 检查wallhaven可用性
if ping -c 1 wallhaven.cc &>/dev/null; then
    wallhaven_available=0
else
    wallhaven_available=1
fi

if [ $wallhaven_available -eq 1 ]; then
    force_bottom_pocket=1
    while [ $INITIALIZED -eq 0 ]; do
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
        if download_fallback_image "$current_category" "$PURITY"; then
            if [ -n "$CACHED_WALLPAPER" ] && [ -f "$CACHED_WALLPAPER" ]; then
                read width height < <(identify -format "%w %h" "$CACHED_WALLPAPER" 2>/dev/null)
                if [ -n "$width" ] && [ "$width" -ge "$MIN_WIDTH" ] && [ "$height" -ge "$MIN_HEIGHT" ] && [ "$height" -ge "$width" ]; then
                    aspect_ratio=$(echo "scale=4; $width / $height" | bc -l 2>/dev/null)
                    if [ -z "$aspect_ratio" ] || ! [[ "$aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
                        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 初始下载宽高比计算失败，删除：$(basename "$CACHED_WALLPAPER")" >&2
                        rm -f "$CACHED_WALLPAPER"
                        CACHED_WALLPAPER=""
                        continue
                    fi
                    formatted_aspect_ratio=$(printf "0.%02d" $(echo "$aspect_ratio * 100" | bc -l | cut -d'.' -f1))
                    if (($(echo "$aspect_ratio <= 0.8" | bc -l))); then
                        if set_wallpaper "$CACHED_WALLPAPER"; then
                            echo "$(date '+%m-%d %H:%M') | 初始 Bottom-pocket 壁纸设置成功" >&2
                            echo "$(date '+%m-%d %H:%M') | 等待 $((INTERVAL_MINUTES - 2)) 分钟" >&2
                            sleep $(((INTERVAL_MINUTES - 2) * 60))
                            INITIALIZED=1
                            force_bottom_pocket=0
                            consecutive_failures=0
                            CACHED_WALLPAPER=""
                            rm -f "$TMP_DIR/wallpaper_ready" # 清除临时文件
                        else
                            echo "$(date '+%m-%d %H:%M') | 初始 Bottom-pocket 壁纸设置失败" >&2
                            rm -f "$CACHED_WALLPAPER"
                            CACHED_WALLPAPER=""
                        fi
                    else
                        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 图片宽高比大于0.8，删除：$(basename "$CACHED_WALLPAPER")" >&2
                        rm -f "$CACHED_WALLPAPER"
                        CACHED_WALLPAPER=""
                    fi
                else
                    echo "$(date '+%m-%d %H:%M') | Bottom-pocket 图片分辨率过低或横屏，删除：$(basename "$CACHED_WALLPAPER")" >&2
                    rm -f "$CACHED_WALLPAPER"
                    CACHED_WALLPAPER=""
                fi
            else
                echo "$(date '+%m-%d %H:%M') | Bottom-pocket 初始下载文件无效，删除：$(basename "$CACHED_WALLPAPER")" >&2
                rm -f "$CACHED_WALLPAPER"
                CACHED_WALLPAPER=""
            fi
        else
            CACHED_WALLPAPER=""
        fi
        dynamic_sleep
    done
else
    echo "$(date '+%m-%d %H:%M') | 主程序链接成功，下载初始壁纸" >&2
    force_bottom_pocket=0
    while [ $INITIALIZED -eq 0 ]; do
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
        if download_image "$current_category" "$PURITY"; then
            if [ -n "$CACHED_WALLPAPER" ] && [ -f "$CACHED_WALLPAPER" ]; then
                read width height < <(identify -format "%w %h" "$CACHED_WALLPAPER" 2>/dev/null)
                if [ -n "$width" ] && [ "$width" -ge "$MIN_WIDTH" ] && [ "$height" -ge "$MIN_HEIGHT" ] && [ "$height" -ge "$width" ]; then
                    aspect_ratio=$(echo "scale=4; $width / $height" | bc -l 2>/dev/null)
                    if [ -z "$aspect_ratio" ] || ! [[ "$aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
                        echo "$(date '+%m-%d %H:%M') | 初始壁纸宽高比计算失败，删除：$(basename "$CACHED_WALLPAPER")" >&2
                        rm -f "$CACHED_WALLPAPER"
                        CACHED_WALLPAPER=""
                        continue
                    fi
                    formatted_aspect_ratio=$(printf "0.%02d" $(echo "$aspect_ratio * 100" | bc -l | cut -d'.' -f1))
                    if (($(echo "$aspect_ratio <= 0.8" | bc -l))); then
                        if set_wallpaper "$CACHED_WALLPAPER"; then
                            echo "$(date '+%m-%d %H:%M') | 初始壁纸设置成功" >&2
                            echo "$(date '+%m-%d %H:%M') | 等待 $((INTERVAL_MINUTES - 2)) 分钟" >&2
                            sleep $(((INTERVAL_MINUTES - 2) * 60))
                            INITIALIZED=1
                            force_bottom_pocket=0
                            consecutive_failures=0
                            CACHED_WALLPAPER=""
                            rm -f "$TMP_DIR/wallpaper_ready" # 清除临时文件
                        else
                            echo "$(date '+%m-%d %H:%M') | 初始壁纸设置失败" >&2
                            rm -f "$CACHED_WALLPAPER"
                            CACHED_WALLPAPER=""
                        fi
                    else
                        echo "$(date '+%m-%d %H:%M') | 初始壁纸宽高比大于0.8，删除：$(basename "$CACHED_WALLPAPER")" >&2
                        rm -f "$CACHED_WALLPAPER"
                        CACHED_WALLPAPER=""
                    fi
                else
                    echo "$(date '+%m-%d %H:%M') | 初始壁纸分辨率过低或横屏，删除：$(basename "$CACHED_WALLPAPER")" >&2
                    rm -f "$CACHED_WALLPAPER"
                    CACHED_WALLPAPER=""
                fi
            else
                echo "$(date '+%m-%d %H:%M') | 初始壁纸下载成功但文件无效，删除：$(basename "$CACHED_WALLPAPER")" >&2
                rm -f "$CACHED_WALLPAPER"
                CACHED_WALLPAPER=""
            fi
        else
            echo "$(date '+%m-%d %H:%M') | 初始壁纸下载失败" >&2
            consecutive_failures=$((consecutive_failures + 1))
            echo "$(date '+%m-%d %H:%M') | 主程序下载失败计数：$consecutive_failures/$max_consecutive_failures" >&2
            if [ $consecutive_failures -ge $max_consecutive_failures ]; then
                echo "$(date '+%m-%d %H:%M') | 主程序下载连续失败 $consecutive_failures 次，强制切换到 Bottom-pocket" >&2
                force_bottom_pocket=1
            fi
            CACHED_WALLPAPER=""
        fi
        dynamic_sleep
    done
fi