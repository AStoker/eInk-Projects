ARG BUILD_FROM
FROM $BUILD_FROM

# Pillow and numpy from Alpine's packages rather than pip: building either from
# source on armv7 takes longer than the rest of the image put together.
RUN apk add --no-cache python3 py3-pillow py3-numpy

COPY panelise.py server.py run.sh /app/
RUN chmod a+x /app/run.sh

WORKDIR /app
CMD ["/app/run.sh"]
