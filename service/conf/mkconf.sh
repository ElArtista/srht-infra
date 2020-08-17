#!/bin/sh

KEYDIR=/etc/sr.ht

SERVICE_KEY=$(srht-keygen service)
SERVICE_KEY=$(echo $SERVICE_KEY | awk '/Secret/{print $3}' | tee $KEYDIR/service.key)

NETWORK_KEY=$(srht-keygen network)
NETWORK_KEY=$(echo $NETWORK_KEY | awk '/Secret/{print $3}' | tee $KEYDIR/network.key)

WEBHOOK_KEY=$(srht-keygen webhook)
WEBHOOK_PRV_KEY=$(echo $WEBHOOK_KEY | awk '/Private/{print $3}' | tee $KEYDIR/webhook.priv.key)
WEBHOOK_PUB_KEY=$(echo $WEBHOOK_KEY | awk '/Public/{print $3}' | tee $KEYDIR/webhook.pub.key)

sed -i "s:\${SERVICE_KEY}:$SERVICE_KEY:" /etc/sr.ht/config.ini
sed -i "s:\${NETWORK_KEY}:$NETWORK_KEY:" /etc/sr.ht/config.ini
sed -i "s:\${WEBHOOK_KEY}:$WEBHOOK_PRV_KEY:" /etc/sr.ht/config.ini
sed -i "s:\${DOMAIN}:$DOMAIN:g" /etc/sr.ht/config.ini
