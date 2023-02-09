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

@interface TestNotification : NSObject <IRimeNotificationDelegate>

@end

@implementation TestNotification

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

@end

@interface irime_api_test : XCTestCase

@end

@implementation irime_api_test

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
  IRimeTraits *traits = [[IRimeTraits alloc] init];
  [traits setSharedDataDir:[[self tempSharedSupportURL] path]];
  [traits setUserDataDir:[[self tempUserURL] path]];
  [traits setAppName:@"rime.hamster"];
  [traits setDistributionName:@"仓鼠"];
  [traits setDistributionCodeName:@"Hamster"];
  
  IRimeAPI *api = [[IRimeAPI alloc] init];
  [api setNotificationDelegate:[[TestNotification alloc] init]];
  [api startRimeServer:traits];
  return api;
}

- (void)testStarRime {
  [self startRime];
}

- (void)testCandidateWithIndexAndCount {
  IRimeAPI *api = [self startRime];
  [api processKey:@"w"];
  [api processKeyCode:QuoteLeft];
  IRimeContext *ctx = [api getContext];
  
  for (IRimeCandidate *candidate in [ctx candidates]) {
    NSLog(@"ctx text = %@, comment = %@", [candidate text],
          [candidate comment]);
  }
  
  int count = 5;
  for (int i = 0; i < ctx.pageSize; i++) {
    NSArray<IRimeCandidate *> *candidates = [api getCandidateWithIndex:i * count
                                                              andCount:count];
    for (IRimeCandidate *candidate in candidates) {
      NSLog(@"text = %@, comment = %@", [candidate text], [candidate comment]);
    }
  }
}

- (void)testInputKeys {
  IRimeAPI *api = [self startRime];
  [api processKey:@"w"];
  [api processKey:@"o"];
  [api processKey:@"r"];
  [api processKeyCode:QuoteLeft];
  NSArray<IRimeCandidate *> *candidates = [api getCandidateList];
  XCTAssertNotNil(candidates);
  XCTAssertTrue([@"偓" isEqual:candidates[1].text]);
  [api cleanComposition];
  
  // 繁体模式
  [api simplification:TRUE];
  [api processKey:@"u"];
  [api processKey:@"o"];
  candidates = [api getCandidateList];
  XCTAssertTrue(candidates.count > 0);
  XCTAssertTrue([@"說" isEqual:candidates[0].text]);
  XCTAssertTrue([api isSimplifiedMode]);
  [api cleanComposition];
  
  // 简体模式
  [api simplification:FALSE];
  [api processKey:@"u"];
  [api processKey:@"o"];
  candidates = [api getCandidateList];
  XCTAssertTrue(candidates.count > 0);
  XCTAssertTrue([@"说" isEqual:candidates[0].text]);
  XCTAssertFalse([api isSimplifiedMode]);
  
  // ASCII 模式
  [api asciiMode:FALSE];
  XCTAssertFalse([api isAsciiMode]);
  [api asciiMode:TRUE];
  XCTAssertTrue([api isAsciiMode]);
}

- (void)testPerformanceExample {
  // This is an example of a performance test case.
  [self measureBlock:^{
    // Put the code you want to measure the time of here.
  }];
}

@end
