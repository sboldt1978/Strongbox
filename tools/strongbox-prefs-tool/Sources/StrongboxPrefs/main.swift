// strongbox-prefs – Export / Import Strongbox macOS Preferences
// Usage:
//   strongbox-prefs export [output.json]
//   strongbox-prefs import <input.json>
//   strongbox-prefs list

import Foundation

// MARK: – Known Plist Locations

/// Strongbox macOS stores its shared settings in the App Group container.
/// Two known group names exist (dev vs. App-Store build).
let knownGroupIDs = [
    "group.strongbox.mac.mcguill",
    "4326J8XDF2.group.strongbox.mac.mcguill",
]

func plistURL(for groupID: String) -> URL {
    let gc = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: "Library/Group Containers/\(groupID)/Library/Preferences/\(groupID).plist",
                   directoryHint: .notDirectory)
    return gc
}

func locatePlist() -> (url: URL, groupID: String)? {
    for id in knownGroupIDs {
        let url = plistURL(for: id)
        if FileManager.default.fileExists(atPath: url.path) {
            return (url, id)
        }
    }
    return nil
}

// MARK: – Exportable Keys

/// Only user-facing settings are exported.
/// Internal state (license, biometrics cache, launch counts, CloudKit tokens, …) is excluded.
let exportableKeys: Set<String> = [
    // UI / Behaviour
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
    "hideOnCopy",
    "lockDatabaseOnWindowClose",
    "lockDatabasesOnScreenLock",
    "lockEvenIfEditing",
    "markdownNotes",
    "miniaturizeOnCopy",
    "quickRevealWithOptionKey",
    "quitTerminatesProcessEvenInSystemTrayMode",
    "quitOnAllWindowsClosed",
    "screenCaptureBlocked",
    "showCopyFieldButton",
    "showDatabasesManagerOnCloseAllWindows",
    "showDatabasesManagerOnAppLaunch",
    "showOfflineOptionsOnLocalDeviceDatabases",
    "showPasswordImmediatelyInOutline",
    "showSystemTrayIcon",
    "showPasswordGenInTray",
    "showAutoFillTotpCopiedMessage",
    "hideDockIconOnAllMinimized",
    "closeManagerOnLaunch",
    "autoLaunchSingleDatabase",
    "autoCommitScannedTotp",

    // Auto-Lock
    "autoLockTimeout",
    "autoLockIfInBackgroundTimeoutSeconds",
    "autoPromptForTouchIdOnActivate",

    // Key Files
    "hideKeyFileNameOnLockScreen",
    "doNotRememberKeyFile",

    // Password / TOTP
    "passwordGenerationConfig",
    "trayPasswordGenerationConfig",
    "addLegacySupplementaryTotpCustomFields",
    "addOtpAuthUrl",
    "twoFactorEasyReadSeparator",
    "twoFactorHideCountdownDigits",   // NOTE: macOS uses this key; iOS uses "twoFactorHideCountdownDigits2"

    // FavIcons / AutoFill
    "favIconDownloadOptions",
    "autoFillNewRecordSettings",
    "allowEmptyOrNoPasswordEntry",
    "associatedWebsites",

    // Sync / Backup
    "atomicSftpWrite",
    "makeLocalRollingBackups",
    "stripUnusedHistoricalIcons",
    "stripUnusedIconsOnSave",
    "useIsolatedDropbox",
    "useParentGroupIconOnCreate",
    "disableNativeNetworkStorageOptions",
    "disableWiFiSyncClientMode",
    "wiFiSyncOn",
    "runSshAgent",
    "sshAgentApprovalDefaultExpiryMinutes",
    "sshAgentRequestDatabaseUnlockAllowed",
    "sshAgentPreventRapidRepeatedUnlockRequests",
    "runBrowserAutoFillProxyServer-Prod-22-Oct-2022",

    // App Lock / Access Control
    "appLockMode2.0",
    "appLockDelay2.0",
    "appLockAppliesToPreferences",
    "deleteDataAfterFailedUnlockCount",
    "databasesAreAlwaysReadOnly",
    "disableExport",
    "disablePrinting",
    "disableCopyTo",
    "disableMakeVisibleInFiles",

    // Duplicate / Export
    "duplicateItemPreserveTimestamp",
    "duplicateItemReferencePassword",
    "duplicateItemReferenceUsername",
    "duplicateItemEditAfterwards",

    // Appearance
    "appAppearance2",
    "floatOnTop",
    "passwordGeneratorFloatOnTop",
    "largeTextViewFloatOnTop",
    "systemMenuClickAction",
    "showHiddenDatabases",

    // Enterprise / Organisation
    "businessOrganisationName",
]

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

/// PropertyList values that JSON can't represent natively (Data, Date) are
/// base64-encoded / ISO-8601-stringified so the JSON round-trip is lossless.
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
                if let b64 = dict["value"] as? String, let data = Data(base64Encoded: b64) {
                    return data
                }
            case "date":
                if let s = dict["value"] as? String,
                   let date = ISO8601DateFormatter().date(from: s) {
                    return date
                }
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
    guard let (plistURL, groupID) = locatePlist() else {
        throw StrongboxPrefsError.plistNotFound
    }

    let all = try readPlist(from: plistURL)

    var exported: [String: Any] = [:]
    for key in exportableKeys {
        if let value = all[key] {
            exported[key] = plistValueToJSON(value)
        }
    }

    let json = try JSONSerialization.data(
        withJSONObject: exported,
        options: [.prettyPrinted, .sortedKeys]
    )

    let destination: URL
    if let path = outputPath {
        destination = URL(fileURLWithPath: path)
    } else {
        let name = "strongbox-prefs-\(ISO8601DateFormatter().string(from: Date()).prefix(10)).json"
        destination = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appending(path: name, directoryHint: .notDirectory)
    }

    try json.write(to: destination, options: .atomic)
    print("✅ Exported \(exported.count) settings from group '\(groupID)'")
    print("   → \(destination.path)")
}

func importPrefs(from inputPath: String) throws {
    guard let (plistURL, groupID) = locatePlist() else {
        throw StrongboxPrefsError.plistNotFound
    }

    let jsonData = try Data(contentsOf: URL(fileURLWithPath: inputPath))
    guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
        throw StrongboxPrefsError.invalidJSON
    }

    var current = try readPlist(from: plistURL)

    var importedCount = 0
    var skippedCount = 0

    for (key, jsonValue) in jsonDict {
        guard exportableKeys.contains(key) else {
            print("⚠️  Skipping unknown/non-exportable key: \(key)")
            skippedCount += 1
            continue
        }
        current[key] = jsonValueToPlist(jsonValue)
        importedCount += 1
    }

    try writePlist(current, to: plistURL)

    // Also sync via defaults(1) so cfprefsd picks up the changes immediately
    let task = Process()
    task.launchPath = "/usr/bin/defaults"
    task.arguments = ["read", groupID]
    task.standardOutput = FileHandle.nullDevice
    task.standardError = FileHandle.nullDevice
    try? task.run()
    task.waitUntilExit()

    print("✅ Imported \(importedCount) settings into group '\(groupID)'")
    if skippedCount > 0 {
        print("   ⚠️  Skipped \(skippedCount) unrecognised keys.")
    }
    print("   Restart Strongbox to apply all changes.")
}

func listPrefs() throws {
    guard let (plistURL, groupID) = locatePlist() else {
        throw StrongboxPrefsError.plistNotFound
    }

    let all = try readPlist(from: plistURL)

    print("Strongbox macOS Preferences  [\(groupID)]")
    print(String(repeating: "─", count: 60))

    let sorted = exportableKeys.sorted()
    for key in sorted {
        if let value = all[key] {
            print("  \(key) = \(value)")
        }
    }
    print(String(repeating: "─", count: 60))
}

// MARK: – Errors

enum StrongboxPrefsError: LocalizedError {
    case plistNotFound, invalidPlist, invalidJSON, missingArgument(String)

    var errorDescription: String? {
        switch self {
        case .plistNotFound:
            return """
            Could not find the Strongbox preferences plist.
            Searched in:
            \(knownGroupIDs.map { "  ~/Library/Group Containers/\($0)/Library/Preferences/\($0).plist" }.joined(separator: "\n"))
            Make sure Strongbox has been run at least once.
            """
        case .invalidPlist:
            return "The plist file could not be parsed."
        case .invalidJSON:
            return "The input file is not valid JSON."
        case .missingArgument(let msg):
            return msg
        }
    }
}

// MARK: – Entry Point

func printUsage() {
    print("""
    strongbox-prefs – Export / Import Strongbox macOS Preferences

    USAGE:
      strongbox-prefs export [output.json]   Export user settings to JSON
      strongbox-prefs import <input.json>    Import user settings from JSON
      strongbox-prefs list                   Show current exportable settings

    NOTES:
      • Only user-configurable settings are included (no license data,
        no biometric cache, no CloudKit tokens, no database list).
      • After importing, restart Strongbox for all settings to take effect.
      • Binary plist values (Data, Date) are preserved through a typed JSON
        wrapper so the round-trip is lossless.
    """)
}

let args = CommandLine.arguments.dropFirst()

do {
    switch args.first {
    case "export":
        try exportPrefs(to: args.dropFirst().first)
    case "import":
        guard let path = args.dropFirst().first else {
            throw StrongboxPrefsError.missingArgument("Usage: strongbox-prefs import <input.json>")
        }
        try importPrefs(from: path)
    case "list":
        try listPrefs()
    default:
        printUsage()
        if args.first != nil && args.first != "--help" && args.first != "-h" {
            exit(1)
        }
    }
} catch {
    fputs("🔴 Error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
