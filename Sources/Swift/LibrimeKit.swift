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

public final class RimeKit {
  public static let shared: RimeKit = .init()

  private let engine: IRimeAPI = IRimeAPI()

  private init() { }

  // NOTE: startService 前需要请先设置通知委托
  public func setNotificationDelegate(_ delegate: IRimeNotificationDelegate) {
    engine.setNotificationHandler(delegate, context: self)
  }

  public func startService(_ traits: IRimeTraits) {
    engine.setup(traits)
    if engine.startMaintenance(true) {
      engine.joinMaintenanceThread()
    }
    engine.initialize(traits)
  }

  public func stopService() {
    engine.cleanupAllSessions()
    engine.finalize()
  }

  public func redeployWithFastMode(fastMode: Bool) {
    stopService()
    engine.initialize(nil)
    engine.startMaintenance(fastMode)
  }

  public func createSession() -> IRimeSessionId {
    return engine.createSession()
  }

  public func destorySession(_ session: IRimeSessionId) -> Bool {
    return engine.destroySession(session)
  }

  public func isSessionAlive(_ session: IRimeSessionId) -> Bool {
    return engine.findSession(session)
  }

  public func inputKeyForSession(_ session: IRimeSessionId, keyCode: String) -> Bool {
    let code = Array(keyCode.utf8)[0]
    return engine.processKey(session, keycode: Int32(code), mask: 0)
  }

  public func inputKeyForSession(_ session: IRimeSessionId, keySymbol: KeySymbol) -> Bool {
    return engine.processKey(session, keycode: Int32(keySymbol.rawValue), mask: 0)
  }

  public func commitComposition(_ session: IRimeSessionId) -> Bool {
    return engine.commitComposition(session)
  }

  public func clearComposition(_ session: IRimeSessionId) {
    engine.clearComposition(session)
  }

  // 候选文字列表
  public func candidateList(_ session: IRimeSessionId) -> [String] {
    var result: [String] = []
    let iterator = engine.candidateListBegin(session)
    if let rimeIterator = iterator {
      while engine.candidateListNext(rimeIterator) {
        result.append(rimeIterator.candidate().text())
      }
      engine.candidateListEnd(rimeIterator)
    }
    return result
  }

  // 输入字符
  public func getInput(_ session: IRimeSessionId) -> String {
    return engine.getInput(session) ?? ""
  }

  // 提交字符
  public func getCommit(_ session: IRimeSessionId) -> String {
    guard let commit = engine.getCommit(session) else {
      return ""
    }
    let text = commit.text() ?? ""
    _ = engine.freeCommit(commit)
    return text
  }

  public func getStatus(_ session: IRimeSessionId) -> RimeInputStatus? {
    guard let status = engine.getStatus(session) else {
      return nil
    }

    let inputStatus = RimeInputStatus(
      isAsciiMode: status.isAsciiMode(),
      isComposing: status.isComposing(),
      isAsciiPunct: status.isAsciiPunct(),
      isDisabled: status.isDisabled(),
      isFullShape: status.isFullShape(),
      isSimplified: status.isSimplified(),
      isTraditional: status.isTraditional(),
      schemaId: status.schemaId(),
      schemaName: status.schemaName()
    )

    engine.freeStatus(status)

    return inputStatus
  }

  public func getCurrentSchema(_ session: IRimeSessionId) -> String {
    return engine.getCurrentSchema(session)
  }

  public func selectSchema(_ session: IRimeSessionId, schemaId: String) -> Bool {
    return engine.selectSchema(session, schemeId: schemaId)
  }

  public func deploySchema(_ schemaFile: String) -> Bool {
    return engine.deploySchema(schemaFile)
  }

  public func prebuildAllSchemas() -> Bool {
    return engine.prebuildAllSchemas()
  }

  public func deployWorkspace() -> Bool {
    return engine.deployWorkspace()
  }

  // 打印前方案列表
  public func printSchemaList() {
    guard let list = engine.getSchemaList() else {
      return
    }
    list.list().forEach {
      print($0.schemaId())
      print($0.name())
    }
    engine.freeSchemaList(list)
  }

  public func printStatus(_ session: IRimeSessionId) {
    guard let status = engine.getStatus(session) else {
      return
    }
    status.print()
    engine.freeStatus(status)
  }

  public func simulateKeySequence(_ session: IRimeSessionId, input: String) -> Bool {
    return engine.simulateKeySequence(session, keySequence: input)
  }

  public func getSharedSupportDir() -> String {
    return engine.getSharedDataDir()
  }

  public func getUserDataDir() -> String {
    return engine.getUserDataDir()
  }
}
