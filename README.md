# Container Setup Utilities

[![Build Status](https://travis-ci.org/tommie/container-setuputils.svg?branch=master)](https://travis-ci.org/tommie/container-setuputils)

This is a small collection of utilities to initialize (Docker)
containers.

These have been tested with

* [`library/alpine`](https://hub.docker.com/_/alpine)
* [`library/debian`](https://hub.docker.com/_/debian)
* [`library/ubuntu`](https://hub.docker.com/_/ubuntu)

## Commands

### `addusergroup`

A simplified way of creating users in Dockerfiles.

```Dockerfile
# The user to run the exporter as. Created if it's not root.
ARG RUN_USER=root
# Use this UID for the non-root user. Optional.
ARG RUN_UID=
# Use this GID for the non-root group. Optional.
ARG RUN_GID=
# A comma-separated list of supplemental groups with optional GID,
# e.g. "onewithuid:1234,anotherexisting".
ARG RUN_SUPP_GROUPS=

COPY --from=githubtommie/container-setuptils addusergroup /sbin/addusergroup
RUN [ "$RUN_USER" = root ] || addusergroup -u "$RUN_UID" -g "$RUN_GID" -G "$RUN_SUPP_GROUPS" "$RUN_USER"
USER $RUN_USER
```

## Running tests

Running the tests on your local system: `make check`

Running the tests in Docker for all supported base images: `make check-docker`
