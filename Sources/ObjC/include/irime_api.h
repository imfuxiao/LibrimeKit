#import "irime_entity.h"
#import <Foundation/Foundation.h>

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

/**
 RIME输入法引擎
 使用OC对rime_api的c接口进行封装, 方便swift调用
 */
@interface IRimeAPI : NSObject

- (void)setNotificationDelegate:(id<IRimeNotificationDelegate>)delegate;

// MARK: start and shutdown
- (void)startRimeServer:(IRimeTraits *)traits;
- (void)setup:(IRimeTraits *)traits;
- (void)start:(IRimeTraits *)traits WithFullCheck:(BOOL)check;
- (void)shutdown;
- (BOOL)isAlive;

// MARK: input and output
- (BOOL)processKey:(NSString *)keyCode;
- (BOOL)processKeyCode:(int)code;
- (NSArray<IRimeCandidate *> *)getCandidateList;
- (NSArray<IRimeCandidate *> *)getCandidateWithIndex:(int)pageNo andCount:(int)limit;

- (NSString *)getInput;
- (NSString *)getCommit;
- (BOOL)commitComposition;
- (void)cleanComposition;
- (IRimeStatus *)getStatus;
- (IRimeContext *)getContext;

// MARK: schema
- (NSArray<Schema *> *)schemaList;
- (Schema *)currentSchema;
- (BOOL)selectSchema:(NSString *)schemaId;

// MARK: Options
- (BOOL)isAsciiMode;
- (BOOL)isSimplifiedMode;
- (void)asciiMode:(BOOL)value;
- (void)simplification:(BOOL)value;

// MARK: Debug
- (void)printContext;
@end
