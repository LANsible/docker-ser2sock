FROM alpine:3.10

ENV VERSION=master

LABEL maintainer="wilmardo"

# Add unprivileged user
RUN echo "ser2sock:x:1000:1000:ser2sock:/:" > /etc_passwd

RUN apk --no-cache add \
        git \
        build-base \
        openssl-dev

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/nutechsoftware/ser2sock.git /ser2sock

WORKDIR /ser2sock

RUN sed -i 's/LIBS="-lcrypto $LIBS"/LIBS="$LIBS -lcrypto"/g' configure

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
    export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
    ./configure && \
    make \
      CFLAGS="-Wall -O3 -static" \
      LDFLAGS="-static"
