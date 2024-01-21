ARG ALPINE_VER=3.18
# ffmpeg
FROM docker.io/alpine:$ALPINE_VER as ffmpeg
###############################
# Build the FFmpeg-build image.
ARG PREFIX=/usr/local
ARG LD_LIBRARY_PATH=/usr/local/lib
ARG MAKEFLAGS="-j4"
# FFmpeg build dependencies.
RUN apk add --update --no-cache --virtual=dev \
  autoconf \
  automake \
  bash \
  build-base \
  curl \
  gcc \
  git \
  libtool \
  openssl-dev \
  opus-dev \
  pkgconf \
  pkgconfig \
  wget \
  yasm && \
# fdk-aac https://github.com/mstorsjo/fdk-aac
    cd /tmp && \
    DIR=$(mktemp -d) && cd ${DIR} && \
    curl -sL https://github.com/mstorsjo/fdk-aac/tarball/master | \
    tar -zx --strip-components=1 && \
    autoreconf -fiv && \
    ./configure --prefix=/usr/local --disable-static --datadir="${DIR}" && \
    make && \
    make install && \
# Get ffmpeg source.
    cd /tmp/ && \
    git clone https://git.ffmpeg.org/ffmpeg.git && \
    cd /tmp/ffmpeg && \
    git checkout release/6.1 && \
# Compile ffmpeg.
    ./configure \
        --extra-version=radioserver0.1 \
        --enable-version3 \
        --enable-gpl \
        --enable-nonfree \
        --enable-small \
        --enable-libfdk-aac \
        --enable-openssl \
        --enable-decoder=aac \
        --enable-parser=aac \
        --enable-muxer=adts \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --extra-cflags="-I${PREFIX}/include" \
        --extra-ldflags="-L${PREFIX}/lib" \
        --extra-libs="-lpthread -lm" \
        --prefix="${PREFIX}" && \
    make && make install && make distclean
# ベースイメージを定義
FROM docker.io/alpine:$ALPINE_VER
# Primery packages
ENV TZ=Asia/Tokyo
RUN apk add --update --no-cache tzdata coreutils procps busybox-suid sudo bash && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    echo "Asia/Tokyo" > /etc/timezone
COPY --from=ffmpeg /usr/local /usr/local
COPY ./RadioServer /usr/local/bin/RadioServer
WORKDIR /usr/local/bin/RadioServer
RUN addgroup -g 1000 -S radioserver && \
    adduser -u 1000 -S radioserver -G radioserver && \
    ln -s /usr/local/bin/ffmpeg /usr/bin/ffmpeg && \
    ln -s /usr/local/bin/ffprobe /usr/bin/ffprobe && \
    apk add --update --no-cache pcre \
                     libogg \
                     openssl \
                     opus \
                     python3 py3-django curl && \
    crontab -r && \
    python manage.py migrate && \
    chown -R radioserver:radioserver /usr/local/bin/RadioServer
USER radioserver
VOLUME /usr/local/RadioServer/settings
ENTRYPOINT ["python", "manage.py", "runserver", "radioserver:9000"]
EXPOSE 9000
