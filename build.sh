#!/bin/bash
#
# build static grep because we need exercises in minimalism
# MIT licengrep: google it or see robxu9.mit-license.org.
#
# For Linux, also builds musl for truly static linking.

grep_version="3.1"
musl_version="1.1.15"

platform=$(uname -s)

if [ -d build ]; then
  echo "= removing previous build directory"
  rm -rf build
fi

mkdir build # make build directory
pushd build

# download grepballs
echo "= downloading grep"
curl -LO http://ftp.gnu.org/gnu/grep/grep-${grep_version}.tar.xz

echo "= extracting grep"
tar xJf grep-${grep_version}.tar.xz

if [ "$platform" = "Linux" ]; then
  echo "= downloading musl"
  curl -LO http://www.musl-libc.org/releases/musl-${musl_version}.tar.gz

  echo "= extracting musl"
  tar -xf musl-${musl_version}.tar.gz

  echo "= building musl"
  working_dir=$(pwd)

  install_dir=${working_dir}/musl-install

  pushd musl-${musl_version}
  env CFLAGS="$CFLAGS -Os -ffunction-sections -fdata-sections" LDFLAGS='-Wl,--gc-sections' ./configure --prefix=${install_dir}
  make install
  popd # musl-${musl-version}

  echo "= setting CC to musl-gcc"
  export CC=${working_dir}/musl-install/bin/musl-gcc
  export CFLAGS="-static"
else
  echo "= WARNING: your platform does not support static binaries."
  echo "= (This is mainly due to non-static libc availability.)"
fi

echo "= building grep"

pushd grep-${grep_version}
env FORCE_UNSAFE_CONFIGURE=1 CFLAGS="$CFLAGS -Os -ffunction-sections -fdata-sections" LDFLAGS='-Wl,--gc-sections' ./configure
make
popd # grep-${grep_version}

popd # build

if [ ! -d releases ]; then
  mkdir releases
fi

echo "= striptease"
strip -s -R .comment -R .gnu.version --strip-unneeded build/grep-${grep_version}/src/grep
strip -s -R .comment -R .gnu.version --strip-unneeded build/grep-${grep_version}/src/fgrep
strip -s -R .comment -R .gnu.version --strip-unneeded build/grep-${grep_version}/src/egrep
echo "= compressing"
upx --ultra-brute build/grep-${grep_version}/src/grep
upx --ultra-brute build/grep-${grep_version}/src/egrep
upx --ultra-brute build/grep-${grep_version}/src/fgrep
echo "= extracting grep binary"
cp build/grep-${grep_version}/src/grep releases
cp build/grep-${grep_version}/src/fgrep releases
cp build/grep-${grep_version}/src/egrep releases
sed -i 's/#!/bin/sh/#!/bin/bash/g' releases/fgrep
sed -i 's/#!/bin/sh/#!/bin/bash/g' releases/egrep
echo "= done"
