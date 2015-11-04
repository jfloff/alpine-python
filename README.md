# alpine-python

[![Docker Stars](https://img.shields.io/docker/stars/jfloff/alpine-python.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/jfloff/alpine-python.svg)][hub]
[![Docker Layers](https://badge.imagelayers.io/jfloff/alpine-python:latest.svg)](https://imagelayers.io/?images=jfloff/alpine-python:latest 'Get your own badge on imagelayers.io')

[hub]: https://hub.docker.com/r/jfloff/alpine-python/

A small Python Docker image based on [Alpine Linux](http://alpinelinux.org/). The image is only 225 MB and it includes `python3-dev`.

## Why?

The default docker python images are too [big](https://github.com/docker-library/python/issues/45), much larger than they need to be. Hence I built this simple image based on [docker-alpine](https://github.com/gliderlabs/docker-alpine), that has everything needed for the most common python projects - including `python3-dev` (which is not common in most minimal alpine python packages).

```
REPOSITORY                TAG           VIRTUAL SIZE
jfloff/alpine-python      latest        225.7 MB
python                    3.4           685.5 MB
python                    3.4-slim      215.1 MB
```

We actually get the same size as `python:3.4-slim` *but* with `python3-dev` installed (that's around 55MB).

Perhaps this could be even more smaller, but I'm not an Alpine guru. **Feel free to post a PR.**

## Usage

This image will install the `requirements.txt` of your project from the get go. This allows you to cache your requirements right in the build. _Make sure you are in the same directory of your `requirements.txt` file_.

To build Docker image:
```shell
docker build --rm=true -t jfloff/alpine-python .
```

This image runs `python` command on `docker run`. You can either specify your own command, e.g:
```shell
docker run --rm -ti jfloff/followme python hello.py
```

Or extend this images using your custom `Dockerfile`, e.g:
```dockerfile
FROM jfloff/alpine-python:latest

# for a flask server
EXPOSE 5000
CMD python manage.py runserver
```

You can also access `bash` inside the container:
```shell
docker run --rm -ti jfloff/followme /bin/bash
```

Personally, I build an extended `Dockerfile` version (like shown above), and mount my specific application inside the container:
```shell
docker run --rm -v "$(pwd)":/home/app -w /home/app -p 5000:5000 -ti jfloff/app
```


## Details
* Installs form the get go the `requirements.txt` of your project. This allows you to cache your requirements.
* Just like the main `python` docker image, it creates useful symlinks that are expected to exist (`python3` > `python`, `pip3` > `pip`, etc.)
* Installs `python3-dev` allowing the use of more advanced packages such as `gevent`;
* Installs `bash` allowing interaction with the container;


## License

The code in this repository, unless otherwise noted, is MIT licensed. See the `LICENSE` file in this repository.
