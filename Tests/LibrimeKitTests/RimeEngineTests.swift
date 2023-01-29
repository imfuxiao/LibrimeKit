@testable @_exported import LibrimeKit
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
    print("temp rime directory: ", tempRimeDir)
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
    
    RimeEngine.shared.setNotificationDelegate(TestRimeNotification())
    RimeEngine.shared.startService(traits)
  }
  
  override func setUpWithError() throws {
    try Self.syncRimeConfigFile()
    Self.startRime()
  }
  
  func testCandidateWithIndexAndCount() throws {
    _ = RimeEngine.shared.inputKey("w")
    _ = RimeEngine.shared.inputKey(KeySymbol.QuoteLeft.rawValue)
    let context = RimeEngine.shared.context()
    print(context)
    var count = 5
    for i in 0 ..< context.pageSize {
      // TODO
      let candidates = RimeEngine.shared.candidateWithIndexAndCount(index: count * Int(i), count: count)
      print(candidates)
    }
  }
  
  func testContext() throws {
    _ = RimeEngine.shared.inputKey("w")
    _ = RimeEngine.shared.inputKey(KeySymbol.QuoteLeft.rawValue)
    var context = RimeEngine.shared.context()
    print(context)
    // 发射分页键
    _ = RimeEngine.shared.inputKey(KeySymbol.BracketLeft.rawValue)
    context = RimeEngine.shared.context()
    print(context)
  }
  
  func testPrintContext() throws {
    _ = RimeEngine.shared.inputKey("w")
    _ = RimeEngine.shared.inputKey(KeySymbol.QuoteLeft.rawValue)
    RimeEngine.shared.printContext()
  }
  
  func testInputKeys() throws {
    _ = RimeEngine.shared.inputKey("w")
    _ = RimeEngine.shared.inputKey("o")
    _ = RimeEngine.shared.inputKey("r")
    _ = RimeEngine.shared.inputKey(KeySymbol.QuoteLeft.rawValue)
    var candidates = RimeEngine.shared.candidateList()
    XCTAssertNotNil(candidates)
    XCTAssertEqual(candidates[1].text, "偓")
    RimeEngine.shared.cleanComposition()
    
    // 繁体模式
    RimeEngine.shared.traditionalMode(true)
    _ = RimeEngine.shared.inputKey("u")
    _ = RimeEngine.shared.inputKey("o")
    candidates = RimeEngine.shared.candidateList()
    XCTAssertNotNil(candidates)
    XCTAssertEqual(candidates[0].text, "說")
    XCTAssertFalse(RimeEngine.shared.isSimplifiedMode())
    RimeEngine.shared.cleanComposition()
    
    // 简体模式
    RimeEngine.shared.traditionalMode(false)
    _ = RimeEngine.shared.inputKey("u")
    _ = RimeEngine.shared.inputKey("o")
    candidates = RimeEngine.shared.candidateList()
    XCTAssertNotNil(candidates)
    XCTAssertEqual(candidates[0].text, "说")
    XCTAssertTrue(RimeEngine.shared.isSimplifiedMode())
    
    // ASCII 模式
    RimeEngine.shared.asciiMode(true)
    XCTAssertTrue(RimeEngine.shared.isAsciiMode())
    RimeEngine.shared.asciiMode(false)
    XCTAssertFalse(RimeEngine.shared.isAsciiMode())
  }
}
