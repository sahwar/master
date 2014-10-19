/* Application.vala
 *
 * Copyright © 2009 - 2014 Jerry Casiano
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 *  Jerry Casiano <JerryCasiano@gmail.com>
 */

namespace FontManager {

    namespace Intl {

        public void setup (string name = NAME) {
            GLib.Intl.bindtextdomain(name, null);
            GLib.Intl.bind_textdomain_codeset(name, null);
            GLib.Intl.textdomain(name);
            GLib.Intl.setlocale(GLib.LocaleCategory.ALL, null);
            return;
        }

    }

    namespace Logging {

        public void setup (LogLevel level = LogLevel.INFO) {
            Logger.initialize(FontManager.About.NAME);
            Logger.DisplayLevel = level;
            message("%s %s", FontManager.About.NAME, FontManager.About.VERSION);
            message("Using FontConfig %s", FontConfig.get_version_string());
            message("Using Pango %s", Pango.version_string());
            message("Using Gtk+ %i.%i.%i", Gtk.MAJOR_VERSION, Gtk.MINOR_VERSION, Gtk.MICRO_VERSION);
            return;
        }
    }

    [DBus (name = "org.gnome.FontManager")]
    public class Application: Gtk.Application  {

        [DBus (visible = false)]
        public MainWindow main_window { get; set; }
        [DBus (visible = false)]
        public Gtk.Builder builder { get; set; }

        public Application (string app_id, ApplicationFlags app_flags) {
            Object(application_id : app_id, flags : app_flags);
            startup.connect(() => {
                builder = new Gtk.Builder();
                if (Gnome3()) {
                    set_gnome_app_menu(this, builder);
                    message("Running on %s", get_command_line_output("gnome-shell --version"));
                } else {
                    message("Running on %s", Environment.get_variable("XDG_CURRENT_DESKTOP"));
                }
            });
        }

        protected override void activate () {
            Main.instance.on_activate();
            return;
        }

        public void on_quit () {
            Main.instance.settings.apply();
            main_window.hide();
            remove_window(main_window);
            quit();
        }

        public void on_about () {
            show_about_dialog(main_window);
            return;
        }

        public void on_help () {
            show_help_dialog();
            return;
        }

        public static int main (string [] args) {
            Environment.set_application_name(About.NAME);
            Environment.set_variable("XDG_CONFIG_HOME", "", true);
            FontConfig.enable_user_config(false);
            Logging.setup();
            Intl.setup();
            Gtk.init(ref args);
            set_application_style();
            if (update_declined())
                return 0;
            var main = new Application(BUS_ID, (ApplicationFlags.FLAGS_NONE));
            int res = main.run(args);
            return res;
        }

    }

}
