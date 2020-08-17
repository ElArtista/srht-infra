FROM alpine:3.12

ARG DOMAIN

COPY config.ini /etc/sr.ht/
COPY mkconf.sh /usr/local/bin/

RUN set -ex \
 && apk add --no-cache python3 py3-cryptography \
 && wget -q -P /usr/local/bin/ https://git.sr.ht/~sircmpwn/core.sr.ht/blob/master/srht-keygen \
 && chmod a+x /usr/local/bin/srht-keygen \
 && mkconf.sh
