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

deps=("libglog" "libleveldb" "libmarisa" "libopencc" "libyaml-cpp")

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

  # install octagram plugin
  rm -rf ${LIBRIME_ROOT}/plugins/octagram
  ${LIBRIME_ROOT}/install-plugins.sh lotem/librime-octagram
  (cd ${LIBRIME_ROOT}/plugins/octagram && sed -i "" 's/add_subdirectory(tools)//' CMakeLists.txt)

  # install lua plugin
  rm -rf ${LIBRIME_ROOT}/plugins/lua
  ${LIBRIME_ROOT}/install-plugins.sh imfuxiao/librime-lua@develop


  # install charcode
  #rm -rf ${RIME_ROOT}/librime/plugins/librime-charcode
  #${RIME_ROOT}/librime/install-plugins.sh rime/librime-charcode
  #extern void rime_require_module_charcode();\
  #  rime_require_module_charcode();\

  # install predict
  # rm -rf ${LIBRIME_ROOT}/plugins/predict
  # ${LIBRIME_ROOT}/install-plugins.sh rime/librime-predict
  # (
  #   cd ${LIBRIME_ROOT}/plugins/predict
  #   sed -i '' '/add_subdirectory(tools)/d' CMakeLists.txt
  # )

  # 添加插件模块依赖
  sed -i "" '/#if RIME_BUILD_SHARED_LIBS/,/#endif/c\
  #if RIME_BUILD_SHARED_LIBS\
  void rime_declare_module_dependencies() {}\
  #else\
  extern void rime_require_module_core();\
  extern void rime_require_module_dict();\
  extern void rime_require_module_gears();\
  extern void rime_require_module_levers();\
  extern void rime_require_module_lua();\
  extern void rime_require_module_octagram();\
  // link to default modules explicitly when building static library.\
  void rime_declare_module_dependencies() {\
    rime_require_module_core();\
    rime_require_module_dict();\
    rime_require_module_gears();\
    rime_require_module_levers();\
    rime_require_module_lua();\
    rime_require_module_octagram();\
  }\
  #endif\
  ' ${LIBRIME_ROOT}/src/rime_api.cc

  # build deps
  # first time: for ios
  # rm -rf ${LIBRIME_ROOT}/lib/*.a
  make xcode/ios/deps/clean
  make xcode/ios/deps
  for file in ${deps[@]}
  do
    cp -f ${LIBRIME_ROOT}/lib/${file}.a ${RIME_LIB}/${file}.a
  done

  # second time: for simulator
  # rm -rf ${LIBRIME_ROOT}/lib/*.a
  make xcode/simulator/deps/clean
  make xcode/simulator/deps
  for file in ${deps[@]}
  do
    cp -f ${LIBRIME_ROOT}/lib/${file}.a ${RIME_LIB}/${file}_simulator.a
  done

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

  # librime build: iOS simulator 64 bit (arm64)
  export PLATFORM=SIMULATORARM64
  rm -rf ${LIBRIME_ROOT}/build ${LIBRIME_ROOT}/dist
  make xcode/ios/dist
  cp -f ${LIBRIME_ROOT}/dist/lib/librime.a ${RIME_LIB}/${LIBRIME_VARIANT}_simulator_arm64.a

  # librime build: arm64
  export PLATFORM=OS64
  rm -rf ${LIBRIME_ROOT}/build ${LIBRIME_ROOT}/dist
  make xcode/ios/dist
  cp -f ${LIBRIME_ROOT}/dist/lib/librime.a ${RIME_LIB}/${LIBRIME_VARIANT}.a

  # transform *.a to xcframework
  rm -rf ${RIME_ROOT}/Frameworks/${LIBRIME_VARIANT}.xcframework
  lipo ${RIME_LIB}/${LIBRIME_VARIANT}_simulator_x86_64.a ${RIME_LIB}/${LIBRIME_VARIANT}_simulator_arm64.a -create -output ${RIME_LIB}/${LIBRIME_VARIANT}_simulator.a

  xcodebuild -create-xcframework \
  -library ${RIME_LIB}/${LIBRIME_VARIANT}_simulator.a \
  -headers ${LIBRIME_INCLUDE} \
  -library ${RIME_LIB}/${LIBRIME_VARIANT}.a \
  -headers ${LIBRIME_INCLUDE} \
  -output ${RIME_ROOT}/Frameworks/${LIBRIME_VARIANT}.xcframework

  # clean
  rm -rf ${RIME_ROOT}/lib/${LIBRIME_VARIANT}*.a
}

prepare_library "librime"

for file in ${deps[@]}
do
    rm -rf ${RIME_ROOT}/Frameworks/${file}.xcframework

    if [ "$file" == "libyaml-cpp" ]
    then
      xcodebuild -create-xcframework \
      -library ${RIME_ROOT}/lib/${file}.a \
      -headers ${RIME_ROOT}/librime/deps/yaml-cpp/include \
      -library ${RIME_ROOT}/lib/${file}_simulator.a \
      -headers ${RIME_ROOT}/librime/deps/yaml-cpp/include \
      -output ${RIME_ROOT}/Frameworks/${file}.xcframework
    else
      xcodebuild -create-xcframework \
      -library ${RIME_ROOT}/lib/${file}.a \
      -library ${RIME_ROOT}/lib/${file}_simulator.a \
      -output ${RIME_ROOT}/Frameworks/${file}.xcframework
    fi
done
