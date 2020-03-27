FROM alpine:3.11

# VERSIONS
ENV ALPINE_VERSION=3.11 \
    PYTHON_VERSION=3.8.2

# PATHS
ENV PYTHON_PATH=/usr/local/bin/ \
    PATH="/usr/local/lib/python$PYTHON_VERSION/bin/:/usr/local/lib/pyenv/versions/$PYTHON_VERSION/bin:${PATH}" \
    # These are always installed. Notes:
    #   * dumb-init: a proper init system for containers, to reap zombie children
    #   * bash: For entrypoint, and debugging
    #   * ca-certificates: for SSL verification during Pip and easy_install
    PACKAGES="\
      dumb-init \
      bash \
      ca-certificates \
    " \
    # PACKAGES needed to built python
    PYTHON_BUILD_PACKAGES="\
      bzip2-dev \
      coreutils \
      dpkg \
      dpkg-dev \
      expat-dev \
      findutils \
      gcc \
      gdbm-dev \
      git \
      libc-dev \
      libffi-dev \
      libnsl-dev \
      libtirpc-dev \
      linux-headers \
      make \
      ncurses-dev \
      libressl-dev \
      pax-utils \
      readline-dev \
      sqlite-dev \
      tcl-dev \
      tk \
      tk-dev \
      util-linux-dev \
      xz-dev \
      zlib-dev \
    " \
    # These packages are not installed immediately, but are added at runtime or ONBUILD to shrink the image as much as possible. Notes:
    #   * build-base: used so we include the basic development packages (gcc)
    #   * linux-headers: commonly needed, and an unusual package name from Alpine.
    #   * lib6-compat: compatibility libraries for glibc
    #   * git: to ease up clones of repos
    BUILD_PACKAGES="\
      build-base \
      linux-headers \
      libc6-compat \
      git \
    "

# Copy in the entrypoint script -- this installs prerequisites on container start.
COPY entrypoint.sh /entrypoint.sh

RUN set -ex ;\
    # find MAJOR and MINOR python versions based on $PYTHON_VERSION
    export PYTHON_MAJOR_VERSION=$(echo "${PYTHON_VERSION}" | rev | cut -d"." -f3-  | rev) ;\
    export PYTHON_MINOR_VERSION=$(echo "${PYTHON_VERSION}" | rev | cut -d"." -f2-  | rev) ;\
    # replacing default repositories with edge ones
    echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community" >> /etc/apk/repositories ;\
    echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main" >> /etc/apk/repositories ;\
    # Add the packages, with a CDN-breakage fallback if needed
    apk add --no-cache $PACKAGES || \
        (sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories && apk add --no-cache $PACKAGES) ;\
    # Add packages just for the python build process with a CDN-breakage fallback if needed
    apk add --no-cache --virtual .build-deps $PYTHON_BUILD_PACKAGES || \
        (sed -i -e 's/dl-cdn/dl-4/g' /etc/apk/repositories && apk add --no-cache --virtual .build-deps $PYTHON_BUILD_PACKAGES) ;\
    # turn back the clock -- so hacky!
    echo "http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/main/" > /etc/apk/repositories ;\
    # echo "@community http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/community" >> /etc/apk/repositories ;\
    # echo "@testing http://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/testing" >> /etc/apk/repositories ;\
    # echo "@edge-main http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories ;\
    # use pyenv to download and compile specific python version
    git clone --depth 1 https://github.com/pyenv/pyenv /usr/local/lib/pyenv ;\
    # install
    GNU_ARCH="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" ;\
    PYENV_ROOT=/usr/local/lib/pyenv CONFIGURE_OPTS="--build=$GNU_ARCH --enable-loadable-sqlite-extensions --enable-shared --with-system-expat --with-system-ffi --without-ensurepip --with-shared" /usr/local/lib/pyenv/bin/pyenv install $PYTHON_VERSION ;\
    # keep the needed .so files
    # ignore libpython - that one comes from the pyenv instalation
    find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec scanelf --needed --nobanner --format '%n#p' '{}' ';' \
        | tr ',' '\n' \
        | sort -u \
        | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
        | grep -ve 'libpython' \
        | xargs -rt apk add --no-cache --virtual .python-rundeps ;\
        # for debug
        # | xargs -n1 echo ;\
    # delete everything from pyenv except the installed version
    # this throws an error but we ignore it
    find /usr/local/lib/pyenv/ -mindepth 1 -name versions -prune -o -exec rm -rf {} \; || true ;\
    # delete files to to reduce container size
    # tips taken from main python docker repo
    find /usr/local/lib/pyenv/versions/$PYTHON_VERSION/ -depth \( -name '*.pyo' -o -name '*.pyc' -o -name 'test' -o -name 'tests' \) -exec rm -rf '{}' + ;\
    # symlink the binaries
    ln -s /usr/local/lib/pyenv/versions/$PYTHON_VERSION/bin/* $PYTHON_PATH ;\
    ln -s /usr/local/lib/pyenv/versions/$PYTHON_VERSION/include/python$PYTHON_MINOR_VERSION /usr/include/ ;\
    # remove build dependencies and any leftover apk cache
    apk del --no-cache --purge .build-deps ;\
    rm -rf /var/cache/apk/* ;\
    # set proper permission to run entrypoint script
    chmod a+x /entrypoint.sh

# This script installs APK and Pip prerequisites on container start, or ONBUILD. Notes:
#   * Reads the -a flags and /apk-requirements.txt for install requests
#   * Reads the -b flags and /build-requirements.txt for build packages -- removed when build is complete
#   * Reads the -p flags and /requirements.txt for Pip packages
#   * Reads the -r flag to specify a different file path for /requirements.txt
ENTRYPOINT ["/usr/bin/dumb-init", "bash", "/entrypoint.sh"]
