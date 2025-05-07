#!/bin/bash
echo "创建项目文件夹"
mkdir -p "/storage/emulated/0/Wallpaper"
echo "移动项目文件到文件夹"
mv "PAPER-main"/* "/storage/emulated/0/Wallpaper"
echo "删除项目文件夹"
rm -rf "PAPER-main/"
k="/storage/emulated/0/Wallpaper/Cores/Keywords"
touch "$k/api_key.txt"
touch "$k/Bottom_pocket.txt"
touch "$k/country.txt"
touch "$k/dm.txt"
touch "$k/query_map.txt"
touch "$k/welfare.txt"
directory="/data/data/com.termux/files/home"
filename="l.sh"
filepath="$directory/$filename"

# 确保目录存在
mkdir -p "$directory"

# 创建文件并写入多行内容
cat << EOF > "$filepath"
#!/bin/bash

while true; do
    echo "Wallpaper Management Program ："
    echo "1. 执行主程序"
    echo "2. 推送本地更新"
    echo "3. 拉取远程版本"
    echo "4. 更新运行参数"
    echo "5. 退出脚本"
    read -p "请输入对应的数字 (1-5): " choice

    case "$choice" in
        1)
            bash /storage/emulated/0/Wallpaper/Bin/l.sh
            clear
            ;;
        2)
            bash /storage/emulated/0/Wallpaper/Bin/updategit.sh
            ;;
        3)
            bash /storage/emulated/0/Wallpaper/Bin/update.sh
            ;;
        4)
            nano /storage/emulated/0/Wallpaper/Cores/Cdivination/Thousand.txt
            clear
            ;;
        5)
            clear
            exit
            ;;
        *)
            echo "输入无效，请输入数字 1 到 5 之间的选项。"
            sleep 2
            clear
            ;;
    esac
done
EOF
exit