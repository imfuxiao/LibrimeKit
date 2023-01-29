import Foundation
@_exported import LibrimeKit

public class RimeTraits: IRimeTraits {}

public protocol NotifactionDelegate: IRimeNotificationDelegate {}

public class RimeEngine: ObservableObject {
  @Published var inputKey: String = ""
  @Published var candidates: [String] = []
  @Published var isAlphabet: Bool = false // true: 英文字母模式, false: 中文处理
  
  public static let shared: RimeEngine = .init()
  
  private let rimeAPI: IRimeAPI = .init()
  
  public func setNotificationDelegate(_ delegate: IRimeNotificationDelegate) {
    rimeAPI.setNotificationDelegate(delegate)
  }
  
  public func startService(_ traits: IRimeTraits) {
    if rimeAPI.isAlive() {
      return
    }
    rimeAPI.startRimeServer(traits)
  }
  
  public func stopService() {
    rimeAPI.shutdown()
  }
  
  public func inputKey(_ key: String) -> Bool {
    return rimeAPI.processKey(key)
  }
  
  public func inputKey(_ key: Int) -> Bool {
    return rimeAPI.processKeyCode(Int32(key))
  }
  
  public func candidateList() -> [IRimeCandidate] {
    let cansidates = rimeAPI.getCandidateList()
    if cansidates != nil {
      return cansidates!
    }
    return []
  }
  
  public func candidateWithIndexAndCount(index: Int, count: Int) -> [IRimeCandidate] {
    let cansidates = rimeAPI.getCandidateWith(Int32(index), andCount: Int32(count))
    if cansidates != nil {
      return cansidates!
    }
    return []
  }
  
  public func getInputKeys() -> String {
    return rimeAPI.getInput()
  }
  
  public func getCommitText() -> String {
    return rimeAPI.getCommit()
  }
  
  public func cleanComposition() {
    rimeAPI.cleanComposition()
  }
  
  public func status() -> IRimeStatus {
    return rimeAPI.getStatus()
  }
  
  public func context() -> IRimeContext {
    return rimeAPI.getContext()
  }
  
  public func printContext() {
    return rimeAPI.printContext()
  }
  
  // 繁体模式
  public func traditionalMode(_ value: Bool) {
    rimeAPI.simplification(value)
  }
  
  public func isSimplifiedMode() -> Bool {
    return !rimeAPI.isSimplifiedMode()
  }
  
  // 字母模式
  public func asciiMode(_ value: Bool) {
    rimeAPI.asciiMode(value)
  }
  
  public func isAsciiMode() -> Bool {
    return rimeAPI.isAsciiMode()
  }
}
