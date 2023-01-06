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
${RIME_ROOT}/librime/install-plugins.sh hchunhui/librime-lua
cd ${RIME_ROOT}/librime/plugins/lua
git apply ${RIME_ROOT}/lua_plugin.patch >/dev/null 2>&1
git clone https://github.com/hchunhui/librime-lua.git -b thirdparty --depth=1 thirdparty
cd ${RIME_ROOT}/librime/plugins/lua/thirdparty/lua5.4
git apply ${RIME_ROOT}/lua.patch >/dev/null 2>&1
cd ${RIME_ROOT}/librime


# librime dependences build
export BOOST_ROOT=$RIME_ROOT/boost-iosx/dest
make xcode/ios/deps

# PLATFORM value means
# OS64: to build for iOS (arm64 only)
# OS64COMBINED: to build for iOS & iOS Simulator (FAT lib) (arm64, x86_64)
# SIMULATOR64: to build for iOS simulator 64 bit (x86_64)
# SIMULATORARM64: to build for iOS simulator 64 bit (arm64)
# MAC: to build for macOS (x86_64)
export PLATFORM=SIMULATOR64

# temp save *.a
rm -rf ${RIME_ROOT}/lib && mkdir -p ${RIME_ROOT}/lib ${RIME_ROOT}/lib/headers
cp ${RIME_ROOT}/librime/src/*.h ${RIME_ROOT}/lib/headers

# librime build: iOS simulator 64 bit (x86_64)
rm -rf ${RIME_ROOT}/librime/build ${RIME_ROOT}/librime/dist
make xcode/ios/dist
cp -f ${RIME_ROOT}/librime/dist/lib/librime.a ${RIME_ROOT}/lib/librime_simulator_x86_64.a
# cp -f ${RIME_ROOT}/librime/build/plugins/lua/rime.build/Release/rime-lua-objs.build/librime-lua-objs.a ${RIME_ROOT}/lib/librime_lua_x86_64.a

# librime build: arm64
export PLATFORM=OS64
rm -rf ${RIME_ROOT}/librime/build ${RIME_ROOT}/librime/dist
make xcode/ios/dist
cp -f ${RIME_ROOT}/librime/dist/lib/librime.a ${RIME_ROOT}/lib/librime_arm64.a
# cp -f ${RIME_ROOT}/librime/build/plugins/lua/rime.build/Release/rime-lua-objs.build/librime-lua-objs.a ${RIME_ROOT}/lib/librime_lua_arm64.a

# transform *.a to xcframework
rm -rf ${RIME_ROOT}/Frameworks/librime.xcframework
xcodebuild -create-xcframework \
 -library ${RIME_ROOT}/lib/librime_simulator_x86_64.a -headers ${RIME_ROOT}/lib/headers \
 -library ${RIME_ROOT}/lib/librime_arm64.a -headers ${RIME_ROOT}/lib/headers \
 -output ${RIME_ROOT}/Frameworks/librime.xcframework

# rm -rf ${RIME_ROOT}/Frameworks/librime-lua.xcframework
# xcodebuild -create-xcframework \
#  -library ${RIME_ROOT}/lib/librime_lua_x86_64.a \
#  -library ${RIME_ROOT}/lib/librime_lua_arm64.a \
#  -output ${RIME_ROOT}/Frameworks/librime-lua.xcframework

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
