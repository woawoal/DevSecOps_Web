# Rocky Linux 9.3을 기본 이미지로 사용
FROM rockylinux:9.3.20231119-minimal

# dnf 패키지 관리자 설치
RUN microdnf -y install dnf

# 시스템 패키지 업데이트 및 필요한 패키지 설치
RUN dnf -y update && \
    dnf -y install httpd php php-cli php-fpm php-mysqlnd php-json php-opcache php-xml mariadb mariadb-server && \
    dnf clean all

# Apache 설정 파일에서 ServerName 설정 추가
RUN echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf && \
    echo "LoadModule proxy_module modules/mod_proxy.so" >> /etc/httpd/conf/httpd.conf && \
    echo "LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so" >> /etc/httpd/conf/httpd.conf && \
    echo "ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/html/\$1" >> /etc/httpd/conf/httpd.conf

# PHP 설정
RUN sed -i 's/;date.timezone =/date.timezone = Asia\/Seoul/g' /etc/php.ini && \
    mkdir -p /run/php-fpm && \
    sed -i 's/listen = \/run\/php-fpm\/www.sock/listen = 127.0.0.1:9000/g' /etc/php-fpm.d/www.conf

# MariaDB 초기 설정
RUN mysql_install_db --user=mysql --datadir=/var/lib/mysql

# MariaDB 보안 설정
RUN echo "[mysqld]" >> /etc/my.cnf.d/mariadb-server.cnf && \
    echo "port = 3307" >> /etc/my.cnf.d/mariadb-server.cnf && \
    echo "bind-address = 0.0.0.0" >> /etc/my.cnf.d/mariadb-server.cnf && \
    echo "default-authentication-plugin = mysql_native_password" >> /etc/my.cnf.d/mariadb-server.cnf

# 웹 소스 파일 복사
COPY web/ /var/www/html/

# setup_script 폴더 복사
COPY setup_script/ /setup/

# SELinux 컨텍스트 설정 (필요한 경우)
RUN chown -R apache:apache /var/www/html && \
    chmod -R 755 /var/www/html

# setup 스크립트 권한 설정
RUN chmod +x /setup/usershell.sh && \
    chmod +x /setup/admin_hash.php

# 80 포트 노출
EXPOSE 80 3307

# 서비스 시작 스크립트 생성
RUN printf '#!/bin/bash\n\
# MariaDB 시작\n\
/usr/libexec/mariadbd --user=mysql &\n\
\n\
# PHP-FPM 시작\n\
php-fpm &\n\
\n\
# MariaDB가 완전히 시작될 때까지 대기\n\
sleep 10\n\
\n\
# DB 스크립트 실행\n\
mysql < /setup/DB_flame.sql\n\
mysql < /setup/DB_sql.sql\n\
mysql < /setup/DB_challenge.sql\n\
\n\
# PHP 스크립트 실행\n\
php /setup/admin_hash.php\n\
\n\
# Shell 스크립트 실행\n\
/setup/usershell.sh\n\
\n\
# Apache 시작\n\
/usr/sbin/httpd -D FOREGROUND' > /start.sh && \
chmod +x /start.sh

# 컨테이너 시작 시 실행할 명령
CMD ["/start.sh"]
