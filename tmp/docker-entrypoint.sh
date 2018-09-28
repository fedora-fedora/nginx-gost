/opt/cprocsp/sbin/amd64/cryptsrv

# Указываем CryptoPro где находится библиотека Curl:

/opt/cprocsp/sbin/amd64/cpconfig -ini \\config\\apppath -add string libcurl.so /usr/lib64/libcurl.so

# Если переносимый контейнер имеет пароль, то его надо сбросить:

# /opt/cprocsp/bin/amd64/csptest -passwd -container '\\.\HDIMAGE\test_container' -change '' -passwd 'old_password'

# Устанавливаем сертификат в контейнер с типом провайдера КС1 (обратите внимание, что имя контейнера идет без порядкового номера, используемого в dockerfile test.000):

# /opt/cprocsp/bin/amd64/certmgr -inst -file /tmp/nginx.cer -cont '\\.\HDIMAGE\test'

# Устанавливаем ПО необходимое для работы с контейнерами типа КС2 (Важно чтобы данный пакет был инсталирован после установки сертификата, но перед линковокой установленного сертификата с контейнером типа КС2):

yum install -y /tmp/lsb-cprocsp-kc2-64-4.0.0-4.x86_64.rpm

Линкуем установленный сертификат с контейнером КС2:

# /opt/cprocsp/bin/amd64/certmgr -inst -store uMy -cont '\\.\HDIMAGE\test' -provtype 75 -provname "Crypto-Pro GOST R 34.10-2001 KC2 CSP"

# Перековертируем сертификат из формата X509/DER в X.509/PEM:

# /opt/cprocsp/cp-openssl/bin/amd64/openssl x509 -inform der -in /tmp/nginx.cer -out /etc/nginx/nginx.pem

#Редактируем nginx.conf. Необходимо изменить пользователя, от которого будет запускать nginx. Пользователь должен быть тем, от которого создавался/размещался контейнер с ключами. В нашем случае root

sed -i "s/user nginx;/user root;/" /etc/nginx/nginx.conf
