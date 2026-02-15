import CoreGraphics

final class DisplayManager {

    struct DisplayInfo {
        let id: CGDirectDisplayID
        let isMain: Bool
        let mirrorOf: CGDirectDisplayID
    }

    /// オンラインの全ディスプレイを返す（ミラーリング中のセカンダリも含む）
    func onlineDisplays() -> [DisplayInfo] {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0
        let err = CGGetOnlineDisplayList(UInt32(displayIDs.count), &displayIDs, &displayCount)
        guard err == .success else { return [] }

        return (0..<Int(displayCount)).map { i in
            let id = displayIDs[i]
            return DisplayInfo(
                id: id,
                isMain: CGDisplayIsMain(id) != 0,
                mirrorOf: CGDisplayMirrorsDisplay(id)
            )
        }
    }

    /// 現在ミラーリング中かどうか
    func isMirroring() -> Bool {
        let displays = onlineDisplays()
        return displays.contains { $0.mirrorOf != kCGNullDirectDisplay }
    }

    /// ミラーリングに切り替え
    func enableMirroring() {
        let displays = onlineDisplays()
        guard let main = displays.first(where: { $0.isMain }) else { return }
        let others = displays.filter { !$0.isMain && $0.mirrorOf == kCGNullDirectDisplay }
        guard !others.isEmpty else { return }

        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success else { return }

        for other in others {
            CGConfigureDisplayMirrorOfDisplay(config, other.id, main.id)
        }

        CGCompleteDisplayConfiguration(config, .permanently)
    }

    /// 拡張ディスプレイに切り替え（ミラー解除）
    func disableMirroring() {
        let displays = onlineDisplays()
        let mirrored = displays.filter { $0.mirrorOf != kCGNullDirectDisplay }
        guard !mirrored.isEmpty else { return }

        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success else { return }

        for display in mirrored {
            CGConfigureDisplayMirrorOfDisplay(config, display.id, kCGNullDirectDisplay)
        }

        CGCompleteDisplayConfiguration(config, .permanently)
    }
}
