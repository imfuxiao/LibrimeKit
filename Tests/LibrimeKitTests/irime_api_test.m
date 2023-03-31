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

- (void)onDelployStart {
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
  [api initialize:traits];
  [api startMaintenance:true];
  return api;
}

- (void)testCandidateWithIndexAndCount {
  IRimeAPI *rimeAPI = [self startRime];
  RimeSessionId session = 0;
  while (session == 0) {
    session = [rimeAPI createSession];
  }
  
  XCTAssertTrue(session > 0);
  
  [rimeAPI processKey:@"w" andSession:session];
  [rimeAPI processKeyCode:QuoteLeft andSession:session];
  IRimeContext *ctx = [rimeAPI getContext:session];
  
  for (IRimeCandidate *candidate in [[ctx menu] candidates]) {
    NSLog(@"ctx text = %@, comment = %@", [candidate text],
          [candidate comment]);
  }
  
  int count = 5;
  for (int i = 0; i < ctx.menu.pageSize; i++) {
    for (IRimeCandidate *candidate in ctx.menu.candidates) {
      NSLog(@"text = %@, comment = %@", [candidate text], [candidate comment]);
    }
  }
}

- (void)testInputKeys {
  IRimeAPI *api = [self startRime];
  RimeSessionId session = 0;
  while (session == 0) {
    session = [api createSession];
  }
  
  [api processKey:@"w" andSession:session];
  [api processKey:@"o" andSession:session];
  [api processKey:@"r" andSession:session];
  [api processKeyCode:QuoteLeft andSession:session];
  NSArray<IRimeCandidate *> *candidates = [api getCandidateList:session];
  XCTAssertNotNil(candidates);
  XCTAssertTrue([@"倭" isEqual:candidates[0].text]);
  [api cleanComposition:session];
}

- (void)testSchemaList {
  IRimeAPI *rimeAPI =
  [self startRime:@"/Users/morse/Downloads/rimeTestResources/SharedSupport"
      andUserPath:@"/Users/morse/Downloads/rimeTestResources/rime"];
  
  RimeSessionId session = 0;
  while (session == 0) {
    session = [rimeAPI createSession];
  }
  
  // 选择输入法并设置分页大小.
  IRimeConfig *config = [rimeAPI openSchema:@"clover"];
  [config setInt:@"menu/page_size" value:20];
  int pageSize = [config getInt:@"menu/page_size"];
  NSLog(@"\n \n test pageSize: %d ", pageSize);
  
  NSLog(@"\n schema list: %@", [rimeAPI schemaList]);
  
  [rimeAPI selectSchema:session andSchameId:@"clover"];
  
  IRimeSchema *currentSchema = [rimeAPI currentSchema:session];
  NSLog(@"current schemaName: %@, schemaId: %@", [currentSchema schemaName],
        [currentSchema schemaId]);
  
  [rimeAPI processKey:@"w" andSession:session];
  [rimeAPI processKey:@"o" andSession:session];
  [rimeAPI processKey:@"a" andSession:session];
  [rimeAPI processKey:@"i" andSession:session];
  [rimeAPI processKey:@"c" andSession:session];
  [rimeAPI processKey:@"h" andSession:session];
  [rimeAPI processKey:@"i" andSession:session];
  [rimeAPI processKey:@"m" andSession:session];
  [rimeAPI processKey:@"i" andSession:session];
  [rimeAPI processKey:@"a" andSession:session];
  [rimeAPI processKey:@"n" andSession:session];
  
  
  IRimeContext *ctx = [rimeAPI getContext:session];
  NSLog(@"ctx composition preeidt: %@", ctx.composition.preedit);
  NSArray<IRimeCandidate *> *candidates = [rimeAPI getCandidateList: session];
//  NSArray<IRimeCandidate *> *candidates = [rimeAPI getCandidateWithIndex:1 andCount:20 andSession:session];
  for (IRimeCandidate *c in candidates) {
    NSLog(@"ctx composition: %@", c);
  }
  
//  IRimeStatus *status = [rimeAPI getStatus:session];
//  NSLog(@"status: %@", status);
//
//  // 翻页
//  candidates = [rimeAPI getCandidateWithIndex:21 andCount:20 andSession:session];
//  for (IRimeCandidate *c in candidates) {
//    NSLog(@"ctx composition: %@", c);
//  }
//
//  // 选择第2页下标
//  [rimeAPI selectCandidate: session andIndex: 40];
//  ctx = [rimeAPI getContext:session];
//  NSLog(@"ctx composition preedit: %@", ctx.composition.preedit);
//
//  // 删除选择字
//  [rimeAPI processKeyCode:0xff08 andSession:session];
//  ctx = [rimeAPI getContext:session];
//  NSLog(@"ctx composition preedit: %@", ctx.composition.preedit);
//  candidates = [rimeAPI getCandidateWithIndex:1 andCount:20 andSession:session];
//  for (IRimeCandidate *c in candidates) {
//    NSLog(@"ctx composition: %@", c);
//  }
  
//  status = [rimeAPI getStatus:session];
//  NSLog(@"status: %@", status);
//
//    [rimeAPI processKeyCode: 0xFF56 andSession:session];
  
  // 变更schema
  //  XCTAssertTrue([api selectSchema:@"cangjie5"]);
  //  currentSchema = [api currentSchema];
  //  NSLog(@"current schemaName: %@, schemaId: %@", [currentSchema schemaName],
  //        [currentSchema schemaId]);
}

- (void)testConfigValue {
  IRimeAPI *rimeAPI = [self startRime];
  RimeSessionId session = 0;
  while (session == 0) {
    session = [rimeAPI createSession];
  }
  IRimeConfig *schemaConfig = [rimeAPI openSchema:@"flypy"];
  XCTAssertNotNil(schemaConfig);
  
  NSString *value = [schemaConfig getString:@"schema/version"];
  NSLog(@"schema/version: %@", value);
  XCTAssertTrue([@"10.9.3" isEqual:value]);
  
  int historySize = [schemaConfig getInt:@"history/size"];
  NSLog(@"history/size: %d", historySize);
  XCTAssertTrue(historySize == 1);
  
  IRimeConfig *config = [rimeAPI openConfig:@"squirrel"];
  XCTAssertNotNil(config);
  
  BOOL usKeyboardLayout = [config getBool:@"us_keyboard_layout"];
  XCTAssertTrue(usKeyboardLayout);
  
  double chordDuration = [config getDouble:@"chord_duration"];
  XCTAssertTrue(chordDuration == 0.1);
  
  // 获取系统全部配色map值
  NSArray<IRimeConfigIteratorItem *> *items =
  [config getMapValues:@"preset_color_schemes"];
  XCTAssertNotNil(items);
  for (IRimeConfigIteratorItem *item in items) {
    NSLog(@"color schema: %@", item);
  }
  
  // 多重path使用/分隔
  // 获取当前配色名称
  value = [config getString:@"style/color_scheme"];
  NSLog(@"color_scheme: %@", value);
  XCTAssertTrue([@"metro" isEqual:value], @"color_scheme is: %@", value);
}

- (void)testPerformanceExample {
  // This is an example of a performance test case.
  [self measureBlock:^{
    // Put the code you want to measure the time of here.
  }];
}

@end
