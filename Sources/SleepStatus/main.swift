import AppKit
import IOKit

struct Observation {
    let disabled: Bool?
    let lid: String
    let power: String
    let amphetaminePID: String
    let detail: String
    var key: String { "\(disabled.map(String.init) ?? "unknown")|\(lid)|\(power)|\(amphetaminePID)" }
}

final class SleepStatus: NSObject, NSApplicationDelegate {
    private var item: NSStatusItem!
    private let menu = NSMenu()
    private let stateLine = NSMenuItem(title: "確認中…", action: nil, keyEquivalent: "")
    private let checkedLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let contextLine = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private var timer: Timer?
    private var checking = false
    private var lastKey: String?
    private var lastCheck: Date?
    private var lastLog = Date.distantPast
    private let folder = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/SleepStatus")
    private var logURL: URL { folder.appendingPathComponent("observations.jsonl") }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "❓ 確認中"
        item.menu = menu
        menu.addItem(stateLine)
        menu.addItem(checkedLine)
        menu.addItem(contextLine)
        menu.addItem(NSMenuItem.separator())
        let explanation = NSMenuItem(title: "macOS の実際の状態を1分ごとに確認", action: nil, keyEquivalent: "")
        menu.addItem(explanation)
        addAction("今すぐ確認", #selector(refresh))
        addAction("診断ログを開く", #selector(openLog))
        menu.addItem(NSMenuItem.separator())
        addAction("終了（監視だけ停止）", #selector(quit))
        timer = Timer(timeInterval: 60, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        timer?.tolerance = 2
        RunLoop.main.add(timer!, forMode: .common)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(refresh), name: NSWorkspace.didWakeNotification, object: nil)
        refresh()
    }

    private func addAction(_ title: String, _ action: Selector) {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: "")
        entry.target = self
        menu.addItem(entry)
    }

    private static func command(_ args: [String]) -> (Int32, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            // A stalled probe must never leave a stale green indicator on screen.
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                if process.isRunning { process.terminate() }
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
        } catch {
            return (-1, "")
        }
    }

    private static func observe(amphetaminePID: String) -> Observation {
        let (status, output) = command(["-g"])
        var disabled: Bool?
        if status == 0 {
            for line in output.split(separator: "\n") {
                let fields = line.split(whereSeparator: { $0.isWhitespace })
                if fields.count == 2 && fields[0] == "SleepDisabled" {
                    if fields[1] == "1" { disabled = true }
                    if fields[1] == "0" { disabled = false }
                }
            }
        }
        let (powerStatus, battery) = command(["-g", "batt"])
        let power = powerStatus == 0 ? String(battery.split(separator: "\n").first ?? "unknown") : "unknown"
        var lid = "unknown"
        let root = IORegistryEntryFromPath(kIOMainPortDefault, "IOPower:/IOPowerConnection/IOPMrootDomain")
        if root != 0 {
            if let value = IORegistryEntryCreateCFProperty(root, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool {
                lid = value ? "closed" : "open"
            }
            IOObjectRelease(root)
        }
        return Observation(disabled: disabled, lid: lid, power: power, amphetaminePID: amphetaminePID,
                           detail: disabled == nil ? "pmset取得失敗 (exit=\(status))" : "SleepDisabled = \(disabled! ? 1 : 0)")
    }

    @objc private func refresh() {
        guard !checking else { return }
        checking = true
        let pid = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == "com.if.Amphetamine" })
            .map { String($0.processIdentifier) } ?? "not-running"
        DispatchQueue.global(qos: .utility).async {
            let observation = Self.observe(amphetaminePID: pid)
            DispatchQueue.main.async { self.apply(observation) }
        }
    }

    private func apply(_ observation: Observation) {
        checking = false
        let now = Date()
        let title: String
        switch observation.disabled {
        case true?: title = "🟢 スリープ無効"
        case false?: title = "⚪ 防止OFF"
        case nil: title = "❓ 確認失敗"
        }
        item.button?.title = title
        item.button?.toolTip = "\(title) — \(observation.detail)。電源設定は変更しません。"
        stateLine.title = observation.detail
        checkedLine.title = "確認: \(now.formatted(date: .omitted, time: .standard))"
        contextLine.title = "Amphetamine: \(observation.amphetaminePID == "not-running" ? "停止" : "起動中") / 蓋: \(observation.lid == "closed" ? "閉" : observation.lid == "open" ? "開" : "不明")"
        let gap = lastCheck.map { now.timeIntervalSince($0) }
        if observation.key != lastKey || now.timeIntervalSince(lastLog) >= 60 || (gap ?? 0) > 90 {
            appendLog(observation, at: now, gap: gap)
            lastLog = now
        }
        lastKey = observation.key
        lastCheck = now
    }

    private func appendLog(_ observation: Observation, at date: Date, gap: TimeInterval?) {
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            // Keep this temporary monitor's diagnostic history bounded.
            if let attrs = try? FileManager.default.attributesOfItem(atPath: logURL.path),
               let size = attrs[.size] as? UInt64, size > 5_000_000 {
                let previous = folder.appendingPathComponent("observations.previous.jsonl")
                if FileManager.default.fileExists(atPath: previous.path) { try FileManager.default.removeItem(at: previous) }
                try FileManager.default.moveItem(at: logURL, to: previous)
            }
            let record: [String: Any] = [
                "time": ISO8601DateFormatter().string(from: date),
                "sleep_disabled": observation.disabled.map { $0 as Any } ?? NSNull(),
                "lid": observation.lid,
                "power": observation.power,
                "amphetamine_pid": observation.amphetaminePID,
                "menu_title": item.button?.title ?? "",
                "menu_item_visible": item.isVisible,
                "seconds_since_probe": gap.map { $0 as Any } ?? NSNull()
            ]
            var data = try JSONSerialization.data(withJSONObject: record, options: [.sortedKeys])
            data.append(10)
            if !FileManager.default.fileExists(atPath: logURL.path) {
                FileManager.default.createFile(atPath: logURL.path, contents: nil, attributes: [.posixPermissions: 0o600])
            }
            let handle = try FileHandle(forWritingTo: logURL)
            defer { try? handle.close() }
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch {
            NSLog("SleepStatus log error: %@", error.localizedDescription)
        }
    }

    @objc private func openLog() { NSWorkspace.shared.open(logURL) }
    @objc private func quit() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = SleepStatus()
app.delegate = delegate
app.run()
