#!/bin/bash
# 数海漫游 — 本地预览服务器
# 双击此文件即可启动，自动在浏览器打开课件

DIR="$(cd "$(dirname "$0")" && pwd)"
PORT=8765

cd "$DIR"

echo ""
echo "========================================="
echo " 数海漫游 本地预览服务器"
echo "========================================="
echo " 地址：http://localhost:$PORT"
echo " 关闭：回到此窗口按 Ctrl+C"
echo "========================================="
echo ""

# 等 0.5 秒再打开浏览器，确保服务器已启动
(sleep 0.5 && open "http://localhost:$PORT/%E6%95%B0%E6%B5%B7%E6%BC%AB%E6%B8%B8-%E5%8D%95%E6%96%87%E4%BB%B6%E9%9D%99%E6%80%81%E7%89%88.html") &

python3 -m http.server $PORT
