import Foundation

private class BundleFinder {}

extension Foundation.Bundle {
  /// Returns the resource bundle associated with the current Swift module.
  static var testModule: Bundle = {
    let bundleName = "LibrimeKit_LibrimeKitTests"
    
    let candidates = [
      // Bundle should be present here when the package is linked into an App.
      Bundle.main.resourceURL,
      
      // Bundle should be present here when the package is linked into a framework.
      Bundle(for: BundleFinder.self).resourceURL,
      
      // For command-line tools.
      Bundle.main.bundleURL,
    ]
    
    for candidate in candidates {
      guard let candidate = candidate else {
        continue
      }
      
      #if DEBUG
      print(candidate)
      #endif
      
      if !candidate.lastPathComponent.hasSuffix(".xctest") {
        continue
      }
      
      if #available(iOS 16.0, *) {
        if let bunder = Bundle(url: candidate.deletingLastPathComponent().appending(component: bundleName + ".bundle")) {
          #if DEBUG
          print(bunder.bundlePath)
          #endif
          return bunder
        }
      } else {
        if let bunder = Bundle(url: candidate.deletingLastPathComponent().appendingPathComponent(bundleName + ".bundle")) {
          #if DEBUG
          print(bunder.bundlePath)
          #endif
          return bunder
        }
      }
    }
    
    fatalError("unable to find bundle named \(bundleName)")
  }()
  
//  func copyItem(toPath dstPath: URL) throws {
//    var sharedSupport: URL
//    var user: URL
//    if #available(iOS 16.0, *) {
//      sharedSupport = self.bundleURL.appending(component: "SharedSupport")
//      user = self.bundleURL.appending(component: "user")
//    } else {
//      sharedSupport = self.bundleURL.appendingPathComponent("SharedSupport")
//      user = self.bundleURL.appendingPathComponent("user")
//    }
//
//    try FileManager.default.copyItem(at: sharedSupport, to: dstPath)
//    try FileManager.default.copyItem(at: user, to: dstPath)
//  }
}
