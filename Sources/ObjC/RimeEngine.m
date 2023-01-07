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
  
  // 公开属性
  NSString *sharedDataDir;
  NSString *userDataDir;
  NSString *distributionName;
  NSString *distributionCodeName;
  NSString *distributionVersion;
  NSString *appName;
  NSArray *modules;
  int minLogLevel;
  NSString *logDir;
  NSString *prebuiltDataDir;
  NSString *stagingDir;
}

- (id)init {
  self = [super init];
  if (self != nil) {
    RIME_STRUCT(RimeTraits, rimeTraits);
    self->traits = &rimeTraits;
  }
  return self;
}

- (NSString *)sharedDataDir {
  return self.sharedDataDir;
}
- (void)setSharedDataDir:(NSString *)sharedDataDir {
  self.sharedDataDir = sharedDataDir;
  if (sharedDataDir != nil) {
    self->traits->shared_data_dir = [sharedDataDir UTF8String];
  }
}

- (NSString *)userDataDir {
  return self.userDataDir;
}
- (void)setUserDataDir:(NSString *)userDataDir {
  self.userDataDir = userDataDir;
  if (userDataDir != nil) {
    self->traits->user_data_dir = [userDataDir UTF8String];
  }
}

- (NSString *)distributionName {
  return self.distributionName;
}
- (void)setDistributionName:(NSString *)distributionName {
  self.distributionName = distributionName;
  if (distributionName != nil) {
    self->traits->distribution_name = [distributionName UTF8String];
  }
}

- (NSString *)distributionCodeName {
  return self.distributionCodeName;
}
- (void)setDistributionCodeName:(NSString *)distributionCodeName {
  self.distributionCodeName = distributionCodeName;
  if (distributionCodeName != nil) {
    self->traits->distribution_code_name = [distributionCodeName UTF8String];
  }
}

- (NSString *)distributionVersion {
  return self.distributionVersion;
}
- (void)setDistributionVersion:(NSString *)distributionVersion {
  self.distributionVersion = distributionVersion;
  if (distributionVersion != nil) {
    self->traits->distribution_version = [distributionVersion UTF8String];
  }
}

- (NSString *)appName {
  return self.appName;
}
- (void)setAppName:(NSString *)appName {
  self.appName = appName;
  if (appName != nil) {
    self->traits->app_name = [appName UTF8String];
  }
}

- (NSArray *)modules {
  return self.modules;
}
- (void)setModules:(NSArray<NSString *> *)modules {
  self.modules = modules;
  if (modules == nil || [modules count] == 0) {
    return;
  }
  
  NSUInteger count = [modules count];
  const char *rimeModules[count];
  for (int i = 0; i < count; i++) {
    rimeModules[i] = [modules[i] UTF8String];
  }
  self->traits->modules = rimeModules;
}

- (int)minLogLevel {
  return self.minLogLevel;
}
- (void)setMinLogLevel:(int)minLogLevel {
  self.minLogLevel = minLogLevel;
  self->traits->min_log_level = minLogLevel;
}

- (NSString *)logDir {
  return self.logDir;
}
- (void)setLogDir:(NSString *)logDir {
  self.logDir = logDir;
  if (logDir != nil) {
    self->traits->log_dir = [logDir UTF8String];
  }
}

- (NSString *)prebuiltDataDir {
  return self.prebuiltDataDir;
}
- (void)setPrebuiltDataDir:(NSString *)prebuiltDataDir {
  self.prebuiltDataDir = prebuiltDataDir;
  if (prebuiltDataDir != nil) {
    self->traits->prebuilt_data_dir = [prebuiltDataDir UTF8String];
  }
}

- (NSString *)stagingDir {
  return self.stagingDir;
}
- (void)setStagingDir:(NSString *)stagingDir {
  self.stagingDir = stagingDir;
  if (stagingDir != nil) {
    self->traits->staging_dir = [stagingDir UTF8String];
  }
}

- (RimeTraits *)rimeTraits {
  return self->traits;
}

@end

@implementation IRimeComposition {
  RimeComposition *composition;
}

- initWithComposition:(RimeComposition *)compostion {
  if ((self = [super init]) != nil) {
    self->composition = compostion;
  }
  return self;
}

- (int)length {
  return self->composition->length;
}
- (int)cursorPos {
  
  return self->composition->cursor_pos;
}
- (int)selStart {
  return self->composition->sel_start;
}
- (int)selEnd {
  return self->composition->sel_end;
}
- (NSString *)preedit {
  return [NSString stringWithUTF8String:self->composition->preedit];
}

@end

@implementation IRimeCandidate {
  RimeCandidate *candidate;
}

- initWithCandidate:(RimeCandidate *)candidate {
  if ((self = [super init]) != nil) {
    self->candidate = candidate;
  }
  return self;
}

- (NSString *)text {
  return [NSString stringWithUTF8String:self->candidate->text];
}
- (NSString *)comment {
  return [NSString stringWithUTF8String:self->candidate->text];
}
- (NSString *)reserved {
  return [NSString stringWithUTF8String:self->candidate->text];
}

@end

@implementation IRimeMenu {
  RimeMenu *menu;
}

- (id)initWithMenu:(RimeMenu *)menu {
  if ((self = [super init]) != nil) {
    self->menu = menu;
  }
  return self;
}

- (int)pageSize {
  return self->menu->page_size;
}

- (int)pageNo {
  return self->menu->page_no;
}

- (BOOL)isLastPage {
  return self->menu->is_last_page == True;
}

- (int)highlightedCandidateIndex {
  return self->menu->highlighted_candidate_index;
}

- (int)numCandidates {
  return self->menu->num_candidates;
}

- (NSArray<IRimeCandidate *> *)candidates {
  int count = self->menu->num_candidates;
  if (!count) {
    return nil;
  }
  
  NSMutableArray<IRimeCandidate *> *r =
  [NSMutableArray arrayWithCapacity:count];
  RimeCandidate *candidates = self->menu->candidates;
  for (int i = 0; i < count; i++) {
    RimeCandidate candidate = candidates[i];
    [r addObject:[[IRimeCandidate alloc] initWithCandidate:&candidate]];
  }
  return [NSArray arrayWithArray:r];
}

- (NSString *)selectKeys {
  return [NSString stringWithUTF8String:self->menu->select_keys];
}

@end

@implementation IRimeCommit {
  RimeCommit *rimeCommit;
  
  int dataSize;
  NSString *text;
}

- (id)initWithRimeCommit:(RimeCommit *)commit {
  if ((self = [super init]) != nil) {
    self->rimeCommit = commit;
    if (commit != NULL) {
      self->dataSize = commit->data_size;
      self->text = [NSString stringWithUTF8String:commit->text];
    }
  }
  return self;
}

- (int)dataSize {
  return self.dataSize;
}

- (NSString *)text {
  return self.text;
}

- (RimeCommit *)rimeCommit {
  return self->rimeCommit;
}

@end

@implementation IRimeContext {
  RimeContext *rimeContext;
  
  IRimeComposition *composition;
  IRimeMenu *menu;
}

- (id)initWithContext:(RimeContext *)context {
  if ((self = [super init]) != nil) {
    self->rimeContext = context;
    if (context != nil) {
      self->composition =
      [[IRimeComposition alloc] initWithComposition:&context->composition];
      self->menu = [[IRimeMenu alloc] initWithMenu:&context->menu];
    }
  }
  return self;
}

- (int)dataSize {
  if (self->rimeContext != nil) {
    return self->rimeContext->data_size;
  }
  return 0;
}

- (IRimeComposition *)composition {
  return self.composition;
}
- (IRimeMenu *)menu {
  return self.menu;
}

- (NSString *)commitTextPreview {
  return [NSString stringWithUTF8String:self->rimeContext->commit_text_preview];
}

- (NSArray<NSString *> *)selectLabels {
  int dataSize = [self dataSize];
  if (!dataSize) {
    return nil;
  }
  NSMutableArray<NSString *> *r = [NSMutableArray arrayWithCapacity:dataSize];
  char **labels = self->rimeContext->select_labels;
  for (int i = 0; i < dataSize; i++) {
    NSString *str = [NSString stringWithUTF8String:labels[i]];
    [r addObject:str];
  }
  return [NSArray arrayWithArray:r];
}

- (RimeContext *)rimeContext {
  return self->rimeContext;
}

@end

@implementation IRimeStatus {
  RimeStatus *rimeStatus;
}

- (id)initWithStatus:(RimeStatus *)status {
  if ((self = [super init]) != nil) {
    self->rimeStatus = status;
  }
  return self;
}

- (int)dataSize {
  return self->rimeStatus->data_size;
}
- (NSString *)schemaId {
  return self->rimeStatus->schema_id ? @(self->rimeStatus->schema_id) : @"";
}
- (NSString *)schemaName {
  return self->rimeStatus->schema_name ? @(self->rimeStatus->schema_name) : @"";
}
- (BOOL)isDisabled {
  return self->rimeStatus->is_disabled == True;
}
- (BOOL)isComposing {
  return self->rimeStatus->is_composing == True;
}
- (BOOL)isAsciiMode {
  return self->rimeStatus->is_ascii_mode == True;
}
- (BOOL)isFullShape {
  return self->rimeStatus->is_full_shape == True;
}
- (BOOL)isSimplified {
  return self->rimeStatus->is_simplified == True;
}
- (BOOL)isTraditional {
  return self->rimeStatus->is_traditional == True;
}
- (BOOL)isAsciiPunct {
  return self->rimeStatus->is_ascii_punct == True;
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
    self->rimeCandidateListIterator = iterator;
  }
}

- (NSObject *)ptr {
  if (self->rimeCandidateListIterator == nil) {
    return nil;
  }
  return CFBridgingRelease(self->rimeCandidateListIterator->ptr);
}
- (int)index {
  if (self->rimeCandidateListIterator == nil) {
    return nil;
  }
  return self->rimeCandidateListIterator->index;
}
- (IRimeCandidate *)candidate {
  if (self->rimeCandidateListIterator == nil) {
    return nil;
  }
  return [[IRimeCandidate alloc]
          initWithCandidate:&self->rimeCandidateListIterator->candidate];
}

- (RimeCandidateListIterator *)rimeCandidateListIterator {
  return self->rimeCandidateListIterator;
}

@end

@implementation IRimeConfig {
  RimeConfig *config;
}

// 参考 IRimeCandidateListIterator.ptr
- (NSObject *)ptr {
  if (self->config == nil) {
    return nil;
  }
  return CFBridgingRelease(self->config->ptr);
}

- (RimeConfig *)config {
  return self->config;
}

@end

@implementation IRimeConfigIterator {
  RimeConfigIterator *iterator;
}

- (NSObject *)list {
  if (self->iterator == nil) {
    return nil;
  }
  return CFBridgingRelease(self->iterator->list);
}
- (NSObject *)map {
  if (self->iterator == nil) {
    return nil;
  }
  return CFBridgingRelease(self->iterator->map);
}

- (int)index {
  if (self->iterator == nil) {
    return 0;
  }
  return self->iterator->index;
}
- (NSString *)key {
  if (self->iterator == nil) {
    return nil;
  }
  return @(self->iterator->key);
}
- (NSString *)path {
  
  if (self->iterator == nil) {
    return nil;
  }
  return @(self->iterator->path);
}

- (RimeConfigIterator *)iterator {
  return self->iterator;
}
@end

@implementation IRimeSchemaListItem {
  RimeSchemaListItem *item;
}

- (id)initWithItem:(RimeSchemaListItem *)item {
  if ((self = [super init]) != nil) {
    self->item = item;
  }
  return self;
}

- (NSString *)schemaId {
  if (self->item == nil) {
    return nil;
  }
  return @(self->item->schema_id);
}
- (NSString *)name {
  if (self->item == nil) {
    return nil;
  }
  return @(self->item->name);
}
- (NSObject *)reserved {
  if (self->item == nil) {
    return nil;
  }
  return CFBridgingRelease(self->item->reserved);
}

@end

@implementation IRimeSchemaList {
  RimeSchemaList *schemalist;
}

- (id)initWithSchemaList:(RimeSchemaList *)list {
  if ((self = [super init]) != nil) {
    self->schemalist = list;
  }
  return self;
}

- (NSArray<IRimeSchemaListItem *> *)list {
  if (self->schemalist == nil) {
    return nil;
  }
  size_t count = self->schemalist->size;
  if (!count) {
    return nil;
  }
  
  RimeSchemaListItem *list = self->schemalist->list;
  NSMutableArray<IRimeSchemaListItem *> *r =
  [NSMutableArray arrayWithCapacity:count];
  for (int i = 0; i < count; i++) {
    RimeSchemaListItem item = list[i];
    [r addObject:[[IRimeSchemaListItem alloc] initWithItem:&item]];
  }
  return [NSArray arrayWithArray:r];
}

- (RimeSchemaList *)schemalist {
  return self->schemalist;
}

@end

@implementation IRimeCustomApi {
  RimeCustomApi *customApi;
}

- (id)initWithCustomApi:(RimeCustomApi *)api {
  if ((self = [super init]) != nil) {
    self->customApi = api;
  }
  return self;
}

- (int)dataSize {
  if (self->customApi == nil) {
    return 0;
  }
  return self->customApi->data_size;
}

- (RimeCustomApi *)customApi {
  return self->customApi;
}

@end

/**
 封装 rime_api.h 结构  RimeModule
 */
@implementation IRimeModule {
  RimeModule *module;
}

- (id)initWithModule:(RimeModule *)module {
  if ((self = [super init]) != nil) {
    self->module = module;
  }
  return self;
}

- (NSString *)moduleName {
  if (self->module == nil) {
    return nil;
  }
  return @(self->module->module_name);
}

- (void)initialize {
  if (self->module == nil) {
    return;
  }
  
  self->module->initialize();
}
- (void)finalize {
  if (self->module == nil) {
    return;
  }
  
  self->module->finalize();
}
- (IRimeCustomApi *)getApi {
  if (self->module == nil) {
    return;
  }
  RimeCustomApi *api = self->module->get_api();
  return [[IRimeCustomApi alloc] initWithCustomApi:api];
}

- (RimeModule *)module {
  return self->module;
}

@end

// RimeEngin 实现

@implementation RimeAPI

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
  
  rime_get_api()->set_notification_handler(rimeNotificationHandler,
                                           (__bridge void *)ctx);
}

// Setup

// 在访问任何其他API之前调用这个函数。
- (void)setup:(IRimeTraits *)traits {
  rime_get_api()->setup([traits rimeTraits]);
}

// Entry and exit

- (void)initialize:(IRimeTraits *)traits {
  if (traits == NULL) {
    rime_get_api()->initialize(NULL);
    return;
  }
  rime_get_api()->initialize([traits rimeTraits]);
}

- (void)finalize {
  rime_get_api()->finalize();
}

- (BOOL)startMaintenance:(BOOL)fullCheck {
  return rime_get_api()->start_maintenance(fullCheck ? True : False) == True;
}
- (BOOL)isMaintenancing {
  return rime_get_api()->is_maintenance_mode() == True;
}
- (void)joinMaintenanceThread {
  rime_get_api()->join_maintenance_thread();
}

// Deployment

- (void)deployerInitialize:(IRimeTraits *)traits {
  rime_get_api()->deployer_initialize([traits rimeTraits]);
}
- (BOOL)prebuildAllSchemas {
  return rime_get_api()->prebuild() == True;
}
- (BOOL)deployWorkspace {
  return rime_get_api()->deploy() == True;
}
- (BOOL)deploySchema:(NSString *)schemaFile {
  return rime_get_api()->deploy_schema([schemaFile UTF8String]) == True;
}
- (BOOL)deployConfigFile:(NSString *)fileName versionKey:(NSString *)key {
  return rime_get_api()->deploy_config_file([fileName UTF8String],
                                            [key UTF8String]) == True;
}

- (BOOL)syncUserData {
  return rime_get_api()->sync_user_data();
}

// Session management

- (IRimeSessionId)createSession {
  RimeSessionId sessionId = rime_get_api()->create_session();
  return (IRimeSessionId)sessionId;
}
- (BOOL)findSession:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api()->find_session(sessionId) == True;
}
- (BOOL)destroySession:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api()->destroy_session(sessionId) == True;
}
- (void)cleanupStaleSessions {
  rime_get_api()->cleanup_stale_sessions();
}
- (void)cleanupAllSessions {
  rime_get_api()->cleanup_all_sessions();
}

// Input

- (BOOL)processKey:(IRimeSessionId)session keycode:(int)code mask:(int)mask {
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api()->process_key(sessionId, code, mask) == True;
}
/*!
 * return True if there is unread commit text
 */
- (BOOL)commitComposition:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api()->commit_composition(sessionId) == True;
}

- (void)clearComposition:(IRimeSessionId)session;
{
  RimeSessionId sessionId = (RimeSessionId)session;
  rime_get_api()->clear_composition(sessionId);
}

// Output

- (NSString *)getInput:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  const char *input = rime_get_api()->get_input(sessionId);
  if (input != NULL) {
    return [NSString stringWithUTF8String:input];
  }
  return nil;
}

- (IRimeCommit *)getCommit:(IRimeSessionId)session;
{
  RimeSessionId sessionId = (RimeSessionId)session;
  RIME_STRUCT(RimeCommit, rimeCommit);
  if (rime_get_api()->get_commit(sessionId, &rimeCommit) == True) {
    IRimeCommit *commit = [[IRimeCommit alloc] initWithRimeCommit:&rimeCommit];
    return commit;
  }
  return nil;
}
- (BOOL)freeCommit:(IRimeCommit *)commit {
  return rime_get_api()->free_commit([commit rimeCommit]) == True;
}

- (IRimeContext *)getContext:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  RIME_STRUCT(RimeContext, rimeContext);
  if (rime_get_api()->get_context(sessionId, &rimeContext) == True) {
    return [[IRimeContext alloc] initWithContext:&rimeContext];
  }
  return nil;
}
- (BOOL)freeContext:(IRimeContext *)context;
{ return rime_get_api()->free_context([context rimeContext]) == True; }

- (IRimeStatus *)getStatus:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  RIME_STRUCT(RimeStatus, rimeStatus);
  if (rime_get_api()->get_status(sessionId, &rimeStatus) == True) {
    return [[IRimeStatus alloc] initWithStatus:&rimeStatus];
  }
  return nil;
}

- (BOOL)freeStatus:(IRimeStatus *)status;
{ return rime_get_api()->free_status([status rimeStatus]) == True; }

// Accessing candidate list
- (IRimeCandidateListIterator *)candidateListBegin:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  RimeCandidateListIterator iterator = {0};
  if (rime_get_api()->candidate_list_begin(sessionId, &iterator) == True) {
    return [[IRimeCandidateListIterator alloc] initWithIterator: &iterator];
  }
  return nil;
}
- (BOOL)candidateListNext:(IRimeCandidateListIterator *)iterator {
  return rime_get_api()->candidate_list_next([iterator rimeCandidateListIterator]) == True;
}
- (void)candidateListEnd:(IRimeCandidateListIterator *)iterator {
  rime_get_api()->candidate_list_end([iterator rimeCandidateListIterator]);
}

- (IRimeCandidateListIterator *)candidateListFromIndex:(IRimeSessionId)session
                                                 index:(int)index {
  RimeSessionId sessionId = (RimeSessionId)session;
  RimeCandidateListIterator iterator = {0};
  if (rime_get_api()->candidate_list_from_index(sessionId, &iterator, index) == True) {
    return [[IRimeCandidateListIterator alloc] initWithIterator: &iterator];
  }
  return nil;
}

// Runtime options

- (void)setOption:(IRimeSessionId)session
           option:(NSString *)option
            value:(BOOL)value {
  RimeSessionId sessionId = (RimeSessionId)session;
  rime_get_api()->set_option(sessionId, [option UTF8String],
                             value ? True : False);
}
- (BOOL)getOption:(IRimeSessionId)session option:(NSString *)option {
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api()->get_option(sessionId, [option UTF8String]) == True;
}

- (void)setProperty:(IRimeSessionId)session
               prop:(NSString *)prop
              value:(NSString *)value {
  RimeSessionId sessionId = (RimeSessionId)session;
  rime_get_api()->set_property(sessionId, [prop UTF8String],
                               [value UTF8String]);
}
- (NSString *)getProperty:(IRimeSessionId)session prop:(NSString *)prop {
  char value[256];
  value[sizeof value - 1] = 0; // Compliant Solution: might silently truncate,
  if (rime_get_api()->get_property(session, [prop UTF8String], value,
                                   sizeof(value)) == True) {
    return [NSString stringWithUTF8String:value];
  }
  return nil;
}

- (IRimeSchemaList *)getSchemaList {
  RimeSchemaList list;
  if (rime_get_api()->get_schema_list(&list) == True) {
    return [[IRimeSchemaList alloc] initWithSchemaList: &list];
  }
  return nil;
}

- (void)freeSchemaList:(IRimeSchemaList *)list {
  rime_get_api()->free_schema_list([list schemalist]);
}

- (NSString *)getCurrentSchema:(IRimeSessionId)session {
  RimeSessionId sessionId = (RimeSessionId)session;
  NSLog(@"session = %lu", sessionId);
  char current[100] = {0};
  if (rime_get_api()->get_current_schema(sessionId, current, sizeof(current))) {
    NSLog(@"current schema = %s", current);
    return [NSString stringWithUTF8String:current];
  }
  return nil;
}

- (BOOL)selectSchema:(IRimeSessionId)session schemeId:(NSString *)schema {
  RimeSessionId sessionId = (RimeSessionId)session;
  return rime_get_api()->select_schema(sessionId, [schema UTF8String]) == True;
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
  return rime_get_api()->simulate_key_sequence(sessionId,
                                               [sequence UTF8String]) == True;
}

// Module

- (BOOL)registerModule:(IRimeModule *)module {
  rime_get_api()->register_module([module module]);
}
- (IRimeModule *)findModule:(NSString *)moduleName {
  RimeModule *module = rime_get_api()->find_module([moduleName UTF8String]);
  return [[IRimeModule alloc] initWithModule:module];
}
//
////! Run a registered task
//- (BOOL) runTask:(NSString *) task_name;
//
- (NSString *)getSharedDataDir {
  return [NSString stringWithUTF8String:rime_get_api()->get_shared_data_dir()];
}
- (NSString *)getUserDataDir {
  return [NSString stringWithUTF8String:rime_get_api()->get_user_data_dir()];
}
- (NSString *)getSyncDir {
  return [NSString stringWithUTF8String:rime_get_api()->get_sync_dir()];
}
- (NSString *)getUserId {
  return [NSString stringWithUTF8String:rime_get_api()->get_user_id()];
}

@end
