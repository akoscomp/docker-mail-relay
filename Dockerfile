FROM alpine:latest
LABEL MAINTAINER="Akos NAGY<nagy.akos@libreoffice.ro>"

# Packages: update
RUN apk -U add postfix ca-certificates libsasl cyrus-sasl-login py-pip supervisor rsyslog acf-openssl busybox-extras
RUN rm /usr/lib/python*/EXTERNALLY-MANAGED && \
    python3 -m ensurepip && \
    pip3 install jinjanator

# Add files
ADD conf /root/conf
RUN mkfifo /var/spool/postfix/public/pickup \
    && ln -s /etc/postfix/aliases /etc/aliases

# Configure: supervisor
ADD bin/dfg.sh /usr/local/bin/
ADD conf/supervisor-all.ini /etc/supervisor.d/

# Runner
ADD run.sh /root/run.sh
RUN chmod +x /root/run.sh

#RUN ln -sf /dev/stdout /var/log/mail.log

# Declare
EXPOSE 25

CMD ["/root/run.sh"]
