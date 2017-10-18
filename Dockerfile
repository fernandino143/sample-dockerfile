FROM alpine

RUN apk --update add \
        runit \
        bash \
	openssh-server \
	nginx \
&& rm -rf /var/cache/apk/*

ENV NOTVISIBLE "in users profile"

RUN ssh-keygen -t rsa -b 4096 -C "Mykey" -P "" -f "/etc/ssh/ssh_host_rsa_key" -q

RUN mkdir /run/nginx  /usr/lib/nginx/html
RUN echo 'root:password' | chpasswd
RUN sed -i s/'#PermitRootLogin prohibit-password'/'PermitRootLogin yes'/g /etc/ssh/sshd_config

COPY conf/service /etc/service
COPY conf/nginx/index.html /usr/lib/nginx/html/index.html
COPY conf/nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 22
EXPOSE 80

ENTRYPOINT ["/sbin/runsvdir", "-P", "/etc/service"]
