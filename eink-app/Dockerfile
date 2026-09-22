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
#
# tzdata is not optional here. Alpine ships no zone database, and musl with no
# zone database answers UTC whatever TZ is set to -- silently, so the only
# symptom is the clock being wrong. The agenda's day boundaries and the AI
# image slots are both local-time decisions, and a UTC container rolls over to
# tomorrow at 8pm in New York.
RUN apk add --no-cache python3 py3-pillow py3-numpy tzdata

# Supervisor passes this at build time; bake it in so /health can report which
# version is actually running rather than which one the store thinks it sent.
ARG BUILD_VERSION=dev
ENV EINK_VERSION=$BUILD_VERSION

COPY agenda.py panelise.py server.py run.sh /app/
RUN chmod a+x /app/run.sh

WORKDIR /app
CMD ["/app/run.sh"]
