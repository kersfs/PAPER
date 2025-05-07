#!/bin/bash
#VERSION="1.0.2"
#图片下载
download_page() {
    echo "$(date '+%m-%d %H:%M') | 开始匹配Max参数" >&2
    normalized_search_query=$(echo "$SEARCH_QUERY" | tr '[:upper:]' '[:lower:]' | tr -s ' ')
    last_page=$(grep "^$normalized_search_query|" "$CACHE_FILE" | cut -d'|' -f2)
    if [ -n "$last_page" ] && [[ "$last_page" =~ ^[0-9]+$ ]] && [ "$last_page" -ge 1 ]; then
        echo "$(date '+%m-%d %H:%M') | 获取到Max参数：$last_page" >&2
    else
        echo "$(date '+%m-%d %H:%M') | 无Max参数，开始构造提取" >&2
        local max_retries=2
        local retry_delay=2
        local attempt=1
        if [ "$category" == "zr" ]; then
            if [ "$SEARCH_MODE" == "gjc" ]; then
                ENCODED_QUERY=$(echo "$WELFARE_QUERY" | tr '[:upper:]' '[:lower:]' | tr -s ' ' | sed 's/ /%20/g; s/+/%2B/g; s/&/%26/g; s/=/%3D/g')
            else
                ENCODED_COUNTRY=$(echo "$COUNTRY_QUERY" | tr '[:upper:]' '[:lower:]' | tr -s ' ' | sed 's/ /%20/g; s/+/%2B/g; s/&/%26/g; s/=/%3D/g')
                ENCODED_WELFARE=$(echo "$WELFARE_QUERY" | tr '[:upper:]' '[:lower:]' | tr -s ' ' | sed 's/ /%20/g; s/+/%2B/g; s/&/%26/g; s/=/%3D/g')
                ENCODED_QUERY="${ENCODED_COUNTRY}%2B${ENCODED_WELFARE}"
            fi
        else
            ENCODED_QUERY=$(echo "$ANIME_QUERY_TERM" | tr '[:upper:]' '[:lower:]' | tr -s ' ' | sed 's/ /%20/g; s/+/%2B/g; s/&/%26/g; s/=/%3D/g')
        fi
        while [ $attempt -le $max_retries ]; do
            api_url="https://wallhaven.cc/api/v1/search?q=$ENCODED_QUERY&page=1&purity=$purity&$CATEGORY_FILTER&sorting=${SORT_ORDER}&atleast=${MIN_WIDTH}x${MIN_HEIGHT}&apikey=${API_KEY}"
            echo "$(date '+%m-%d %H:%M') | 整合参数执行API请求" >&2
            response=$(curl -s --max-time 15 --retry 2 --retry-delay 2 "$api_url" 2> "/storage/emulated/0/Wallpaper/Cores/Tmps/curl_error_$$")
            curl_error=$(cat "/storage/emulated/0/Wallpaper/Cores/Tmps/curl_error_$$")
            rm -f "/storage/emulated/0/Wallpaper/Cores/Tmps/curl_error_$$"
            if [ -n "$curl_error" ]; then
                echo "$(date '+%m-%d %H:%M') | curl 错误：$curl_error" >&2
            fi
            error=$(echo "$response" | jq -r '.error // null')
            if [ -n "$response" ] && [ "$error" == "null" ] && [ "$(echo "$response" | jq -r '.data?')" != "null" ]; then
                last_page=$(echo "$response" | jq -r '.meta.last_page // 100')
                if [ -z "$last_page" ] || [ "$last_page" -lt 1 ]; then
                    echo "$(date '+%m-%d %H:%M') | 无法提取最大页数，默认使用 100" >&2
                    last_page=100
                fi
                data_count=$(echo "$response" | jq -r '.data | length')
                if [ "$data_count" -eq 0 ]; then
                    echo "$(date '+%m-%d %H:%M') | 第一页无数据，重试..." >&2
                    if [ $attempt -eq $max_retries ]; then
                        echo "$(date '+%m-%d %H:%M') | 达到最大重试次数，跳过关键词：$SEARCH_DISPLAY" >&2
                        return 1  # 让 download_image 处理 add_to_fallback
                    fi
                    sleep $retry_delay
                    attempt=$((attempt + 1))
                    continue
                fi
                local timestamp=$(date +%s)
                local cache_entry="$normalized_search_query|$last_page|$timestamp"
                grep -v "^$normalized_search_query|" "$CACHE_FILE" > "/storage/emulated/0/Wallpaper/Cores/Pages/cache_tmp_$$" || true
                echo "$cache_entry" >> "/storage/emulated/0/Wallpaper/Cores/Pages/cache_tmp_$$"
                mv -f "/storage/emulated/0/Wallpaper/Cores/Pages/cache_tmp_$$" "$CACHE_FILE"
                echo "$(date '+%m-%d %H:%M') | 获取到最大页数：$last_page 添加关键词<$SEARCH_DISPLAY> 到Max文件" >&2
                break
            else
                echo "$(date '+%m-%d %H:%M') | API 请求失败（尝试 $attempt/$max_retries）" >&2
                if [ $attempt -eq $max_retries ]; then
                    echo "$(date '+%m-%d %H:%M') | 达到最大重试次数，跳过关键词：$SEARCH_DISPLAY" >&2
                    return 1  # 让 download_image 处理 add_to_fallback
                fi
                sleep $retry_delay
                attempt=$((attempt + 1))
            fi
        done
    fi
    local page_attempts=0
    local valid_image_found=0
    skipped_downloaded=0  # 初始化全局变量
    local -a tried_pages=()
    while [ ${#tried_pages[@]} -lt $last_page ]; do
        while true; do
            PAGE=$((RANDOM % last_page + 1))
            if [[ ! " ${tried_pages[*]} " =~ " $PAGE " ]]; then
                tried_pages+=("$PAGE")
                break
            fi
        done
        echo "$(date '+%m-%d %H:%M') | 选择页面 $PAGE/$last_page (已尝试 ${#tried_pages[@]}/$last_page)" >&2
        api_url="https://wallhaven.cc/api/v1/search?q=$ENCODED_QUERY&page=${PAGE}&purity=$purity&$CATEGORY_FILTER&sorting=${SORT_ORDER}&atleast=${MIN_WIDTH}x${MIN_HEIGHT}&apikey=${API_KEY}"
        sleep 2
        response=$(curl -s --max-time 15 --retry 2 --retry-delay 2 "$api_url" 2> "/storage/emulated/0/Wallpaper/Cores/Tmps/curl_error_$$")
        curl_error=$(cat "/storage/emulated/0/Wallpaper/Cores/Tmps/curl_error_$$")
        rm -f "/storage/emulated/0/Wallpaper/Cores/Tmps/curl_error_$$"
        if [ -n "$curl_error" ]; then
            echo "$(date '+%m-%d %H:%M') | curl 错误：$curl_error" >&2
        fi
        if [ -z "$response" ] || [ "$(echo "$response" | jq -r '.data?')" == "null" ]; then
            echo "$(date '+%m-%d %H:%M') | API 请求失败或无数据，页面 $PAGE，重试..." >&2
            page_attempts=$((page_attempts + 1))
            sleep 5
            continue
        fi
        mapfile -t images < <(echo "$response" | jq -r '.data[] | "\(.path) \(.dimension_x // "unknown") \(.dimension_y // "unknown")"')
        if [ ${#images[@]} -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 无结果，重试..." >&2
            page_attempts=$((page_attempts + 1))
            sleep 5
            continue
        fi
        echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 获取到 ${#images[@]} 张图片" >&2

        local skipped_api=0
        local image_index=1
        local processed_images=0
        for image in "${images[@]}"; do
            processed_images=$((processed_images + 1))
            read -r img_url api_dimension_x api_dimension_y <<< "$image"
            echo "$(date '+%m-%d %H:%M') | 执行API请求,获取图片 $processed_images/${#images[@]}" >&2
            [ "$MODE" == "bz" ] && is_downloaded "$img_url" && {
                skipped_downloaded=$((skipped_downloaded + 1))  # 更新全局变量
                echo "$(date '+%m-%d %H:%M') | 跳过已下载图片" >&2
                continue
            }
            if [ "$api_dimension_x" != "unknown" ] && [ "$api_dimension_y" != "unknown" ]; then
                if [ "$api_dimension_x" -gt "$api_dimension_y" ]; then
                    skipped_api=$((skipped_api + 1))
                    echo "$(date '+%m-%d %H:%M') | 跳过横屏壁纸 (分辨率: ${api_dimension_x}x${api_dimension_y}) 请求下一张" >&2
                    continue
                fi
                local api_aspect_ratio=$(echo "scale=4; $api_dimension_x / $api_dimension_y" | bc -l 2>/dev/null)
                if [ -z "$api_aspect_ratio" ] || ! [[ "$api_aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
                    skipped_api=$((skipped_api + 1))
                    echo "$(date '+%m-%d %H:%M') | 跳过宽高比计算失败的壁纸 (分辨率: ${api_dimension_x}x${api_dimension_y}) 请求下一张" >&2
                    continue
                fi
                # 格式化为两位小数，带前导 0
                local formatted_api_aspect_ratio=$(printf "0.%02d" $(echo "$api_aspect_ratio * 100" | bc -l | cut -d'.' -f1))
                if [ "$(echo "$api_aspect_ratio > 0.8" | bc -l)" -eq 1 ]; then
                    skipped_api=$((skipped_api + 1))
                    echo "$(date '+%m-%d %H:%M') | 跳过宽高比大于0.8的壁纸 (分辨率: ${api_dimension_x}x${api_dimension_y}, 宽高比: $formatted_api_aspect_ratio) 请求下一张" >&2
                    continue
                fi
                if [ "$api_dimension_x" -lt "$MIN_WIDTH" ] || [ "$api_dimension_y" -lt "$MIN_HEIGHT" ]; then
                    skipped_api=$((skipped_api + 1))
                    echo "$(date '+%m-%d %H:%M') | 跳过低分辨率壁纸 (分辨率: ${api_dimension_x}x${api_dimension_y}) 请求下一张" >&2
                    continue
                fi
            fi
            ext="${img_url##*.}"
            if [ "$category" == "dm" ]; then
                prefix="[动漫${QUERY_MAP[$ANIME_QUERY_TERM]:-未知}]"
            else
                prefix="[${QUERY_MAP[$COUNTRY_QUERY]:-未知}${QUERY_MAP[$WELFARE_QUERY]:-未知}]"
            fi
            echo "$(date '+%m-%d %H:%M') | 生成文件名：${prefix}${PAGE}_${count}.${ext}" >&2
            file_name="${prefix}${PAGE}_${count}.${ext}"
            file_path="$SAVE_DIR/$file_name"
            retry=0
            success=0
            while [[ $retry -lt $download_retry ]]; do
                if curl -sL --max-time 60 --retry 2 --retry-delay 2 "$img_url" -o "$file_path" && [[ -s "$file_path" ]]; then
                    success=1
                    break
                else
                    ((retry++))
                    echo "$(date '+%m-%d %H:%M') | 下载失败，重试" >&2
                    sleep "$retry_delay"
                fi
            done

            if [[ $success -ne 1 ]]; then
                rm -f "$file_path"
                echo "$(date '+%m-%d %H:%M') | 下载失败（已重试 $download_retry 次）：$img_url" >&2
                continue
            fi
            file_size=$(stat -c %s "$file_path")
            file_size_mb=$(echo "scale=2; $file_size / 1048576" | bc | awk '{printf "%.2f", $0}')
            if [ "$file_size" -lt 104858 ]; then
                echo "$(date '+%m-%d %H:%M') | 壁纸文件损坏，删除：$file_name ($file_size_mb MB)" >&2
                rm -f "$file_path"
                continue
            fi
            if [ "$api_dimension_x" != "unknown" ] && [ "$api_dimension_y" != "unknown" ]; then
                width=$api_dimension_x
                height=$api_dimension_y
                if [ "$width" -gt "$height" ]; then
                    echo "$(date '+%m-%d %H:%M') | 横屏壁纸（API检测），删除：$file_name (分辨率: ${width}x${height})" >&2
                    rm -f "$file_path"
                    continue
                fi
                local aspect_ratio=$(echo "scale=4; $width / $height" | bc)
                if [ "$(echo "$aspect_ratio > 0.8" | bc -l)" -eq 1 ]; then
                    echo "$(date '+%m-%d %H:%M') | 宽高比大于0.8的壁纸（API检测），删除：$file_name (分辨率: ${width}x${height}, 宽高比: $formatted_aspect_ratio)" >&2
                    rm -f "$file_path"
                    continue
                fi
                if [ "$width" -lt "$MIN_WIDTH" ] || [ "$height" -lt "$MIN_HEIGHT" ]; then
                    echo "$(date '+%m-%d %H:%M') | 低分辨率壁纸（API检测），删除：$file_name (分辨率: ${width}x${height})" >&2
                    rm -f "$file_path"
                    continue
                fi
            else
                width=$(identify -format "%w" "$file_path" 2>/dev/null)
                height=$(identify -format "%h" "$file_path" 2>/dev/null)
                if [ -z "$width" ] || [ -z "$height" ]; then
                    echo "$(date '+%m-%d %H:%M') | 无法获取分辨率（identify），保留文件：$file_name" >&2
                else
                    if [ "$width" -gt "$height" ]; then
                        echo "$(date '+%m-%d %H:%M') | 横屏壁纸（identify检测），删除：$file_name (分辨率: ${width}x${height})" >&2
                        rm -f "$file_path"
                        continue
                    fi
                    local aspect_ratio=$(echo "scale=4; $width / $height" | bc -l 2>/dev/null)
                    if [ -z "$aspect_ratio" ] || ! [[ "$aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
                        echo "$(date '+%m-%d %H:%M') | 宽高比计算失败（identify检测），删除：$file_name (分辨率: ${width}x${height})" >&2
                        rm -f "$file_path"
                        continue
                    fi
# 格式化为两位小数，带前导 0
                    local formatted_aspect_ratio=$(printf "0.%02d" $(echo "$aspect_ratio * 100" | bc -l | cut -d'.' -f1))
                    if [ "$(echo "$aspect_ratio > 0.8" | bc -l)" -eq 1 ]; then
                        echo "$(date '+%m-%d %H:%M') | 宽高比大于0.8的壁纸（identify检测），删除：$file_name (分辨率: ${width}x${height}, 宽高比: $formatted_aspect_ratio)" >&2
                        rm -f "$file_path"
                        continue
                    fi
                fi
            fi
            for i in {1..3}; do
                if [ "$MODE" == "bz" ] && sqlite3 "$DB_FILE" "INSERT INTO downloaded (url) VALUES ('$img_url');"; then
                    break
                fi
                echo "$(date '+%m-%d %H:%M') | SQLite 插入失败，重试 $i/3..." >&2
                sleep 0.5
            done
            echo "$(date '+%m-%d %H:%M') | 下载成功：$file_name >>> 第 $((count + 1)) 张 (分辨率: ${width:-$api_dimension_x}x${height:-$api_dimension_y}, 宽高比: ${formatted_aspect_ratio:-$formatted_api_aspect_ratio}, 大小: $file_size_mb MB)" >&2
            echo "$(date) | $file_name | 类型: ${CATEGORY_MAP[$category]} | 分分辨率: ${width:-$api_dimension_x}x${height:-$api_dimension_y} | 大小: $file_size_mb MB" >> "$LOG_DIR/cron_log.txt"
            if [ "$MODE" == "bz" ]; then
                CACHED_WALLPAPER="$file_path"
            fi
            count=$((count + 1))
            downloaded=$((downloaded + 1))
            image_index=$((image_index + 1))
            if [ "$MODE" == "xz" ]; then
                echo "$(date '+%m-%d %H:%M') | 进度：已下载 $downloaded/$TARGET_COUNT 张" >&2
                current_count=$((current_count + 1))
            else
                if [ "$CATEGORY_MODE" == "lh" ]; then
                    if [ "$current_category" == "zr" ]; then
                        current_category="dm"
                    else
                        current_category="zr"
                    fi
                fi
            fi
            valid_image_found=1
            return 0
        done
        echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 命中率：$((image_index - 1))/${#images[@]} 张 (跳过 $skipped_api 张，已下载 $skipped_downloaded 张，已尝试 ${#tried_pages[@]}/$last_page 页)" >&2
        page_attempts=$((page_attempts + 1))
    done
    if [ $valid_image_found -eq 1 ]; then
        echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 命中率：$((image_index - 1))/${#images[@]} 张 (跳过 $skipped_api 张，已下载 $skipped_downloaded 张，已尝试 ${#tried_pages[@]}/$last_page 页)" >&2
        return 0
    fi

    if [ ${#tried_pages[@]} -ge $last_page ]; then
        if [ $skipped_downloaded -eq 0 ]; then
            echo "$(date '+%m-%d %H:%M') | 已尝试所有 ${#tried_pages[@]}/$last_page 页，无有效图片，跳过关键词<$SEARCH_DISPLAY>" >&2
        else
            echo "$(date '+%m-%d %H:%M') | 已尝试所有 ${#tried_pages[@]}/$last_page 页，存在已下载图片（$skipped_downloaded 张），不添加关键词<$SEARCH_DISPLAY>到Fallback" >&2
        fi
        return 1
    fi
    echo "$(date '+%m-%d %H:%M') | 页面 $PAGE 命中率：$((image_index - 1))/${#images[@]} 张 (跳过 $skipped_api 张，已下载 $skipped_downloaded 张，已尝试 ${#tried_pages[@]}/$last_page 页)" >&2
    return 1
}