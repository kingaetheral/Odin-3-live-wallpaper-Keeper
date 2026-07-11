#!/system/bin/sh
# Live Wallpaper Keeper - boot service
#
# Strategy:
#  - When the wallpaper is healthy (component present), keep a fresh backup.
#  - At boot, if the wallpaper reverted (marker missing), restore the backup
#    and reload the wallpaper service so it takes effect.

DIR=/data/adb/live_wallpaper_keeper
CONF=$DIR/config.conf
LOG=$DIR/keeper.log
WP=/data/system/users/0/wallpaper_info.xml
BACKUP=$DIR/wallpaper_info.backup.xml

log() { echo "$(date '+%m-%d %H:%M:%S') $1" >> "$LOG"; }

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 5; done

[ -f "$CONF" ] || exit 0
. "$CONF"

sleep "${BOOT_DELAY:-40}"

: > "$LOG"
log "keeper started (component: $WALLPAPER_COMPONENT)"

if [ ! -f "$WP" ]; then
  log "ERROR: $WP not found"
  exit 0
fi

healthy() {
  grep -qa "${HEALTHY_MARKER:-VideoWallpaperService}" "$WP" 2>/dev/null
}

if healthy; then
  # Wallpaper survived the boot. Refresh our backup so it stays current.
  cp -f "$WP" "$BACKUP"
  log "OK: live wallpaper present, backup refreshed"
  exit 0
fi

# Wallpaper reverted.
log "MISMATCH: live wallpaper reverted to default"

if [ ! -f "$BACKUP" ]; then
  log "no backup available yet - cannot restore. Set wallpaper and reboot once."
  exit 0
fi

# Restore the backed-up wallpaper_info.xml with correct owner/permissions.
# system_server reads this file; it must be owned by system:system, mode 600.
cp -f "$BACKUP" "$WP"
chown 1000:1000 "$WP" 2>/dev/null
chmod 600 "$WP" 2>/dev/null
# Match SELinux context to the users directory
chcon --reference=/data/system/users/0 "$WP" 2>/dev/null \
  || restorecon "$WP" 2>/dev/null
log "restored wallpaper_info.xml from backup"

# Try to make it take effect without a second reboot.
if [ "${REAPPLY_AFTER_RESTORE:-1}" = "1" ] && [ -n "$WALLPAPER_COMPONENT" ]; then
  # Nudge the wallpaper service to (re)bind. Best-effort; several approaches:
  # 1) Ensure the provider package isn't stopped
  cmd package unstop "$WALLPAPER_PACKAGE" 2>/dev/null
  am start-service "$WALLPAPER_COMPONENT" 2>/dev/null
  # 2) Ask WallpaperManagerService to reload by restarting it is not safe;
  #    instead, poke the settings so a rebind happens on next unlock.
  log "requested wallpaper service rebind ($WALLPAPER_COMPONENT)"
  log "NOTE: if wallpaper still shows default, a reboot will apply the restore"
fi

log "keeper done"
