#!/usr/bin/env python3
import os
import sys
import subprocess
import argparse
import signal
from urllib.request import urlopen

try:
    import gi
    gi.require_version('Gtk', '3.0')
    
    # Try AyatanaAppIndicator3 first (newer Ubuntu)
    try:
        gi.require_version('AyatanaAppIndicator3', '0.1')
        from gi.repository import AyatanaAppIndicator3 as AppIndicator
    except (ImportError, ValueError):
        # Fallback to AppIndicator3 (older Ubuntu)
        try:
            gi.require_version('AppIndicator3', '0.1')
            from gi.repository import AppIndicator3 as AppIndicator
        except (ImportError, ValueError):
            print("Missing dependencies: sudo apt install gir1.2-ayatanaappindicator3-0.1 OR gir1.2-appindicator3-0.1")
            sys.exit(1)
            
    from gi.repository import Gtk, GLib
except ImportError:
    print("Missing dependencies: sudo apt install python3-gi gir1.2-gtk-3.0")
    sys.exit(1)

class WeChatTray:
    def __init__(self, project_root):
        self.project_root = os.path.abspath(project_root)
        self.indicator_id = "wechat-skill-indicator"
        
        # Icon path
        icon_path = os.path.join(self.project_root, ".claude", "hooks", "wechat-tray.ico")
        if not os.path.exists(icon_path):
            icon_path = "system-run" # Fallback to system icon
            
        self.indicator = AppIndicator.Indicator.new(
            self.indicator_id,
            icon_path,
            AppIndicator.IndicatorCategory.APPLICATION_STATUS
        )
        self.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE)
        self.indicator.set_menu(self.build_menu())
        
        # Setup polling for status updates
        GLib.timeout_add_seconds(5, self.update_status)

    def build_menu(self):
        menu = Gtk.Menu()
        
        item_gui = Gtk.MenuItem(label="Open Web GUI")
        item_gui.connect("activate", self.on_open_gui)
        menu.append(item_gui)
        
        menu.append(Gtk.SeparatorMenuItem())
        
        item_start = Gtk.MenuItem(label="Start Watcher")
        item_start.connect("activate", self.on_start_watcher)
        menu.append(item_start)
        
        item_stop = Gtk.MenuItem(label="Stop Watcher")
        item_stop.connect("activate", self.on_stop_watcher)
        menu.append(item_stop)
        
        menu.append(Gtk.SeparatorMenuItem())
        
        item_quit = Gtk.MenuItem(label="Quit")
        item_quit.connect("activate", self.on_quit)
        menu.append(item_quit)
        
        menu.show_all()
        return menu

    def update_status(self):
        # Optional: check if watcher is actually running and update icon/tooltip
        return True

    def on_open_gui(self, _):
        subprocess.Popen(["xdg-open", "http://localhost:3456"])

    def on_start_watcher(self, _):
        script = os.path.join(self.project_root, ".claude", "skills", "wechat-skill-2", "collect-wechat.sh")
        subprocess.Popen(["bash", script, "--start"], cwd=self.project_root)

    def on_stop_watcher(self, _):
        script = os.path.join(self.project_root, ".claude", "skills", "wechat-skill-2", "collect-wechat.sh")
        subprocess.Popen(["bash", script, "--stop"], cwd=self.project_root)

    def on_quit(self, _):
        self.on_stop_watcher(None)
        Gtk.main_quit()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-ProjectRoot", required=True)
    args = parser.parse_args()
    
    # Handle Ctrl+C
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    
    tray = WeChatTray(args.ProjectRoot)
    Gtk.main()

if __name__ == "__main__":
    main()
