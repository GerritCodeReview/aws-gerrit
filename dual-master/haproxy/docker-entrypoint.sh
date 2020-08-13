#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
	# if the user wants "haproxy", let's use "haproxy-systemd-wrapper" instead so we can have proper reloadability implemented by upstream
	shift # "haproxy"
	set -- "$(which haproxy-systemd-wrapper)" -p /run/haproxy.pid "$@"
fi

export HA_TEMPLATE=/usr/local/etc/haproxy/haproxy.cfg.template
if [ "$MULTISITE_ENABLED" = "true" ]; then
  HA_TEMPLATE=/usr/local/etc/haproxy/haproxy.cfg.multisite.template
fi

echo "***** MULTISITE_ENABLED: '$MULTISITE_ENABLED'."
echo "**** Using '$HA_TEMPLATE' template."

envsubst < "$HA_TEMPLATE" > /usr/local/etc/haproxy/haproxy.cfg

exec "$@"
