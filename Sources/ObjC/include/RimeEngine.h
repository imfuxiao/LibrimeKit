#import <Foundation/Foundation.h>

typedef uintptr_t IRimeSessionId;

typedef void (*IRimeNotificationHandler) (id contextObject,
                                          IRimeSessionId sessionId,
                                          NSString *messageType,
                                          NSString *messageValue);

@interface IRimeTraits: NSObject
// v0.9
@property NSString *sharedDataDir;
@property NSString *userDataDir;
@property NSString *distributionName;
@property NSString *distributionCodeName;
@property NSString *distributionVersion;
// v1.0
// 传递一个格式为 "rime.x "的C-string常量，其中'x'是你的应用程序的名称。添加前缀 "rime. "以确保旧的日志文件被自动清理。
@property NSString *appName;

// 初始化(initializing)前要加载的模块列表
@property NSArray *modules;
// v1.6
/*! Minimal level of logged messages.
 *  Value is passed to Glog library using FLAGS_minloglevel variable.
 *  0 = INFO (default), 1 = WARNING, 2 = ERROR, 3 = FATAL
 */
// 记录日志的最小级别。这个值是通过FLAGS_minloglevel变量传递给Glog库的。0 = INFO（默认），1 = WARNING，2 = ERROR，3 = FATAL。
@property int minLogLevel;

// 日志文件的目录。该值使用FLAGS_log_dir变量传递给Glog库。
@property NSString *logDir;

// 预先构建的数据目录中。默认为${shared_data_dir}/build
@property NSString *prebuiltDataDir;
// 暂存目录，默认为${user_data_dir}/build
@property NSString *stagingDir;

@end

@interface IRimeCommit : NSObject
- (NSString *) text;
@end

@interface IRimeContext : NSObject

@property NSString *preeditText;

@end

@interface IRimeStatus : NSObject

@property BOOL isAsciiMode;
@property BOOL isComposing;
@property BOOL isAsciiPunct;
@property BOOL isDisabled;
@property BOOL isFullShape;
@property BOOL isSimplified;
@property BOOL isTraditional;
@property NSString *schemaId;
@property NSString *schemaName;

- (void) print;

@end

@interface IRimeCandidateListIterator: NSObject

- (int) index;
- (NSString *) text;

@end


@interface IRimeSchemaList: NSObject
- (void) print;
@end

// 对 rimelib 的 notification 回调函数封装
@protocol IRimeNotificationDelegate

// message_type="deploy", message_value="start"
- (void) onDelployStart;

//  message_type="deploy", message_value="success"
- (void) onDeploySuccess;

// message_type="deploy", message_value="failure"
- (void) onDeployFailure;

// on changing mode
- (void) onChangeMode:(NSString *) mode;

// on loading schema
- (void) onLoadingSchema:(NSString *) schema;

@end


// RIME输入法引擎
// 使用OC对rime_api的c接口进行封装, 方便swift调用
@interface RimeEngine: NSObject

+ (RimeEngine *) sharedRimeEngine;

// Setup

// 在访问任何其他API之前调用这个函数。
- (void) setup:(IRimeTraits *) traits;

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
- (void) setNotificationHandler:(id<IRimeNotificationDelegate>) handler context:(id) ctx;

// Entry and exit

- (void) initialize:(IRimeTraits *) traits;
- (void) finalize;

- (BOOL) startMaintenance:(BOOL) fullCheck;
- (BOOL) isMaintenancing;
- (void) joinMaintenanceThread;


// Deployment

- (void) deployerInitialize:(IRimeTraits *) traits;
- (BOOL) prebuildAllSchemas;
- (BOOL) deployWorkspace;
- (BOOL) deploySchema:(NSString *) schemaFile;
- (BOOL) deployConfigFile:(NSString *) fileName versionKey:(NSString *) key;

- (BOOL) syncUserData;

// Session management

- (IRimeSessionId) createSession;
- (BOOL) findSession:(IRimeSessionId) session;
- (BOOL) destroySession:(IRimeSessionId) session;
- (void) cleanupStaleSessions;
- (void) cleanupAllSessions;

// Input

- (BOOL) processKey:(IRimeSessionId) session keycode:(int) code mask:(int) mask;
/*!
 * return True if there is unread commit text
 */
- (BOOL) commitComposition:(IRimeSessionId) session;
- (void) clearComposition:(IRimeSessionId) session;

// Output

- (NSString *) getInput:(IRimeSessionId) session;

- (IRimeCommit *) getCommit:(IRimeSessionId) session;
- (BOOL) freeCommit:(IRimeCommit *)commit;
- (IRimeContext *) getContext:(IRimeSessionId) sessionId;
- (BOOL) freeContext:(IRimeContext *) context;
- (IRimeStatus *) getStatus:(IRimeSessionId) sessionId;
- (BOOL) freeStatus:(IRimeStatus *) status;

// Accessing candidate list
- (IRimeCandidateListIterator *) candidateListBegin:(IRimeSessionId)sessionId;
- (BOOL) candidateListNext:(IRimeCandidateListIterator *) iterator;
- (void) candidateListEnd:(IRimeCandidateListIterator *) iterator;
- (IRimeCandidateListIterator *) candidateListFromIndex:(IRimeSessionId) sessionId index:(int) index;

// Runtime options

- (void) setOption:(IRimeSessionId) session option:(NSString *) option value:(BOOL) value;
- (BOOL) getOption:(IRimeSessionId) session option:(NSString *) option;

- (void) setProperty:(IRimeSessionId) session prop:(NSString *) prop value:(NSString *) value;
- (NSString *) getProperty:(IRimeSessionId) session prop:(NSString *) prop;

- (IRimeSchemaList *) getSchemaList;
- (void) freeSchemaList:(IRimeSchemaList *) list;
- (NSString *) getCurrentSchema:(IRimeSessionId) session;
- (BOOL) selectSchema:(IRimeSessionId) session schemeId:(NSString *) schema;

// Configuration

// <schema_id>.schema.yaml
//- (BOOL) schemaOpen:(NSString *) schemaId config:(struct IRimeConfig *) config;
//// <config_id>.yaml
//- (BOOL) configOpen:(NSString *) configId config:(struct IRimeConfig *) config;
//// access config files in user data directory, eg. user.yaml and installation.yaml
//- (BOOL) userConfigOpen:(NSString *) configId config:(struct IRimeConfig *) config;
//- (BOOL) configClose:(struct IRimeConfig *) config;
//- (BOOL) configInit:(struct IRimeConfig *) config;
//- (BOOL) configLoadString:(struct IRimeConfig *) config yaml:(NSString *) yaml;
//// Access config values
//- (BOOL) configGetBool:(struct IRimeConfig *) config key:(NSString *) key value:(BOOL *) value;
//- (BOOL) configGetInt:(struct IRimeConfig *) config key:(NSString *) key value:(int *) value;
//- (BOOL) configGetDouble:(struct IRimeConfig *) config key:(NSString *) key value:(double *) value;
//- (BOOL) configGetString:(struct IRimeConfig *) config key:(NSString *) key value:(NSString *) value;
//- (NSString *) configGetCString:(struct IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configSetBool:(struct IRimeConfig *) config key:(NSString *) key value:(BOOL) value;
//- (BOOL) configSetInt:(struct IRimeConfig *) config key:(NSString *) key value:(int) value;
//- (BOOL) configSetDouble:(struct IRimeConfig *) config key:(NSString *) key value:(double) value;
//- (BOOL) configSetString:(struct IRimeConfig *) config key:(NSString *) key value:(NSString *) value;
//// Manipulate complex structures
//- (BOOL) configGetItem:(struct IRimeConfig *) config key:(NSString *) key value:(struct IRimeConfig *) value;
//- (BOOL) configSetItem:(struct IRimeConfig *) config key:(NSString *) key value:(struct IRimeConfig *) value;
//- (BOOL) configClear:(struct IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configCreateList:(struct IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configCreateMap:(struct IRimeConfig *) config key:(NSString *) key;
//- (int) configListSize:(struct IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configBeginList:(struct IRimeConfigIterator *)iterator config:(struct IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configBeginMap:(struct IRimeConfigIterator *)iterator config:(struct IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configNext:(struct IRimeConfigIterator *) iterator;
//- (void) configEnd:(struct IRimeConfigIterator *) iterator;
//// Utilities
//- (BOOL) configUpdateSignature:(struct IRimeConfig *) config signer:(NSString *) signer;

// Testing

- (BOOL) simulateKeySequence:(IRimeSessionId) session keySequence:(NSString *) sequence;

// Module

/*!
 扩展结构，在你的特定模块中发布自定义数据/功能
 */

//- (BOOL) registerModule:(struct IRimeModule *) module;
//- (struct IRimeModule *) findModule:(NSString *) moduleName;

//! Run a registered task
//- (BOOL) runTask:(NSString *) task_name;

- (NSString *) getSharedDataDir;
- (NSString *) getUserDataDir;
- (NSString *) getSyncDir;
- (NSString *) getUserId;

@end


