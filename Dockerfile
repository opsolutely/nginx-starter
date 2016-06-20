FROM ubuntu:14.04
MAINTAINER Kate Heddleston <kate@makemeup.co>

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
        && echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
        && apt-get update \
        && apt-get install --no-install-recommends --no-install-suggests -y \
                                                ca-certificates \
                                                nginx=${NGINX_VERSION} \
                                                nginx-module-xslt \
                                                nginx-module-geoip \
                                                nginx-module-image-filter \
                                                nginx-module-perl \
                                                nginx-module-njs \
                                                gettext-base \
        && rm -rf /var/lib/apt/lists/*

# stop supervisor service as we'll run it manually
RUN service supervisor stop
RUN rm /etc/nginx/sites-enabled/default

# Add logging conf file
RUN wget -O ./remote_syslog.tar.gz https://github.com/papertrail/remote_syslog2/releases/download/v0.17/remote_syslog_linux_amd64.tar.gz && tar xzf ./remote_syslog.tar.gz && cp ./remote_syslog/remote_syslog /usr/bin/remote_syslog && rm ./remote_syslog.tar.gz && rm -rf ./remote_syslog/

# Add remote syslog config files
COPY ./docker_files/log_files.yml /etc/log_files.yml

# Add service.conf
COPY ./docker_files/service.conf /etc/nginx/sites-enabled/service.conf

# Add supervisor
COPY ./docker_files/supervisord.conf /etc/supervisor/conf.d/supervisor.conf

RUN mkdir /opt/code

# Add github repo code to code file
COPY . /opt/code/

WORKDIR /opt/code

# expose port(s)
EXPOSE 80 443

CMD supervisord -c /etc/supervisor/conf.d/supervisord.conf
