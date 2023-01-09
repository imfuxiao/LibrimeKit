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
  
  override func setUpWithError() throws {
    try Self.syncRimeConfigFile()
  }

  func testRimeEngine() throws {
    let traits = IRimeTraits()
    traits.sharedDataDir = Self.dstSharedSupportURL.path
    traits.userDataDir = Self.dstUserURL.path
    traits.appName = "rime.squirrel"
    traits.modules = ["default", "lua"]
    traits.distributionCodeName = "Squirrel"
    traits.distributionName = "鼠鬚管"
    
    RimeKit.shared.setNotificationDelegate(TestRimeNotification())
    RimeKit.shared.startService(traits)
    
    print("Rime Ready...")
    RimeKit.shared.debug()
  }
}
