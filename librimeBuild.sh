#!/bin/bash
set -ex

RIME_ROOT="$(cd "$(dirname "$0")"; pwd)"

echo ${RIME_ROOT}

# librime dependences build
if [[ ! -d ${RIME_ROOT}/.boost ]]
then
  mkdir ${RIME_ROOT}/.boost
  cp -R ${RIME_ROOT}/boost-iosx/dest ${RIME_ROOT}/.boost
fi
export BOOST_ROOT=$RIME_ROOT/.boost/dest

# temp directory for librime lib and headers
RIME_LIB=${RIME_ROOT}/lib
RIME_INCLUDE=${RIME_ROOT}/include

rm -rf ${RIME_LIB} ${RIME_INCLUDE} && mkdir -p ${RIME_LIB} ${RIME_INCLUDE}

function prepare_library() {
  LIBRIME_VARIANT=$1
  LIBRIME_ROOT=${RIME_ROOT}/${LIBRIME_VARIANT}
  LIBRIME_INCLUDE=${RIME_INCLUDE}/${LIBRIME_VARIANT}
  cd ${LIBRIME_ROOT}
  git submodule update --init

  if [[ ! -f ${RIME_ROOT}/${LIBRIME_VARIANT}.patch.apply ]]
  then
      touch ${RIME_ROOT}/${LIBRIME_VARIANT}.patch.apply
      git apply ${RIME_ROOT}/librime.patch >/dev/null 2>&1
  fi

  # install lua plugin
  rm -rf ${LIBRIME_ROOT}/plugins/lua
  ${LIBRIME_ROOT}/install-plugins.sh imfuxiao/librime-lua@main

  # install charcode
  #rm -rf ${RIME_ROOT}/librime/plugins/librime-charcode
  #${RIME_ROOT}/librime/install-plugins.sh rime/librime-charcode
  #extern void rime_require_module_charcode();\
  #  rime_require_module_charcode();\

  # 添加lua模块依赖
  sed -i "" '/#if RIME_BUILD_SHARED_LIBS/,/#endif/c\
  #if RIME_BUILD_SHARED_LIBS\
  #define rime_declare_module_dependencies()\
  #else\
  extern void rime_require_module_core();\
  extern void rime_require_module_dict();\
  extern void rime_require_module_gears();\
  extern void rime_require_module_levers();\
  extern void rime_require_module_lua();\
  // link to default modules explicitly when building static library.\
  static void rime_declare_module_dependencies() {\
    rime_require_module_core();\
    rime_require_module_dict();\
    rime_require_module_gears();\
    rime_require_module_levers();\
    rime_require_module_lua();\
  }\
  #endif\
  ' ${LIBRIME_ROOT}/src/rime_api.cc

  make xcode/ios/deps

  mkdir -p ${LIBRIME_INCLUDE}
  cp ${LIBRIME_ROOT}/src/*.h ${LIBRIME_INCLUDE}

  # librime build

  # PLATFORM value means
  # OS64: to build for iOS (arm64 only)
  # OS64COMBINED: to build for iOS & iOS Simulator (FAT lib) (arm64, x86_64)
  # SIMULATOR64: to build for iOS simulator 64 bit (x86_64)
  # SIMULATORARM64: to build for iOS simulator 64 bit (arm64)
  # MAC: to build for macOS (x86_64)

  # librime build: iOS simulator 64 bit (x86_64)
  export PLATFORM=SIMULATOR64
  rm -rf ${LIBRIME_ROOT}/build ${LIBRIME_ROOT}/dist
  make xcode/ios/dist
  cp -f ${LIBRIME_ROOT}/dist/lib/librime.a ${RIME_LIB}/${LIBRIME_VARIANT}_simulator_x86_64.a

  # librime build: arm64
  export PLATFORM=OS64
  rm -rf ${LIBRIME_ROOT}/build ${LIBRIME_ROOT}/dist
  make xcode/ios/dist
  cp -f ${LIBRIME_ROOT}/dist/lib/librime.a ${RIME_LIB}/${LIBRIME_VARIANT}_arm64.a

  # transform *.a to xcframework
  rm -rf ${RIME_ROOT}/Frameworks/${LIBRIME_VARIANT}.xcframework

  # 屏蔽 headers ，双键盘引用不同的 librime frameworke, 在 XCoode 编译期间报错：重复的文件 
  # -library ${RIME_LIB}/${LIBRIME_VARIANT}_simulator_x86_64.a -headers ${LIBRIME_INCLUDE} \
  # -library ${RIME_LIB}/${LIBRIME_VARIANT}_arm64.a -headers ${LIBRIME_INCLUDE} \
  xcodebuild -create-xcframework \
  -library ${RIME_LIB}/${LIBRIME_VARIANT}_simulator_x86_64.a \
  -library ${RIME_LIB}/${LIBRIME_VARIANT}_arm64.a \
  -output ${RIME_ROOT}/Frameworks/${LIBRIME_VARIANT}.xcframework

  # clean
  rm -rf ${RIME_ROOT}/lib/${LIBRIME_VARIANT}*.a
}

prepare_library "librime"
prepare_library "librime-sbxlm"

# copy librime dependence lib
cp -f ${RIME_ROOT}/librime/lib/*.a ${RIME_ROOT}/lib

files=("libglog" "libleveldb" "libmarisa" "libopencc" "libyaml-cpp")
for file in ${files[@]}
do
    echo "file = ${file}"

    # 拆分模拟器编译文件
    rm -rf $RIME_ROOT/lib/${file}_x86.a
    lipo $RIME_ROOT/lib/${file}.a \
         -thin x86_64 \
         -output $RIME_ROOT/lib/${file}_x86.a

    rm -rf $RIME_ROOT/lib/${file}_arm64.a
    lipo $RIME_ROOT/lib/${file}.a \
         -thin arm64 \
         -output $RIME_ROOT/lib/${file}_arm64.a

    rm -rf ${RIME_ROOT}/Frameworks/${file}.xcframework
    xcodebuild -create-xcframework \
    -library ${RIME_ROOT}/lib/${file}_x86.a \
    -library ${RIME_ROOT}/lib/${file}_arm64.a \
    -output ${RIME_ROOT}/Frameworks/${file}.xcframework
done
