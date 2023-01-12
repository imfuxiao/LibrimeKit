#import "irime_api.h"
#import "rime_api.h"

static id<IRimeNotificationDelegate> notificationDelegate = nil;

static void rimeNotificationHandler(void *contextObject,
                                    RimeSessionId sessionId,
                                    const char *messageType,
                                    const char *messageValue) {
  
  if (notificationDelegate == NULL || messageValue == NULL) {
    return;
  }
  
  // on deployment
  if (!strcmp(messageType, "deploy")) {
    
    if (!strcmp(messageValue, "start")) {
      [notificationDelegate onDelployStart];
      return;
    }
    
    if (!strcmp(messageValue, "success")) {
      [notificationDelegate onDeploySuccess];
      return;
    }
    
    if (!strcmp(messageValue, "failure")) {
      [notificationDelegate onDeployFailure];
      return;
    }
    
    return;
  }
  
  // TODO: 对context_object处理
  //  id app_delegate = (__bridge id)context_object;
  //  if (app_delegate && ![app_delegate enableNotifications]) {
  //    return;
  //  }
  
  // on loading schema
  if (!strcmp(messageType, "schema")) {
    [notificationDelegate
     onLoadingSchema:[NSString stringWithUTF8String:messageValue]];
    return;
  }
  
  // on changing mode:
  if (!strcmp(messageType, "option")) {
    [notificationDelegate
     onChangeMode:[NSString stringWithUTF8String:messageValue]];
    return;
  }
}

@implementation IRimeTraits

@synthesize sharedDataDir;
@synthesize userDataDir;
@synthesize distributionName;
@synthesize distributionCodeName;
@synthesize distributionVersion;
@synthesize appName;
@synthesize modules;
@synthesize minLogLevel;
@synthesize logDir;
@synthesize prebuiltDataDir;
@synthesize stagingDir;

- (void)rimeTraits:(RimeTraits *)rimeTraits {
  @autoreleasepool {
    
    if (sharedDataDir != nil) {
      rimeTraits->shared_data_dir = [sharedDataDir UTF8String];
    }
    if (userDataDir != nil) {
      rimeTraits->user_data_dir = [userDataDir UTF8String];
    }
    if (distributionName != nil) {
      rimeTraits->distribution_name = [distributionName UTF8String];
    }
    if (distributionCodeName != nil) {
      rimeTraits->distribution_code_name = [distributionCodeName UTF8String];
    }
    if (distributionVersion != nil) {
      rimeTraits->distribution_version = [distributionVersion UTF8String];
    }
    if (appName != nil) {
      rimeTraits->app_name = [appName UTF8String];
    }
    rimeTraits->min_log_level = minLogLevel;
    if (logDir != nil) {
      rimeTraits->log_dir = [logDir UTF8String];
    }
    if (prebuiltDataDir != nil) {
      rimeTraits->prebuilt_data_dir = [prebuiltDataDir UTF8String];
    }
    if (stagingDir != nil) {
      rimeTraits->staging_dir = [stagingDir UTF8String];
    }
  }
}

@end

@implementation Schema

@synthesize schemaId, schemaName;

- (id)initWithSchemaId:(NSString *)d andSchemaName:(NSString *)name {
  if ((self = [super init]) != nil) {
    schemaId = d;
    schemaName = name;
  }
  return self;
}

- (NSString *)description {
  return
  [NSString stringWithFormat:@"id = %@, name = %@", schemaId, schemaName];
}

@end

const NSString *asciiMode = @"ascii_mode";
const NSString *simplifiedMode = @"simplification";

// RimeEngin 实现

@implementation IRimeAPI {
  RimeSessionId session;
}

- (void)setNotificationDelegate:(id<IRimeNotificationDelegate>)delegate {
  notificationDelegate = delegate;
}

- (void)startRimeServer:(IRimeTraits *)traits {
  [self setup:traits];
  [self start:traits WithFullCheck:true];
}

- (void)setup:(IRimeTraits *)traits {
  RimeSetNotificationHandler(rimeNotificationHandler, (__bridge void *)self);
  
  RIME_STRUCT(RimeTraits, rimeTraits);
  // MARK: 需要在调用rimeTraits方法前先分配好module数组的空间大小,
  // 方法内数组变量在方法结束后会被释放.
  NSUInteger count = [traits.modules count];
  const char *modules[count + 1];
  modules[count] = NULL;
  rimeTraits.modules = modules;
  for (int i = 0; i < count; i++) {
    modules[i] = [traits.modules[i] UTF8String];
  }
  [traits rimeTraits:&rimeTraits];
  RimeSetup(&rimeTraits);
}

- (void)start:(IRimeTraits *)traits WithFullCheck:(BOOL)check {
  if (traits == nil) {
    RimeInitialize(NULL);
  } else {
    RIME_STRUCT(RimeTraits, rimeTraits);
    // MARK: 需要在调用rimeTraits方法前先分配好module数组的空间大小,
    // 方法内数组变量在方法结束后会被释放.
    NSUInteger count = [traits.modules count];
    const char *modules[count + 1];
    modules[count] = NULL;
    rimeTraits.modules = modules;
    for (int i = 0; i < count; i++) {
      modules[i] = [traits.modules[i] UTF8String];
    }
    [traits rimeTraits:&rimeTraits];
    RimeInitialize(&rimeTraits);
  }
  
  // check for configuration updates
  if (RimeStartMaintenance((Bool)check)) {
    RimeJoinMaintenanceThread();
    
    // update squirrel config
    RimeDeployConfigFile("squirrel.yaml", "config_version");
  }
}

- (void)shutdown {
  RimeCleanupAllSessions();
  RimeFinalize();
}

- (BOOL)isAlive {
  if (session && RimeFindSession(session)) {
    return true;
  }
  return false;
}

- (RimeSessionId)session {
  if (session && RimeFindSession(session)) {
    return session;
  }
  session = RimeCreateSession();
  return session;
}

- (NSArray<Schema *> *)schemaList {
  @autoreleasepool {
    RimeSchemaList list;
    if (RimeGetSchemaList(&list)) {
      size_t count = list.size;
      NSMutableArray *r = [NSMutableArray arrayWithCapacity:count];
      RimeSchemaListItem *items = list.list;
      for (int i = 0; i < count; i++) {
        RimeSchemaListItem item = items[i];
        [r addObject:[[Schema alloc] initWithSchemaId:@(item.schema_id)
                                        andSchemaName:@(item.name)]];
      }
      RimeFreeSchemaList(&list);
      return [NSArray arrayWithArray:r];
    }
    return nil;
  }
}

- (Schema *)currentSchema {
  @autoreleasepool {
    Schema *s = [[Schema alloc] init];
    RIME_STRUCT(RimeStatus, rimeStatus);
    if (RimeGetStatus(session, &rimeStatus)) {
      [s setSchemaId:@(rimeStatus.schema_id)];
      [s setSchemaName:@(rimeStatus.schema_name)];
    }
    RimeFreeStatus(&rimeStatus);
    return s;
  }
}

- (BOOL)selectSchema:(NSString *)schemaId {
  return RimeSelectSchema(session, [schemaId UTF8String]);
}

- (BOOL)processKey:(NSString *)keyCode {
  [self processKey:keyCode modifiers:0];
}

- (BOOL)processKey:(NSString *)keyCode modifiers:(int)modifier {
  @autoreleasepool {
    const char *code = [keyCode UTF8String][0];
    // TODO: code转换
    return RimeProcessKey([self session], code, modifier);
  }
}

- (NSArray<NSString *> *)candidateList {
  @autoreleasepool {
    RimeCandidateListIterator iterator = {0};
    if (!RimeCandidateListBegin(session, &iterator)) {
#if DEBUG
      NSLog(@"get candidate list error");
#endif
      return nil;
    }
    NSMutableArray<NSString *> *list = [NSMutableArray array];
    while (RimeCandidateListNext(&iterator)) {
#if DEBUG
      NSLog(@"candidate text: %s, comment: %s", iterator.candidate.text,
            iterator.candidate.comment);
#endif
      [list addObject:@(iterator.candidate.text)];
    }
    RimeCandidateListEnd(&iterator);
    return [NSArray arrayWithArray:list];
  }
}

- (BOOL)commitComposition {
  @autoreleasepool {
    return RimeCommitComposition(session);
  }
}

- (void)cleanComposition {
  @autoreleasepool {
    RimeClearComposition(session);
  }
}

- (NSString *)getInput {
  @autoreleasepool {
    const char *input = rime_get_api()->get_input(session);
    return input ? @(input) : @("");
  }
}

- (NSString *)getCommit {
  @autoreleasepool {
    RIME_STRUCT(RimeCommit, rimeCommit);
    if (!RimeGetCommit([self session], &rimeCommit)) {
      return nil;
    }
    NSString *commitText = @(rimeCommit.text);
    RimeFreeCommit(&rimeCommit);
    return commitText;
  }
}

- (BOOL)isAsciiMode {
  @autoreleasepool {
    return RimeGetOption([self session], [asciiMode UTF8String]);
  }
}

- (BOOL)isSimplifiedMode {
  @autoreleasepool {
    return RimeGetOption([self session], [simplifiedMode UTF8String]);
  }
}

- (void)asciiMode:(BOOL)value {
  @autoreleasepool {
    RimeSetOption([self session], [asciiMode UTF8String], value ? True : False);
  }
}

- (void)simplification:(BOOL)value {
  @autoreleasepool {
    RimeSetOption([self session], [simplifiedMode UTF8String],
                  value ? True : False);
  }
}

- (void)printContext {
  @autoreleasepool {
    // context
    RIME_STRUCT(RimeContext, ctx);
    if (RimeGetContext(session, &ctx)) {
      
      // update preedit text
      const char *preedit = ctx.composition.preedit;
      NSString *preeditText = preedit ? @(preedit) : @"";
      NSLog(@"context preeidt text: %@", preeditText);
      
      const char *candidatePreview = ctx.commit_text_preview;
      NSString *candidatePreviewText =
      candidatePreview ? @(candidatePreview) : @"";
      NSLog(@"candidate preview text: %@", candidatePreviewText);
      
      // update candidates
      NSMutableArray *candidates = [NSMutableArray array];
      NSMutableArray *comments = [NSMutableArray array];
      NSUInteger i;
      for (i = 0; i < ctx.menu.num_candidates; ++i) {
        [candidates addObject:@(ctx.menu.candidates[i].text)];
        if (ctx.menu.candidates[i].comment) {
          [comments addObject:@(ctx.menu.candidates[i].comment)];
        } else {
          [comments addObject:@""];
        }
      }
      NSArray *labels;
      if (ctx.menu.select_keys) {
        labels = @[ @(ctx.menu.select_keys) ];
      } else if (ctx.select_labels) {
        NSMutableArray *selectLabels = [NSMutableArray array];
        for (i = 0; i < ctx.menu.page_size; ++i) {
          char *label_str = ctx.select_labels[i];
          [selectLabels addObject:@(label_str)];
        }
        labels = selectLabels;
      } else {
        labels = @[];
      }
      rime_get_api()->free_context(&ctx);
      
      NSLog(@"candidates: %@", candidates);
      NSLog(@"comments: %@", comments);
      NSLog(@"labels: %@", labels);
    }
    RimeFreeContext(&ctx);
  }
}

- (void)printStatus {
  @autoreleasepool {
    RIME_STRUCT(RimeStatus, rimeStatus);
    if (!RimeGetStatus(session, &rimeStatus)) {
      NSLog(@"get status error");
      return;
    }
    NSLog(@"current status: schema_id = %s, schema_name = %s,\n ascii_mode = "
          @"%d, ascii_punct = %d, composing = %d, disaled = %d, full_shape = "
          @"%d, simplified = %d, traditional = %d",
          rimeStatus.schema_id, rimeStatus.schema_name,
          rimeStatus.is_ascii_mode, rimeStatus.is_ascii_punct,
          rimeStatus.is_composing, rimeStatus.is_disabled,
          rimeStatus.is_full_shape, rimeStatus.is_simplified,
          rimeStatus.is_traditional);
    RimeFreeStatus(&rimeStatus);
  }
}

- (void)simulateKeySequence:(NSString *)keys {
  NSLog(@"input keys = %@", keys);
  RimeSessionId s = [self session];
  const char *codes = [keys UTF8String];
  RimeSimulateKeySequence(s, codes);
  [self printStatus];
  [self printContext];
}

@end
