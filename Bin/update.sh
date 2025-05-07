#!/bin/bash
REMOTE_REPO="git@github.com:kersfs/wallpaper.git"
BRANCH="main"
LOCAL_DIR="/storage/emulated/0/Wallpaper"
TEMP_CLONE_DIR="/storage/emulated/0/Wallpaper/Cores/Tmps/wallpaper_remote"
EXCLUDE_DIRS=(
  "/storage/emulated/0/Wallpaper/Cores/Logs/"
  "/storage/emulated/0/Wallpaper/Cores/Reallys/"
  "/storage/emulated/0/Wallpaper/Cores/Pages/"
  "/storage/emulated/0/Wallpaper/Cores/Keywords/"
  "/storage/emulated/0/Wallpaper/Cores/FallBacks/"
  "/storage/emulated/0/Wallpaper/Cores/Papers/"
  "/storage/emulated/0/Wallpaper/.git/"
  "/storage/emulated/0/Wallpaper/Tmps/"
  "/storage/emulated/0/Wallpaper/Cores/Gitconfiguration/"
)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

# 检查路径是否在排除列表中
is_excluded() {
    local path="$1"
    for dir in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$path" == "$dir"* ]]; then
            return 0
        fi
    done
    return 1
}

# 克隆远程仓库
clone_remote() {
    echo -e "${CYAN}🔄 正在同步远程仓库数据...${NC}"
    rm -rf "$TEMP_CLONE_DIR"
    git clone --depth 1 --branch "$BRANCH" "$REMOTE_REPO" "$TEMP_CLONE_DIR" &>/dev/null || {
        echo -e "${RED}❌ 远程仓库克隆失败${NC}"
        exit 1
    }
}

# 检查并处理文件更新
process_files() {
    local updated=0
    while IFS= read -r -d '' remote_file; do
        local relative_path="${remote_file#$TEMP_CLONE_DIR/}"
        local local_file="$LOCAL_DIR/$relative_path"

        if is_excluded "$local_file"; then
            continue
        fi

        local needs_update=0
        if [[ ! -f "$local_file" ]]; then
            needs_update=1
        elif ! cmp -s "$remote_file" "$local_file"; then
            needs_update=1
        fi

        if [[ $needs_update -eq 1 ]]; then
            echo -e "${YELLOW}检测到变更：${CYAN}$relative_path${NC}"
            read -p "是否更新此文件？[y/N] " choice </dev/tty
            if [[ "$choice" =~ ^[Yy]$ ]]; then
                mkdir -p "$(dirname "$local_file")"
                cp -f "$remote_file" "$local_file"
                echo -e "${GREEN}✅ 已更新：$relative_path${NC}"
                updated=1
            else
                echo -e "${CYAN}⏭️ 跳过：$relative_path${NC}"
            fi
        fi
    done < <(find "$TEMP_CLONE_DIR" -type f -print0)

    return $updated
}

# 主流程
main() {
    clone_remote
    process_files
    local status=$?
    rm -rf "$TEMP_CLONE_DIR"

    if [[ $status -eq 0 ]]; then
        echo -e "${GREEN}🎉 所有文件均为最新或用户跳过更新${NC}"
    else
        echo -e "${GREEN}✅ 更新流程已完成${NC}"
    fi
}

main