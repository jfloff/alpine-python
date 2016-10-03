FROM alpine:3.4

ENV PYTHON_MAJOR_VERSION=3

# Install needed packages. Notes:
#   * dumb-init: a proper init system for containers, to reap zombie children
#   * build-base: used so we include the basic development packages (gcc)
#   * bash: so we can access /bin/bash
#   * ca-certificates: for SSL verification during Pip and easy_install
#   * python-dev: are used for gevent e.g.
ENV PACKAGES="\
  dumb-init \
  musl \
  build-base \
  bash \
  ca-certificates \
  python${PYTHON_MAJOR_VERSION} \
  python${PYTHON_MAJOR_VERSION}-dev \
"

RUN echo \
# Figure out the minor version from the binary name
# no real need for this variable at the moment
#  && PYTHON_MINOR_VERSION="$(find /usr/bin -type f -name python\* | sort | tail -n1 | cut -d'.' -f2 | cut -d'-' -f1)" \

# Unfortunately the Alpine repositories are in a slightly inconsistent state for now-- python2 only exists in 'edge', not main.
  && if [[ "$PYTHON_MAJOR_VERSION" == '2' ]]; then PACKAGES="$(echo $PACKAGES | sed -e 's/python2/python/g')"; fi \

# Add testing and community repositories -- community is untagged as tagging it causes odd issues with the package index
  && echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  # Add the packages, with a CDN-breakage fallback if needed
  && apk add --no-cache $PACKAGES || \
    (sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories && apk add --no-cache $PACKAGES) \

# make some useful symlinks that are expected to exist
  && if [[ ! -e /usr/bin/python ]];        then ln -sf /usr/bin/python${PYTHON_MAJOR_VERSION} /usr/bin/python; fi \
  && if [[ ! -e /usr/bin/python-config ]]; then ln -sf /usr/bin/python-config${PYTHON_MAJOR_VERSION} /usr/bin/python-config; fi \

  && if [[ ! -e /usr/bin/idle ]];          then ln -sf /usr/bin/idle${PYTHON_MAJOR_VERSION} /usr/bin/idle; fi \
  && if [[ ! -e /usr/bin/pydoc ]];         then ln -sf /usr/bin/pydoc${PYTHON_MAJOR_VERSION} /usr/bin/pydoc; fi \

  && if [[ ! -e /usr/bin/easy_install ]];  then ln -sf /usr/bin/easy_install-${PYTHON_MAJOR_VERSION}.* /usr/bin/easy_install; fi \

# Install and upgrade Pip
  && easy_install pip \
  && pip install --upgrade pip \

  && if [[ ! -e /usr/bin/pip ]];           then ln -sf /usr/bin/pip${PYTHON_MAJOR_VERSION} /usr/bin/pip; fi \

&& echo

# since we will be "always" mounting the volume, we can set this up
ENTRYPOINT ["/usr/bin/dumb-init"]
CMD ["python"]
