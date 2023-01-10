#import <Foundation/Foundation.h>

/**
 封装 rime_api.h 结构 rime_traits_t
 
 Should be initialized by calling RIME_STRUCT_INIT(Type, var)
 */
@interface IRimeTraits : NSObject {
  NSString *sharedDataDir;
  NSString *userDataDir;
  NSString *distributionName;
  NSString *distributionCodeName;
  NSString *distributionVersion;
  
  // 传递一个格式为 "rime.x
  // "的C-string常量，其中'x'是你的应用程序的名称。添加前缀 "rime.
  // "以确保旧的日志文件被自动清理。
  NSString *appName;
  // 初始化(initializing)前要加载的模块列表
  NSArray<NSString *> *modules;
  // v1.6
  /*! Minimal level of logged messages.
   *  Value is passed to Glog library using FLAGS_minloglevel variable.
   *  0 = INFO (default), 1 = WARNING, 2 = ERROR, 3 = FATAL
   */
  // 记录日志的最小级别。这个值是通过FLAGS_minloglevel变量传递给Glog库的。0 =
  // INFO（默认），1 = WARNING，2 = ERROR，3 = FATAL。
  int minLogLevel;
  // 日志文件的目录。该值使用FLAGS_log_dir变量传递给Glog库。
  NSString *logDir;
  // 预先构建的数据目录中。默认为${shared_data_dir}/build
  NSString *prebuiltDataDir;
  // 暂存目录，默认为${user_data_dir}/build
  NSString *stagingDir;
}

@property NSString *sharedDataDir;
@property NSString *userDataDir;
@property NSString *distributionName;
@property NSString *distributionCodeName;
@property NSString *distributionVersion;
@property NSString *appName;
@property NSArray<NSString *> *modules;
@property int minLogLevel;
@property NSString *logDir;
@property NSString *prebuiltDataDir;
@property NSString *stagingDir;

@end

@interface Schema : NSObject {
  NSString *schemaId;
  NSString *schemaName;
}

@property NSString *schemaId;
@property NSString *schemaName;

- (id)initWithSchemaId:(NSString *)schemaId andSchemaName:(NSString *)name;

@end
