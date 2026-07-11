# Live Wallpaper Keeper

A Magisk module that stops your live wallpaper from reverting to the default after a reboot.

## The problem

Android stores the active wallpaper as a component reference in
`/data/system/users/0/wallpaper_info.xml`. When a live wallpaper's provider
process isn't ready in time at boot — often because a battery optimizer killed
it, or it simply loses the startup race — the system falls back to the default
wallpaper and rewrites that file. The result: your live wallpaper is gone after
some reboots, seemingly at random.

Live Wallpaper Keeper backs up the wallpaper configuration while it's healthy
and restores it at boot if it reverted, then asks the wallpaper service to
rebind.

## How it works

On each boot, after the system settles, the module:

1. Checks whether the live wallpaper is still set.
2. If it is, refreshes its backup of `wallpaper_info.xml` so the saved copy
   stays current.
3. If it reverted to default, restores the backed-up configuration with the
   correct owner (`system:system`), permissions (`600`), and SELinux context,
   then nudges the wallpaper provider to rebind.

All actions are written to a log for verification.

## Requirements

- Rooted device with Magisk
- A live wallpaper already applied (by any means — the wallpaper app's own
  picker, system settings, or a third-party applier)

The module is independent of how the wallpaper was set. It operates on the
system's wallpaper configuration, not on any particular wallpaper app.

## Install

1. Apply your live wallpaper and confirm it looks correct.
2. Install the module in Magisk → Modules → Install from storage. The installer
   captures a backup of your current wallpaper configuration during install.
3. Reboot.

If the installer reports that the current wallpaper doesn't match an expected
live wallpaper, set your wallpaper first and reboot once so the module can
capture a good backup.

## Configuration

Settings live in `/data/adb/live_wallpaper_keeper/config.conf`:

| Key | Meaning |
|---|---|
| `WALLPAPER_COMPONENT` | The live wallpaper component to protect (e.g. `com.example.app/.service.WallpaperService`) |
| `WALLPAPER_PACKAGE` | The package that provides the wallpaper |
| `HEALTHY_MARKER` | A distinctive substring of the component used to detect a healthy wallpaper |
| `BOOT_DELAY` | Seconds to wait after boot before checking (default 40) |
| `REAPPLY_AFTER_RESTORE` | `1` to nudge the wallpaper service to rebind after a restore |

To find your wallpaper's component, run:

```
su -c 'cat /data/system/users/0/wallpaper_info.xml'
```

and read the `component…` value from the output.

## Verifying

After a reboot:

```
su -c 'cat /data/adb/live_wallpaper_keeper/keeper.log'
```

Expected lines:

- `OK: live wallpaper present, backup refreshed` — the wallpaper survived this
  boot; the backup was updated.
- `restored wallpaper_info.xml from backup` — the wallpaper had reverted and the
  module restored it.

Because reverts happen intermittently, the meaningful test is over several
reboots: if the default wallpaper no longer returns permanently, the module is
doing its job.

## Recommended companion setting

The underlying cause is usually the wallpaper
provider being killed at boot. For best results, also exclude the wallpaper app
from battery optimization:

**Settings → Apps → [your wallpaper app] → Battery → Unrestricted**, and allow
background autostart if your ROM offers it.

With both in place, reverts should stop entirely — the battery setting prevents
most of them, and the module restores any that still slip through.

## Limitations

- The module runs after boot completes, so a brief flash of the default
  wallpaper is possible before the restore applies. It prevents the permanent
  revert, not necessarily a momentary one.
- After a restore, the wallpaper may fully rebind only after the next unlock. If
  it still shows default, a reboot applies the restored configuration.
- Only the primary user (`user 0`) is handled. Secondary users and work profiles
  are not currently supported.

## Uninstall

Remove the module in Magisk and reboot. Your wallpaper configuration is left as
whatever it currently is. The backup directory
`/data/adb/live_wallpaper_keeper/` can be deleted manually if desired.

## License

MIT
