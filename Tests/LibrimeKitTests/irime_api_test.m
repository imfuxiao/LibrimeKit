#import "irime_api.h"
#import <XCTest/XCTest.h>

static int Backspace = 0xff08; //
static int Return = 0xff0d;    //
static int QuoteLeft = 0x0060; // 反引号(`), 标准键盘数字1左边的键
static int Plus = 0x002b;      // +
static int Minus = 0x002d;     // -
static int Comma = 0x002c;     // ,
static int Period = 0x002e;    // .
static int BracketLeft = 0x005b;  // [
static int BracketRight = 0x005d; // ]

static NSString *bundleName = @"LibrimeKit_LibrimeKitTests.bundle";
static NSString *rimeTempDirectoryName = @"rime";
static NSString *sharedSupportDirectoryName = @"SharedSupport";
static NSString *userDirectoryName = @"user";

@interface irime_api_test : XCTestCase <IRimeNotificationDelegate>
@end

@implementation irime_api_test {
}

- (void)onChangeMode:(NSString *)mode {
  NSLog(@"rime notifition: change mode: %@", mode);
}

- (void)onDeployStart {
  NSLog(@"rime notifition: deploy start");
}

- (void)onDeployFailure {
  NSLog(@"rime notifition: deploy failure");
}

- (void)onDeploySuccess {
  NSLog(@"rime notifition: deploy success");
}

- (void)onLoadingSchema:(NSString *)schema {
  NSLog(@"rime notifition: loading schema %@", schema);
}

- (NSURL *)tempRimeURL {
  NSFileManager *fm = [NSFileManager defaultManager];
  return [fm temporaryDirectory];
}

- (NSURL *)tempSharedSupportURL {
  return [[self tempRimeURL]
          URLByAppendingPathComponent:sharedSupportDirectoryName];
}

- (NSURL *)tempUserURL {
  return [[self tempRimeURL] URLByAppendingPathComponent:userDirectoryName];
}

- (NSBundle *)resourcesBundle {
  NSURL *url = [[NSBundle bundleForClass:irime_api_test.class] resourceURL];
  url = [url URLByDeletingLastPathComponent];
  url = [url URLByAppendingPathComponent:bundleName];
  return [NSBundle bundleWithURL:url];
}

- (void)syncTestResource {
  NSBundle *testResourceBundle = [self resourcesBundle];
  NSURL *resourceURL = [testResourceBundle resourceURL];
  NSLog(@"test resources url: %@", [resourceURL path]);
  
  NSURL *sharedSupportURL =
  [resourceURL URLByAppendingPathComponent:sharedSupportDirectoryName];
  NSURL *userURL = [resourceURL URLByAppendingPathComponent:userDirectoryName];
  
  NSFileManager *fm = [NSFileManager defaultManager];
  NSError *err;
  
  NSURL *tempRimeURL = [self tempRimeURL];
  NSLog(@"temp dir: %@", [tempRimeURL path]);
  
  if ([fm fileExistsAtPath:[tempRimeURL path]]) {
    [fm removeItemAtURL:tempRimeURL error:NULL];
  }
  
  [fm createDirectoryAtURL:tempRimeURL
withIntermediateDirectories:TRUE
                attributes:NULL
                     error:NULL];
  [fm copyItemAtURL:sharedSupportURL
              toURL:[self tempSharedSupportURL]
              error:NULL];
  [fm copyItemAtURL:userURL toURL:[self tempUserURL] error:NULL];
}

- (void)setUp {
  [self syncTestResource];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
}

- (IRimeAPI *)startRime {
  return [self startRime:[[self tempSharedSupportURL] path]
             andUserPath:[[self tempUserURL] path]];
}

- (IRimeAPI *)startRime:(NSString *)sharedSupportPath
            andUserPath:(NSString *)userPath {
  IRimeTraits *traits = [[IRimeTraits alloc] init];
  [traits setSharedDataDir:sharedSupportPath];
  [traits setUserDataDir:userPath];
  [traits setAppName:@"rime.hamster"];
  [traits setDistributionName:@"仓鼠"];
  [traits setDistributionCodeName:@"Hamster"];
  
  IRimeAPI *api = [[IRimeAPI alloc] init];
  [api setNotificationDelegate:self];
  [api setup:traits];
  [api preBuildAllSchemas];
  [api initialize:traits];
  RimeSessionId session =  [api createSession];
  printf(@"session %lu", session);
//  [api startMaintenance:true];
  return api;
}

- (void)testRimeAPI {
  IRimeAPI *rimeAPI = [self startRime];
  RimeSessionId session = 0;
  while (session == 0) {
    session = [rimeAPI createSession];
  }
  XCTAssertTrue(session > 0);
  
  IRimeStatus *state = [rimeAPI getStatus:session];
  printf("state: %@", state);
  [rimeAPI selectSchema:session andSchemaId:@"stroke"];
  state = [rimeAPI getStatus:session];
  printf("state: %@", state);
  
  NSArray<IRimeSchema *> *list = [rimeAPI schemaList];
  for (IRimeSchema *schema in list) {
    NSLog(@"schemaId = %@, schemaName = %@", schema.schemaId, schema.schemaName);
  }
  XCTAssertTrue(list.count > 0);
  
  
  [rimeAPI processKey:@"`" andSession:session];
  NSArray<IRimeCandidate* > *candidates = [rimeAPI getCandidateList: session];
  XCTAssertTrue(candidates.count > 0);
  NSLog(@"candidates[0].text = %@", candidates[0].text);
}

- (void)testConfigValue {
  IRimeAPI *rimeAPI = [self startRime];
  RimeSessionId session = 0;
  while (session == 0) {
    session = [rimeAPI createSession];
  }
  IRimeConfig *schemaConfig = [rimeAPI openSchema:@"bopomofo"];
  XCTAssertNotNil(schemaConfig);
  
  NSString *value = [schemaConfig getString:@"schema/schema_id"];
  NSLog(@"schema/schema_id: %@", value);
  XCTAssertTrue([@"bopomofo" isEqual:value]);
}

-(void) testLevelsAPI {
  IRimeAPI *rimeAPI = [self startRime];
  NSArray<IRimeSchema *> *schemas = [rimeAPI schemaList];
  for (IRimeSchema *schema in schemas) {
    NSLog(@"rime schemas schema_id %@, schema_name %@", schema.schemaId, schema.schemaName);
  }
  XCTAssertTrue(schemas.count > 0);
  
  NSLog(@"rime is first run: %@", [rimeAPI isFirstRun] ? @"True" : @"False");
  
  NSArray<NSString *> *selectSchemas = @[@"stroke"];
  for (NSString *schemaId in selectSchemas) {
    NSLog(@"rime pre set schema_id %@", schemaId);
  }
  
  // 重置完需要重启rime
  BOOL handled = [rimeAPI selectRimeSchemas: selectSchemas];
  NSLog(@"selectRimeSchema handled: %@", handled ? @"true" : @"false");
  
  [rimeAPI startMaintenance: true];
  NSLog(@"rime is first run: %@", [rimeAPI isFirstRun] ? @"True" : @"False");
  
  NSArray<IRimeSchema *> *availableSchemas = [rimeAPI getAvailableRimeSchemaList];
  XCTAssertTrue(availableSchemas.count > 0);
  for (IRimeSchema *schema in availableSchemas) {
    NSLog(@"available schema_id %@, schema_name %@", schema.schemaId, schema.schemaName);
  }
  
  NSArray<IRimeSchema *> *getSelectRimeSchemaList = [rimeAPI getSelectedRimeSchemaList];
  XCTAssertTrue(getSelectRimeSchemaList.count > 0);
  for (IRimeSchema *schema in getSelectRimeSchemaList) {
    NSLog(@"getSelectRimeSchemaList schema_id %@, schema_name %@", schema.schemaId, schema.schemaName);
  }
}

-(void) testHotKey {
  IRimeAPI *rimeAPI = [self startRime];
  NSArray<IRimeSchema *> *getSelectRimeSchemaList = [rimeAPI getSelectedRimeSchemaList];
  XCTAssertTrue(getSelectRimeSchemaList.count > 0);
  for (IRimeSchema *schema in getSelectRimeSchemaList) {
    NSLog(@"getSelectRimeSchemaList schema_id %@, schema_name %@", schema.schemaId, schema.schemaName);
  }
  NSString *hotkeys = [rimeAPI getHotkeys];
  XCTAssertTrue(hotkeys.length > 0);
  NSLog(@"hotkeys: %@", hotkeys);
}

- (void)testPerformanceExample {
  // This is an example of a performance test case.
  [self measureBlock:^{
    // Put the code you want to measure the time of here.
  }];
}

@end
