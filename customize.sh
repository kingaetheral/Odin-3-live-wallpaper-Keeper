#!/system/bin/sh
CONF_DIR=/data/adb/live_wallpaper_keeper

ui_print "*******************************"
ui_print " Live Wallpaper Keeper v1.0.0"
ui_print " by KingAether"
ui_print "*******************************"

mkdir -p "$CONF_DIR"
if [ -f "$CONF_DIR/config.conf" ]; then
  ui_print "- Kept existing config."
else
  cp -f "$MODPATH/config.conf" "$CONF_DIR/config.conf"
  ui_print "- Default config installed."
fi

# Take an initial backup right now if the wallpaper looks healthy
WP=/data/system/users/0/wallpaper_info.xml
if [ -f "$WP" ] && grep -qa "VideoWallpaperService" "$WP" 2>/dev/null; then
  cp -f "$WP" "$CONF_DIR/wallpaper_info.backup.xml"
  ui_print "- Backed up current live wallpaper config."
else
  ui_print "! Current wallpaper doesn't match expected live wallpaper."
  ui_print "  Set your live wallpaper first, then reboot once so the"
  ui_print "  keeper can capture a good backup."
fi

ui_print "- On each boot, restores the wallpaper if it reverted."
ui_print "- Log: $CONF_DIR/keeper.log"
ui_print "- Reboot to activate."

chmod 755 "$MODPATH/service.sh"
