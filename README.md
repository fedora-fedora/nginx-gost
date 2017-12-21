 ![N|Solid](https://www.cryptopro.ru/forum2/forumlogo.png)

# Создание Docker образа для связки CryptoPro и Nginx
Далее по тексту мы используем следующие оговорки:

  - Docker образ на основе **Centos 6.X**
  - **CryptoPro 4 R2** for linux
  - **Nginx** последняя сборка (на момент написания статьи **1.12.2-1.el6**)
  - У нас выпущены валидные ключи и сертификаты для доменного имени или сгенерированы с помощью тестового УЦ CryptoPro
  - Сертификаты будут устанавливаться в контейеры с типом провайдера КС2, так как **nginx** работает только с этим типом

### Описание Dockerfile (очевидные вещи опущены)
  - Копируем специально подготовленный конфигурационный файл **openssl** в Docker-образ (см. [форум CryptoPro])
  - Инсталируем необходимое ПО **redhat-lsb-core libcurl**
  - Копируем контейнер (по усмолчанию контейнеры CryptoPro размещаются по пути `/var/opt/cprocsp/keys/...`, где `...` имя пользователя, от которого создавался контейнер. В нашем случае **root**. Меняем владельца папки)
  - Копируем сертификат (местоназначения скопированного сертификата не имеет значения, но если использовать большую вложенность пути, импорт завершится с ошибкой)
  - Копируем файл конфигурации виртуального хоста **test.conf**

### Описание docker-entrypoint
  - Запускаем сервис CryptoPro:
  
    `/opt/cprocsp/sbin/amd64/cryptsrv`
  - Указываем CryptoPro где находится библиотека **Curl**:
  
    `/opt/cprocsp/sbin/amd64/cpconfig -ini \\config\\apppath -add string libcurl.so /usr/lib64/libcurl.so`
  - Если переносимый контейнер имеет пароль, то его надо сбросить:
  
    `/opt/cprocsp/bin/amd64/csptest -passwd -container '\\.\HDIMAGE\test_container' -change '' -passwd 'old_password'`
  - Устанавливаем сертификат в контейнер с типом провайдера **КС1** (обратите внимание, что имя контейнера идет без порядкового номера, используемого в dockerfile **test.000**):
  
    `/opt/cprocsp/bin/amd64/certmgr -inst -file /tmp/nginx.cer -cont '\\.\HDIMAGE\test'`
  - Устанавливаем ПО необходимое для работы с контейнерами типа **КС2** (Важно чтобы данный пакет был инсталирован после установки сертификата, но перед линковокой установленного сертификата с контейнером типа **КС2**):
  
    `yum install -y /tmp/lsb-cprocsp-kc2-64-4.0.0-4.x86_64.rpm`
  - Линкуем установленный сертификат с контейнером **КС2**:
  
    `/opt/cprocsp/bin/amd64/certmgr -inst -store uMy -cont '\\.\HDIMAGE\test' -provtype 75 -provname "Crypto-Pro GOST R 34.10-2001 KC2 CSP"`
  - Перековертируем сертификат из формата **X509/DER** в **X.509/PEM**:
  
    `/opt/cprocsp/cp-openssl/bin/amd64/openssl x509 -inform der -in /tmp/nginx.cer -out /etc/nginx/nginx.pem`
  - Редактируем **nginx.conf**. Необходимо изменить пользователя, от которого будет запускать **nginx**. Пользователь должен быть тем, от которого создавался/размещался контейнер с ключами. В нашем случае **root**
  
    `sed -i "s/user  nginx;/user  root;/" /etc/nginx/nginx.conf`

## Полезные команды и информация
  - Запуск контейнера осуществляется командой:
    
    `docker run --rm -p 443:443 -p 80:80 --name cprocsp6 --privileged --security-opt seccomp=unconfined --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro -d crypto`
  - Создание тестового запроса на сертификат, получение сертификата, создание контейнера и размещение в контейнере сертификата:
  `/opt/cprocsp/bin/amd64/cryptcp -creatcert -provtype 75 -provname "Crypto-Pro GOST R 34.10-2001 KC1 CSP" -rdn 'CN=www.aaa.ru' -cont '\\.\HDIMAGE\test_container' -certusage 1.3.6.1.5.5.7.3.1  -ku -du -ex -ca http://cryptopro.ru/certsrv`
  - Экспрот сертификата из контейнера в формате **X509/DER** (лучше использовать этот формат, так как при экспорте с опцией -base64 в файле сертификата будут отсутствовать строчки -----BEGIN CERTIFICATE----- и -----END CERTIFICATE-----)
  `/opt/cprocsp/bin/amd64/certmgr -export -store uMy -dest /tmp/nginx.cer`
  - Проверить наличие установленных сертификатов в системе (в поле **Provider Name** должно быть **Crypto-Pro GOST R 34.10-2001 KC2 CSP**):
  `/opt/cprocsp/bin/amd64/certmgr -list -store uMy`
 - Содержание контейнера:
header.key
masks2.key
masks.key
name.key
primary2.key
primary.key
  - Работа с выгруженным контейнером формата **pfx** в Linux-like системах не поддерживается!
  - Описание файла конфигурации виртуального хоста:

```   
ssl_certificate     /etc/nginx/nginx.pem;               наш ГОСТовский сертификат
ssl_certificate_key engine:gost_capi:node.sdsys.ru;     наш ГОСТовский ключ
ssl_certificate     /etc/nginx/sdsys.crt;               
ssl_certificate_key /etc/nginx/sdsys.key;
ssl_session_cache shared:SSL:1m;
ssl_session_timeout  5m;
ssl_protocols               TLSv1;
ssl_ciphers GOST2001-GOST89-GOST89:HIGH:MEDIUM;         описание Ciphers
ssl_prefer_server_ciphers   on;

```

В описании **location** необходимо добавить `proxy_set_header X-SSL-Cipher $ssl_cipher;`

##### Используемая литература:
[Форум CryptoPro][форум CryptoPro]

[Другие источники][pushorigin.ru]

[форум CryptoPro]: https://www.cryptopro.ru/forum2/default.aspx?g=posts&t=8733
[pushorigin.ru]: http://pushorigin.ru/cryptopro/article#размещение-контейнеров


## Запуск контейнера
docker run -p 443:443 -p 80:80 --name cprocsp6 --privileged --security-opt seccomp=unconfined --tmpfs /run --tmpfs /run/lock -v /sys/fs/cgroup:/sys/fs/cgroup:ro --network=proxy --restart always -d -e "ADMIN_LAB=dev-admin-lab.infoclinica.lan" -e "ADMIN_WEB=dev-admin-web.infoclinica.lan" -e "NODE_LAB=node-lab.infoclinica.lan" -e "NODE_WEB=node-web.infoclinica.lan" dev-registry.infoclinica.ru:5000/nginx:latest
