# Build stage
FROM alpine:3.12 as build-stage

RUN set -ex \
 && apk update && apk add sudo git alpine-sdk lua-aports \
 && abuild-keygen -a -i -n \
 && mkdir -p /etc/init.d /etc/conf.d \
 && mkdir -p /usr/src && cd /usr/src \
 && git clone https://git.sr.ht/~sircmpwn/sr.ht-apkbuilds && cd sr.ht-apkbuilds/sr.ht \
 && (for pkg in $(ap recursdeps meta.sr.ht); do (cd $pkg; abuild -F checksum && abuild -F -r -P /var/local/repo) || exit; done)

# Production stage
FROM alpine:3.12 as prod-stage
COPY --from=build-stage /var/local/repo /var/local/repo
COPY --from=build-stage /etc/apk/keys /etc/apk/keys

RUN set -ex \
 && echo "/var/local/repo/sr.ht" >> /etc/apk/repositories \
 && mkdir -p /etc/sr.ht \
 && apk add --no-cache \
        postgresql-client \
        supervisor nginx \
        meta.sr.ht

COPY supervisord.conf /etc/supervisord.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY setup.sh /usr/local/bin/setup.sh

EXPOSE 80
CMD ["/bin/sh", "-c", "setup.sh && supervisord -n -c /etc/supervisord.conf"]
