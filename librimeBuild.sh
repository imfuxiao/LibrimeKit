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
# TODO: 这里是临时解决方案. 非librime官方方法.
# 可能是个人能力问题, 使用官方的方法始终无法加载lua模块. 临时使用此方法. 希望以后可以解决这个问题.
# 注意: 改写代码后发现 gear 模块也无法加载. 所以代码中同时将gear模块添加进去.
rm -rf ${RIME_ROOT}/librime/plugins/lua
${RIME_ROOT}/librime/install-plugins.sh imfuxiao/librime-lua@main
rm -rf ${RIME_ROOT}/librime/src/rime/lua && \
  mkdir ${RIME_ROOT}/librime/src/rime/lua && \
  cp -R ${RIME_ROOT}/librime/plugins/lua/src/* ${RIME_ROOT}/librime/src/rime/lua && \
  rm -rf ${RIME_ROOT}/librime/plugins/lua
  
# TODO: begin 改写文件内容
cat << "MODULE" | tee ${RIME_ROOT}/librime/src/rime/core_module.cc

//
// Copyright RIME Developers
// Distributed under the BSD License
//
// 2013-10-17 GONG Chen <chen.sst@gmail.com>
//

#include <rime_api.h>
#include <rime/common.h>
#include <rime/registry.h>

// built-in components
#include <rime/config.h>
#include <rime/config/plugins.h>
#include <rime/schema.h>

#include <cstdio>
#include "lua/lib/lua_templates.h"
#include "lua/lua_gears.h"

#include <rime/gear/abc_segmentor.h>
#include <rime/gear/affix_segmentor.h>
#include <rime/gear/ascii_composer.h>
#include <rime/gear/ascii_segmentor.h>
#include <rime/gear/charset_filter.h>
#include <rime/gear/chord_composer.h>
#include <rime/gear/echo_translator.h>
#include <rime/gear/editor.h>
#include <rime/gear/fallback_segmentor.h>
#include <rime/gear/history_translator.h>
#include <rime/gear/key_binder.h>
#include <rime/gear/matcher.h>
#include <rime/gear/navigator.h>
#include <rime/gear/punctuator.h>
#include <rime/gear/recognizer.h>
#include <rime/gear/reverse_lookup_filter.h>
#include <rime/gear/reverse_lookup_translator.h>
#include <rime/gear/schema_list_translator.h>
#include <rime/gear/script_translator.h>
#include <rime/gear/selector.h>
#include <rime/gear/shape.h>
#include <rime/gear/simplifier.h>
#include <rime/gear/single_char_filter.h>
#include <rime/gear/speller.h>
#include <rime/gear/switch_translator.h>
#include <rime/gear/table_translator.h>
#include <rime/gear/uniquifier.h>

void types_init(lua_State *L);

static bool file_exists(const char *fname) noexcept {
  FILE * const fp = fopen(fname, "r");
  if (fp) {
    fclose(fp);
    return true;
  }
  return false;
}


static void lua_init(lua_State *L) {
  const auto user_dir = std::string(RimeGetUserDataDir());
  const auto shared_dir = std::string(RimeGetSharedDataDir());

  types_init(L);
  lua_getglobal(L, "package");
  lua_pushfstring(L, "%s%slua%s?.lua;"
                     "%s%slua%s?%sinit.lua;"
                     "%s%slua%s?.lua;"
                     "%s%slua%s?%sinit.lua;",
                  user_dir.c_str(), LUA_DIRSEP, LUA_DIRSEP,
                  user_dir.c_str(), LUA_DIRSEP, LUA_DIRSEP, LUA_DIRSEP,
                  shared_dir.c_str(), LUA_DIRSEP, LUA_DIRSEP,
                  shared_dir.c_str(), LUA_DIRSEP, LUA_DIRSEP, LUA_DIRSEP);
  lua_getfield(L, -2, "path");
  lua_concat(L, 2);
  lua_setfield(L, -2, "path");
  lua_pop(L, 1);

  const auto user_file = user_dir + LUA_DIRSEP "rime.lua";
  const auto shared_file = shared_dir + LUA_DIRSEP "rime.lua";

  // use the user_file first
  // use the shared_file if the user_file doesn't exist
  if (file_exists(user_file.c_str())) {
    if (luaL_dofile(L, user_file.c_str())) {
      const char *e = lua_tostring(L, -1);
      LOG(ERROR) << "rime.lua error: " << e;
      lua_pop(L, 1);
    }
  } else if (file_exists(shared_file.c_str())) {
    if (luaL_dofile(L, shared_file.c_str())) {
      const char *e = lua_tostring(L, -1);
      LOG(ERROR) << "rime.lua error: " << e;
      lua_pop(L, 1);
    }
  } else {
    LOG(INFO) << "rime.lua info: rime.lua should be either in the "
                 "rime user data directory or in the rime shared "
                 "data directory";
  }
}

using namespace rime;
static void rime_core_initialize() {
  LOG(INFO) << "registering core components.";
  Registry& r = Registry::instance();

  auto config_builder = new ConfigComponent<ConfigBuilder>(
      [&](ConfigBuilder* builder) {
        builder->InstallPlugin(new AutoPatchConfigPlugin);
        builder->InstallPlugin(new DefaultConfigPlugin);
        builder->InstallPlugin(new LegacyPresetConfigPlugin);
        builder->InstallPlugin(new LegacyDictionaryConfigPlugin);
        builder->InstallPlugin(new BuildInfoPlugin);
        builder->InstallPlugin(new SaveOutputPlugin);
      });
  r.Register("config_builder", config_builder);

  auto config_loader =
      new ConfigComponent<ConfigLoader, DeployedConfigResourceProvider>;
  r.Register("config", config_loader);
  r.Register("schema", new SchemaComponent(config_loader));

  auto user_config =
      new ConfigComponent<ConfigLoader, UserConfigResourceProvider>(
          [](ConfigLoader* loader) {
            loader->set_auto_save(true);
          });
  r.Register("user_config", user_config);

  LOG(INFO) << "registering components from module 'gears'.";

  // processors
  r.Register("ascii_composer", new Component<AsciiComposer>);
  r.Register("chord_composer", new Component<ChordComposer>);
  r.Register("express_editor", new Component<ExpressEditor>);
  r.Register("fluid_editor", new Component<FluidEditor>);
  r.Register("fluency_editor", new Component<FluidEditor>);  // alias
  r.Register("key_binder", new Component<KeyBinder>);
  r.Register("navigator", new Component<Navigator>);
  r.Register("punctuator", new Component<Punctuator>);
  r.Register("recognizer", new Component<Recognizer>);
  r.Register("selector", new Component<Selector>);
  r.Register("speller", new Component<Speller>);
  r.Register("shape_processor", new Component<ShapeProcessor>);

  // segmentors
  r.Register("abc_segmentor", new Component<AbcSegmentor>);
  r.Register("affix_segmentor", new Component<AffixSegmentor>);
  r.Register("ascii_segmentor", new Component<AsciiSegmentor>);
  r.Register("matcher", new Component<Matcher>);
  r.Register("punct_segmentor", new Component<PunctSegmentor>);
  r.Register("fallback_segmentor", new Component<FallbackSegmentor>);

  // translators
  r.Register("echo_translator", new Component<EchoTranslator>);
  r.Register("punct_translator", new Component<PunctTranslator>);
  r.Register("table_translator", new Component<TableTranslator>);
  r.Register("script_translator", new Component<ScriptTranslator>);
  r.Register("r10n_translator", new Component<ScriptTranslator>);  // alias
  r.Register("reverse_lookup_translator",
             new Component<ReverseLookupTranslator>);
  r.Register("schema_list_translator", new Component<SchemaListTranslator>);
  r.Register("switch_translator", new Component<SwitchTranslator>);
  r.Register("history_translator", new Component<HistoryTranslator>);

  // filters
  r.Register("simplifier", new Component<Simplifier>);
  r.Register("uniquifier", new Component<Uniquifier>);
  if (!r.Find("charset_filter")) {  // allow improved implementation
    r.Register("charset_filter", new Component<CharsetFilter>);
  }
  r.Register("cjk_minifier", new Component<CharsetFilter>);  // alias
  r.Register("reverse_lookup_filter", new Component<ReverseLookupFilter>);
  r.Register("single_char_filter", new Component<SingleCharFilter>);

  // formatters
  r.Register("shape_formatter", new Component<ShapeFormatter>);

  LOG(INFO) << "registering components from module 'lua'.";

  an<Lua> lua(new Lua);
  lua->to_state(lua_init);

  r.Register("lua_translator", new LuaComponent<LuaTranslator>(lua));
  r.Register("lua_filter", new LuaComponent<LuaFilter>(lua));
  r.Register("lua_segmentor", new LuaComponent<LuaSegmentor>(lua));
  r.Register("lua_processor", new LuaComponent<LuaProcessor>(lua));
}

static void rime_core_finalize() {
  // registered components have been automatically destroyed prior to this call
}

RIME_REGISTER_MODULE(core)


MODULE


cat << "MODULE" | tee ${RIME_ROOT}/librime/src/CMakeLists.txt
set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)

aux_source_directory(. rime_api_src)
aux_source_directory(rime rime_base_src)
aux_source_directory(rime/algo rime_algo_src)
aux_source_directory(rime/config rime_config_src)
aux_source_directory(rime/dict rime_dict_src)
aux_source_directory(rime/gear rime_gears_src)
aux_source_directory(rime/lever rime_levers_src)
aux_source_directory(rime/lua rime_lua_src)
aux_source_directory(rime/lua/lib rime_lua_lib_src)
aux_source_directory(rime/lua/lib/lua rime_lua_lib_lua_src)
if(rime_plugins_library)
  aux_source_directory(../plugins rime_plugins_src)
endif()

set(rime_core_module_src
  ${rime_api_src}
  ${rime_base_src}
  ${rime_config_src}
  ${rime_lua_src}
  ${rime_lua_lib_src}
  ${rime_lua_lib_lua_src}
)
set(rime_dict_module_src
  ${rime_algo_src}
  ${rime_dict_src})

if(BUILD_SHARED_LIBS AND BUILD_SEPARATE_LIBS)
  set(rime_src ${rime_core_module_src})
else()
  set(rime_src
      ${rime_core_module_src}
      ${rime_dict_module_src}
      ${rime_gears_src}
      ${rime_levers_src}
      ${rime_plugins_src}
      ${rime_plugins_objs})
endif()

set(rime_optional_deps "")
if(Gflags_FOUND)
  set(rime_optional_deps ${rime_optional_deps} ${Gflags_LIBRARY})
endif()
if(ENABLE_EXTERNAL_PLUGINS)
  set(rime_optional_deps ${rime_optional_deps} dl)
endif()

set(rime_core_deps
    ${Boost_LIBRARIES}
    ${Glog_LIBRARY}
    ${YamlCpp_LIBRARY}
    ${CMAKE_THREAD_LIBS_INIT}
    ${rime_optional_deps})
set(rime_dict_deps
    ${LevelDb_LIBRARY}
    ${Marisa_LIBRARY})
set(rime_gears_deps
    ${ICONV_LIBRARIES}
    ${ICU_LIBRARIES}
    ${Opencc_LIBRARY})
set(rime_levers_deps "")

if(MINGW)
  set(rime_core_deps ${rime_core_deps} wsock32 ws2_32)
endif()

if(BUILD_SEPARATE_LIBS)
  set(rime_deps ${rime_core_deps})
else()
  set(rime_deps
    ${rime_core_deps}
    ${rime_dict_deps}
    ${rime_gears_deps}
    ${rime_levers_deps}
    ${rime_plugins_deps})
endif()


if(BUILD_SHARED_LIBS)
  add_library(rime ${rime_src})
  target_link_libraries(rime ${rime_deps})
  set_target_properties(rime PROPERTIES
    DEFINE_SYMBOL "RIME_EXPORTS"
    VERSION ${rime_version}
    SOVERSION ${rime_soversion})

  if(XCODE_VERSION)
    set_target_properties(rime PROPERTIES INSTALL_NAME_DIR "@rpath")
  endif()

  if(${CMAKE_SYSTEM_NAME} MATCHES "iOS")
    set(RIME_BUNDLE_IDENTIFIER "")
    set(RIME_BUNDLE_IDENTIFIER ${RIME_BUNDLE_IDENTIFIER})

    if (DEFINED RIME_BUNDLE_IDENTIFIER)
      message (STATUS "Using RIME_BUNDLE_IDENTIFIER: ${RIME_BUNDLE_IDENTIFIER}")
      set_xcode_property (rime PRODUCT_BUNDLE_IDENTIFIER ${RIME_BUNDLE_IDENTIFIER} All)
    else()
      message (STATUS "No RIME_BUNDLE_IDENTIFIER - with -DRIME_BUNDLE_IDENTIFIER=<rime bundle identifier>")
    endif()

    if (NOT DEFINED DEVELOPMENT_TEAM)
      message (STATUS "No DEVELOPMENT_TEAM specified - if code signing for running on an iOS devicde is required, pass a valid development team id with -DDEVELOPMENT_TEAM=<YOUR_APPLE_DEVELOPER_TEAM_ID>")
      set(CODESIGN_EMBEDDED_FRAMEWORKS 0)
    else()
      message (STATUS "Using DEVELOPMENT_TEAM: ${DEVELOPMENT_TEAM}")
      set(CODESIGN_EMBEDDED_FRAMEWORKS 1)
      set_xcode_property (rime DEVELOPMENT_TEAM ${DEVELOPMENT_TEAM} All)
    endif()
  endif()


  install(TARGETS rime DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})

  if(BUILD_SEPARATE_LIBS)
    add_library(rime-dict ${rime_dict_module_src})
    target_link_libraries(rime-dict
      ${rime_dict_deps}
      ${rime_library})
    set_target_properties(rime-dict PROPERTIES
      VERSION ${rime_version}
      SOVERSION ${rime_soversion})
    if(XCODE_VERSION)
      set_target_properties(rime-dict PROPERTIES INSTALL_NAME_DIR "@rpath")
    endif()
    install(TARGETS rime-dict DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})

    add_library(rime-gears ${rime_gears_src})
    target_link_libraries(rime-gears
      ${rime_gears_deps}
      ${rime_library}
      ${rime_dict_library})
    set_target_properties(rime-gears PROPERTIES
      VERSION ${rime_version}
      SOVERSION ${rime_soversion})
    if(XCODE_VERSION)
      set_target_properties(rime-gears PROPERTIES INSTALL_NAME_DIR "@rpath")
    endif()
    install(TARGETS rime-gears DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})

    add_library(rime-levers ${rime_levers_src})
    target_link_libraries(rime-levers
      ${rime_levers_deps}
      ${rime_library}
      ${rime_dict_library})
    set_target_properties(rime-levers PROPERTIES
      VERSION ${rime_version}
      SOVERSION ${rime_soversion})
    if(XCODE_VERSION)
      set_target_properties(rime-levers PROPERTIES INSTALL_NAME_DIR "@rpath")
    endif()
    install(TARGETS rime-levers DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})

    if(rime_plugins_library)
      add_library(rime-plugins
        ${rime_plugins_src}
        ${rime_plugins_objs})
      target_link_libraries(rime-plugins
        ${rime_plugins_deps}
        ${rime_library}
        ${rime_dict_library}
        ${rime_gears_library})
      set_target_properties(rime-plugins PROPERTIES
        VERSION ${rime_version}
        SOVERSION ${rime_soversion})
      if(XCODE_VERSION)
        set_target_properties(rime-plugins PROPERTIES INSTALL_NAME_DIR "@rpath")
      endif()
      install(TARGETS rime-plugins DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})
    endif()
  endif()
else()
  add_library(rime-static STATIC ${rime_src})
  target_link_libraries(rime-static ${rime_deps})
  set_target_properties(rime-static PROPERTIES OUTPUT_NAME "rime" PREFIX "lib")
  install(TARGETS rime-static DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})
endif()

MODULE

# TODO: end 改写文件内容



# librime dependences build
if [[ ! -d ${RIME_ROOT}/.boost ]]
then
  mkdir ${RIME_ROOT}/.boost
  cp -R ${RIME_ROOT}/boost-iosx/dest ${RIME_ROOT}/.boost
fi
export BOOST_ROOT=$RIME_ROOT/.boost/dest
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
