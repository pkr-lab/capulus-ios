import Foundation

enum RemoteWolTarget: String, Identifiable {
    case windowsPC = "windows-pc"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .windowsPC: return "Windows-PC (Vereinsheim)"
        }
    }
}
