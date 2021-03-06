FROM centos:7

#Копируем файл репозитория
COPY configs/nginx.repo /etc/yum.repos.d/nginx.repo

#Копируем подготовленный конфиг openssl.cnf
COPY configs/openssl.cnf /etc/pki/tls/openssl.cnf

#Ставим необходимое СПО и КриптоПро заисключением lsb-cprocsp-kc2-64-4.0.0-4.x86_64.rpm! Его необходимо инсталировать через docker-entrypoint!!! Линкуем библиотеку.
RUN set -x \
           && yum install -y redhat-lsb-core libcurl initscripts \
           && yum install -y https://git.sdsys.ru/sdsys/docker/raw/bda498df1cb6cf0e7a26fd6e5aaac0c9fab35baf/cryptopro/distributive/lsb-cprocsp-base-4.0.0-4.noarch.rpm \
                        https://git.sdsys.ru/sdsys/docker/raw/bda498df1cb6cf0e7a26fd6e5aaac0c9fab35baf/cryptopro/distributive/lsb-cprocsp-rdr-64-4.0.0-4.x86_64.rpm \
                        https://git.sdsys.ru/sdsys/docker/raw/bda498df1cb6cf0e7a26fd6e5aaac0c9fab35baf/cryptopro/distributive/lsb-cprocsp-capilite-64-4.0.0-4.x86_64.rpm \
                        https://git.sdsys.ru/sdsys/docker/raw/bda498df1cb6cf0e7a26fd6e5aaac0c9fab35baf/cryptopro/distributive/lsb-cprocsp-kc1-64-4.0.0-4.x86_64.rpm \
                        https://git.sdsys.ru/sdsys/docker/raw/bda498df1cb6cf0e7a26fd6e5aaac0c9fab35baf/cryptopro/distributive/cprocsp-curl-64-4.0.0-4.x86_64.rpm \
                        https://git.sdsys.ru/sdsys/docker/raw/bda498df1cb6cf0e7a26fd6e5aaac0c9fab35baf/cryptopro/distributive/cprocsp-cpopenssl-64-4.0.0-4.x86_64.rpm \
                        https://git.sdsys.ru/sdsys/docker/raw/bda498df1cb6cf0e7a26fd6e5aaac0c9fab35baf/cryptopro/distributive/cprocsp-cpopenssl-base-4.0.0-4.noarch.rpm \
                        https://git.sdsys.ru/sdsys/docker/raw/bda498df1cb6cf0e7a26fd6e5aaac0c9fab35baf/cryptopro/distributive/cprocsp-cpopenssl-gost-64-4.0.0-4.x86_64.rpm \
                        nginx \
            && yum clean all \
            && rm -rf /var/cache/yum \
            && ln -s /usr/lib64/libcurl.so.4.1.1 /usr/lib64/libcurl.so \
            && ln -sf /dev/stdout /var/log/nginx/access.log \
            && ln -sf /dev/stderr /var/log/nginx/error.log

ENTRYPOINT ["/tmp/docker-entrypoint.sh"]

#Копируем дистрибутив
COPY configs/docker-entrypoint.sh \
     iru-hosts \
     distributive/lsb-cprocsp-kc2-64-4.0.0-4.x86_64.rpm \
     /tmp/
RUN chmod 755 /tmp/docker-entrypoint.sh
#Копируем контейнер с ключами, сертификат в формате DER и тестовый конфиг для виртуального хоста, меняем владельца.

COPY keys/infoclin.000 /var/opt/cprocsp/keys/root/
COPY keys/gost.infoclinica.ru.cer /etc/pki/tls/certs/

COPY configs/nginx.conf /etc/nginx/conf.d/
#COPY bundle/ /etc/pki/tls/
COPY keys/htaccess.passwd /etc/nginx/htaccess.passwd
RUN chown -R root:root /var/opt/cprocsp/keys/root

EXPOSE 81 80 443 
#HEALTHCHECK --start-period=30s --interval=15s --timeout=5s --retries=2 CMD curl -f 127.0.0.1:81 || exit 1
CMD ["nginx", "-g", "daemon off;"]
