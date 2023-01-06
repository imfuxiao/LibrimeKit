@testable import LibrimeKit
import XCTest

class TestRimeNotification: IRimeNotificationDelegate {
  func onDelployStart() {
    print("TestRimeNotification: onDelployStart")
  }
    
  func onDeploySuccess() {
    print("TestRimeNotification: onDeploySuccess")
  }
    
  func onDeployFailure() {
    print("TestRimeNotification: onDeployFailure")
  }
    
  func onChangeMode(_ mode: String) {
    print("TestRimeNotification: onChangeMode, mode: %s", mode)
  }
    
  func onLoadingSchema(_ schema: String) {
    print("TestRimeNotification: onLoadingSchema, schema: %s", schema)
  }
}

final class RimeKitTests: XCTestCase {
  static let rimeTempDirectoryName = "rime"
  static let sharedSupportDirectoryName = "SharedSupport"
  static let userDirectoryName = "user"
  
  // RIME配置文件临时文件夹
  static var tempRimeDir: URL {
    // 创建RIME临时文件夹, 并将测试资源bundle内容copy到临时文件夹内
    var tempRimeDir: URL
    if #available(iOS 16.0, *) {
      tempRimeDir = URL.temporaryDirectory.appending(component: "rime")
    } else {
      tempRimeDir = FileManager.default.temporaryDirectory.appendingPathComponent("rime")
    }
    return tempRimeDir
  }
  
  static var dstSharedSupportURL: URL {
    tempRimeDir.appendingPathComponent(sharedSupportDirectoryName)
  }
  
  static var dstUserURL: URL {
    tempRimeDir.appendingPathComponent(userDirectoryName)
  }
  
  // 同步bundle资源到临时文件夹
  static func syncRimeConfigFile() throws {
    // 创建临时文件夹
    var isDirectory = ObjCBool(true)
    if FileManager.default.fileExists(atPath: tempRimeDir.path, isDirectory: &isDirectory) {
      try FileManager.default.removeItem(at: tempRimeDir)
    }
    try FileManager.default.createDirectory(at: tempRimeDir, withIntermediateDirectories: true)
    
    // 检测bundle文件是否存在
    guard let resourcesURL = Bundle.testModule.resourceURL else {
      fatalError("Not found rime test resources.")
    }
    
    let sharedSupportURL = resourcesURL.appendingPathComponent(sharedSupportDirectoryName)
    let userURL = resourcesURL.appendingPathComponent(userDirectoryName)
    
    try FileManager.default.copyItem(at: sharedSupportURL, to: dstSharedSupportURL)
    try FileManager.default.copyItem(at: userURL, to: dstUserURL)
  }
  
  override func setUpWithError() throws {
    try Self.syncRimeConfigFile()
  }

  func testRimeEngine() throws {
    let traits = IRimeTraits()
    traits.sharedDataDir = Self.dstSharedSupportURL.path
    traits.userDataDir = Self.dstUserURL.path
    traits.appName = "rime.squirrel"
    traits.distributionCodeName = "Squirrel"
    traits.distributionName = "鼠鬚管"
    
    RimeKit.shared.setNotificationDelegate(TestRimeNotification())
    RimeKit.shared.startService(traits)
    
    print("Rime Ready...")
    
    print(RimeKit.shared.getUserDataDir())
    print(RimeKit.shared.getSharedSupportDir())
        
    // 打印前方案列表
    RimeKit.shared.printSchemaList()
        
    let session = RimeKit.shared.createSession()
    print("session_id = ", session)
    if session == 0 {
      print("Error creating rime session.")
      return
    }
        
    let currentSchema = RimeKit.shared.getCurrentSchema(session)
    print("current schema \(currentSchema)")
        
//        print("selecct schema ", RimeKit.shared.selectSchema(session, schemaId: "clover"))
        
//        currentSchema = RimeKit.shared.getCurrentSchema(session)
//        print("current schema \(currentSchema)")
    let
//        print("prebuild all schema ", RimeKit.shared.prebuildAllSchemas())
//        print("deploy workspace ", RimeKit.shared.deployWorkspace())
        
      // input: W
      // rimeStatus =  is_ascii_mode: 0, is_composing: 0, is_ascii_punct: 1, is_disabled: 0, is_full_shape: 0, is_simplified: 0, is_traditional: 0, schema_id: flypy, schema_name: 小鹤音形
      // input: w
      // rimeStatus =  is_ascii_mode: 0, is_composing: 1, is_ascii_punct: 1, is_disabled: 0, is_full_shape: 0, is_simplified: 0, is_traditional: 0, schema_id: flypy, schema_name: 小鹤音形
      // input: ww
      // rimeStatus =  is_ascii_mode: 0, is_composing: 1, is_ascii_punct: 1, is_disabled: 0, is_full_shape: 0, is_simplified: 0, is_traditional: 0, schema_id: flypy, schema_name: 小鹤音形
      // input: www
      // rimeStatus =  is_ascii_mode: 0, is_composing: 1, is_ascii_punct: 1, is_disabled: 0, is_full_shape: 0, is_simplified: 0, is_traditional: 0, schema_id: flypy, schema_name: 小鹤音形
      // input: wwww
      // rimeStatus =  is_ascii_mode: 0, is_composing: 1, is_ascii_punct: 1, is_disabled: 0, is_full_shape: 0, is_simplified: 0, is_traditional: 0, schema_id: flypy, schema_name: 小鹤音形
      // input: .
      // rimeStatus =  is_ascii_mode: 0, is_composing: 0, is_ascii_punct: 1, is_disabled: 0, is_full_shape: 0, is_simplified: 0, is_traditional: 0, schema_id: flypy, schema_name: 小鹤音形
        
//    if !RimeKit.shared.simulateKeySequence(session, input: "orq") {
//      print("Error simulateKeySequence call.")
//      return
//    }
    
      _ = RimeKit.shared.inputKeyForSession(session, keyCode: "o")
    var candidateList = RimeKit.shared.candidateList(session)
    for candidate in candidateList {
      print("candidate: \(candidate)")
    }
    
    _ = RimeKit.shared.inputKeyForSession(session, keyCode: "r")
    candidateList = RimeKit.shared.candidateList(session)
    for candidate in candidateList {
      print("candidate: \(candidate)")
    }
    
    _ = RimeKit.shared.inputKeyForSession(session, keyCode: "q")
    
    candidateList = RimeKit.shared.candidateList(session)
    for candidate in candidateList {
      print("candidate: \(candidate)")
    }
    
    //
    print("input = ", RimeKit.shared.getInput(session))
    print("commit = ", RimeKit.shared.getCommit(session))
    if let status = RimeKit.shared.getStatus(session) {
      print("status = ", status)
    }
        
    RimeKit.shared.printStatus(session)
        
    RimeKit.shared.stopService()
  }
}
