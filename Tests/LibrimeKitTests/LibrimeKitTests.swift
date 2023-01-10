@testable import LibrimeKit
import XCTest

class TestRimeNotification: NotifactionDelegate {
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
    print("TestRimeNotification: onChangeMode, mode: ", mode)
  }
    
  func onLoadingSchema(_ schema: String) {
    print("TestRimeNotification: onLoadingSchema, schema: ", schema)
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
    print("temp rime directory: ", tempRimeDir);
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
  
  static func startRime() {
    let traits = RimeTraits()
    traits.sharedDataDir = Self.dstSharedSupportURL.path
    traits.userDataDir = Self.dstUserURL.path
    traits.appName = "rime.hamster"
    traits.distributionCodeName = "Hamster"
    traits.distributionName = "仓鼠"
    
    RimeKit.shared.setNotificationDelegate(TestRimeNotification())
    RimeKit.shared.startService(traits)
  }
  
  override func setUpWithError() throws {
    try Self.syncRimeConfigFile()
    Self.startRime()
  }
  
  func testInputKeys() throws {
    _ = RimeKit.shared.inputKey("w");
    _ = RimeKit.shared.inputKey("w");
    var candidates = RimeKit.shared.inputKey("w");
    XCTAssertNotNil(candidates);
    XCTAssertEqual(candidates[0], "威")
    XCTAssertEqual(RimeKit.shared.getInputKeys(), "www")
    RimeKit.shared.cleanComposition()
    
    // 繁体模式
    RimeKit.shared.traditionalMode(true)
    _ = RimeKit.shared.inputKey("u")
    candidates = RimeKit.shared.inputKey("o")
    XCTAssertNotNil(candidates);
    XCTAssertEqual(candidates[0], "說")
    XCTAssertEqual(RimeKit.shared.getInputKeys(), "uo")
    XCTAssertFalse(RimeKit.shared.isSimplifiedMode())
    RimeKit.shared.cleanComposition()
    
    // 简体模式
    RimeKit.shared.traditionalMode(false)
    _ = RimeKit.shared.inputKey("u")
    candidates = RimeKit.shared.inputKey("o")
    XCTAssertNotNil(candidates);
    XCTAssertEqual(candidates[0], "说")
    XCTAssertEqual(RimeKit.shared.getInputKeys(), "uo")
    XCTAssertTrue(RimeKit.shared.isSimplifiedMode())
    
    // ASCII 模式
    RimeKit.shared.asciiMode(true)
    XCTAssertTrue(RimeKit.shared.isAsciiMode())
    RimeKit.shared.asciiMode(false)
    XCTAssertFalse(RimeKit.shared.isAsciiMode())
  }
}
