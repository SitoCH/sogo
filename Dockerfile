FROM phusion/baseimage:bionic-1.0.0

# Install Apache, SOGo from repository
RUN apt-get update && apt-get install -y wget && \
    echo "deb http://packages.inverse.ca/SOGo/nightly/5/ubuntu/ bionic bionic" > /etc/apt/sources.list.d/inverse.list && \
    wget -q "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x810273C4" -O- | gpg --dearmor > 0x810273C4.gpg && \
    mv 0x810273C4.gpg /etc/apt/trusted.gpg.d/ && \
    apt-get update && \
    mkdir /usr/share/doc/sogo/ && \
    touch /usr/share/doc/sogo/empty.sh && \
    apt-get install -y --no-install-recommends iproute2 gettext-base apache2 sogo sogo-activesync sope4.9-gdl1-mysql memcached && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Activate required Apache modules
RUN a2enmod headers proxy proxy_http rewrite ssl

# Move SOGo's data directory to /srv
RUN usermod --home /srv/lib/sogo sogo

# Fix memcached not listening on IPv6
RUN sed -i -e 's/^-l.*/-l localhost/' /etc/memcached.conf

# SOGo daemons
RUN mkdir /etc/service/sogod /etc/service/apache2 /etc/service/memcached
ADD sogod.sh /etc/service/sogod/run
ADD apache2.sh /etc/service/apache2/run
ADD memcached.sh /etc/service/memcached/run

# Make GATEWAY host available, control memcached startup
RUN mkdir -p /etc/my_init.d
ADD gateway.sh memcached-control.sh /etc/my_init.d/

# Interface the environment
VOLUME /srv
EXPOSE 80 443 8800

# Baseimage init process
ENTRYPOINT ["/sbin/my_init"]
