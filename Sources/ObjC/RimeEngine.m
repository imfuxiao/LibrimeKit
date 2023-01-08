#import "RimeEngine.h"
#import "rime_api.h"
#import <Foundation/Foundation.h>

static void (^NotificationHandler)(void *context_object,
                                   IRimeSessionId session_id,
                                   const char *message_type,
                                   const char *message_value);

static void rimeNotificationHandler(void *context_object,
                                    RimeSessionId session_id,
                                    const char *message_type,
                                    const char *message_value) {
  NotificationHandler(context_object, session_id, message_type, message_value);
}

@implementation IRimeTraits {
  // 内部引用, 外部只读
  RimeTraits *traits;
}

@dynamic sharedDataDir;
@dynamic userDataDir;
@dynamic distributionName;
@dynamic distributionCodeName;
@dynamic distributionVersion;
@dynamic appName;
@dynamic modules;
@dynamic minLogLevel;
@dynamic logDir;
@dynamic prebuiltDataDir;
@dynamic stagingDir;

- (id)init {
  self = [super init];
  if (self != nil) {
    RIME_STRUCT(RimeTraits, rimeTraits);
    traits = &rimeTraits;
  }
  return self;
}

- (NSString *)sharedDataDir {
  return sharedDataDir;
}
- (void)setSharedDataDir:(NSString *)dir {
  sharedDataDir = dir;
  if (dir != nil && traits != NULL) {
    traits->shared_data_dir = [dir UTF8String];
  }
}

- (NSString *)userDataDir {
  return userDataDir;
}
- (void)setUserDataDir:(NSString *)dir {
  userDataDir = dir;
  if (dir != nil && traits != NULL) {
    traits->user_data_dir = [dir UTF8String];
  }
}

- (NSString *)distributionName {
  return distributionName;
}
- (void)setDistributionName:(NSString *)name {
  distributionName = name;
  if (name != nil && traits != NULL) {
    traits->distribution_name = [name UTF8String];
  }
}

- (NSString *)distributionCodeName {
  return distributionCodeName;
}
- (void)setDistributionCodeName:(NSString *)name {
  distributionCodeName = name;
  if (name != nil && traits != NULL) {
    traits->distribution_code_name = [name UTF8String];
  }
}

- (NSString *)distributionVersion {
  return distributionVersion;
}
- (void)setDistributionVersion:(NSString *)version {
  distributionVersion = version;
  if (version != nil && traits != NULL) {
    traits->distribution_version = [version UTF8String];
  }
}

- (NSString *)appName {
  return appName;
}
- (void)setAppName:(NSString *)name {
  appName = name;
  if (name != nil && traits != NULL) {
    traits->app_name = [name UTF8String];
  }
}

- (NSArray *)modules {
  return modules;
}
- (void)setModules:(NSArray<NSString *> *)m {
  modules = m;
  if (m == nil || [m count] == 0) {
    return;
  }
  
  NSUInteger count = [m count];
  const char *rimeModules[count];
  for (int i = 0; i < count; i++) {
    rimeModules[i] = [m[i] UTF8String];
  }
  
  if (traits != NULL) {
    traits->modules = rimeModules;
  }
}

- (int)minLogLevel {
  return minLogLevel;
}
- (void)setMinLogLevel:(int)level {
  minLogLevel = level;
  if (traits != NULL) {
    traits->min_log_level = level;
  }
}

- (NSString *)logDir {
  return logDir;
}
- (void)setLogDir:(NSString *)dir {
  logDir = dir;
  if (dir != nil && traits != NULL) {
    traits->log_dir = [dir UTF8String];
  }
}

- (NSString *)prebuiltDataDir {
  return prebuiltDataDir;
}
- (void)setPrebuiltDataDir:(NSString *)dir {
  prebuiltDataDir = dir;
  if (dir != nil && traits != NULL) {
    traits->prebuilt_data_dir = [dir UTF8String];
  }
}

- (NSString *)stagingDir {
  return stagingDir;
}
- (void)setStagingDir:(NSString *)dir {
  stagingDir = dir;
  if (dir != nil && traits != NULL) {
    traits->staging_dir = [dir UTF8String];
  }
}

- (RimeTraits *) rimeTraits {
  
  return traits;
}

@end

@implementation IRimeComposition {
  RimeComposition *composition;
}

- initWithComposition:(RimeComposition *)c {
  if ((self = [super init]) != nil) {
    composition = c;
  }
  return self;
}

- (int)length {
  return composition->length;
}
- (int)cursorPos {
  
  return composition->cursor_pos;
}
- (int)selStart {
  return composition->sel_start;
}
- (int)selEnd {
  return composition->sel_end;
}
- (NSString *)preedit {
  return [NSString stringWithUTF8String:composition->preedit];
}

@end

@implementation IRimeCandidate {
  RimeCandidate *candidate;
}

- initWithCandidate:(RimeCandidate *)c {
  if ((self = [super init]) != nil) {
    candidate = c;
  }
  return self;
}

- (NSString *)text {
  return [NSString stringWithUTF8String:candidate->text];
}
- (NSString *)comment {
  return [NSString stringWithUTF8String:candidate->text];
}
- (NSString *)reserved {
  return [NSString stringWithUTF8String:candidate->text];
}

@end

@implementation IRimeMenu {
  RimeMenu *menu;
}

- (id)initWithMenu:(RimeMenu *)m {
  if ((self = [super init]) != nil) {
    menu = m;
  }
  return self;
}

- (int)pageSize {
  return menu->page_size;
}

- (int)pageNo {
  return menu->page_no;
}

- (BOOL)isLastPage {
  return menu->is_last_page == True;
}

- (int)highlightedCandidateIndex {
  return menu->highlighted_candidate_index;
}

- (int)numCandidates {
  return menu->num_candidates;
}

- (NSArray<IRimeCandidate *> *)candidates {
  int count = menu->num_candidates;
  if (!count) {
    return nil;
  }
  
  NSMutableArray<IRimeCandidate *> *r =
  [NSMutableArray arrayWithCapacity:count];
  RimeCandidate *candidates = menu->candidates;
  for (int i = 0; i < count; i++) {
    RimeCandidate candidate = candidates[i];
    [r addObject:[[IRimeCandidate alloc] initWithCandidate:&candidate]];
  }
  return [NSArray arrayWithArray:r];
}

- (NSString *)selectKeys {
  return [NSString stringWithUTF8String:menu->select_keys];
}

@end

@implementation IRimeCommit {
  RimeCommit *rimeCommit;
}

- (id)initWithRimeCommit:(RimeCommit *)c {
  if ((self = [super init]) != nil) {
    rimeCommit = c;
  }
  return self;
}

- (int)dataSize {
  return rimeCommit->data_size;
}

- (NSString *)text {
  return [NSString stringWithUTF8String:rimeCommit->text];
}

- (RimeCommit *)rimeCommit {
  return rimeCommit;
}

@end

@implementation IRimeContext {
  RimeContext *rimeContext;
  
  IRimeComposition *composition;
  IRimeMenu *menu;
}

- (id)initWithContext:(RimeContext *)ctx {
  if ((self = [super init]) != nil) {
    rimeContext = ctx;
    if (ctx != nil) {
      composition =
      [[IRimeComposition alloc] initWithComposition:&ctx->composition];
      menu = [[IRimeMenu alloc] initWithMenu:&ctx->menu];
    }
  }
  return self;
}

- (int)dataSize {
  if (rimeContext != nil) {
    return rimeContext->data_size;
  }
  return 0;
}

- (IRimeComposition *)composition {
  return composition;
}
- (IRimeMenu *)menu {
  return menu;
}

- (NSString *)commitTextPreview {
  return [NSString stringWithUTF8String:rimeContext->commit_text_preview];
}

- (NSArray<NSString *> *)selectLabels {
  int dataSize = [self dataSize];
  if (!dataSize) {
    return nil;
  }
  NSMutableArray<NSString *> *r = [NSMutableArray arrayWithCapacity:dataSize];
  char **labels = rimeContext->select_labels;
  for (int i = 0; i < dataSize; i++) {
    NSString *str = [NSString stringWithUTF8String:labels[i]];
    [r addObject:str];
  }
  return [NSArray arrayWithArray:r];
}

- (RimeContext *)rimeContext {
  return rimeContext;
}

@end

@implementation IRimeStatus {
  RimeStatus *rimeStatus;
}

- (id)initWithStatus:(RimeStatus *)status {
  if ((self = [super init]) != nil) {
    rimeStatus = status;
  }
  return self;
}

- (int)dataSize {
  return rimeStatus->data_size;
}
- (NSString *)schemaId {
  return rimeStatus->schema_id ? @(rimeStatus->schema_id) : @"";
}
- (NSString *)schemaName {
  return rimeStatus->schema_name ? @(rimeStatus->schema_name) : @"";
}
- (BOOL)isDisabled {
  return rimeStatus->is_disabled == True;
}
- (BOOL)isComposing {
  return rimeStatus->is_composing == True;
}
- (BOOL)isAsciiMode {
  return rimeStatus->is_ascii_mode == True;
}
- (BOOL)isFullShape {
  return rimeStatus->is_full_shape == True;
}
- (BOOL)isSimplified {
  return rimeStatus->is_simplified == True;
}
- (BOOL)isTraditional {
  return rimeStatus->is_traditional == True;
}
- (BOOL)isAsciiPunct {
  return rimeStatus->is_ascii_punct == True;
}

- (RimeStatus *)rimeStatus {
  return rimeStatus;
}

- (void)print {
  NSLog(
        @"rimeStatus =  %@",
        [NSString stringWithFormat:
         @"is_ascii_mode: %d, is_composing: %d, is_ascii_punct: "
         @"%d, is_disabled: %d, is_full_shape: %d, is_simplified: "
         @"%d, is_traditional: %d, schema_id: %@, schema_name: %@",
         [self isAsciiMode], [self isComposing], [self isAsciiPunct],
         [self isDisabled], [self isFullShape], [self isSimplified],
         [self isTraditional], [self schemaId], [self schemaName]]);
}

@end

@implementation IRimeCandidateListIterator {
  RimeCandidateListIterator *rimeCandidateListIterator;
}

- (id)initWithIterator:(RimeCandidateListIterator *)iterator {
  if ((self = [super init]) != nil) {
    rimeCandidateListIterator = iterator;
  }
  return self;
}

- (int)index {
  if (rimeCandidateListIterator == nil) {
    return nil;
  }
  return rimeCandidateListIterator->index;
}
- (IRimeCandidate *)candidate {
  if (rimeCandidateListIterator == nil) {
    return nil;
  }
  return [[IRimeCandidate alloc]
          initWithCandidate:&rimeCandidateListIterator->candidate];
}

- (RimeCandidateListIterator *)rimeCandidateListIterator {
  return rimeCandidateListIterator;
}

@end

@implementation IRimeConfig {
  RimeConfig *config;
}

// 参考 IRimeCandidateListIterator.ptr
- (id)ptr {
  if (config == nil) {
    return nil;
  }
  return CFBridgingRelease(config->ptr);
}

- (RimeConfig *)config {
  return config;
}

@end

@implementation IRimeConfigIterator {
  RimeConfigIterator *iterator;
}

- (NSObject *)list {
  if (iterator == nil) {
    return nil;
  }
  return CFBridgingRelease(iterator->list);
}
- (NSObject *)map {
  if (iterator == nil) {
    return nil;
  }
  return CFBridgingRelease(iterator->map);
}

- (int)index {
  if (iterator == nil) {
    return 0;
  }
  return iterator->index;
}
- (NSString *)key {
  if (iterator == nil) {
    return nil;
  }
  return @(iterator->key);
}
- (NSString *)path {
  
  if (iterator == nil) {
    return nil;
  }
  return @(iterator->path);
}

- (RimeConfigIterator *)iterator {
  return iterator;
}
@end

@implementation IRimeSchemaListItem {
  RimeSchemaListItem *item;
}

- (id)initWithItem:(RimeSchemaListItem *)i {
  if ((self = [super init]) != nil) {
    item = i;
  }
  return self;
}

- (NSString *)schemaId {
  if (item == nil) {
    return nil;
  }
  return @(item->schema_id);
}
- (NSString *)name {
  if (item == nil) {
    return nil;
  }
  return @(item->name);
}
- (NSObject *)reserved {
  if (item == nil) {
    return nil;
  }
  return CFBridgingRelease(item->reserved);
}

@end

@implementation IRimeSchemaList {
  RimeSchemaList *schemalist;
}

- (id)initWithSchemaList:(RimeSchemaList *)list {
  if ((self = [super init]) != nil) {
    schemalist = list;
  }
  return self;
}

- (NSArray<IRimeSchemaListItem *> *)list {
  if (schemalist == nil) {
    return nil;
  }
  size_t count = schemalist->size;
  if (!count) {
    return nil;
  }
  
  RimeSchemaListItem *list = schemalist->list;
  NSMutableArray<IRimeSchemaListItem *> *r =
  [NSMutableArray arrayWithCapacity:count];
  for (int i = 0; i < count; i++) {
    RimeSchemaListItem item = list[i];
    [r addObject:[[IRimeSchemaListItem alloc] initWithItem:&item]];
  }
  return [NSArray arrayWithArray:r];
}

- (RimeSchemaList *)schemalist {
  return schemalist;
}

@end

@implementation IRimeCustomApi {
  RimeCustomApi *customApi;
}

- (id)initWithCustomApi:(RimeCustomApi *)api {
  if ((self = [super init]) != nil) {
    customApi = api;
  }
  return self;
}

- (int)dataSize {
  if (customApi == nil) {
    return 0;
  }
  return customApi->data_size;
}

- (RimeCustomApi *)customApi {
  return customApi;
}

@end

/**
 封装 rime_api.h 结构  RimeModule
 */
@implementation IRimeModule {
  RimeModule *module;
}

- (id)initWithModule:(RimeModule *)m {
  if ((self = [super init]) != nil) {
    module = m;
  }
  return self;
}

- (NSString *)moduleName {
  if (module == nil) {
    return nil;
  }
  return @(module->module_name);
}

- (void)initialize {
  if (module == nil) {
    return;
  }
  
  module->initialize();
}
- (void)finalize {
  if (module == nil) {
    return;
  }
  
  module->finalize();
}
- (IRimeCustomApi *)getApi {
  if (module == nil) {
    return;
  }
  RimeCustomApi *api = module->get_api();
  return [[IRimeCustomApi alloc] initWithCustomApi:api];
}

- (RimeModule *)module {
  return module;
}

@end

// RimeEngin 实现

@implementation IRimeAPI {
  RimeApi *api;
}

- (id)init {
  if ((self = [super init]) != nil) {
    api = rime_get_api();
  }
  return self;
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
- (void)setNotificationHandler:(id<IRimeNotificationDelegate>)delegate
                       context:(id)ctx {
  __weak id<IRimeNotificationDelegate> handleDelegate = delegate;
  
  NotificationHandler = ^(void *context_object, IRimeSessionId session_id,
                          const char *message_type, const char *message_value) {
    if (handleDelegate == NULL || message_value == NULL) {
      return;
    }
    
    // on deployment
    if (!strcmp(message_type, "deploy")) {
      
      if (!strcmp(message_value, "start")) {
        [handleDelegate onDelployStart];
        return;
      }
      
      if (!strcmp(message_value, "success")) {
        [handleDelegate onDeploySuccess];
        return;
      }
      
      if (!strcmp(message_value, "failure")) {
        [handleDelegate onDeployFailure];
        return;
      }
      
      return;
    }
    
    // on loading schema
    if (!strcmp(message_type, "schema")) {
      [handleDelegate
       onLoadingSchema:[NSString stringWithUTF8String:message_value]];
      return;
    }
    
    // on changing mode:
    if (!strcmp(message_type, "option")) {
      [handleDelegate
       onChangeMode:[NSString stringWithUTF8String:message_value]];
      return;
    }
  };
  
  api->set_notification_handler(rimeNotificationHandler, (__bridge void *)ctx);
}

// Setup

// 在访问任何其他API之前调用这个函数。
- (void)setup:(IRimeTraits *)traits {
  RimeTraits *t = [traits rimeTraits];
  api->setup(t);
}

// Entry and exit

- (void)initialize:(IRimeTraits *)traits {
  if (traits == NULL) {
    api->initialize(NULL);
    return;
  }
  RimeTraits *t = [traits rimeTraits];
  api->initialize(t);
}

- (void)finalize {
  api->finalize();
}

- (BOOL)startMaintenance:(BOOL)fullCheck {
  return api->start_maintenance(fullCheck ? True : False) == True;
}
- (bool)isMaintenancing {
  return api->is_maintenance_mode() == True;
}
- (void)joinMaintenanceThread {
  api->join_maintenance_thread();
}

// Deployment

- (void)deployerInitialize:(IRimeTraits *)traits {
  api->deployer_initialize([traits rimeTraits]);
}
- (BOOL)prebuildAllSchemas {
  return api->prebuild() == True;
}
- (BOOL)deployWorkspace {
  return api->deploy() == True;
}
- (BOOL)deploySchema:(NSString *)schemaFile {
  return api->deploy_schema([schemaFile UTF8String]) == True;
}
- (BOOL)deployConfigFile:(NSString *)fileName versionKey:(NSString *)key {
  return api->deploy_config_file([fileName UTF8String], [key UTF8String]) ==
  True;
}

- (BOOL)syncUserData {
  return api->sync_user_data();
}

// Session management

- (IRimeSessionId)createSession {
  RimeSessionId sessionId = api->create_session();
  return (IRimeSessionId)sessionId;
}
- (BOOL)findSession:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  return api->find_session(sessionId) == True;
}
- (BOOL)destroySession:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  return api->destroy_session(sessionId) == True;
}
- (void)cleanupStaleSessions {
  api->cleanup_stale_sessions();
}
- (void)cleanupAllSessions {
  api->cleanup_all_sessions();
}

// Input

- (BOOL)processKey:(IRimeSessionId)session keycode:(int)code mask:(int)mask {
  RimeSessionId sessionId = (RimeSessionId)session;
  return api->process_key(sessionId, code, mask) == True;
}
/*!
 * return True if there is unread commit text
 */
- (BOOL)commitComposition:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  return api->commit_composition(sessionId) == True;
}

- (void)clearComposition:(IRimeSessionId)session;
{
  RimeSessionId sessionId = (RimeSessionId)session;
  api->clear_composition(sessionId);
}

// Output

- (NSString *)getInput:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  const char *input = api->get_input(sessionId);
  if (input != NULL) {
    return [NSString stringWithUTF8String:input];
  }
  return nil;
}

- (IRimeCommit *)getCommit:(IRimeSessionId)session;
{
  RimeSessionId sessionId = (RimeSessionId)session;
  RIME_STRUCT(RimeCommit, rimeCommit);
  if (api->get_commit(sessionId, &rimeCommit) == True) {
    IRimeCommit *commit = [[IRimeCommit alloc] initWithRimeCommit:&rimeCommit];
    return commit;
  }
  return nil;
}
- (BOOL)freeCommit:(IRimeCommit *)commit {
  return api->free_commit([commit rimeCommit]) == True;
}

- (IRimeContext *)getContext:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  RIME_STRUCT(RimeContext, rimeContext);
  if (api->get_context(sessionId, &rimeContext) == True) {
    return [[IRimeContext alloc] initWithContext:&rimeContext];
  }
  return nil;
}
- (BOOL)freeContext:(IRimeContext *)context;
{ return api->free_context([context rimeContext]) == True; }

- (IRimeStatus *)getStatus:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  RIME_STRUCT(RimeStatus, rimeStatus);
  RimeStatus *s = &rimeStatus;
  if (api->get_status(sessionId, s) == True) {
    return [[IRimeStatus alloc] initWithStatus:&rimeStatus];
  }
  return nil;
}

- (BOOL)freeStatus:(IRimeStatus *)status {
  RimeStatus *s = [status rimeStatus];
  return api->free_status(s) == True;
}

// Accessing candidate list
- (IRimeCandidateListIterator *)candidateListBegin:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  RimeCandidateListIterator iterator = {0};
  if (api->candidate_list_begin(sessionId, &iterator) == True) {
    return [[IRimeCandidateListIterator alloc] initWithIterator:&iterator];
  }
  return nil;
}
- (BOOL)candidateListNext:(IRimeCandidateListIterator *)iterator {
  return api->candidate_list_next([iterator rimeCandidateListIterator]) == True;
}
- (void)candidateListEnd:(IRimeCandidateListIterator *)iterator {
  api->candidate_list_end([iterator rimeCandidateListIterator]);
}

- (IRimeCandidateListIterator *)candidateListFromIndex:(IRimeSessionId)session
                                                 index:(int)index {
  RimeSessionId sessionId = (RimeSessionId)session;
  RimeCandidateListIterator iterator = {0};
  if (api->candidate_list_from_index(sessionId, &iterator, index) == True) {
    return [[IRimeCandidateListIterator alloc] initWithIterator:&iterator];
  }
  return nil;
}

// Runtime options

- (void)setOption:(IRimeSessionId)session
           option:(NSString *)option
            value:(BOOL)value {
  RimeSessionId sessionId = (RimeSessionId)session;
  api->set_option(sessionId, [option UTF8String], value ? True : False);
}
- (BOOL)getOption:(IRimeSessionId)session option:(NSString *)option {
  RimeSessionId sessionId = (RimeSessionId)session;
  return api->get_option(sessionId, [option UTF8String]) == True;
}

- (void)setProperty:(IRimeSessionId)session
               prop:(NSString *)prop
              value:(NSString *)value {
  RimeSessionId sessionId = (RimeSessionId)session;
  api->set_property(sessionId, [prop UTF8String], [value UTF8String]);
}
- (NSString *)getProperty:(IRimeSessionId)session prop:(NSString *)prop {
  char value[256];
  value[sizeof value - 1] = 0; // Compliant Solution: might silently truncate,
  if (api->get_property(session, [prop UTF8String], value, sizeof(value)) ==
      True) {
    return [NSString stringWithUTF8String:value];
  }
  return nil;
}

- (IRimeSchemaList *)getSchemaList {
  RimeSchemaList list;
  if (api->get_schema_list(&list) == True) {
    return [[IRimeSchemaList alloc] initWithSchemaList:&list];
  }
  return nil;
}

- (void)freeSchemaList:(IRimeSchemaList *)list {
  api->free_schema_list([list schemalist]);
}

- (NSString *)getCurrentSchema:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  NSLog(@"session = %lu", sessionId);
  char current[100] = {0};
  if (api->get_current_schema(sessionId, current, sizeof(current))) {
    NSLog(@"current schema = %s", current);
    return [NSString stringWithUTF8String:current];
  }
  return nil;
}

- (BOOL)selectSchema:(IRimeSessionId)session schemeId:(NSString *)schema {
  RimeSessionId sessionId = (RimeSessionId)session;
  return api->select_schema(sessionId, [schema UTF8String]) == True;
}

// Configuration

//// <schema_id>.schema.yaml
//- (BOOL) schemaOpen:(NSString *) schemaId config:(struct IRimeConfig *)
// config;
//// <config_id>.yaml
//- (BOOL) configOpen:(NSString *) configId config:(struct IRimeConfig *)
// config;
//// access config files in user data directory, eg. user.yaml and
/// installation.yaml
//- (BOOL) userConfigOpen:(NSString *) configId config:(struct IRimeConfig *)
// config;
//- (BOOL) configClose:(struct IRimeConfig *) config;
//- (BOOL) configInit:(struct IRimeConfig *) config;
//- (BOOL) configLoadString:(struct IRimeConfig *) config yaml:(NSString *)
// yaml;
//// Access config values
//- (BOOL) configGetBool:(struct IRimeConfig *) config key:(NSString *) key
// value:(BOOL *) value;
//- (BOOL) configGetInt:(struct IRimeConfig *) config key:(NSString *) key
// value:(int *) value;
//- (BOOL) configGetDouble:(struct IRimeConfig *) config key:(NSString *) key
// value:(double *) value;
//- (BOOL) configGetString:(struct IRimeConfig *) config key:(NSString *) key
// value:(NSString *) value;
//- (NSString *) configGetCString:(struct IRimeConfig *) config key:(NSString *)
// key;
//- (BOOL) configSetBool:(struct IRimeConfig *) config key:(NSString *) key
// value:(BOOL) value;
//- (BOOL) configSetInt:(struct IRimeConfig *) config key:(NSString *) key
// value:(int) value;
//- (BOOL) configSetDouble:(struct IRimeConfig *) config key:(NSString *) key
// value:(double) value;
//- (BOOL) configSetString:(struct IRimeConfig *) config key:(NSString *) key
// value:(NSString *) value;
//// Manipulate complex structures
//- (BOOL) configGetItem:(struct IRimeConfig *) config key:(NSString *) key
// value:(struct IRimeConfig *) value;
//- (BOOL) configSetItem:(struct IRimeConfig *) config key:(NSString *) key
// value:(struct IRimeConfig *) value;
//- (BOOL) configClear:(struct IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configCreateList:(struct IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configCreateMap:(struct IRimeConfig *) config key:(NSString *) key;
//- (int) configListSize:(struct IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configBeginList:(struct IRimeConfigIterator *)iterator config:(struct
// IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configBeginMap:(struct IRimeConfigIterator *)iterator config:(struct
// IRimeConfig *) config key:(NSString *) key;
//- (BOOL) configNext:(struct IRimeConfigIterator *) iterator;
//- (void) configEnd:(struct IRimeConfigIterator *) iterator;
//// Utilities
//- (BOOL) configUpdateSignature:(struct IRimeConfig *) config signer:(NSString
//*) signer;
//
// Testing

- (BOOL)simulateKeySequence:(IRimeSessionId)session
                keySequence:(NSString *)sequence {
  RimeSessionId sessionId = (RimeSessionId)session;
  return api->simulate_key_sequence(sessionId, [sequence UTF8String]) == True;
}

// Module

- (BOOL)registerModule:(IRimeModule *)module {
  api->register_module([module module]);
}
- (IRimeModule *)findModule:(NSString *)moduleName {
  RimeModule *module = api->find_module([moduleName UTF8String]);
  return [[IRimeModule alloc] initWithModule:module];
}
//
////! Run a registered task
//- (BOOL) runTask:(NSString *) task_name;
//
- (NSString *)getSharedDataDir {
  return [NSString stringWithUTF8String:api->get_shared_data_dir()];
}
- (NSString *)getUserDataDir {
  return [NSString stringWithUTF8String:rime_get_api() -> get_user_data_dir()];
}
- (NSString *)getSyncDir {
  return [NSString stringWithUTF8String:api->get_sync_dir()];
}
- (NSString *)getUserId {
  return [NSString stringWithUTF8String:api->get_user_id()];
}

@end
