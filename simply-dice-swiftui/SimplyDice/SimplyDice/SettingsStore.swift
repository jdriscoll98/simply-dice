import SwiftUI

class SettingsStore: ObservableObject {
    @AppStorage("sound") var sound: Bool = true
    @AppStorage("haptics") var haptics: Bool = true
    @AppStorage("shake") var shake: Bool = false
}
