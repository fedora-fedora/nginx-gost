#!/usr/bin/env bash
#set -e

#Осуществляем запуск Cryptopro
service cprocsp start

#Указываем место нахождения libcurl
/opt/cprocsp/sbin/amd64/cpconfig -ini \\config\\apppath -add string libcurl.so /usr/lib64/libcurl.so

#Сбрасываем пароль для контейнера, если он был установлен
#/opt/cprocsp/bin/amd64/csptest -passwd -container '\\.\HDIMAGE\test_container' -change '' -passwd 'old_password'

#Выгружаем сертификат из контейнера
#/opt/cprocsp/bin/amd64/certmgr -export -store uMy -dest /tmp/nginx.cer

#Загружаем сертификат в контейнер
cd /etc/pki/tls/certs && /opt/cprocsp/bin/amd64/certmgr -inst -file gost.infoclinica.ru.cer -cont '\\.\HDIMAGE\infoclinica'

#Устанавливаем КС2
yum install -y /tmp/lsb-cprocsp-kc2-64-4.0.0-4.x86_64.rpm

#Линкуем только что загруженный сертификат как КС2
/opt/cprocsp/bin/amd64/certmgr -inst -store uMy -cont '\\.\HDIMAGE\infoclinica' -provtype 75 -provname "Crypto-Pro GOST R 34.10-2001 KC2 CSP"

#Переконвертируем сертифика из X509/DER в X.509/PEM
cd /etc/pki/tls/certs &&  /opt/cprocsp/cp-openssl/bin/amd64/openssl x509 -inform der -in gost.infoclinica.ru.cer -out gost.infoclinica.ru.pem

#Редактируем nginx.conf
sed -i "s/user  nginx;/user  root;/" /etc/nginx/nginx.conf

#Подчищаем
#rm -rf /tmp/nginx.cer /tmp/nginx.pem

exec "$@"
