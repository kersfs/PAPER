# PAPER
基于whallhaven开发的手机壁纸项目
#克隆本项目
git clone https://github.com/kersfs/PAPER.git
#使用说明
该项目脚本基于Termux和Termux API运行前请下载对于应用
首次使用先运行Bin目录下的paper.sh脚本，初始化程序/后续无需再运行
本脚本支持功能如下
1.使用wallhaven API下载或设置壁纸
2.1 支持关键词筛选，类别筛选，国家筛选，纯度筛选（脚本初始化后，会创建关键词文件在/storage/emulated/0/Wallpaper/Cores/Keywords/目录下）
2.2 Keywords/目录各文件使用说明
api_key.txt 写入你的wallhaven API密钥 若使用R18纯度必须写入
Bottom_pocket.txt  Bottom_pocket机制的下载链接，填入你需要的图片API
country.txt 国家关键词目录，写入你想要匹配的国家（英文一行一个，支持词组）如 japanese
dm.txt  动漫壁纸关键词目录 写入动漫壁纸关键词 （英文一行一个，支持词组） 如 cat girl
welfare.txt 真人壁纸关键词目录 写入真人壁纸关键词 （英文一行一个，支持词组）如 cat girl
query_map.txt 关键词的中文映射目录 格式 英文|中文 如 japanese|日本 一行一个
3.纯度支持 R8 R13 R18 Only13 Only18 R18D 主程序交互会有详细说明
4.支持定时更换壁纸
5.真人支持国家和关键词组合搜索或只搜索关键词
6.支持动漫和真人轮换也可锁定类别


