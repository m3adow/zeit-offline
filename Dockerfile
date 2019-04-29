FROM httpd:latest

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get install -y --no-install-recommends curl xsltproc
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /var/log/*

COPY --chown=www-data render.sh zeitoffline* /usr/local/apache2/cgi-bin/


