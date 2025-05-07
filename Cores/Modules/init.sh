#!/bin/bash
#VERSION="1.0.2"
#========== 初始化 ==========
IS_DIVINATION_MODE=0
DIVINATION_LOGGED=0
ANCHOR_NOT_FOUND_LOGGED=0
BACK_WAIT_LOGGED=0
BACK_WALLPAPER_SET=0
NETWORK_ANOMALY_LOGGED=0
BACK_ANCHOR_NOT_FOUND_LOGGED=0
IS_BACK_MODE=0
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$(basename "$0")"

# 创建必要目录和缓存文件
FUNCTION_DIR="/storage/emulated/0/Wallpaper/Cores/Function"
SAVE_DIR="/storage/emulated/0/Wallpaper/Cores/Papers"
LOG_DIR="/storage/emulated/0/Wallpaper/Cores/Logs"
SCRIPT_PATH="/data/data/com.termux/files/home/wallpaper_run_tmp.sh"
API_KEY_FILE="/storage/emulated/0/Wallpaper/Cores/Keywords/api_key.txt"
DB_FILE="$LOG_DIR/wallpaper_history.db"
touch "$LOG_DIR/wallpaper_history.db"
FALLBACK_DIR="/storage/emulated/0/Wallpaper/Cores/Fallbacks"
mkdir -p "$SAVE_DIR" "$LOG_DIR" "/storage/emulated/0/Wallpaper/Cores/Pages"
# 标定文件路径
CONFIG_DIR="/storage/emulated/0/Wallpaper/Cores/Configs"
ANCHOR_FILE="$CONFIG_DIR/Anchor_point"
mkdir -p "$CONFIG_DIR"
BACK_ANCHOR_FILE="/storage/emulated/0/Wallpaper/Cores/Backs/Anchor"
BACK_WALLPAPER="/storage/emulated/0/Wallpaper/Cores/Backs/back.jpg"
KEYWORD_DIR="/storage/emulated/0/Wallpaper/Cores/Keywords"
TMP_DIR="/storage/emulated/0/Wallpaper/Cores/Tmps"

TARGET_COUNT=510
SWITCH_THRESHOLD=5

declare -A FALLBACK_CACHE
declare -A REALLY_CACHE

