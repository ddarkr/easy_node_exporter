#!/bin/bash

DOWNLOAD_VERSION=1.2.2

arch=$(uname -i)
if [[ $arch == x86_64* ]]; then
    DOWNLOAD_FILE=https://github.com/prometheus/node_exporter/releases/download/v$DOWNLOAD_VERSION/node_exporter-$DOWNLOAD_VERSION.linux-amd64.tar.gz
elif  [[ $arch == aarch64 ]]; then
    DOWNLOAD_FILE=https://github.com/prometheus/node_exporter/releases/download/v$DOWNLOAD_VERSION/node_exporter-$DOWNLOAD_VERSION.linux-armv7.tar.gz
else
    echo "[!] 해당 스크립트가 지원하지 않는 아키텍쳐입니다."
    exit 1
fi

SERVICE_FILE=/etc/systemd/system/node_exporter.service

# root only
if [[ $EUID -ne 0 ]]; then
   echo "[!] 이 스크립트는 root 권한으로만 사용할 수 있습니다."
   exit 1
fi

# 파일 작업
cd /root/
wget $DOWNLOAD_FILE
tar xvfz node_exporter-*.*-*.tar.gz
mv node_exporter*/ node_exporter/

# 잔여 파일 정리
rm -rf node_exporter-*.*-*.tar.gz

if test -f "$SERVICE_FILE"; then
    echo "[!] systemd 파일이 이미 존재하는 것으로 확인되었습니다. 먼저 기존에 존재하던 서비스를 제거 후 다시 실행 바랍니다."
    echo "   - systemd 파일 경로: $SERVICE_FILE"
    rm -rf node_exporter/
    exit 1
fi

# systemd 파일 생성
echo "[Unit]" >> $SERVICE_FILE
echo "Description=Prometheus Node Exporter" >> $SERVICE_FILE
echo "Documentation=https://prometheus.io/docs/guides/node-exporter/" >> $SERVICE_FILE
echo "Wants=network-online.target" >> $SERVICE_FILE
echo "After=network-online.target" >> $SERVICE_FILE
echo "" >> $SERVICE_FILE
echo "[Service]" >> $SERVICE_FILE
echo "User=root" >> $SERVICE_FILE
echo "Restart=on-failure" >> $SERVICE_FILE
echo "ExecStart=/root/node_exporter/node_exporter" >> $SERVICE_FILE
echo "" >> $SERVICE_FILE
echo "[Install]" >> $SERVICE_FILE
echo "WantedBy=multi-user.target" >> $SERVICE_FILE

systemctl enable node_exporter.service
systemctl start node_exporter.service

# 상태 확인
echo "[@] 설치가 완료되었습니다."
echo ""
echo ""
systemctl status node_exporter.service
