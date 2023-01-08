#import <Foundation/Foundation.h>
/**
 用来封装 rime_api.h 中的RimeSessionId
 */
typedef uintptr_t IRimeSessionId;

/**
 封装 rime_api.h 结构 rime_traits_t
 
 Should be initialized by calling RIME_STRUCT_INIT(Type, var)
 */
@interface IRimeTraits : NSObject {
  NSString *sharedDataDir;
  NSString *userDataDir;
  NSString *distributionName;
  NSString *distributionCodeName;
  NSString *distributionVersion;
  
  // 传递一个格式为 "rime.x
  // "的C-string常量，其中'x'是你的应用程序的名称。添加前缀 "rime.
  // "以确保旧的日志文件被自动清理。
  NSString *appName;
  // 初始化(initializing)前要加载的模块列表
  NSArray<NSString *> *modules;
  // v1.6
  /*! Minimal level of logged messages.
   *  Value is passed to Glog library using FLAGS_minloglevel variable.
   *  0 = INFO (default), 1 = WARNING, 2 = ERROR, 3 = FATAL
   */
  // 记录日志的最小级别。这个值是通过FLAGS_minloglevel变量传递给Glog库的。0 =
  // INFO（默认），1 = WARNING，2 = ERROR，3 = FATAL。
  int minLogLevel;
  // 日志文件的目录。该值使用FLAGS_log_dir变量传递给Glog库。
  NSString *logDir;
  // 预先构建的数据目录中。默认为${shared_data_dir}/build
  NSString *prebuiltDataDir;
  // 暂存目录，默认为${user_data_dir}/build
  NSString *stagingDir;
}

@property NSString *sharedDataDir;
@property NSString *userDataDir;
@property NSString *distributionName;
@property NSString *distributionCodeName;
@property NSString *distributionVersion;
@property NSString *appName;
@property NSArray<NSString *> *modules;
@property int minLogLevel;
@property NSString *logDir;
@property NSString *prebuiltDataDir;
@property NSString *stagingDir;

@end

/**
 封装 rime_api.h 结构 RimeComposition
 */
@interface IRimeComposition : NSObject

- (int)length;
- (int)cursorPos;
- (int)selStart;
- (int)selEnd;
- (NSString *)preedit;

@end

/**
 封装 rime_api.h 结构 rime_candidate_t
 */
@interface IRimeCandidate : NSObject

- (NSString *)text;
- (NSString *)comment;
- (NSString *)reserved;

@end

/**
 封装 rime_api.h 结构 RimeMenu
 */
@interface IRimeMenu : NSObject

- (int)pageSize;
- (int)pageNo;
- (BOOL)isLastPage;
- (int)highlightedCandidateIndex;
- (int)numCandidates;
- (NSArray<IRimeCandidate *> *)candidates;
- (NSString *)selectKeys;

@end

/**
 封装 rime_api.h 结构 rime_commit_t
 Should be initialized by calling RIME_STRUCT_INIT(Type, var);
 */
@interface IRimeCommit : NSObject

- (int)dataSize;
- (NSString *)text;

@end

/**
 封装 rime_api.h 结构 rime_context_t
 */
@interface IRimeContext : NSObject

- (int)dataSize;
- (IRimeComposition *)composition;
- (IRimeMenu *)menu;
- (NSString *)commitTextPreview;
- (NSArray<NSString *> *)selectLabels;

@end

/**
 封装 rime_api.h 结构 rime_status_t
 
 Should be initialized by calling RIME_STRUCT_INIT(Type, var);
 */
@interface IRimeStatus : NSObject

- (int)dataSize;
- (NSString *)schemaId;
- (NSString *)schemaName;
- (BOOL)isDisabled;
- (BOOL)isComposing;
- (BOOL)isAsciiMode;
- (BOOL)isFullShape;
- (BOOL)isSimplified;
- (BOOL)isTraditional;
- (BOOL)isAsciiPunct;

- (void)print;

@end

/**
 封装 rime_api 结构 RimeCandidateListIterator
 */
@interface IRimeCandidateListIterator : NSObject

// void *ptr to Objective-C
// void func(void *q)
//{
//  NSObject* o = CFBridgingRelease(q);
//  NSLog(@"%@", o);
//}
//
// int main(int argc, const char * argv[])
//{
//  @autoreleasepool {
//    NSObject* o = [NSObject new];
//    func((void*)CFBridgingRetain(o));
//  }
//  return 0;
//}
- (int)index;
- (IRimeCandidate *)candidate;

@end

/**
 封装 rime_api.h 结构 RimeConfig
 */
@interface IRimeConfig : NSObject

// 参考 IRimeCandidateListIterator.ptr
- (id)ptr;

@end

/**
 封装 rime_api.h 结构 RimeConfigIterator
 */
@interface IRimeConfigIterator : NSObject

- (NSObject *)list;
- (NSObject *)map;
- (int)index;
- (NSString *)key;
- (NSString *)path;

@end

/**
 封装 rime_api.h 结构 RimeSchemaListItem
 */
@interface IRimeSchemaListItem : NSObject

- (NSString *)schemaId;
- (NSString *)name;
- (NSObject *)reserved;

@end

/**
 封装 rime_api.h 结构 RimeSchemaList
 */
@interface IRimeSchemaList : NSObject

- (NSArray<IRimeSchemaListItem *> *)list;

@end

/**
 对 rime_api.h 的 notification 回调函数封装
 */
@protocol IRimeNotificationDelegate

// message_type="deploy", message_value="start"
- (void)onDelployStart;

//  message_type="deploy", message_value="success"
- (void)onDeploySuccess;

// message_type="deploy", message_value="failure"
- (void)onDeployFailure;

// on changing mode
- (void)onChangeMode:(NSString *)mode;

// on loading schema
- (void)onLoadingSchema:(NSString *)schema;

@end

// Module

/**
 *  Extend the structure to publish custom data/functions in your specific
 * module 扩展结构，在你的特定模块中发布自定义数据/功能
 */

/**
 封装 rime_api.h 结构 RimeCustomApi
 */
@interface IRimeCustomApi : NSObject

- (int)dataSize;

@end

/**
 封装 rime_api.h 结构  RimeModule
 */
@interface IRimeModule : NSObject

- (NSString *)moduleName;
- (void)initialize;
- (void)finalize;
- (IRimeCustomApi *)getApi;

@end

/**
 RIME输入法引擎
 使用OC对rime_api的c接口进行封装, 方便swift调用
 */
@interface IRimeAPI : NSObject

/** setup
 *  Call this function before accessing any other API functions.
 */
- (void)setup:(IRimeTraits *)traits;

//! Receive notifications
/*!
 * - on loading schema:
 *   + message_type="schema", message_value="luna_pinyin/Luna Pinyin"
 * - on changing mode:
 *   + message_type="option", message_value="ascii_mode"
 *   + message_type="option", message_value="!ascii_mode"
 * - on deployment:
 *   + session_id = 0, message_type="deploy", message_value="start"
 *   + session_id = 0, message_type="deploy", message_value="success"
 *   + session_id = 0, message_type="deploy", message_value="failure"
 *
 *   handler will be called with context_object as the first parameter
 *   every time an event occurs in librime, until RimeFinalize() is called.
 *   when handler is NULL, notification is disabled.
 */
- (void)setNotificationHandler:(id<IRimeNotificationDelegate>)handler
                       context:(id)ctx;

// Entry and exit

- (void)initialize:(IRimeTraits *)traits;
- (void)finalize;

- (BOOL)startMaintenance:(BOOL)fullCheck;
- (BOOL)isMaintenancing;
- (void)joinMaintenanceThread;

// Deployment

- (void)deployerInitialize:(IRimeTraits *)traits;
- (BOOL)prebuildAllSchemas;
- (BOOL)deployWorkspace;
- (BOOL)deploySchema:(NSString *)schemaFile;
- (BOOL)deployConfigFile:(NSString *)fileName versionKey:(NSString *)key;

- (BOOL)syncUserData;

// Session management

- (IRimeSessionId)createSession;
- (BOOL)findSession:(IRimeSessionId)session;
- (BOOL)destroySession:(IRimeSessionId)session;
- (void)cleanupStaleSessions;
- (void)cleanupAllSessions;

// Input

- (BOOL)processKey:(IRimeSessionId)session keycode:(int)code mask:(int)mask;
// return True if there is unread commit text
- (BOOL)commitComposition:(IRimeSessionId)session;
- (void)clearComposition:(IRimeSessionId)session;

// Output

- (IRimeCommit *)getCommit:(IRimeSessionId)session;
- (BOOL)freeCommit:(IRimeCommit *)commit;
- (IRimeContext *)getContext:(IRimeSessionId)sessionId;
- (BOOL)freeContext:(IRimeContext *)context;
- (IRimeStatus *)getStatus:(IRimeSessionId)sessionId;
- (BOOL)freeStatus:(IRimeStatus *)status;

// Accessing candidate list

- (IRimeCandidateListIterator *)candidateListBegin:(IRimeSessionId)sessionId;
- (BOOL)candidateListNext:(IRimeCandidateListIterator *)iterator;
- (void)candidateListEnd:(IRimeCandidateListIterator *)iterator;
- (IRimeCandidateListIterator *)candidateListFromIndex:(IRimeSessionId)sessionId
                                                 index:(int)index;

// Runtime options

- (void)setOption:(IRimeSessionId)session
           option:(NSString *)option
            value:(BOOL)value;
- (NSString *)getOption:(IRimeSessionId)session;

- (void)setProperty:(IRimeSessionId)session
               prop:(NSString *)prop
              value:(NSString *)value;
- (NSString *)getProperty:(IRimeSessionId)session prop:(NSString *)prop;

- (IRimeSchemaList *)getSchemaList;
- (void)freeSchemaList:(IRimeSchemaList *)list;

- (NSString *)getCurrentSchema:(IRimeSessionId)session;
- (BOOL)selectSchema:(IRimeSessionId)session schemeId:(NSString *)schema;

// Configuration

// <schema_id>.schema.yaml
- (BOOL)schemaOpen:(NSString *)scheme rimeConfig:(IRimeConfig *)config;
// <config_id>.yaml
- (BOOL)configOpen:(NSString *)config rimeConfig:(IRimeConfig *)config;
// access config files in user data directory, eg. user.yaml and
// installation.yaml
- (BOOL)userConfigOpen:(NSString *)config rimeConfig:(IRimeConfig *)config;
- (BOOL)configClose:(IRimeConfig *)config;
- (BOOL)configInit:(IRimeConfig *)config;
- (BOOL)configLoadString:(IRimeConfig *)config yamlName:(NSString *)name;
// Access config values
- (BOOL)configGetBool:(IRimeConfig *)config
                  key:(NSString *)key
                value:(BOOL *)value;
- (BOOL)configGetInt:(IRimeConfig *)config
                 key:(NSString *)key
               value:(int *)value;
- (BOOL)configGetDouble:(IRimeConfig *)config
                    key:(NSString *)key
                  value:(double *)value;
- (NSString *)configGetString:(IRimeConfig *)config key:(NSString *)key;
- (BOOL)configSetBool:(IRimeConfig *)config
                  key:(NSString *)key
                value:(BOOL)value;
- (BOOL)configSetInt:(IRimeConfig *)config key:(NSString *)key value:(int)value;
- (BOOL)configSetDouble:(IRimeConfig *)config
                    key:(NSString *)key
                  value:(double)value;
- (BOOL)configSetString:(IRimeConfig *)config
                    key:(NSString *)key
                  value:(NSString *)value;
// Manipulate complex structures
- (BOOL)configGetItem:(IRimeConfig *)config
                  key:(NSString *)key
                value:(IRimeConfig *)value;
- (BOOL)configSetItem:(IRimeConfig *)config
                  key:(NSString *)key
                value:(IRimeConfig *)value;
- (BOOL)configClear:(IRimeConfig *)config key:(NSString *)key;
- (BOOL)configCreateList:(IRimeConfig *)config key:(NSString *)key;
- (BOOL)configCreateMap:(IRimeConfig *)config key:(NSString *)key;
- (int)configListSize:(IRimeConfig *)config key:(NSString *)key;
- (BOOL)configBeginList:(IRimeConfigIterator *)iterator
                 config:(IRimeConfig *)config
                    key:(NSString *)key;
- (BOOL)configBeginMap:(IRimeConfigIterator *)iterator
                config:(IRimeConfig *)config
                   key:(NSString *)key;
- (BOOL)configNext:(IRimeConfigIterator *)iterator;
- (void)configEnd:(IRimeConfigIterator *)iterator;
// Utilities
- (BOOL)configUpdateSignature:(IRimeConfig *)config signer:(NSString *)signer;

// Testing

- (BOOL)simulateKeySequence:(IRimeSessionId)session
                keySequence:(NSString *)sequence;

// Module

- (BOOL)registerModule:(IRimeModule *)module;
- (IRimeModule *)findModule:(NSString *)name;

// Run a registered task
- (BOOL)runTask:(NSString *)name;

- (NSString *)getSharedDataDir;
- (NSString *)getUserDataDir;
- (NSString *)getSyncDir;
- (NSString *)getUserId;

//! get raw input
/*!
 *  NULL is returned if session does not exist.
 *  the returned pointer to input string will become invalid upon editing.
 */
- (NSString *)getInput:(IRimeSessionId)session;

//! caret posistion in terms of raw input
- (size_t)getCaretPos:(IRimeSessionId)session;

//! select a candidate at the given index in candidate list.
- (BOOL)selectCandidate:(IRimeSessionId)session index:(size_t)index;

//! get the version of librime
- (NSString *)getVersion;

//! set caret posistion in terms of raw input
- (void)setCaretPos:(IRimeSessionId)session caretPos:(size_t)pos;

//! select a candidate from current page.
- (BOOL)selectCandidateOnCurrentPage:(IRimeSessionId)session
                               index:(size_t)index;

//! prebuilt data directory.
- (NSString *)getPrebuiltDataDir;

//! staging directory, stores data files deployed to a Rime client.
- (NSString *)get_staging_dir;

- (NSString *)get_state_label:(IRimeSessionId)session_id
                  option_name:(NSString *)name
                        state:(BOOL)state;

//! delete a candidate at the given index in candidate list.
- (BOOL)delete_candidate:(IRimeSessionId)session_id index:(size_t)index;
//! delete a candidate from current page.
- (BOOL)delete_candidate_on_current_page:(IRimeSessionId)session_id
                                   index:(size_t)index;

@end
