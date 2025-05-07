#!/bin/bash
#VERSION="1.0.9"

# 配置区
LOCAL_DIR="/storage/emulated/0/Wallpaper"
REMOTE_REPO="git@github.com:kersfs/wallpaper.git"
BRANCH="main"
SSH_KEY="/data/data/com.termux/files/home/storage/shared/.ssh/wallpaper_key"
GITIGNORE_LINK="$LOCAL_DIR/.gitignore"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_env() {
    if [ ! -d ~/storage/shared ]; then
        echo -e "${RED}❌ 未授予Termux存储权限，正在自动配置...${NC}"
        termux-setup-storage
        sleep 2
    fi

    if [ ! -f "$SSH_KEY" ]; then
        echo -e "${RED}❌ SSH密钥文件不存在：$SSH_KEY${NC}"
        exit 1
    fi
}

setup_ssh() {
    mkdir -p ~/.ssh
    cat > ~/.ssh/config <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY
    IdentitiesOnly yes
    StrictHostKeyChecking no
EOF
    chmod 600 ~/.ssh/config
    chmod 600 "$SSH_KEY"
}

create_gitignore() {
    mkdir -p "$(dirname "$GITIGNORE_LINK")"
    cat > "$GITIGNORE_LINK" <<EOF
Cores/Logs/*
Cores/Reallys/*
Cores/Pages/*
Cores/Keywords/*
Cores/FallBacks/*
Cores/Papers/*
Cores/Tmps/*
!*.gitkeep
EOF

    # 在每个目录中创建 .gitkeep 文件
    for dir in Logs Reallys Pages Keywords FallBacks Papers Tmps; do
        mkdir -p "$LOCAL_DIR/Cores/$dir"
        touch "$LOCAL_DIR/Cores/$dir/.gitkeep"
    done
}

main() {
    cd "$LOCAL_DIR" || {
        echo -e "${RED}❌ 无法进入目录：$LOCAL_DIR${NC}"
        exit 1
    }

    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}⚠️ 初始化Git仓库...${NC}"
        git init >/dev/null 2>&1 || {
            echo -e "${RED}❌ Git初始化失败${NC}"
            exit 1
        }
    fi

    git config --local user.email "kers@killove.cn"
    git config --local user.name "kersfs"

    if git remote | grep -q origin; then
        git remote remove origin >/dev/null 2>&1
    fi
    git remote add origin "$REMOTE_REPO" >/dev/null 2>&1

    create_gitignore

    echo -e "${YELLOW}🔄 添加文件到暂存区...${NC}"
    git add . >/dev/null 2>&1 || {
        echo -e "${RED}❌ 添加文件失败${NC}"
        exit 1
    }

    echo -e "${YELLOW}📝 创建提交...${NC}"
    git commit -m "自动提交 $(date +'%Y-%m-%d %H:%M:%S')" >/dev/null 2>&1 || {
        echo -e "${YELLOW}⚠️ 没有内容需要提交${NC}"
        exit 0
    }
    echo -e "${YELLOW}📦 提交的文件列表：${NC}"
    git diff-tree --no-commit-id --name-only -r HEAD
    echo -e "${YELLOW}🔁 同步远程仓库...${NC}"
    git pull --rebase --allow-unrelated-histories origin "$BRANCH" >/dev/null 2>&1 || {
        echo -e "${YELLOW}⚠️ 尝试强制推送...${NC}"
        git push -f origin "$BRANCH" >/dev/null 2>&1 && {
            echo -e "${GREEN}✅ 强制推送成功${NC}"
            exit 0
        } || {
            echo -e "${RED}❌ 推送失败${NC}"
            exit 1
        }
    }

    echo -e "${YELLOW}🚀 推送更改...${NC}"
    git push -u origin "$BRANCH" >/dev/null 2>&1 && {
        echo -e "${GREEN}✅ 推送成功${NC}"
    } || {
        echo -e "${RED}❌ 推送失败${NC}"
        exit 1
    }
}

check_env
setup_ssh
main