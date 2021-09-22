#!/bin/bash

external="$(pwd)/external/win32"

for i in "$@"; do
  case $i in
    --linux* | --win*) arch=${i#--};;
    --docker-image) docker=true; image=true ci=false;;
    --docker) docker=true; image=false ci=false;;
    --ci) docker=true; image=false ci=true;;
  esac
done

archs=(
  "linux32"
  "linux64"
  "win32"
  "win64"
  "linuxarmhf"
)

hosts=(
  ""
  ""
  "i686-w64-mingw32"
  "x86_64-w64-mingw32"
  "arm-linux-gnueabihf"
)

defines=(
  "-DBUILD_SHARED=OFF -DBUILD_EXAMPLES=OFF -DDUMB=OFF -DMODPLUG=OFF"
  "-DBUILD_SHARED=OFF -DBUILD_EXAMPLES=OFF -DDUMB=OFF -DMODPLUG=OFF"
  "-DBUILD_SHARED=OFF -DBUILD_EXAMPLES=OFF -DDUMB=OFF -DMODPLUG=OFF -DHAS_SNDFILE=1 -DHAS_VORBISFILE=1 -DHAS_FLAC=1 -DHAS_MPG123=1 -DHAS_FLUIDSYNTH=1"
  "-DBUILD_SHARED=OFF -DBUILD_EXAMPLES=OFF -DDUMB=OFF -DMODPLUG=OFF -DHAS_SNDFILE=1 -DHAS_VORBISFILE=1 -DHAS_FLAC=1 -DHAS_MPG123=1 -DHAS_FLUIDSYNTH=1"
  "-DBUILD_SHARED=OFF -DBUILD_EXAMPLES=OFF -DDUMB=OFF -DMODPLUG=OFF"
)

ccflags=(
  "-DCMAKE_PREFIX_PATH=\"/usr/lib/i386-linux-gnu/\" -DCMAKE_CXX_FLAGS=-m32 -DCMAKE_C_FLAGS=-m32"
  "-DCMAKE_CXX_FLAGS=-m64 -DCMAKE_C_FLAGS=-m64"
  "-DCMAKE_CXX_FLAGS=\"-I$external/include\" -DCMAKE_TOOLCHAIN_FILE=../XCompile.txt"
  "-DCMAKE_CXX_FLAGS=\"-I$external/include\" -DCMAKE_TOOLCHAIN_FILE=../XCompile.txt"
  "-DCMAKE_PREFIX_PATH=\"/usr/lib/arm-linux-gnueabihf/\" -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++"
)

output=(
  "libalure-static.a"
  "libalure-static.a"
  "libALURE32-static.a"
  "libALURE32-static.a"
  "libalure-static.a"
)

openaldir=(
  ""
  ""
  "$external"
  "$external"
  ""
)
if [ "$docker" = true ]; then
  if [ "$image" = true ]; then
    for i in ${!archs[@]}; do
      if [ ! -z ${arch} ] && [ ! ${archs[$i]} = ${arch} ]; then
        continue
      fi
      docker build -t alure-builder:${archs[$i]} - < docker/${archs[$i]}.Dockerfile
    done
  else
    for i in ${!archs[@]}; do
      if [ ! -z ${arch} ] && [ ! ${archs[$i]} = ${arch} ]; then
        continue
      fi
      if [ "$ci" = true ]; then
        docker run --rm -tv jenkins_home:/var/jenkins_home -w "$(pwd)" debian-rvgl:${archs[$i]} ./build.sh "--${archs[$i]}"
      else
        docker run --rm -tv "$(pwd)":/work -w /work alure-builder:${archs[$i]} ./build.sh "--${archs[$i]}"
      fi
    done
  fi

  exit
fi

for i in ${!archs[@]}; do  
  if [ ! -z ${arch} ] && [ ! ${archs[$i]} = ${arch} ]; then
    continue
  fi

  mkdir -p "build_${archs[$i]}"
  export OPENALDIR=${openaldir[$i]}
  prefix=`[ ! -z ${hosts[$i]} ] && echo ${hosts[$i]}-`
  (cd "build_${archs[$i]}" && cmake .. -DHOST=${hosts[$i]} ${ccflags[$i]} ${defines[$i]} && make)
  ${prefix}strip --strip-unneeded build_${archs[$i]}/${output[$i]}
done
