FROM jfloff/alpine-python:3.4

# Copy in the entrypoint script -- this installs prerequisites on container start.
COPY entrypoint.sh /entrypoint.sh

# install requirements
# this way when you build you won't need to install again
# and since COPY is cached we don't need to wait
ONBUILD COPY requirements.txt /tmp/requirements.txt

# Run the dependencies installer and then allow it to be run again if needed.
ONBUILD RUN /entrypoint.sh -r /tmp/requirements.txt
ONBUILD RUN rm -f /requirements.installed
