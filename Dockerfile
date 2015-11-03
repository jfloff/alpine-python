FROM alpine:latest

# Install needed packages. Notes:
#   * python3-dev, libevent-dev: are used for gevent
#   * build-base: used so we include the basic development packages
#   * bash: so we can access /bin/bash
RUN apk add --update \
              musl \
              build-base \
              bash \
              python3 \
              pyther3-dev \
  && rm /var/cache/apk/*

# make some useful symlinks that are expected to exist
RUN cd /usr/bin \
  && ln -sf easy_install-3.4 easy_install \
  && ln -sf idle3.4 idle \
  && ln -sf pydoc3.4 pydoc \
  && ln -sf python3.4 python \
  && ln -sf python-config3.4 python-config \
  && ln -sf pip3.4 pip

# upgrade pip
RUN pip install --upgrade pip

# install requirements
# this way when you build you won't need to install again
# ans since COPY is cached we don't need to wait
COPY ./requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# since we will be "always" mounting the volume, we can set this up
CMD python
