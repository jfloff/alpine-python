# alpine-python

[![Docker Stars](https://img.shields.io/docker/stars/jfloff/alpine-python.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/jfloff/alpine-python.svg)][hub]
[![Docker Layers](https://badge.imagelayers.io/jfloff/alpine-python:latest.svg)](https://imagelayers.io/?images=jfloff/alpine-python:latest 'Get your own badge on imagelayers.io')

[hub]: https://hub.docker.com/r/jfloff/alpine-python/

A small Python Docker image based on [Alpine Linux](http://alpinelinux.org/).

<!-- MDTOC maxdepth:6 firsth1:0 numbering:0 flatten:0 bullets:1 updateOnSave:1 -->

- [Supported tags](#supported-tags)   
- [Why?](#why)   
- [Details](#details)   
- [Usage](#usage)   
   - [Via `docker run`](#via-docker-run)   
   - [Pip Dependencies](#pip-dependencies)   
   - [Run-Time Dependencies](#run-time-dependencies)   
   - [Build-Time Dependencies](#build-time-dependencies)   
   - [Creating Images](#creating-images)   
   - [Debugging](#debugging)   
- [License](#license)   

<!-- /MDTOC -->

## Supported tags
* **2.7 ([Dockerfile](https://github.com/jfloff/alpine-python/blob/master/2.7/Dockerfile))**
* **2.7-onbuild ([Dockerfile](https://github.com/jfloff/alpine-python/blob/master/2.7/onbuild/Dockerfile))**
* **3.4 ([Dockerfile](https://github.com/jfloff/alpine-python/blob/master/3.4/Dockerfile))**
* **3.4-onbuild ([Dockerfile](https://github.com/jfloff/alpine-python/blob/master/3.4/onbuild/Dockerfile))**

**NOTE:** `onbuild` images install the `requirements.txt` of your project from the get go. This allows you to cache your requirements right in the build. _Make sure you are in the same directory of your `requirements.txt` file_.

## Why?
The default docker python images are too [big](https://github.com/docker-library/python/issues/45), much larger than they need to be. Hence I built this simple image based on [docker-alpine](https://github.com/gliderlabs/docker-alpine), that has everything needed for the most common python projects - including `python3-dev` (which is not common in most minimal alpine python packages).

```
REPOSITORY                TAG           VIRTUAL SIZE
jfloff/alpine-python      3.4           102.7 MB
jfloff/alpine-python      2.7           52.17 MB
python                    3.4           681.4 MB
python                    3.4-slim      196 MB
```

Perhaps this could be even more smaller, but I'm not an Alpine guru. **Feel free to post a PR.**

## Details
* Installs `build-base`, `linux-headers`, and `python-dev`, allowing the use of more advanced packages such as `gevent`
* Installs `bash` allowing interaction with the container
* Just like the main `python` docker image, it creates useful symlinks that are expected to exist, e.g. `python3.4` > `python`, `pip2.7` > `pip`, etc.)
* Added `testing` and `community` repositories to Alpine's `/etc/apk/repositories` file



## Usage

### Via `docker run`
This image can be run in multiple ways. With no arguments, it will run `python` interactively:
```shell
docker run --rm -ti jfloff/alpine-python
```

If you specify a command, it will run that:
```shell
docker run --rm -ti jfloff/alpine-python python hello.py
```

### Pip Dependencies
Pip dependencies can be installed by the `-p` switch, or a `requirements.txt` file.

If the file is at `/requirements.txt` it will be automatically read for dependencies. If not, use the `-P` or `-r` switch to specify a file.
```shell
# This runs interactive Python with 'simplejson' and 'requests' installed
docker run --rm -ti jfloff/alpine-python -p simplejson -p requests

# Don't forget to add '--' after your dependencies to run a custom command:
docker run --rm -ti jfloff/alpine-python -p simplejson -p requests -- python hello.py

# This accomplishes the same thing by mounting a requirements.txt in:
echo 'simplejson' > requirements.txt
echo 'requests' > requirements.txt
docker run --rm -ti \
  -v requirements.txt:/requirements.txt \
  jfloff/alpine-python python hello.py

# This does too, but with the file somewhere else:
echo 'simplejson requests' > myapp/requirements.txt
docker run --rm -ti \
  -v myapp:/usr/src/app \
  jfloff/alpine-python \
    -r /usr/src/app/requirements.txt \
    -- python /usr/src/app/hello.py
```

### Run-Time Dependencies
Alpine package dependencies can be installed by the `-a` switch, or an `apk-requirements.txt` file.

If the file is at `/apk-requirements.txt` it will be automatically read for dependencies. If not, use the `-A` switch to specify a file.

You can also try installing some Python modules via packages, but it is possible for Pip to interfere if it detects a version problem.
```shell
# Unknown why you'd need to do this, but you can!
docker run --rm -ti jfloff/alpine-python -a openssl -- python hello.py

# This installs libxml2 module, but then Pip removes the packaged version and reinstalls because Ajenti's dependencies make it think it's the wrong version.
docker run --rm -ti jfloff/alpine-python -a py-libxml2 -p ajenti
```

### Build-Time Dependencies
Build-time Alpine package dependencies (such as compile headers) can be installed by the `-b` switch, or a `build-requirements.txt` file. They will be removed after the dependencies are installed to save space.

If the file is at `/build-requirements.txt` it will be automatically read for dependencies. If not, use the `-B` switch to specify a file.

`build-base`, `linux-headers` and `python-dev` are always build dependencies, you don't need to include them.
```shell
docker run --rm -ti jfloff/alpine-python \
  -p gevent \
  -p libxml2 \
  -b libxslt-dev \
  -b libxml-dev \
  -- python hello.py
```

### Creating Images
Dependencies can be baked into a new image by using a custom `Dockerfile`, e.g:
```dockerfile
FROM jfloff/alpine-python:2.7
RUN /entrypoint.sh \
  -p ajenti-panel \
  -p ajenti.plugin.dashboard \
  -p ajenti.plugin.settings \
  -p ajenti.plugin.plugins \
  -b libxml2-dev \
  -b libxslt-dev \
  -b libffi-dev \
  -b openssl-dev \
&& echo
CMD ["ajenti-panel"]
```

Or, using the onbuild image:
```dockerfile
FROM jfloff/alpine-python:3.4-onbuild

# if you'd need APK or build dependencies, this is where you'd copy that in:
# COPY apk-requirements.txt /
# COPY build-requirements.txt /

# for a flask server
EXPOSE 5000
CMD python manage.py runserver
```

Don't forget to build _your_ image:
```shell
docker build --rm -t jfloff/app .
```

### Debugging
You can also access `bash` inside the container:
```shell
docker run --rm -ti jfloff/alpine-python /bin/bash
```


Personally, I build an extended `Dockerfile` version (like shown above), and mount my specific application inside the container:
```shell
docker run --rm -v "$(pwd)":/home/app -w /home/app -p 5000:5000 -ti jfloff/app
```

## License
The code in this repository, unless otherwise noted, is MIT licensed. See the `LICENSE` file in this repository.
