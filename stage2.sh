#!/bin/sh

eval set -- "$(getopt -o "brlLmM:" --long "build-dir:,root-dir:,with-libevent-archive:,with-libevent-dir:,with-memcached-archive:,with-memcached-dir:" -- "$@")"
while true; do
    case "$1" in
        -b|--build-dir             ) BUILD_DIR="$2"         ; shift 2 ;;
        -r|--root-dir              ) ROOT_DIR="$2"          ; shift 2 ;;
        -l|--with-libevent-archive ) LIBEVENT_ARCHIVE="$2"  ; shift 2 ;;
        -L|--with-libevent-dir     ) LIBEVENT_DIR="$2"      ; shift 2 ;;
        -m|--with-memcached-archive) MEMCACHED_ARCHIVE="$2" ; shift 2 ;;
        -M|--with-memcached-dir    ) MEMCACHED_DIR="$2"     ; shift 2 ;;
        *                          ) break                            ;;
    esac
done

cd "$BUILD_DIR"

[ -d "$LIBEVENT_DIR" ] && rm -rf "$LIBEVENT_DIR"
tar -xzf "$LIBEVENT_ARCHIVE" -C "$BUILD_DIR"
pushd "$LIBEVENT_DIR"
./autogen.sh
./configure --prefix=/usr/local
make
make install
popd

