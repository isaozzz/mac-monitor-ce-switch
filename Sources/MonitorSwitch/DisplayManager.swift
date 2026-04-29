import AppKit
import CoreGraphics

final class DisplayManager {

    struct DisplayInfo {
        let id: CGDirectDisplayID
        let isMain: Bool
        let mirrorOf: CGDirectDisplayID
    }

    struct ResolutionMode {
        let mode: CGDisplayMode
        let width: Int
        let height: Int
        let refreshRate: Double
        let isHiDPI: Bool
        let scale: Double  // ネイティブとの比率 (例: 1.00, 1.50, 2.00)
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

    /// ディスプレイの表示名を返す
    func displayName(_ id: CGDirectDisplayID) -> String {
        return NSScreen.screens
            .first { screen in
                guard let num = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return false }
                return num == id
            }?
            .localizedName ?? "Display \(id)"
    }

    /// 指定ディスプレイを主ディスプレイ（原点）に設定する
    func setMainDisplay(_ targetID: CGDirectDisplayID) {
        let displays = onlineDisplays().filter { $0.mirrorOf == kCGNullDirectDisplay }
        guard displays.contains(where: { $0.id == targetID }) else { return }
        guard CGDisplayIsMain(targetID) == 0 else { return }

        let targetBounds = CGDisplayBounds(targetID)
        let shiftX = Int32(-targetBounds.origin.x)
        let shiftY = Int32(-targetBounds.origin.y)

        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success else { return }

        for display in displays {
            let bounds = CGDisplayBounds(display.id)
            let newX = Int32(bounds.origin.x) + shiftX
            let newY = Int32(bounds.origin.y) + shiftY
            CGConfigureDisplayOrigin(config, display.id, newX, newY)
        }

        CGCompleteDisplayConfiguration(config, .permanently)
    }

    /// 指定ディスプレイで利用可能な解像度モード一覧を返す
    /// ネイティブ解像度から標準スケール (1.0/1.25/1.5/1.75/2.0/2.5倍) で割った
    /// ターゲットサイズに最も近いモードだけを選び、System Settings の "Displays" と
    /// 同程度（4〜6個）に絞り込む
    func availableModes(for displayID: CGDirectDisplayID) -> [ResolutionMode] {
        guard let allModes = CGDisplayCopyAllDisplayModes(displayID, nil) as? [CGDisplayMode] else { return [] }

        let usable = allModes.filter { $0.isUsableForDesktopGUI() }
        guard let native = usable.max(by: {
            ($0.pixelWidth * $0.pixelHeight) < ($1.pixelWidth * $1.pixelHeight)
        }) else { return [] }

        let nativePxW = Double(native.pixelWidth)
        let nativePxH = Double(native.pixelHeight)
        let scales: [Double] = [1.0, 1.25, 1.5, 1.75, 2.0, 2.5]
        let tolerance = 0.20  // 目標サイズから20%以上ずれたら採用しない

        var picked: [CGDisplayMode] = []

        for scale in scales {
            let targetW = nativePxW / scale
            let targetH = nativePxH / scale
            let targetMag = sqrt(targetW * targetW + targetH * targetH)

            let best = usable.min { a, b in
                let aDist = pow(Double(a.width) - targetW, 2) + pow(Double(a.height) - targetH, 2)
                let bDist = pow(Double(b.width) - targetW, 2) + pow(Double(b.height) - targetH, 2)
                return aDist < bDist
            }
            if let best = best {
                let bestMag = sqrt(Double(best.width * best.width + best.height * best.height))
                if abs(bestMag - targetMag) / targetMag <= tolerance {
                    picked.append(best)
                }
            }
        }

        // 現在のモードは必ず含める（チェックマーク表示のため）
        if let current = CGDisplayCopyDisplayMode(displayID) {
            picked.append(current)
        }

        // 同じ論理解像度で重複したら HiDPI > 高リフレッシュレート を優先
        var grouped: [String: ResolutionMode] = [:]
        for mode in picked {
            let rm = ResolutionMode(
                mode: mode,
                width: mode.width,
                height: mode.height,
                refreshRate: mode.refreshRate,
                isHiDPI: mode.pixelWidth > mode.width,
                scale: nativePxW / Double(mode.width)
            )
            let key = "\(rm.width)x\(rm.height)"
            if let existing = grouped[key] {
                if !existing.isHiDPI && rm.isHiDPI {
                    grouped[key] = rm
                } else if existing.isHiDPI == rm.isHiDPI && rm.refreshRate > existing.refreshRate {
                    grouped[key] = rm
                }
            } else {
                grouped[key] = rm
            }
        }

        return grouped.values.sorted { ($0.width * $0.height) > ($1.width * $1.height) }
    }

    /// 指定ディスプレイの現在のモード
    func currentMode(for displayID: CGDirectDisplayID) -> CGDisplayMode? {
        return CGDisplayCopyDisplayMode(displayID)
    }

    /// 指定ディスプレイの解像度を変更
    func setMode(_ mode: CGDisplayMode, for displayID: CGDirectDisplayID) {
        var config: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&config) == .success else { return }
        CGConfigureDisplayWithDisplayMode(config, displayID, mode, nil)
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
