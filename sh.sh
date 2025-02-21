#!/bin/bash

set -e  # Dừng script nếu có lỗi

# Hỏi tên người dùng
read -p "Nhập tên hiển thị cho kết nối Shadowsocks: " CLIENT_NAME
CLIENT_NAME=$(echo "$CLIENT_NAME" | sed 's/ /_/g')  # Thay khoảng trắng bằng "_"

# Random port trong khoảng an toàn
SERVER_PORT=$((RANDOM % (65535 - 1024) + 1024))
PASSWORD=$(openssl rand -base64 16)
METHOD="chacha20-ietf-poly1305"

# Cài đặt Shadowsocks nếu chưa có
echo "⚡ Cài đặt môi trường..."
sudo apt update -y
sudo apt install -y shadowsocks-libev qrencode curl

if ! command -v ss-server &> /dev/null; then
    echo "⚡ Cài đặt Shadowsocks từ PPA..."
    sudo add-apt-repository ppa:max-c-lv/shadowsocks-libev -y
    sudo apt update -y
    sudo apt install -y shadowsocks-libev
fi

# Tạo thư mục cấu hình nếu chưa có
sudo mkdir -p /etc/shadowsocks-libev

# Ghi file cấu hình Shadowsocks
echo "⚡ Cấu hình Shadowsocks..."
cat <<EOF | sudo tee /etc/shadowsocks-libev/config.json
{
    "server": "0.0.0.0",
    "server_port": $SERVER_PORT,
    "password": "$PASSWORD",
    "method": "$METHOD",
    "mode": "tcp_and_udp",
    "fast_open": true
}
EOF

# Mở firewall
echo "⚡ Cấu hình firewall..."
sudo ufw allow $SERVER_PORT/tcp
sudo ufw allow $SERVER_PORT/udp

# Restart dịch vụ
echo "⚡ Khởi động Shadowsocks..."
sudo systemctl restart shadowsocks-libev
sudo systemctl enable shadowsocks-libev

# Lấy địa chỉ IP bên ngoài
SERVER_IP=$(curl -s ifconfig.me)

# Xuất URL ss:// theo format không mã hóa method:password
SS_URL="ss://$METHOD:$PASSWORD@$SERVER_IP:$SERVER_PORT#$CLIENT_NAME"
echo "✅ Shadowsocks đã cài đặt!"
echo "🔗 Link kết nối: $SS_URL"

# Xuất QR Code có tên khách hàng
echo "⚡ Mã QR kết nối:"
qrencode -t UTF8 -o ss-qr.png "$SS_URL"
qrencode -t UTF8 "$SS_URL"

# Hiển thị tên khách dưới QR
echo -e "\n📌 Tên kết nối: $CLIENT_NAME\n"
