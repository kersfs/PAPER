#!/bin/bash
#VERSION="1.0.2"
# Bottom-pocket图片下载函数
download_fallback_image() {
    local category=$1
    local purity=$2
    local bottom_pocket_file="/storage/emulated/0/Wallpaper/Cores/Keywords/Bottom_pocket.txt"
    local ext="jpg"  # 假设图片为 jpg 格式
    local prefix="[Bottom-pocket]"
    local file_name="${prefix}${count}.${ext}"
    local file_path="$SAVE_DIR/$file_name"
    local success=0
    local retry=0
    local max_retries=3
    local retry_delay=3
    # 检查 Bottom_pocket.txt 是否存在且不为空
    if [ ! -s "$bottom_pocket_file" ]; then
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 文件不存在或为空：$bottom_pocket_file" >&2
        return 1
    fi

    # 从 Bottom_pocket.txt 随机选择一个 URL
    mapfile -t bottom_pocket_urls < <(grep -v '^[[:space:]]*$' "$bottom_pocket_file" | sed 's/[[:space:]]*$//')
    if [ ${#bottom_pocket_urls[@]} -eq 0 ]; then
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket 文件不包含有效 URL" >&2
        return 1
    fi
    local fallback_url="${bottom_pocket_urls[$((RANDOM % ${#bottom_pocket_urls[@]}))]}"
    echo "$(date '+%m-%d %H:%M') | 触发Bottom-pocket机制，Bottom-pocket正在下载图片" >&2
    while [ $retry -lt $max_retries ]; do
        if curl -sL --max-time 30 --retry 2 --retry-delay 2 "$fallback_url" -o "$file_path" && [[ -s "$file_path" ]]; then
            success=1
            break
        else
            retry=$((retry + 1))
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket下载失败，重试" >&2
            dynamic_sleep
        fi
    done
    if [ $success -ne 1 ]; then
        rm -f "$file_path"
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket下载失败（已重试 $max_retries 次）" >&2
        return 1
    fi

    # 检查文件大小
    local file_size=$(stat -c %s "$file_path")
    local file_size_mb=$(echo "scale=2; $file_size / 1048576" | bc | awk '{printf "%.2f", $0}')
    if [ "$file_size" -lt 104858 ]; then
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket文件损坏，删除：$file_name ($file_size_mb MB)" >&2
        rm -f "$file_path"
        return 1
    fi

    # 检查分辨率（过滤横屏、宽高比大于0.8、低分辨率）
    local width=$(identify -format "%w" "$file_path" 2>/dev/null)
    local height=$(identify -format "%h" "$file_path" 2>/dev/null)
    if [ -z "$width" ] || [ -z "$height" ]; then
        echo "$(date '+%m-%d %H:%M') | Bottom-pocket图片无法获取分辨率，保留文件：$file_name" >&2
    else
        if [ "$width" -gt "$height" ]; then
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket图片为横屏，删除：$file_name (分辨率: ${width}x${height})" >&2
            rm -f "$file_path"
            return 1
        fi
        # 计算宽高比 width/height
        local aspect_ratio=$(echo "scale=4; $width / $height" | bc -l 2>/dev/null)
        if [ -z "$aspect_ratio" ] || ! [[ "$aspect_ratio" =~ ^[0-9]*\.[0-9]+$ ]]; then
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket图片宽高比计算失败，删除：$file_name (分辨率: ${width}x${height})" >&2
            rm -f "$file_path"
            return 1
        fi
        # 格式化为两位小数，带前导 0
        local formatted_aspect_ratio=$(printf "0.%02d" $(echo "$aspect_ratio * 100" | bc -l | cut -d'.' -f1))
        if [ "$(echo "$aspect_ratio > 0.8" | bc -l)" -eq 1 ]; then
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket图片宽高比大于0.8，删除：$file_name (分辨率: ${width}x${height}, 宽高比: $formatted_aspect_ratio)" >&2
            rm -f "$file_path"
            return 1
        fi
        # 过滤分辨率小于 1.5k 的图片
        if [ "$width" -lt "$MIN_WIDTH" ] || [ "$height" -lt "$MIN_HEIGHT" ]; then
            echo "$(date '+%m-%d %H:%M') | Bottom-pocket图片分辨率过低，删除：$file_name (分辨率: ${width}x${height})" >&2
            rm -f "$file_path"
            return 1
        fi
    fi
    echo "$(date '+%m-%d %H:%M') | Bottom-pocket下载成功：$file_name >>> 第 $((count + 1)) 张 (分辨率: ${width}x${height}, 宽高比: $formatted_aspect_ratio, 大小: $file_size_mb MB)" >&2
    echo "$(date) | $file_name | 类型: Bottom-pocket | 分辨率: ${width}x${height} | 大小: $file_size_mb MB" >> "$LOG_DIR/cron_log.txt"

    if [ "$MODE" == "bz" ]; then
        CACHED_WALLPAPER="$file_path"
    fi
    count=$((count + 1))
    downloaded=$((downloaded + 1))
    if [ "$MODE" == "xz" ]; then
        echo "$(date '+%m-%d %H:%M') | 进度：已下载 $downloaded/$TARGET_COUNT 张" >&2
        current_count=$((current_count + 1))
    fi

    return 0
}