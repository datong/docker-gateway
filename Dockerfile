FROM balenalib/aarch64-alpine

COPY init.sh /
COPY tx-local /
COPY tx-redir /
COPY dns2socks /


#RUN ["cross-build-start"]
RUN chmod +x /init.sh
RUN chmod +x /tx-local
RUN chmod +x /init.sh
RUN chmod +x /tx-redir
RUN chmod +x /dns2socks


RUN echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/01-ip_forward.conf

RUN apk --no-cache --no-progress upgrade && \
    apk --no-cache --no-progress add iptables pcre openssl libsodium libev mbedtls pcre dnsmasq ipset&& \
    rm -rf /tmp/*

#RUN ["cross-build-end"]

#COPY config.json /v2ray/
COPY dnsmasq.conf /etc/
COPY dnsmasq.china.conf /etc/dnsmasq.d/
COPY chnroute.ipset /

ENTRYPOINT ["/init.sh"]
