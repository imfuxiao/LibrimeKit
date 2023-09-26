#!/bin/bash
set -ex

RIME_ROOT="$(cd "$(dirname "$0")"; pwd)"

echo ${RIME_ROOT}

cd ${RIME_ROOT}/librime
git submodule update --init

if [[ ! -f ${RIME_ROOT}/librime.patch.apply ]]
then
    touch ${RIME_ROOT}/librime.patch.apply
    git apply ${RIME_ROOT}/librime.patch >/dev/null 2>&1
fi

# install lua plugin
rm -rf ${RIME_ROOT}/librime/plugins/lua
${RIME_ROOT}/librime/install-plugins.sh imfuxiao/librime-lua@main

# install charcode
# TODO: 需要依赖 boost_locale.xcframework 而 boost_locale 依赖 icu, 在 xcode下编译失败
# rm -rf ${RIME_ROOT}/librime/plugins/librime-charcode
# ${RIME_ROOT}/librime/install-plugins.sh rime/librime-charcode
# 下面记得添加 rime_require_module_charcode()

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
' ${RIME_ROOT}/librime/src/rime_api.cc

# librime dependences build
if [[ ! -d ${RIME_ROOT}/.boost ]]
then
  mkdir ${RIME_ROOT}/.boost
  cp -R ${RIME_ROOT}/boost-iosx/dest ${RIME_ROOT}/.boost
fi
export BOOST_ROOT=$RIME_ROOT/.boost/dest
make xcode/ios/deps

# librime api header
rm -rf ${RIME_ROOT}/lib && mkdir -p ${RIME_ROOT}/lib ${RIME_ROOT}/lib/headers
cp ${RIME_ROOT}/librime/src/*.h ${RIME_ROOT}/lib/headers

# librime build

# PLATFORM value means
# OS64: to build for iOS (arm64 only)
# OS64COMBINED: to build for iOS & iOS Simulator (FAT lib) (arm64, x86_64)
# SIMULATOR64: to build for iOS simulator 64 bit (x86_64)
# SIMULATORARM64: to build for iOS simulator 64 bit (arm64)
# MAC: to build for macOS (x86_64)
export PLATFORM=SIMULATOR64

# librime build: iOS simulator 64 bit (x86_64)
rm -rf ${RIME_ROOT}/librime/build ${RIME_ROOT}/librime/dist
make xcode/ios/dist
cp -f ${RIME_ROOT}/librime/dist/lib/librime.a ${RIME_ROOT}/lib/librime_simulator_x86_64.a

# librime build: arm64
export PLATFORM=OS64
rm -rf ${RIME_ROOT}/librime/build ${RIME_ROOT}/librime/dist
make xcode/ios/dist
cp -f ${RIME_ROOT}/librime/dist/lib/librime.a ${RIME_ROOT}/lib/librime_arm64.a

# transform *.a to xcframework
rm -rf ${RIME_ROOT}/Frameworks/librime.xcframework
xcodebuild -create-xcframework \
 -library ${RIME_ROOT}/lib/librime_simulator_x86_64.a -headers ${RIME_ROOT}/lib/headers \
 -library ${RIME_ROOT}/lib/librime_arm64.a -headers ${RIME_ROOT}/lib/headers \
 -output ${RIME_ROOT}/Frameworks/librime.xcframework

# clean
rm -rf ${RIME_ROOT}/lib/librime*.a

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
