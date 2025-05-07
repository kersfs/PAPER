#!/bin/bash
#VERSION="1.0.2"
#========== 输出运行模式 ==========
if [ "$MODE" == "bz" ]; then
    echo "$(date '+%m-%d %H:%M') | 壁纸更换初始化成功" >&2
    if [ -n "$INTERVAL_MINUTES" ]; then
        echo "$(date '+%m-%d %H:%M') | 壁纸更换间隔 $INTERVAL_MINUTES 分钟" >&2
    else
        echo "$(date '+%m-%d %H:%M') | 未设置间隔时间，默认使用 7 分钟" >&2
        INTERVAL_MINUTES=7
    fi
elif [ "$MODE" == "xz" ]; then
    echo "$(date '+%m-%d %H:%M') | 壁纸下载初始化成功" >&2
else
    echo "$(date '+%m-%d %H:%M') | 无效模式：$MODE，默认使用下载模式" >&2
    MODE="xz"
fi

# 安装依赖（静默模式）
for cmd in termux-wallpaper imagemagick curl bc awk jq sqlite3 libxml2; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "$(date '+%m-%d %H:%M') | 开始安装必要依赖：$cmd" >&2
        if ! pkg install "$cmd" -y > /dev/null 2>&1; then
            echo "$(date '+%m-%d %H:%M') | 安装依赖 $cmd 失败，请手动检查" >&2
            exit 1
        fi
    fi
done

# 检测网络连通性和 API 密钥
wallhaven_available=1
if ! ping -c 1 wallhaven.cc &>/dev/null; then
    echo "$(date '+%m-%d %H:%M') | 主程序启动失败，使用子程序初始化" >&2
    wallhaven_available=0
fi

# 加载 API Key
if [[ -f "$API_KEY_FILE" ]]; then
    API_KEY=$(cat "$API_KEY_FILE" | tr -d '[:space:]\n')
    if [ -z "$API_KEY" ]; then
        echo "$(date '+%m-%d %H:%M') | API 密钥为空，请检查 $API_KEY_FILE" >&2
        wallhaven_available=0
    elif ! test_api_key; then
        wallhaven_available=0
    else
        echo "$(date '+%m-%d %H:%M') | API 密钥加载成功" >&2
    fi
else
    echo "$(date '+%m-%d %H:%M') | API 密钥文件不存在：$API_KEY_FILE" >&2
    wallhaven_available=0
fi

# 验证 INTERVAL_MINUTES
if [ -z "$INTERVAL_MINUTES" ] || ! [[ "$INTERVAL_MINUTES" =~ ^[0-9]+$ ]]; then
    INTERVAL_MINUTES=7
    echo "$(date '+%m-%d %H:%M') | INTERVAL_MINUTES 未定义或非数字，默认使用 7 分钟" >&2
fi

# 检查日志文件大小，超过 10MB 则备份
if [ -f "$LOG_DIR/cron_log.txt" ]; then
    log_size=$(stat -c %s "$LOG_DIR/cron_log.txt")
    if [ "$log_size" -gt $((10 * 1024 * 1024)) ]; then
        mv "$LOG_DIR/cron_log.txt" "$LOG_DIR/cron_log_$(date '+%Y%m%d_%H%M%S').txt"
        echo "$(date '+%m-%d %H:%M') | 日志文件过大，已备份为 cron_log_$(date '+%Y%m%d_%H%M%S').txt" >&2
    fi
fi

# 根据类别模式设置初始类别
case "$CATEGORY_MODE" in
    "zr")
        current_category="zr"
        ;;
    "dm")
        current_category="dm"
        ;;
    "lh")
        current_category="zr"  # 轮换模式默认从 zr 开始
        ;;
    *)
        current_category="zr"  # 默认类别
        echo "$(date '+%m-%d %H:%M') | CATEGORY_MODE 未正确设置，默认使用 zr 类别" >&2
        ;;
esac

# 确保 PURITY 已设置
if [ -z "$PURITY" ]; then
    PURITY="110"  # 默认 R13
    echo "$(date '+%m-%d %H:%M') | PURITY 未设置，默认使用 R13" >&2
fi

# 提前设置 FALLBACK_FILE 和 REALLY_FILE
set_fallback_file "$PURITY" "$current_category"
set_really_file "$PURITY" "$current_category"

# 清理过期缓存、旧日志和 Really/Fallback 文件
cleanup_logs
cleanup_fallback
#cleanup_really

# 清空壁纸文件夹
if [ -d "$SAVE_DIR" ]; then
    find "$SAVE_DIR" -type f -delete
    echo "$(date '+%m-%d %H:%M') | 已清空残留壁纸" >&2
else
    echo "$(date '+%m-%d %H:%M') | 壁纸文件夹不存在：$SAVE_DIR" >&2
    exit 1
fi
