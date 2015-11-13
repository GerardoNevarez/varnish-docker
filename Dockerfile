#FROM debian:jessie
#
#MAINTAINER Dennis Clark <boomfish@gmail.com>
#
#
# Varnish installation steps based on https://www.varnish-cache.org/installation/debian
#
#
# We don't have curl installed yet so grab the Varnish package signing key from a PGP keyserver

FROM alpine
MAINTAINER Gerardo Nevarez Moorillon <gnevarez@gmail.com>
RUN apk add --update bash curl varnish varnish-doc && rm -rf /var/cache/apk/*

ENV VARNISH_BACKEND_PORT 80
ENV VARNISH_BACKEND_IP 172.17.42.1
ENV VARNISH_BACKEND_PROBE_METHOD HEAD
ENV VARNISH_BACKEND_PROBE_URL /
ENV VARNISH_BACKEND_PROBE_HOST localhost

# Expose port 80
EXPOSE 80

# Expose varnish lib as a volume so it can persist outside the container
VOLUME ["/var/lib/varnish"]

ADD start.sh /start.sh
CMD ["/start.sh"]

# Make our custom VCLs available on the container
ADD default.vcl /etc/varnish/default.vcl

