BASEDIR="$(pwd)"

get_toolchain() {
  HOST_OS=$(uname -s)
  case ${HOST_OS} in
  Darwin) HOST_OS=darwin ;;
  Linux) HOST_OS=linux ;;
  FreeBsd) HOST_OS=freebsd ;;
  CYGWIN* | *_NT-*) HOST_OS=cygwin ;;
  esac

  HOST_ARCH=$(uname -m)
  case ${HOST_ARCH} in
  i?86) HOST_ARCH=x86 ;;
  x86_64 | amd64) HOST_ARCH=x86_64 ;;
  esac

  if [ "$(is_darwin_arm64)" == "1" ]; then
    # NDK DOESNT HAVE AN ARM64 TOOLCHAIN ON DARWIN
    # WE USE x86-64 WITH ROSETTA INSTEAD
    HOST_ARCH=x86_64
  fi

  echo "${HOST_OS}-${HOST_ARCH}"
}

overwrite_file() {
  rm -f "$2" 2>>"${BASEDIR}"/build.log
  cp "$1" "$2" 2>>"${BASEDIR}"/build.log
}

ANDROID_NDK_ROOT="/home/meonardo/Android/gstreamer/old/cerbero/build/android-ndk-21"
TOOLCHAIN=$(get_toolchain)
LIB_NAME="ffmpeg"
FFMPEG_LIBRARY_PATH="${BASEDIR}/out"
HOST="aarch64-linux-android-"
ANDROID_SYSROOT="${ANDROID_NDK_ROOT}"/toolchains/llvm/prebuilt/"${TOOLCHAIN}"/sysroot


export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/home/meonardo/Android/FFmpeg/deps/pkgconfig
export PATH=$PATH:"${ANDROID_NDK_ROOT}"/toolchains/llvm/prebuilt/"${TOOLCHAIN}"/bin


# configure
./configure --cross-prefix="${HOST}" --sysroot="${ANDROID_SYSROOT}" --pkg-config=/usr/bin/pkg-config --enable-version3 --arch=aarch64 --cpu=armv8-a --target-os=android --enable-neon --enable-asm --enable-inline-asm --ar=llvm-ar --cc=aarch64-linux-android21-clang --cxx=aarch64-linux-android21-clang++ --ranlib=llvm-ranlib --strip=llvm-strip --nm=llvm-nm --extra-libs='-L/home/meonardo/Android/FFmpeg/ffmpeg-kit/prebuilt/android-arm64-lts/cpu-features/lib -lndk_compat' --disable-autodetect --enable-cross-compile --enable-pic --enable-optimizations --enable-swscale --disable-static --enable-shared --enable-pthreads --enable-v4l2-m2m --disable-outdev=fbdev --disable-indev=fbdev --enable-small --disable-xmm-clobber-test --enable-debug --disable-stripping --disable-neon-clobber-test --disable-programs --disable-postproc --disable-doc --disable-htmlpages --disable-manpages --disable-podpages --disable-txtpages --disable-sndio --disable-schannel --disable-securetransport --disable-xlib --disable-cuda --disable-cuvid --disable-nvenc --disable-vaapi --disable-vdpau --disable-videotoolbox --disable-audiotoolbox --disable-appkit --disable-alsa --disable-cuda --disable-cuvid --disable-nvenc --disable-vaapi --disable-vdpau --disable-sdl2 --disable-openssl --enable-zlib --enable-mediacodec --enable-gpl --enable-rkmpp --enable-jni --enable-libdrm --extra-libs='-L/home/meonardo/Android/gstreamer/mpp/build/android/aarch64/rockchip-mpp/lib -lrockchip_mpp -L/home/meonardo/Android/gstreamer/librga/build/build_android_ndk/install/lib -lrga -L/home/meonardo/Android/android-project/libyuv/libyuv/out/arm64-v8a -lyuv -L/home/meonardo/Android/gstreamer/old/drm/build/lib -ldrm' --extra-cflags='-I/home/meonardo/Android/gstreamer/mpp/build/android/aarch64/rockchip-mpp/include -I/home/meonardo/Android/android-project/libyuv/libyuv/include -I/home/meonardo/Android/gstreamer/librga/build/build_android_ndk/install/include -I/home/meonardo/Android/gstreamer/old/drm/build/include' --prefix="${FFMPEG_LIBRARY_PATH}"

echo "configure done, building..."


# build
make -j20

# install
# DELETE THE PREVIOUS BUILD OF THE LIBRARY BEFORE INSTALLING
if [ -d "${FFMPEG_LIBRARY_PATH}" ]; then
  rm -rf "${FFMPEG_LIBRARY_PATH}" 1>>"${BASEDIR}"/build.log 2>&1 || return 1
fi
make install 1>>"${BASEDIR}"/build.log 2>&1

if [[ $? -ne 0 ]]; then
  echo -e "failed\n\nSee build.log for details\n"
  exit 1
fi

# MANUALLY ADD REQUIRED HEADERS
mkdir -p "${FFMPEG_LIBRARY_PATH}"/include/libavutil/x86 1>>"${BASEDIR}"/build.log 2>&1
mkdir -p "${FFMPEG_LIBRARY_PATH}"/include/libavutil/arm 1>>"${BASEDIR}"/build.log 2>&1
mkdir -p "${FFMPEG_LIBRARY_PATH}"/include/libavutil/aarch64 1>>"${BASEDIR}"/build.log 2>&1
mkdir -p "${FFMPEG_LIBRARY_PATH}"/include/libavcodec/x86 1>>"${BASEDIR}"/build.log 2>&1
mkdir -p "${FFMPEG_LIBRARY_PATH}"/include/libavcodec/arm 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/config.h "${FFMPEG_LIBRARY_PATH}"/include/config.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavcodec/mathops.h "${FFMPEG_LIBRARY_PATH}"/include/libavcodec/mathops.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavcodec/x86/mathops.h "${FFMPEG_LIBRARY_PATH}"/include/libavcodec/x86/mathops.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavcodec/arm/mathops.h "${FFMPEG_LIBRARY_PATH}"/include/libavcodec/arm/mathops.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavformat/network.h "${FFMPEG_LIBRARY_PATH}"/include/libavformat/network.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavformat/os_support.h "${FFMPEG_LIBRARY_PATH}"/include/libavformat/os_support.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavformat/url.h "${FFMPEG_LIBRARY_PATH}"/include/libavformat/url.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/attributes_internal.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/attributes_internal.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/bprint.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/bprint.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/getenv_utf8.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/getenv_utf8.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/internal.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/internal.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/libm.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/libm.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/reverse.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/reverse.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/thread.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/thread.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/timer.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/timer.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/x86/asm.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/x86/asm.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/x86/timer.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/x86/timer.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/arm/timer.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/arm/timer.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/aarch64/timer.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/aarch64/timer.h 1>>"${BASEDIR}"/build.log 2>&1
overwrite_file "${BASEDIR}"/libavutil/x86/emms.h "${FFMPEG_LIBRARY_PATH}"/include/libavutil/x86/emms.h 1>>"${BASEDIR}"/build.log 2>&1


if [ $? -eq 0 ]; then
  echo "ok"
else
  echo -e "failed\n\nSee build.log for details\n"
  exit 1
fi