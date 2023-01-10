import Foundation
@_exported import ObjCRime

public class RimeTraits: IRimeTraits {}

public protocol NotifactionDelegate: IRimeNotificationDelegate {}

public final class RimeKit {
  public static let shared: RimeKit = .init()

  private let rimeAPI: IRimeAPI = .init()

  private init() {}

  public func setNotificationDelegate(_ delegate: NotifactionDelegate) {
    rimeAPI.setNotificationDelegate(delegate)
  }

  public func startService(_ traits: RimeTraits) {
    rimeAPI.startRimeServer(traits)
  }

  public func stopService() {
    rimeAPI.shutdown()
  }

  public func inputKey(_ key: String) -> [String] {
    if rimeAPI.processKey(key) {
      return []
    }
    return rimeAPI.candidateList()
  }

  public func getInputKeys() -> String {
    return rimeAPI.getInput()
  }

  public func cleanComposition() {
    rimeAPI.cleanComposition()
  }

  // 繁体模式
  public func traditionalMode(_ value: Bool) {
    rimeAPI.simplification(value)
  }

  public func isSimplifiedMode() -> Bool {
    return !rimeAPI.isSimplifiedMode()
  }

  public func asciiMode(_ value: Bool) {
    rimeAPI.asciiMode(value)
  }

  public func isAsciiMode() -> Bool {
    return rimeAPI.isAsciiMode()
  }
}
