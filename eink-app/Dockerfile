# A plain distro base, not $BUILD_FROM.
#
# Supervisor only passes BUILD_FROM when a build.yaml declares a base image per
# architecture; without one the arg is empty and the build dies on
# "base name ($BUILD_FROM) should not be blank". Naming the base directly needs
# no build.yaml and no per-arch table to keep current.
FROM alpine:3.21

# Pillow and numpy from apk, not pip: pip on Alpine compiles both from source,
# which needs a toolchain and takes longer than everything else put together.
# Taking python and both libraries from the same distro release also avoids the
# mismatch you get layering apk packages onto a python:*-alpine image, where the
# interpreter and the system packages can be different minor versions.
RUN apk add --no-cache python3 py3-pillow py3-numpy

# Supervisor passes this at build time; bake it in so /health can report which
# version is actually running rather than which one the store thinks it sent.
ARG BUILD_VERSION=dev
ENV EINK_VERSION=$BUILD_VERSION

COPY panelise.py server.py run.sh /app/
RUN chmod a+x /app/run.sh

WORKDIR /app
CMD ["/app/run.sh"]
