# strongbox-prefs-tool

A small macOS CLI tool for **exporting and importing Strongbox preferences** — useful when setting up a new Mac or transferring your configuration to a second device.

## Build

```bash
cd tools/strongbox-prefs-tool
swift build -c release
# Binary: .build/release/strongbox-prefs
```

Optionally copy to PATH:

```bash
cp .build/release/strongbox-prefs /usr/local/bin/strongbox-prefs
```

## Usage

```
strongbox-prefs export [output.json]          Export settings to JSON
strongbox-prefs import <input.json>           Import settings from JSON (replace mode)
strongbox-prefs import <input.json> --merge   Import settings, keep existing values
strongbox-prefs list                          Show current exportable settings
```

### Import modes

**Replace (default):** All exportable keys are removed from both plist files first, giving a clean baseline. Only the values present in the import file are then written. This guarantees no stale settings survive from a previous configuration.

**`--merge`:** Existing settings are left untouched; only keys present in the import file are overwritten. Useful when combining settings from two sources or transferring a partial set.

In both modes a timestamped backup is written to the current directory before any changes are made:

```
strongbox-prefs-backup-2026-03-24T15-34-02.json
```

### Typical workflow

#### On the old Mac

```bash
strongbox-prefs export strongbox-settings.json
# Transfer strongbox-settings.json to the new Mac (AirDrop, iCloud, …)
```

#### On the new Mac

```bash
# Launch Strongbox once (so the Group Container is created), then:
strongbox-prefs import strongbox-settings.json
# Restart Strongbox to apply all changes
```

## What is exported?

Only **user-configurable, non-sensitive settings** are included (~87 keys), e.g.:

- Auto-lock timeouts, App Lock mode and delay
- Clipboard handling (clear timeout, handoff, conceal from monitors)
- Backup and sync options (rolling backups, atomic SFTP writes, Wi-Fi Sync)
- UI preferences (markdown notes, colorblind palette, window behaviour)
- TOTP display (separator, hide countdown, add OTPAuth URL)
- Password generator and FavIcon download configuration
- SSH Agent, browser AutoFill proxy
- Keyboard shortcuts (global hotkeys via MASShortcutBinder)

**Not included** (security-sensitive or device-specific):

- License / Pro status
- Biometric cache, App Lock PIN
- CloudKit tokens / zone state
- Database list and metadata
- Install date, launch counters
