FROM alpine:3.10

ENV VERSION=master

RUN apk --no-cache add \
      build-base \
      git \
      libressl-dev

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/nutechsoftware/ser2sock.git /ser2sock

WORKDIR /ser2sock

RUN ./configure && \
    make

# Staticx requires, readelf, objcopy, patchelf
RUN apk --no-cache add \
      # Provides readelf and objcopy
      binutils \
      patchelf \
      python3

RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    pip3 install \
      scons \
      https://github.com/JonathonReinhart/staticx/archive/master.zip

RUN staticx --strip ser2sock ser2sock_static
