#import "RimeEngine.h"
#import "rime_api.h"
#import "macos_keycode.h"
#import <Foundation/Foundation.h>

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
  if (modules != nil && [modules count]) {
    NSUInteger count = [modules count];
    const char *rimeModules[count];
    for (int i = 0; i < count; i++) {
      rimeModules[i] = [modules[i] UTF8String];
    }
    rimeTraits->modules = rimeModules;
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
  
  return &rimeTraits;
}

@end

@interface Schema : NSObject {
  NSString *schemaId;
  NSString *schemaName;
}

@property NSString *schemaId;
@property NSString *schemaName;

- (id)initWithSchemaId:(NSString *)schemaId andSchemaName:(NSString *)name;

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
  [self start:traits WithFullCheck:TRUE];
}

- (void)setup:(IRimeTraits *)traits {
  RimeSetNotificationHandler(rimeNotificationHandler, (__bridge void *)self);
  
  RIME_STRUCT(RimeTraits, rimeTraits);
  [traits rimeTraits:&rimeTraits];
  RimeSetup(&rimeTraits);
}

- (void)start:(IRimeTraits *)traits WithFullCheck:(BOOL)check {
  if (traits == nil) {
    RimeInitialize(NULL);
  } else {
    RIME_STRUCT(RimeTraits, rimeTraits);
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

// MARK: test method

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

- (NSString *)currentSchema {
  @autoreleasepool {
    char current[100] = {0};
    if (RimeGetCurrentSchema(session, current, sizeof(current))) {
      return @(current);
    }
    return @("");
  }
}

- (BOOL)processKey:(NSString *)keyCode {
  @autoreleasepool {
    const char *code = [keyCode UTF8String][0];
    // TODO: key mark attr
    return RimeProcessKey([self session], code, 0);
  }
}

- (BOOL)processKey:(NSString *)keyCode modifiers: (int) modifier {
  
}

- (NSArray<NSString *> *)candidateList {
  @autoreleasepool {
    RimeCandidateListIterator iterator = {0};
    if (!RimeCandidateListBegin(session, &iterator)) {
      NSLog(@"get candidate list error");
      return nil;
    }
    NSMutableArray<NSString *> *list = [NSMutableArray array];
    while (RimeCandidateListNext(&iterator)) {
      NSLog(@"candidate text: %s, comment: %s", iterator.candidate.text,
            iterator.candidate.comment);
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

- (void) context {
  
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

- (void)debugInfo {
  @autoreleasepool {
    // print schema list
    NSLog(@"schema list: %@", [self schemaList]);
    
    // session
    if (![self session]) {
      NSLog(@"session error!!!");
      return;
    }
    
    NSLog(@"Session = %lu", session);
    
    // currentSchema
    NSLog(@"current schema = %@", [self currentSchema]);
    
    // input key
    if (![self processKey:@"u"]) {
      NSLog(@"input key error");
    }
    
    
    // context
    RIME_STRUCT(RimeContext, ctx);
    if (rime_get_api()->get_context(session, &ctx)) {
      
      // update preedit text
      const char *preedit = ctx.composition.preedit;
      NSString *preeditText = preedit ? @(preedit) : @"";
      NSLog(@"context preeidt text: %@", preeditText);
      const char *candidatePreview = ctx.commit_text_preview;
      NSString *candidatePreviewText = candidatePreview ? @(candidatePreview) : @"";
      NSLog(@"candidate preview text: %@", candidatePreviewText);
      
      
      //      NSUInteger start = utf8len(preedit, ctx.composition.sel_start);
      //      NSUInteger end = utf8len(preedit, ctx.composition.sel_end);
      //      NSUInteger caretPos = utf8len(preedit, ctx.composition.cursor_pos);
      //      NSRange selRange = NSMakeRange(start, end - start);
      
      // update candidates
      NSMutableArray *candidates = [NSMutableArray array];
      NSMutableArray *comments = [NSMutableArray array];
      NSUInteger i;
      for (i = 0; i < ctx.menu.num_candidates; ++i) {
        [candidates addObject:@(ctx.menu.candidates[i].text)];
        if (ctx.menu.candidates[i].comment) {
          [comments addObject:@(ctx.menu.candidates[i].comment)];
        }
        else {
          [comments addObject:@""];
        }
      }
      NSArray* labels;
      if (ctx.menu.select_keys) {
        labels = @[@(ctx.menu.select_keys)];
      } else if (ctx.select_labels) {
        NSMutableArray *selectLabels = [NSMutableArray array];
        for (i = 0; i < ctx.menu.page_size; ++i) {
          char* label_str = ctx.select_labels[i];
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
    
//    NSLog(@"commit text: commit composition %@", [self getCommit]);
//    [self printStatus];
//
//    const char *input = rime_get_api() -> get_input(session);
//    NSLog(@"get input text: %s", input);
//    if (![self processKey:@"o"]) {
//      NSLog(@"input key error");
//    }
    
//    // candidate list
//    NSArray<NSString *> *candidateList = [self candidateList];
//    NSLog(@"candidateList: %@", candidateList);
//
//    NSLog(@"commit text: commit composition befor %@", [self getCommit]);
//
//    // 提交候选字
//    // commit composition
//    [self commitComposition];
//
//    // 获取提交的字
//    NSLog(@"commit text: commit composition %@", [self getCommit]);
//
//    // 清除候选字
//    // clean composition
//    [self cleanComposition];
//
//    NSLog(@"commit text: clean composition %@", [self getCommit]);
//
//    // status
//    [self printStatus];
//
//    // 繁体模式
//    [self simplification:false];
//
//    // input key
//    if (![self processKey:@"u"]) {
//      NSLog(@"input key error");
//    }
//    if (![self processKey:@"o"]) {
//      NSLog(@"input key error");
//    }
//    candidateList = [self candidateList];
//    NSLog(@"candidateList: set ascii_mode %@", candidateList);
//    NSLog(@"commit text: set ascii_mode %@", [self getCommit]);
//
//    // status
//    [self printStatus];
//
//    // 设置英文模式
//    //    [self asciiMode:true];
  }
}

@end
