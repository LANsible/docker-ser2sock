FROM alpine:3.10 as builder

ENV VERSION=v1.5.5

# Add unprivileged user
RUN echo "ser2sock:x:1000:1000:ser2sock:/:" > /etc_passwd

RUN apk --no-cache add \
        git \
        build-base \
        openssl-dev

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/nutechsoftware/ser2sock.git /ser2sock

WORKDIR /ser2sock

# Needed until https://github.com/nutechsoftware/ser2sock/pull/13 is merged
RUN sed -i 's/LIBS="-lcrypto $LIBS"/LIBS="$LIBS -lcrypto"/g' configure

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
    export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
    ./configure && \
    make \
      CFLAGS="-Wall -O3 -static" \
      LDFLAGS="-static"

# Minify binaries
# --brute does not work
RUN apk add --no-cache upx && \
    upx --best /ser2sock/ser2sock

# Test binary
RUN upx -t /root/.nexe/*/out/Release/node

FROM scratch

# Copy the unprivileged user
COPY --from=builder /etc_passwd /etc/passwd

# Copy static binary
COPY --from=builder /ser2sock/ser2sock /ser2sock
COPY ser2sock.conf /config/ser2sock.conf

USER ser2sock
ENTRYPOINT ["/ser2sock"]
CMD ["-f", "/config/ser2sock.conf"]
EXPOSE 10000
