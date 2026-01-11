ARG ALPINE_VER=3.22
# ffmpeg
FROM docker.io/alpine:$ALPINE_VER as ffmpeg
###############################
# Build the FFmpeg-build image.
ARG PREFIX=/usr/local
ARG LD_LIBRARY_PATH=/usr/local/lib
ARG MAKEFLAGS="-j4"
ENV PKG_CONFIG_PATH "/usr/share/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig"
ENV LD_PRELOAD /usr/bin/lib/preloadable_libiconv.so
# FFmpeg build dependencies.
RUN apk add --update --no-cache --virtual=dev \
  autoconf \
  automake \
  bash \
  build-base \
  curl \
  cmake \
  docbook2x \
  expat-dev \
  g++ \
  gcc \
  gettext-dev \
  git \
  gperf \
  json-c-dev \
  libtool \
  libva-dev \
  nasm \
  opus-dev \
  pkgconf \
  pkgconfig \
  python3-dev \
  util-linux-dev \
  wget \
  yasm && \
  # fribidi-dev \
# openssl
  cd /tmp && \
  git clone https://github.com/openssl/openssl.git && \
  cd openssl && \
  ./config --prefix=/usr/local no-shared enable-fips linux-x86_64 && \
  make && \
  make install_sw && \
# zlib
    cd /tmp && \
    DIR=$(mktemp -d) && cd ${DIR} && \
    curl -sLO https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz && \
    tar -xvzf zlib-1.3.1.tar.gz && \
    ls -l && \
    cd zlib-1.3.1 && \
    ./configure --static --prefix=/usr/local && \
    make && \
    make install && \
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
#    git clone https://github.com/0p1pp1/FFmpeg.git ffmpeg && \
    git clone https://git.ffmpeg.org/ffmpeg.git && \
    cd /tmp/ffmpeg && \
    git checkout release/7.1 && \
# Compile ffmpeg.
    ./configure \
	--enable-static \
        --enable-network \
        --enable-autodetect \
        --disable-debug \
        --enable-version3 \
        --enable-gpl \
        --enable-nonfree \
        --enable-small \
        --disable-hwaccels \
        --disable-swscale \
        --enable-libfdk-aac \
        --disable-libdrm \
        --disable-libxcb \
        --enable-openssl \
        --enable-decoder=aac \
        --enable-parser=aac \
        --enable-muxer=adts \
        --disable-doc \
        --disable-ffplay \
        --disable-ffprobe \
        --enable-ffmpeg \
        --enable-decoder=aac*,mp3,ac3*,pcm*,wav,3g*,m4*,mj2,mov \
        --enable-encoder=aac,flac,mp3,wav,mp4,pcm* \
        --enable-parser=mpegaudio \
        --enable-demuxer=aac*,mp3,ac3*,pcm*,wav,mp4,m4a,3g*,m4*,mj2,mov \
        --enable-muxer=aac,ipod,flac,mp3,wav,mp4,pcm* \
        --enable-filter=aresample \
        --extra-cflags="-I${PREFIX}/include" \
        --extra-ldflags="-L${PREFIX}/lib" \
        --extra-libs="-lpthread -lm" \
        --prefix="${PREFIX}" \
        --pkg-config-flags=--static && \
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
                     python3 py3-django curl musl libva && \
    crontab -r && \
    chown -R radioserver:radioserver /usr/local/bin/RadioServer
USER radioserver
RUN python3 -m venv ~/radioserver --system-site-packages && \
    source ~/radioserver/bin/activate && \
    ~/radioserver/bin/python manage.py migrate
VOLUME /usr/local/RadioServer/settings
ENTRYPOINT ["/home/radioserver/radioserver/bin/python", "manage.py", "runserver", "radioserver:9000"]
EXPOSE 9000
