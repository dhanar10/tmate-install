#!/usr/bin/env bash

set -e
set -o pipefail

API_KEY=$1
SESSION_NAME=$2

if [ $(id -u) -ne 0 ]; then
    sudo bash "$0" "$@"
    exit $?
fi

if [ -z "$API_KEY" ]; then
	echo "Usage: $0 API_KEY"
	exit 1
fi

if [ -z "$SESSION_NAME" ]; then
    SESSION_NAME=$HOSTNAME-$(echo -n $HOSTNAME | sha1sum | cut -c1-8)
fi

TEMP_DIR="$(mktemp -d)" 

trap "rm -rf $TEMP_DIR" EXIT

pushd "$TEMP_DIR"

case "$(uname -m)" in
	x86_64)
		wget -c 'https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-amd64.tar.xz' -O tmate.tar.xz
		;;
        armv6l)
                wget -c 'https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-arm32v6.tar.xz' -O tmate.tar.xz
                ;;
	armv7l)
		wget -c 'https://github.com/tmate-io/tmate/releases/download/2.4.0/tmate-2.4.0-static-linux-arm32v7.tar.xz' -O tmate.tar.xz
		;;
	*)
		echo "Unsupported architecture: $(uname -m)"
		exit 1
		;;
esac

tar xvf tmate.tar.xz --strip 1 -C /usr/local/bin

cat << EOF | tee /etc/systemd/system/tmate@.service
[Unit]
Description=Instant terminal sharing
After=network-online.target
Wants=network-online.target

[Service]
Environment="API_KEY=$API_KEY"
WorkingDirectory=$(getent passwd ${SUDO_USER:-$USER} | cut -d: -f6)
ExecStart=/usr/local/bin/tmate -F -k \$API_KEY -n %i
User=${SUDO_USER:-$USER}
Group=${SUDO_USER:-$USER}

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable tmate@$SESSION_NAME
systemctl start tmate@$SESSION_NAME

