#!/usr/bin/env bash

API_KEY=$1

if [ -z "$API_KEY" ]; then
	echo "Usage: $0 API_KEY"
	exit 1
fi

case "$(uname -m)" in
	x86_64)
		wget -c 'https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-amd64.tar.xz' -O tmate.tar.xz
		;;
	armv7l)
		wget -c 'https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-arm32v7.tar.xz' -O tmate.tar.xz
		;;
	*)
		echo "Unsupported architecture"
		exit 1
		;;
esac

sudo tar xvf tmate.tar.xz --strip 1 -C /usr/local/bin

cat << EOF | sudo tee /etc/systemd/system/tmate@.service
[Unit]
Description=Instant terminal sharing
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/tmate -F -k $API_KEY -n %i
User=$(whoami)
Group=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable tmate@$(hostname)
sudo systemctl start tmate@$(hostname)
