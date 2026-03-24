// strongbox-prefs – Export / Import Strongbox macOS Preferences
//
// Strongbox writes user settings to TWO separate plist files:
//
//   1. App Group plist  (most settings – via Settings.sharedInstance)
//      ~/Library/Group Containers/<groupID>/Library/Preferences/<groupID>.plist
//      groupID = "group.strongbox.mac.mcguill"  (dev / direct distribution)
//              = "4326J8XDF2.group.strongbox.mac.mcguill"  (App Store build)
//
//   2. Standard defaults plist  (keyboard shortcuts – via MASShortcutBinder)
//      ~/Library/Containers/com.markmcguill.strongbox/Data/Library/Preferences/
//          com.markmcguill.strongbox.plist
//
// This tool reads / writes both files so that ALL user-configurable settings
// are captured in a single export JSON.
//
// Usage:
//   strongbox-prefs export [output.json]
//   strongbox-prefs import <input.json>
//   strongbox-prefs list

import Foundation

// MARK: – Plist Sources

/// Represents one preferences storage location together with its exportable key whitelist.
struct PlistSource {
    let label: String
    let url: URL
    let exportableKeys: Set<String>
}

// ---------------------------------------------------------------------------
// Source 1 – App Group defaults
// ---------------------------------------------------------------------------

/// Two known App Group IDs (dev build vs. App Store build).
let knownGroupIDs = [
    "group.strongbox.mac.mcguill",
    "4326J8XDF2.group.strongbox.mac.mcguill",
]

func appGroupPlistURL(for groupID: String) -> URL {
    FileManager.default.homeDirectoryForCurrentUser
        .appending(
            path: "Library/Group Containers/\(groupID)/Library/Preferences/\(groupID).plist",
            directoryHint: .notDirectory
        )
}

/// Keys exported from the App Group plist.
/// Derived by reading every `static NSString* const k…` in Settings.m and
/// keeping only those that back user-facing preferences.
///
/// Excluded intentionally:
///   • fullVersion / endFreeTrialDate            – license state
///   • lastEntitlementCheckAttempt / …           – entitlement housekeeping
///   • appHasBeenDowngraded… / hasPrompted…       – one-time prompt flags
///   • hasShownFirstRunWelcome / freeTrialNudge…  – onboarding state
///   • installDate / launchCountKey               – telemetry
///   • hasAskedAboutDatabaseOpenInBackground      – one-time prompt flag
///   • hasPromptedForThirdPartyAutoFill           – one-time prompt flag
///   • lastKnownGoodDatabaseState / autoFill…     – biometric cache (security)
///   • cloudKitZoneCreated / changeNotifications… – CloudKit internal state
///   • hasWarnedAboutCloudKitUnavailability        – one-time warning flag
///   • lastCloudKitRefresh                        – sync timestamp
///   • wiFiSyncPasscodeSSKey                      – stored in SecretStore, not plist
///   • wiFiSyncPasscodeSSKeyHasBeenInitialized    – internal init flag
///   • wiFiSyncServiceName                        – device-specific
///   • lastWiFiSyncPasscodeError                  – transient error string
///   • autoFillWroteCleanly                       – crash-guard flag
///   • lastQuickTypeMultiDbRegularClear            – internal cleanup timestamp
///   • failedUnlockAttempts                       – security counter
///   • appLockPin2.0                              – stored in SecretStore, not plist
///   • duressDummyData                            – security data (setter is NOTIMPL)
///   • passwordStrengthConfig                     – getter returns .defaults, setter is NOTIMPL
///   • useUSGovAuthority                          – getter returns NO, setter is NOP
///   • checkPinYin                                – always returns NO on macOS
let appGroupExportableKeys: Set<String> = [
    // ── UI / Window behaviour ──────────────────────────────────────────────
    "alwaysShowPassword",
    "autoSave",
    "clearClipboardEnabled",
    "clearClipboardAfterSeconds",
    "clipboardHandoff",
    "clearQuickSearchOnOpen",
    "colorizePasswords",
    "colorizeUseColorBlindPalette",
    "concealClipboardFromMonitors-DefaultON-27-Dec-2022",
    "disableCustomViews",
    "floatOnTop",
    "hideOnCopy",
    "largeTextViewFloatOnTop",
    "lockDatabaseOnWindowClose",
    "lockDatabasesOnScreenLock",
    "lockEvenIfEditing",
    "markdownNotes",
    "miniaturizeOnCopy",
    "passwordGeneratorFloatOnTop",
    "quickRevealWithOptionKey",
    "quitOnAllWindowsClosed",
    "quitTerminatesProcessEvenInSystemTrayMode",
    "screenCaptureBlocked",
    "showAutoFillTotpCopiedMessage",
    "showCopyFieldButton",
    "showDatabasesManagerOnAppLaunch",
    "showDatabasesManagerOnCloseAllWindows",
    "showHiddenDatabases",
    "showOfflineOptionsOnLocalDeviceDatabases",
    "showPasswordGenInTray",
    "showPasswordImmediatelyInOutline",
    "showSystemTrayIcon",
    "hideDockIconOnAllMinimized",
    "closeManagerOnLaunch",
    "autoLaunchSingleDatabase",
    "autoCommitScannedTotp",
    "systemMenuClickAction",

    // ── Appearance ────────────────────────────────────────────────────────
    "appAppearance2",

    // ── Auto-Lock ─────────────────────────────────────────────────────────
    "autoLockTimeout",
    "autoLockIfInBackgroundTimeoutSeconds",
    "autoPromptForTouchIdOnActivate",

    // ── App Lock ──────────────────────────────────────────────────────────
    "appLockMode2.0",
    "appLockDelay2.0",
    "appLockAppliesToPreferences",
    "deleteDataAfterFailedUnlockCount",

    // ── Access / Restrictions ─────────────────────────────────────────────
    "databasesAreAlwaysReadOnly",
    "disableExport",
    "disablePrinting",
    "disableCopyTo",
    "disableMakeVisibleInFiles",

    // ── Key Files ─────────────────────────────────────────────────────────
    "hideKeyFileNameOnLockScreen",
    "doNotRememberKeyFile",

    // ── Password Generation / TOTP ────────────────────────────────────────
    "passwordGenerationConfig",
    "trayPasswordGenerationConfig",
    "addLegacySupplementaryTotpCustomFields",
    "addOtpAuthUrl",
    "twoFactorEasyReadSeparator",
    // NOTE: macOS Settings.m uses "twoFactorHideCountdownDigits" (no suffix).
    //       The iOS AppPreferences.m uses "twoFactorHideCountdownDigits2".
    "twoFactorHideCountdownDigits",

    // ── FavIcons / AutoFill ───────────────────────────────────────────────
    "favIconDownloadOptions",
    "autoFillNewRecordSettings",
    "allowEmptyOrNoPasswordEntry",
    "associatedWebsites",

    // ── Sync / Backup ─────────────────────────────────────────────────────
    "atomicSftpWrite",
    "makeLocalRollingBackups",
    "stripUnusedHistoricalIcons",
    "stripUnusedIconsOnSave",
    "useIsolatedDropbox",
    "useParentGroupIconOnCreate",
    "disableNativeNetworkStorageOptions",
    "disableWiFiSyncClientMode",
    "wiFiSyncOn",
    "runBrowserAutoFillProxyServer-Prod-22-Oct-2022",

    // ── SSH Agent ─────────────────────────────────────────────────────────
    "runSshAgent",
    "sshAgentApprovalDefaultExpiryMinutes",
    "sshAgentRequestDatabaseUnlockAllowed",
    "sshAgentPreventRapidRepeatedUnlockRequests",

    // ── Duplicate / Export behaviour ──────────────────────────────────────
    "duplicateItemPreserveTimestamp",
    "duplicateItemReferencePassword",
    "duplicateItemReferenceUsername",
    "duplicateItemEditAfterwards",

    // ── Enterprise / Organisation ─────────────────────────────────────────
    "businessOrganisationName",
]

// ---------------------------------------------------------------------------
// Source 2 – Standard (sandboxed-app) defaults
// ---------------------------------------------------------------------------

/// The bundle identifier used by the Strongbox macOS app.
/// The standard defaults plist lives inside the app's sandbox container.
let knownBundleIDs = [
    "com.markmcguill.strongbox",
]

func standardPlistURL(for bundleID: String) -> URL {
    FileManager.default.homeDirectoryForCurrentUser
        .appending(
            path: "Library/Containers/\(bundleID)/Data/Library/Preferences/\(bundleID).plist",
            directoryHint: .notDirectory
        )
}

/// Keys exported from the standard (sandboxed-app) defaults plist.
///
/// MASShortcutBinder persists keyboard shortcuts via [NSUserDefaults standardUserDefaults],
/// which maps to the app's own container plist – NOT the shared App Group plist.
/// Key values come from Constants.m:
///   kPreferenceGlobalShowShortcutNotification = "GlobalShowStrongboxHotKey-New"
///   kPreferenceLaunchQuickSearchShortcut      = "LaunchQuickSearchShortcut"
///   kPreferencePasswordGeneratorShortcut      = "PasswordGeneratorShortcut"
let standardExportableKeys: Set<String> = [
    "GlobalShowStrongboxHotKey-New",
    "LaunchQuickSearchShortcut",
    "PasswordGeneratorShortcut",
]

// ---------------------------------------------------------------------------
// Source resolution
// ---------------------------------------------------------------------------

func resolveSources() -> [PlistSource] {
    var sources: [PlistSource] = []

    // App Group plist
    for id in knownGroupIDs {
        let url = appGroupPlistURL(for: id)
        if FileManager.default.fileExists(atPath: url.path) {
            sources.append(PlistSource(label: id, url: url, exportableKeys: appGroupExportableKeys))
            break
        }
    }

    // Standard plist
    for bid in knownBundleIDs {
        let url = standardPlistURL(for: bid)
        if FileManager.default.fileExists(atPath: url.path) {
            sources.append(PlistSource(label: bid, url: url, exportableKeys: standardExportableKeys))
            break
        }
    }

    return sources
}

// MARK: – Plist Helpers

func readPlist(from url: URL) throws -> [String: Any] {
    let data = try Data(contentsOf: url)
    guard let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
        throw StrongboxPrefsError.invalidPlist
    }
    return dict
}

func writePlist(_ dict: [String: Any], to url: URL) throws {
    let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
    try data.write(to: url, options: .atomic)
}

// MARK: – JSON Helpers

/// PropertyList values that JSON cannot represent natively (Data, Date) are
/// wrapped in a typed object so the round-trip is lossless.
func plistValueToJSON(_ value: Any) -> Any {
    switch value {
    case let d as Data:
        return ["__type": "data", "value": d.base64EncodedString()]
    case let date as Date:
        return ["__type": "date", "value": ISO8601DateFormatter().string(from: date)]
    case let dict as [String: Any]:
        return dict.mapValues { plistValueToJSON($0) }
    case let arr as [Any]:
        return arr.map { plistValueToJSON($0) }
    default:
        return value
    }
}

func jsonValueToPlist(_ value: Any) -> Any {
    if let dict = value as? [String: Any] {
        if let type = dict["__type"] as? String {
            switch type {
            case "data":
                if let b64 = dict["value"] as? String, let data = Data(base64Encoded: b64) { return data }
            case "date":
                if let s = dict["value"] as? String, let date = ISO8601DateFormatter().date(from: s) { return date }
            default: break
            }
        }
        return dict.mapValues { jsonValueToPlist($0) }
    } else if let arr = value as? [Any] {
        return arr.map { jsonValueToPlist($0) }
    }
    return value
}

// MARK: – Commands

func exportPrefs(to outputPath: String?) throws {
    let sources = resolveSources()
    guard !sources.isEmpty else { throw StrongboxPrefsError.plistNotFound }

    var exported: [String: Any] = [:]
    var sourceLabels: [String] = []

    for source in sources {
        let all = try readPlist(from: source.url)
        var count = 0
        for key in source.exportableKeys {
            if let value = all[key] {
                exported[key] = plistValueToJSON(value)
                count += 1
            }
        }
        sourceLabels.append("\(source.label) (\(count) keys)")
    }

    let json = try JSONSerialization.data(withJSONObject: exported, options: [.prettyPrinted, .sortedKeys])

    let destination: URL
    if let path = outputPath {
        destination = URL(fileURLWithPath: path)
    } else {
        let name = "strongbox-prefs-\(ISO8601DateFormatter().string(from: Date()).prefix(10)).json"
        destination = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(path: name, directoryHint: .notDirectory)
    }

    try json.write(to: destination, options: .atomic)
    print("✅ Exported \(exported.count) settings total")
    for label in sourceLabels { print("   • \(label)") }
    print("   → \(destination.path)")
}

/// Writes a timestamped backup of all currently exported settings to the current working directory.
/// Returns the URL of the written backup file.
@discardableResult
func backupPrefs(sources: [PlistSource]) throws -> URL {
    var snapshot: [String: Any] = [:]

    for source in sources {
        let all = try readPlist(from: source.url)
        for key in source.exportableKeys {
            if let value = all[key] {
                snapshot[key] = plistValueToJSON(value)
            }
        }
    }

    let json = try JSONSerialization.data(withJSONObject: snapshot, options: [.prettyPrinted, .sortedKeys])

    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
    let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
    let name = "strongbox-prefs-backup-\(timestamp).json"
    let dest = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appending(path: name, directoryHint: .notDirectory)

    try json.write(to: dest, options: .atomic)
    return dest
}

func importPrefs(from inputPath: String, merge: Bool) throws {
    let sources = resolveSources()
    guard !sources.isEmpty else { throw StrongboxPrefsError.plistNotFound }

    // 1. Backup current state before any changes
    let backupURL = try backupPrefs(sources: sources)
    print("📦 Backup written to: \(backupURL.lastPathComponent)")

    let jsonData = try Data(contentsOf: URL(fileURLWithPath: inputPath))
    guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
        throw StrongboxPrefsError.invalidJSON
    }

    // Build a reverse-lookup: key → source
    var keyToSource: [String: PlistSource] = [:]
    for source in sources {
        for key in source.exportableKeys {
            keyToSource[key] = source
        }
    }

    // 2. In replace mode (default): strip all exportable keys from each plist first,
    //    producing a clean baseline before writing the incoming values.
    //    In --merge mode: keep existing values and only overwrite keys present in the file.
    var plistUpdates: [URL: [String: Any]] = [:]
    for source in sources {
        var dict = try readPlist(from: source.url)
        if !merge {
            for key in source.exportableKeys {
                dict.removeValue(forKey: key)
            }
        }
        plistUpdates[source.url] = dict
    }

    // 3. Write incoming key/value pairs into the (possibly stripped) plists
    var importedCount = 0
    var skippedCount = 0

    for (key, jsonValue) in jsonDict {
        guard let source = keyToSource[key] else {
            print("⚠️  Skipping unknown/non-exportable key: \(key)")
            skippedCount += 1
            continue
        }
        plistUpdates[source.url]![key] = jsonValueToPlist(jsonValue)
        importedCount += 1
    }

    // 4. Write each modified plist back
    for (url, dict) in plistUpdates {
        try writePlist(dict, to: url)
    }

    // 5. Touch each source domain so cfprefsd picks up the changes immediately
    for source in sources {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", source.label]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try? task.run()
        task.waitUntilExit()
    }

    let mode = merge ? "merged" : "replaced (clean baseline)"
    print("✅ Imported \(importedCount) settings [\(mode)]")
    if skippedCount > 0 { print("   ⚠️  Skipped \(skippedCount) unrecognised keys.") }
    print("   Restart Strongbox to apply all changes.")
}

func listPrefs() throws {
    let sources = resolveSources()
    guard !sources.isEmpty else { throw StrongboxPrefsError.plistNotFound }

    for source in sources {
        let all = try readPlist(from: source.url)
        print("\nStrongbox Preferences  [\(source.label)]")
        print(String(repeating: "─", count: 60))
        for key in source.exportableKeys.sorted() {
            if let value = all[key] {
                print("  \(key) = \(value)")
            }
        }
        print(String(repeating: "─", count: 60))
    }
}

// MARK: – Errors

enum StrongboxPrefsError: LocalizedError {
    case plistNotFound, invalidPlist, invalidJSON, missingArgument(String)

    var errorDescription: String? {
        switch self {
        case .plistNotFound:
            let groupPaths = knownGroupIDs.map {
                "  ~/Library/Group Containers/\($0)/Library/Preferences/\($0).plist"
            }.joined(separator: "\n")
            let stdPaths = knownBundleIDs.map {
                "  ~/Library/Containers/\($0)/Data/Library/Preferences/\($0).plist"
            }.joined(separator: "\n")
            return """
            Could not find any Strongbox preferences plist.
            Searched (App Group):
            \(groupPaths)
            Searched (Standard):
            \(stdPaths)
            Make sure Strongbox has been launched at least once.
            """
        case .invalidPlist:   return "The plist file could not be parsed."
        case .invalidJSON:    return "The input file is not valid JSON."
        case .missingArgument(let msg): return msg
        }
    }
}

// MARK: – Entry Point

func printUsage() {
    print("""
    strongbox-prefs – Export / Import Strongbox macOS Preferences

    USAGE:
      strongbox-prefs export [output.json]          Export all user settings to JSON
      strongbox-prefs import <input.json> [--merge] Import user settings from JSON
      strongbox-prefs list                          Show current exportable settings

    IMPORT MODES:
      Default (replace):  All exportable settings are wiped first (clean baseline),
                          then the values from the file are written.
      --merge:            Existing settings are kept; only keys present in the file
                          are overwritten.
      In both modes a timestamped backup is written to the current directory before
      any changes are made.

    NOTES:
      • Settings from both the App Group plist and the standard sandboxed-app
        plist (keyboard shortcuts) are captured in a single JSON file.
      • Only user-configurable settings are included: no license data,
        no biometric cache, no CloudKit tokens, no database list.
      • After importing, restart Strongbox for all settings to take effect.
      • Binary plist values (Data, Date) are round-tripped losslessly via a
        typed JSON wrapper ({ "__type": "data"|"date", "value": "…" }).
    """)
}

let args = CommandLine.arguments.dropFirst()

do {
    switch args.first {
    case "export":
        try exportPrefs(to: args.dropFirst().first)
    case "import":
        let importArgs = args.dropFirst()
        guard let path = importArgs.first(where: { !$0.hasPrefix("--") }) else {
            throw StrongboxPrefsError.missingArgument("Usage: strongbox-prefs import <input.json> [--merge]")
        }
        let merge = importArgs.contains("--merge")
        try importPrefs(from: path, merge: merge)
    case "list":
        try listPrefs()
    default:
        printUsage()
        if args.first != nil && args.first != "--help" && args.first != "-h" { exit(1) }
    }
} catch {
    fputs("🔴 Error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
