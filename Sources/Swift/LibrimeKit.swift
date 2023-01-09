import Foundation
@_exported import ObjCRime

public struct RimeInputStatus {
  public let isAsciiMode: Bool
  public let isComposing: Bool
  // 是否ASCII标点
  public let isAsciiPunct: Bool
  public let isDisabled: Bool
  public let isFullShape: Bool
  public let isSimplified: Bool
  public let isTraditional: Bool
  public let schemaId: String
  public let schemaName: String
}

public enum KeySymbol: Int {
  case Backspace = 0xff08
  case Return = 0xff0d
}

public protocol NotifactionDelegate: IRimeNotificationDelegate { }

public final class RimeKit {
  public static let shared: RimeKit = .init()

  private let rimeAPI: IRimeAPI = IRimeAPI()

  private init() { }

  public func setNotificationDelegate(_ delegate: NotifactionDelegate) {
    rimeAPI.setNotificationDelegate(delegate)
  }

  public func startService(_ traits: IRimeTraits) {
    rimeAPI.startRimeServer(traits);
  }

  public func stopService() {
    rimeAPI.shutdown()
  }
  
  /// 用于测试
  @available(*, deprecated)
  public func debug() {
    rimeAPI.debugInfo()
  }

}
