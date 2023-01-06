#import <Foundation/Foundation.h>
#import "rime_api.h"
#import "RimeEngine.h"

@implementation IRimeTraits

@end

// RimeCommit Wrapper
@implementation IRimeCommit
{
  RimeCommit rimeCommit;
}

+ (IRimeCommit *) rimeCommit:(RimeCommit) rimeCommit
{
  IRimeCommit *c = [[IRimeCommit alloc] init];
  [c setRimeCommit: rimeCommit];
  return c;
}

- (void) setRimeCommit:(RimeCommit) commit
{
  rimeCommit = commit;
}
- (RimeCommit *) rimeCommit
{
  return &rimeCommit;
}

- (NSString *) text
{
  NSString *text = [NSString stringWithUTF8String: rimeCommit.text];
  return text;
}

@end

// RimeContext Wrapper
@implementation IRimeContext
{
  RimeContext rimeContext;
}

+ (IRimeContext *) rimeContext:(RimeContext) rimeContext
{
  IRimeContext *ctx = [[IRimeContext alloc] init];
  [ctx setRimeContext: rimeContext];
  return ctx;
}

- (void) setRimeContext:(RimeContext) context
{
  rimeContext = context;
  self.preeditText = context.composition.preedit ? @(context.composition.preedit) : @"";
}

- (RimeContext *) rimeContext
{
  return &rimeContext;
}
@end

// RimeStatus Wrapper
@implementation IRimeStatus
{
  RimeStatus rimeStatus;
}

+ (IRimeStatus *) rimeStatus:(RimeStatus) rimeStatus
{
  IRimeStatus *status = [[IRimeStatus alloc] init];
  [status setRimeStatus: rimeStatus];
  return status;
}

- (void) setRimeStatus:(RimeStatus) status
{
  rimeStatus = status;
  self.isAsciiMode = status.is_ascii_mode == 1;
  self.isComposing = status.is_composing == 1;
  self.isAsciiPunct = status.is_ascii_punct == 1;
  self.isDisabled = status.is_disabled == 1;
  self.isFullShape = status.is_full_shape == 1;
  self.isSimplified = status.is_simplified == 1;
  self.isTraditional = status.is_traditional == 1;
  self.schemaId = status.schema_id ? @(status.schema_id) : @"";
  self.schemaName = status.schema_name ? @(status.schema_name) : @"";
}

- (RimeStatus *) rimeStatus
{
  return &rimeStatus;
}

- (void) print
{
  NSLog(@"rimeStatus =  %@", [NSString stringWithFormat: @"is_ascii_mode: %d, is_composing: %d, is_ascii_punct: %d, is_disabled: %d, is_full_shape: %d, is_simplified: %d, is_traditional: %d, schema_id: %s, schema_name: %@",
                              rimeStatus.is_ascii_mode,
                              rimeStatus.is_composing,
                              rimeStatus.is_ascii_punct,
                              rimeStatus.is_disabled,
                              rimeStatus.is_full_shape,
                              rimeStatus.is_simplified,
                              rimeStatus.is_traditional,
                              rimeStatus.schema_id,
                              [NSString stringWithUTF8String: rimeStatus.schema_name]
                             ]);
}



@end

// RimeCandidateListIterator Wrapper
@implementation IRimeCandidateListIterator
{
  RimeCandidateListIterator rimeCandidateListIterator;
}

// private

+ (IRimeCandidateListIterator *) rimeCandidateListIterator:(RimeCandidateListIterator) rimeCandidateListIterator
{
  IRimeCandidateListIterator *iterator = [[IRimeCandidateListIterator alloc] init];
  [iterator setRimeCandidateListIterator: rimeCandidateListIterator];
  return iterator;
}

- (void) setRimeCandidateListIterator:(RimeCandidateListIterator) iterator
{
  rimeCandidateListIterator = iterator;
}

- (RimeCandidateListIterator *) rimeCandidateListIterator
{
  return &rimeCandidateListIterator;
}


// public
- (int) index
{
  return rimeCandidateListIterator.index;
}
- (NSString *) text
{
  return [NSString  stringWithUTF8String: rimeCandidateListIterator.candidate.text];
}

@end


//
@implementation IRimeSchemaList
{
  RimeSchemaList schemaList;
}

+ (IRimeSchemaList *) rimeSchemaList:(RimeSchemaList) list
{
  IRimeSchemaList *rimeSchemaList = [[IRimeSchemaList alloc] init];
  [rimeSchemaList setRimeSchemaList: list];
  return rimeSchemaList;
}

- (void) setRimeSchemaList:(RimeSchemaList) rimeSchemaList
{
  schemaList = rimeSchemaList;
}

- (RimeSchemaList *) rimeSchemaList
{
  return &schemaList;
}

- (void) print
{
  for (size_t i = 0; i < schemaList.size; ++i) {
    NSLog(@"%lu. %s [%s]\n", (i + 1),
          schemaList.list[i].name, schemaList.list[i].schema_id);
  }
}


@end


static id<IRimeNotificationDelegate> _delegate = nil;

//! Receive notifications
/*!
 * - on loading schema:
 *   + message_type="schema", message_value="luna_pinyin/Luna Pinyin"
 * - on changing mode:
 *   + message_type="option", message_value="ascii_mode"
 *   + message_type="option", message_value="!ascii_mode"
 * -
 *   + session_id = 0, message_type="deploy", message_value="start"
 *   + session_id = 0, message_type="deploy", message_value="success"
 *   + session_id = 0, message_type="deploy", message_value="failure"
 *
 *   handler will be called with context_object as the first parameter
 *   every time an event occurs in librime, until RimeFinalize() is called.
 *   when handler is NULL, notification is disabled.
 */
void rimeNotificationHandler(void* contextObject, RimeSessionId session, const char* messageType, const char* messageValue) {
  if (_delegate == NULL || messageValue == NULL) {
    return;
  }
  
  // on deployment
  if (!strcmp(messageType, "deploy")) {
    
    if (!strcmp(messageValue, "start")) {
      [_delegate onDelployStart];
      return;
    }
    
    if (!strcmp(messageValue, "success")) {
      [_delegate onDeploySuccess];
      return;
    }
    
    if (!strcmp(messageValue, "failure")) {
      [_delegate onDeployFailure];
      return;
    }
    
    return;
  }
  
  // on loading schema
  if (!strcmp(messageType, "schema")) {
    [_delegate onLoadingSchema:[NSString stringWithUTF8String: messageValue]];
    return;
  }
  
  // on changing mode:
  if (!strcmp(messageType, "option")) {
    [_delegate onChangeMode: [NSString stringWithUTF8String: messageValue]];
    return;
  }
}

RimeTraits toRimeTraits(IRimeTraits *traits)
{
  RIME_STRUCT(RimeTraits, rimeTraits);
  
  if (traits.sharedDataDir) {
    rimeTraits.shared_data_dir = [traits.sharedDataDir UTF8String];
  }
  if (traits.userDataDir) {
    rimeTraits.user_data_dir = [traits.userDataDir UTF8String];
  }
  if (traits.distributionCodeName) {
    rimeTraits.distribution_code_name = [traits.distributionCodeName UTF8String];
  }
  if (traits.distributionName) {
    rimeTraits.distribution_name = [traits.distributionName UTF8String];
  }
  if (traits.distributionVersion) {
    rimeTraits.distribution_version = [traits.distributionVersion UTF8String];
  }
  if (traits.appName) {
    rimeTraits.app_name = [traits.appName UTF8String];
  }
  
  // 提取NSArray中字符, 并返回接口要求的modules格式
//  if (traits.modules && [traits.modules count]) {
//    NSArray *modules = traits.modules;
//    NSUInteger count =[traits.modules count];
//    const char *rimeModules[count];
//    for (int i = 0; i < count; i++) {
//      rimeModules[i] = [((NSString *)[modules objectAtIndex: i]) UTF8String];
//    }
//    rimeTraits.modules = rimeModules;
//  }
  
  if (traits.minLogLevel) {
    rimeTraits.min_log_level = traits.minLogLevel;
  }
  
  if (traits.logDir) {
    rimeTraits.log_dir = [traits.logDir UTF8String];
  }
  if (traits.prebuiltDataDir) {
    rimeTraits.prebuilt_data_dir = [traits.prebuiltDataDir UTF8String];
  }
  if (traits.stagingDir) {
    rimeTraits.staging_dir = [traits.stagingDir UTF8String];
  }
  return rimeTraits;
}

// RimeEngin 实现

@implementation RimeEngine

static RimeEngine *shared = nil;

+ (RimeEngine *) sharedRimeEngine
{
  @synchronized([RimeEngine class]) {
    if (shared == nil) {
      shared = [[self alloc] init];
    }
    return shared;
  }
}

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
//
- (void) setNotificationHandler:(id<IRimeNotificationDelegate>) delegate context:(id) ctx
{
  _delegate = delegate;
  rime_get_api() -> set_notification_handler(rimeNotificationHandler, (__bridge void *)ctx);
}

// Setup

// 在访问任何其他API之前调用这个函数。
- (void) setup:(IRimeTraits *) traits
{
  RimeTraits rimeTraits = toRimeTraits(traits);
  rime_get_api() -> setup(&rimeTraits);
}

// Entry and exit

- (void) initialize:(IRimeTraits *) traits
{
  if (traits == NULL) {
    rime_get_api() -> initialize(NULL);
    return;
  }
  RimeTraits rimeTraits = toRimeTraits(traits);
  rime_get_api() -> initialize(&rimeTraits);
}

- (void) finalize
{
  rime_get_api() -> finalize();
}

- (BOOL) startMaintenance:(BOOL) fullCheck
{
  return rime_get_api() -> start_maintenance( fullCheck ? True : False) == True;
}
- (BOOL) isMaintenancing
{
  return rime_get_api() -> is_maintenance_mode() == True;
}
- (void) joinMaintenanceThread
{
  rime_get_api() -> join_maintenance_thread();
}


// Deployment

- (void) deployerInitialize:( IRimeTraits*) traits
{
  RimeTraits rimeTraits = toRimeTraits(traits);
  rime_get_api() -> deployer_initialize(&rimeTraits);
}
- (BOOL) prebuildAllSchemas
{
  return rime_get_api() -> prebuild() == True;
}
- (BOOL) deployWorkspace
{
  return rime_get_api() -> deploy() == True;
}
- (BOOL) deploySchema:(NSString *) schemaFile
{
  return rime_get_api() -> deploy_schema([schemaFile UTF8String]) == True;
}
- (BOOL) deployConfigFile:(NSString *) fileName versionKey:(NSString *) key {
  return rime_get_api() -> deploy_config_file([fileName UTF8String], [key UTF8String]) == True;
}

- (BOOL) syncUserData
{
  return rime_get_api() -> sync_user_data();
}

// Session management

- (IRimeSessionId) createSession
{
  RimeSessionId sessionId = rime_get_api() -> create_session();
  return (IRimeSessionId)sessionId;
}
- (BOOL) findSession:(IRimeSessionId) session
{
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api() -> find_session(sessionId) == True;
}
- (BOOL) destroySession:(IRimeSessionId) session
{
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api() -> destroy_session(sessionId) == True;
}
- (void) cleanupStaleSessions
{
  rime_get_api() -> cleanup_stale_sessions();
}
- (void) cleanupAllSessions
{
  rime_get_api() -> cleanup_all_sessions();
}

// Input

- (BOOL) processKey:(IRimeSessionId) session keycode:(int) code mask:(int) mask
{
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api() -> process_key(sessionId, code, mask) == True;
}
/*!
 * return True if there is unread commit text
 */
- (BOOL) commitComposition:(IRimeSessionId) session
{
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api() -> commit_composition(sessionId) == True;
}

- (void) clearComposition:(IRimeSessionId) session;
{
  RimeSessionId sessionId = (RimeSessionId)session;
  rime_get_api() -> clear_composition(sessionId);
}

// Output

- (NSString *) getInput:(IRimeSessionId) session
{
  RimeSessionId sessionId = (RimeSessionId)session;
  const char *input = rime_get_api() -> get_input(sessionId);
  if (input != NULL) {
    return [NSString stringWithUTF8String: input];
  }
  return nil;
}

- (IRimeCommit *) getCommit:(IRimeSessionId) session;
{
  RimeSessionId sessionId = (RimeSessionId)session;
  RIME_STRUCT(RimeCommit, rimeCommit);
  if (rime_get_api() -> get_commit(sessionId, &rimeCommit) == True) {
    return [IRimeCommit rimeCommit: rimeCommit];
  }
  return nil;
}
- (BOOL) freeCommit:(IRimeCommit *) commit
{
  return rime_get_api() -> free_commit([commit rimeCommit]) == True;
}

- (IRimeContext *) getContext:(IRimeSessionId) session
{
  RimeSessionId sessionId = (RimeSessionId)session;
  RIME_STRUCT(RimeContext, rimeContext);
  
  if (rime_get_api() -> get_context(sessionId, &rimeContext) == True) {
    return [IRimeContext rimeContext: rimeContext];
  }
  return nil;
}
- (BOOL) freeContext:(IRimeContext *)context;
{
  return rime_get_api() -> free_context([context rimeContext]) == True;
}
- (IRimeStatus *) getStatus:(IRimeSessionId) session
{
  
  RimeSessionId sessionId = (RimeSessionId)session;
  RIME_STRUCT(RimeStatus, rimeStatus);
  if (rime_get_api() -> get_status(sessionId, &rimeStatus) == True) {
    return [IRimeStatus rimeStatus: rimeStatus];
  }
  return nil;
}

- (BOOL) freeStatus:(IRimeStatus *) status;
{
  return rime_get_api() -> free_status([status rimeStatus]) == True;
}

// Accessing candidate list
- (IRimeCandidateListIterator *) candidateListBegin:(IRimeSessionId) session
{
  RimeSessionId sessionId = (RimeSessionId)session;
  RimeCandidateListIterator iterator = {0};
  if (rime_get_api() -> candidate_list_begin(sessionId, &iterator) == True) {
    return [IRimeCandidateListIterator rimeCandidateListIterator: iterator];
  }
  return nil;
}
- (BOOL) candidateListNext:(IRimeCandidateListIterator *) iterator
{
  return rime_get_api() -> candidate_list_next([iterator rimeCandidateListIterator]) == True;
}
- (void) candidateListEnd:(IRimeCandidateListIterator *) iterator
{
  rime_get_api() -> candidate_list_end([iterator rimeCandidateListIterator]);
}
- (IRimeCandidateListIterator *) candidateListFromIndex:(IRimeSessionId) session index:(int) index
{
  RimeSessionId sessionId = (RimeSessionId)session;
  RimeCandidateListIterator iterator = {0};
  if (rime_get_api() -> candidate_list_from_index(sessionId, &iterator, index) == True) {
    return [IRimeCandidateListIterator rimeCandidateListIterator: iterator];
  }
  return nil;
}

// Runtime options

- (void) setOption:(IRimeSessionId) session option:(NSString *) option value:(BOOL) value
{
  RimeSessionId sessionId = (RimeSessionId)session;
  rime_get_api() -> set_option(sessionId, [option UTF8String], value ? True : False);
}
- (BOOL) getOption:(IRimeSessionId) session option:(NSString *) option
{
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api() -> get_option(sessionId, [option UTF8String]) == True;
}

- (void) setProperty:(IRimeSessionId) session prop:(NSString *) prop value:(NSString *) value
{
  RimeSessionId sessionId = (RimeSessionId)session;
  rime_get_api() -> set_property(sessionId, [prop UTF8String], [value UTF8String]);
  
}
- (NSString *) getProperty:(IRimeSessionId) session prop:(NSString *) prop
{
  char value[256];
  value[sizeof value - 1] = 0; // Compliant Solution: might silently truncate,
  if (rime_get_api() -> get_property(session, [prop UTF8String], value, sizeof(value)) == True) {
    return [NSString stringWithUTF8String: value];
  }
  return nil;
}

- (IRimeSchemaList *) getSchemaList
{
  RimeSchemaList list;
  if (rime_get_api() -> get_schema_list(&list) == True) {
    return [IRimeSchemaList rimeSchemaList: list];
  }
  return nil;
}

- (void) freeSchemaList:(IRimeSchemaList *) list
{
  rime_get_api()->free_schema_list([list rimeSchemaList]);
}

- (NSString *) getCurrentSchema:(IRimeSessionId) session
{
  RimeSessionId sessionId = (RimeSessionId)session;
  NSLog(@"session = %lu", sessionId);
  char current[100] = {0};
  if (rime_get_api() -> get_current_schema(sessionId, current, sizeof(current))) {
    NSLog(@"current schema = %s", current);
    return [NSString stringWithUTF8String: current];
  }
  return nil;
}

- (BOOL) selectSchema:(IRimeSessionId) session schemeId:(NSString *) schema
{
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api() -> select_schema(sessionId, [schema UTF8String]) == True;
}

// Configuration

//// <schema_id>.schema.yaml
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
//
// Testing

- (BOOL) simulateKeySequence:(IRimeSessionId) session keySequence:(NSString *) sequence
{
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api() -> simulate_key_sequence(sessionId, [sequence UTF8String]) == True;
}

// Module

//- (BOOL) registerModule:(struct IRimeModule *) module;
//- (struct IRimeModule *) findModule:(NSString *) moduleName;
//
////! Run a registered task
//- (BOOL) runTask:(NSString *) task_name;
//
- (NSString *) getSharedDataDir
{
  return [NSString stringWithUTF8String: rime_get_api() -> get_shared_data_dir()];
}
- (NSString *) getUserDataDir
{
  return [NSString stringWithUTF8String: rime_get_api() -> get_user_data_dir()];
}
- (NSString *) getSyncDir
{
  return [NSString stringWithUTF8String: rime_get_api() -> get_sync_dir()];
}
- (NSString *) getUserId
{
  return [NSString stringWithUTF8String: rime_get_api() -> get_user_id()];
}

@end
