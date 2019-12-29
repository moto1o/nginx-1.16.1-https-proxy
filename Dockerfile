FROM alpine:3.10

LABEL maintainer="moto1o <moto1o@163.com>"

ENV NGINX_VERSION 1.16.1
ENV NJS_VERSION   0.3.5
ENV PKG_RELEASE   1
ENV WORK_DIR /home/workdir

RUN set -x \
# create nginx user/group first, to be consistent throughout docker variants
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
    && apkArch="$(cat /etc/apk/arch)" \
# create WORKDIR  dir
    && if [ ! -d "${WORK_DIR}" ]; then mkdir -p "${WORK_DIR}"; fi \
    && chmod 777 ${WORK_DIR} \
# replace source
    && githuburl="https://raw.githubusercontent.com/moto1o/nginx-1.16.1-https-proxy/master" \
    && wget --no-check-certificate -O ${WORK_DIR}/select_source.sh ${githuburl}/select_source.sh \
    && sed -i 's/\r//g' ${WORK_DIR}/select_source.sh \
    && sh ${WORK_DIR}/select_source.sh \
# download file
    && wget --no-check-certificate -O /etc/apk/keys/abuild-key.rsa.pub ${githuburl}/packages/alpine_apk/abuild-key.rsa.pub \
    && wget --no-check-certificate -O ${WORK_DIR}/nginx-1.16.1-r1.apk ${githuburl}/packages/alpine_apk/nginx-1.16.1-r1.apk \
    && apk add ${WORK_DIR}/nginx-1.16.1-r1.apk \
    && rm -rf ${WORK_DIR}/nginx-1.16.1-r1.apk \
    #&& wget --no-check-certificate -O ${WORK_DIR}/alpine_apk.tar.gz ${githuburl}/packages/alpine_apk.tar.gz \
    #&& tar -xvf ${WORK_DIR}/alpine_apk.tar.gz -C ${WORK_DIR} \
    #&& cp ${WORK_DIR}/alpine_apk/abuild-key.rsa.pub /etc/apk/keys/ \
    #&& apk add ${WORK_DIR}/alpine_apk/*.apk \
    #&& rm -rf ${WORK_DIR}/alpine_apk.tar.gz ${WORK_DIR}/alpine_apk \
    && wget --no-check-certificate -O ${WORK_DIR}/forward-proxy.conf ${githuburl}/forward-proxy.conf \
    && cp ${WORK_DIR}/forward-proxy.conf /etc/nginx/conf.d \
# setting soft link
    && ln -sf /var/log/nginx ${WORK_DIR}/log-nginx \
    && ln -sf /var/log/nginx ${WORK_DIR}/conf-nginx \
# add tool
    && apk --update add logrotate openssl bash curl \
# Create 'messages' file used from 'logrotate'
    && touch /var/log/messages \
# Bring in gettext so we can get `envsubst`, then throw
# the rest away. To do this, we need to install `gettext`
# then move `envsubst` out of the way so `gettext` can
# be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && runDeps="$( \
        scanelf --needed --nobanner /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache $runDeps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
# Bring in tzdata so users could set the timezones through the environment
# variables
    && apk add --no-cache tzdata \
    ## setting shanghai zonetime
    && cp -r -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
# forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
# down start file
    && wget --no-check-certificate -O /startup.sh ${githuburl}/startup.sh \
    && sed -i 's/\r//g' /startup.sh


WORKDIR "${WORK_DIR}"
EXPOSE 80 8899

STOPSIGNAL SIGTERM

#CMD ["nginx", "-g", "daemon off;"]
CMD ["/bin/bash", "/startup.sh"]
