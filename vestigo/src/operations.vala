namespace Vestigo {
public class Operations: GLib.Object {
    // Make
    public void make_new(bool file) {
        string entry_title = null;
        string typed = null;
        if (file == true) {
            entry_title = _("Create File");
        } else {
            entry_title = _("Create Folder");
        }
        var dialog = new Gtk.Dialog();
        dialog.set_title(entry_title);
        dialog.set_border_width(10);
        dialog.set_property("skip-taskbar-hint", true);
        dialog.set_transient_for(window);
        dialog.set_resizable(false);
        var entry = new Gtk.Entry();
        entry.set_text("new");
        entry.select_region(0, 0);
        entry.set_position(-1);
        entry.set_size_request(250, 0);
        entry.activate.connect(() => {
            typed = entry.get_text();
            on_make_new_dialog_response(entry, dialog, typed, file);
        });
        var content = dialog.get_content_area() as Gtk.Box;
        content.pack_start(entry, true, true, 10);
        dialog.add_button(_("Close"), Gtk.ResponseType.CLOSE);
        dialog.add_button(_("Create"), Gtk.ResponseType.OK);
        dialog.set_default_response(Gtk.ResponseType.OK);
        dialog.show_all();
        if (dialog.run() == Gtk.ResponseType.OK) {
            typed = entry.get_text();
            on_make_new_dialog_response(entry, dialog, typed, file);
        }
        dialog.destroy();
    }

    private void on_make_new_dialog_response(Gtk.Entry entry, Gtk.Dialog dialog,
            string typed, bool file) {
        if (typed != "")
            if (file == true) {
                execute_command_sync("touch '%s'".printf(GLib.Path.build_filename(current_dir,
                                     typed)));
            } else {
                execute_command_sync("mkdir '%s'".printf(GLib.Path.build_filename(current_dir,
                                     typed)));
            }
        dialog.destroy();
    }

    // Bookmark
    public void add_bookmark() {
        GLib.FileOutputStream fos = null;
        string bookmark = GLib.Path.build_filename(
                              GLib.Environment.get_user_config_dir(), "gtk-3.0/bookmarks");
        try {
            fos = File.new_for_path(bookmark).append_to(FileCreateFlags.NONE);
        } catch (GLib.Error e) {
            stderr.printf ("%s\n", e.message);
        }
        string current_uri = GLib.File.new_for_path(current_dir).get_uri() + "\n";
        try {
            fos.write(current_uri.data);
        } catch (GLib.IOError e) {
            stderr.printf ("%s\n", e.message);
        }
    }

    // Open
    public void file_open_activate() {
        GLib.FileInfo file_info = null;
        var files_open = new GLib.List<string>();
        files_open = get_files_selection();
        if (files_open.length() == 1) {
            GLib.File file_check = GLib.File.new_for_path(files_open.nth_data(0));
            if (file_check.query_file_type(0) == GLib.FileType.DIRECTORY) {
                new Vestigo.IconView().open_location(GLib.File.new_for_path(files_open.nth_data(
                        0)),
                                                     true);
            } else {
                try {
                    file_info = file_check.query_info("standard::content-type", 0, null);
                } catch (GLib.Error e) {
                    stderr.printf("%s\n", e.message);
                }
                string content = file_info.get_content_type();
                string mime = GLib.ContentType.get_mime_type(content);
                var appinfo = AppInfo.get_default_for_type(mime, false);
                if (appinfo != null) {
                    execute_command_async("%s '%s'".printf(appinfo.get_executable(),
                                                           files_open.nth_data(0)));
                }
            }
        }
    }

    // Open With
    public void file_open_with_activate() {
        GLib.FileInfo file_info = null;
        var files_open_with = new GLib.List<string>();
        files_open_with = get_files_selection();
        if (files_open_with.length() == 1) {
            GLib.File file_check = GLib.File.new_for_path(files_open_with.nth_data(0));
            if (file_check.query_file_type(0) != GLib.FileType.DIRECTORY) {
                try {
                    file_info = file_check.query_info("standard::content-type", 0, null);
                } catch (GLib.Error e) {
                    stderr.printf("%s\n", e.message);
                }
                string content = file_info.get_content_type();
                string mime = GLib.ContentType.get_mime_type(content);
                var dialog = new Gtk.AppChooserDialog.for_content_type(window, 0, mime);
                if (dialog.run() == Gtk.ResponseType.OK) {
                    var appinfo = dialog.get_app_info();
                    if (appinfo != null) {
                        execute_command_async("%s '%s'".printf(appinfo.get_executable(),
                                                               files_open_with.nth_data(0)));
                    }
                }
                dialog.close();
            }
        }
    }

    // Cut
    public void file_cut_activate() {
        if (files_copy != null) {
            files_copy = null;
            //files_copy.clear();
        }
        files_cut = get_files_selection();
    }

    // Copy
    public void file_copy_activate() {
        if (files_cut!= null) {
            files_cut = null;
            //files_cut.clear();
        }
        files_copy = get_files_selection();
    }

    // Paste
    public void file_paste_activate() {
        if (files_copy != null) {
            foreach(string i in files_copy) {
                execute_command_sync("cp -a '%s' '%s'".printf(i, current_dir));
                stdout.printf("DEBUG: copying '%s' to '%s'\n".printf(i, current_dir));
            }
        }
        if (files_cut != null) {
            foreach(string i in files_cut) {
                execute_command_sync("mv '%s' '%s'".printf(i, current_dir));
                stdout.printf("DEBUG: moving '%s' to '%s'\n".printf(i, current_dir));
            }
        }
    }

    // Rename
    public void file_rename_activate() {
        var files_rename = new GLib.List<string>();
        files_rename = get_files_selection();
        string typed = null;
        if (files_rename.length() == 1) {
            var dialog = new Gtk.Dialog();
            dialog.set_title(_("Rename File/Folder"));
            dialog.set_border_width(10);
            dialog.set_property("skip-taskbar-hint", true);
            dialog.set_transient_for(window);
            dialog.set_resizable(false);
            var entry = new Gtk.Entry();
            entry.set_size_request(250, 0);
            entry.set_text(GLib.Path.get_basename(files_rename.nth_data(0)));
            entry.activate.connect(() => {
                typed = entry.get_text();
                on_rename_dialog_response(entry, dialog, files_rename.nth_data(0), typed);
            });
            var content = dialog.get_content_area() as Gtk.Box;
            content.pack_start(entry, true, true, 10);
            dialog.add_button(_("Close"), Gtk.ResponseType.CLOSE);
            dialog.add_button(_("Rename"), Gtk.ResponseType.OK);
            dialog.set_default_response(Gtk.ResponseType.OK);
            dialog.show_all();
            if (dialog.run() == Gtk.ResponseType.OK) {
                typed = entry.get_text();
                on_rename_dialog_response(entry, dialog, files_rename.nth_data(0), typed);
            }
            dialog.destroy();
        }
    }

    private void on_rename_dialog_response(Gtk.Entry entry, Gtk.Dialog dialog,
                                           string old_path, string new_name) {
        if (new_name != "") {
            execute_command_sync("mv '%s' '%s'".printf(old_path,
                                 GLib.Path.build_filename(current_dir, new_name)));
        }
        stdout.printf("DEBUG: moving '%s' to '%s'\n".printf(old_path,
                      GLib.Path.build_filename(current_dir, new_name)));
        dialog.destroy();
    }

    // Delete
    public void file_delete_activate() {
        var files_delete = new GLib.List<string>();
        files_delete = get_files_selection();
        var dialog = new Gtk.Dialog();
        dialog.set_title(_("Delete File/Folder"));
        dialog.set_border_width(10);
        dialog.set_property("skip-taskbar-hint", true);
        dialog.set_transient_for(window);
        dialog.set_resizable(false);
        var label = new Gtk.Label(_("Delete %d selected item(s)?").printf(
                                      (int)files_delete.length()));
        var content = dialog.get_content_area() as Gtk.Box;
        content.pack_start(label, true, true, 10);
        dialog.add_button(_("Close"), Gtk.ResponseType.CLOSE);
        dialog.add_button(_("Delete"), Gtk.ResponseType.OK);
        dialog.set_default_response(Gtk.ResponseType.OK);
        dialog.show_all();
        if (dialog.run() == Gtk.ResponseType.OK) {
            foreach(string i in files_delete) {
                on_delete_dialog_response(dialog, i);
            }
        }
        dialog.destroy();
    }

    private void on_delete_dialog_response(Gtk.Dialog dialog, string filename) {
        if (filename != "") {
            execute_command_sync("rm -r '%s'".printf(filename));
        }
        stdout.printf("DEBUG: deleted '%s'\n".printf(filename));
        dialog.destroy();
    }

    // Properties
    public void file_properties_activate() {
        var files_properties = new GLib.List<string>();
        files_properties = get_files_selection();
        if (files_properties.length() == 1) {
            var dialog = new Gtk.Dialog();
            dialog.set_title(_("File properties"));
            dialog.set_border_width(10);
            dialog.set_property("skip-taskbar-hint", true);
            dialog.set_transient_for(window);
            dialog.set_resizable(false);
            dialog.width_request = 450;
            string fullpath = files_properties.nth_data(0);
            // name
            string name = GLib.Path.get_basename(fullpath);
            // location
            string location = GLib.Path.get_dirname(fullpath);
            // size, type, modified
            string size = "";
            string type = "";
            string modified = "";
            try {
                var file_check = GLib.File.new_for_path(fullpath);
                GLib.FileInfo file_info = file_check.query_info("*", 0, null);
                size = file_info.get_size().to_string();
                string content = file_info.get_content_type();
                type = GLib.ContentType.get_mime_type(content);
                modified = file_info.get_modification_time().to_iso8601();
            } catch (GLib.Error e) {
                stderr.printf ("%s\n", e.message);
            }
            // ui
            var label_name = new Gtk.Label("");
            label_name.set_markup(_("<b>Name:</b> %s".printf(name)));
            label_name.set_xalign(0.0f);
            var label_size = new Gtk.Label("");
            label_size.set_markup(_("<b>Size:</b> %s bytes".printf(size)));
            label_size.set_xalign(0.0f);
            var label_type = new Gtk.Label("");
            label_type.set_markup(_("<b>Type:</b> %s".printf(type)));
            label_type.set_xalign(0.0f);
            var label_location = new Gtk.Label("");
            label_location.set_markup(_("<b>Location:</b> %s".printf(location)));
            label_location.set_xalign(0.0f);
            var label_modified = new Gtk.Label("");
            label_modified.set_markup(_("<b>Modified:</b> %s".printf(modified)));
            label_modified.set_xalign(0.0f);
            var grid = new Gtk.Grid();
            grid.attach(label_name,     0, 0, 1, 1);
            grid.attach(label_size,     0, 1, 1, 1);
            grid.attach(label_type,     0, 2, 1, 1);
            grid.attach(label_location, 0, 3, 1, 1);
            grid.attach(label_modified, 0, 4, 1, 1);
            grid.set_column_spacing(5);
            grid.set_row_spacing(5);
            grid.set_border_width(10);
            grid.set_column_homogeneous(true);
            var container = dialog.get_content_area() as Gtk.Container;
            container.add(grid);
            dialog.show_all();
        }
    }

    private GLib.List<string> get_files_selection() {
        var list = new GLib.List<string>();
        List<Gtk.TreePath> paths = view.get_selected_items();
        GLib.Value filepath;
        foreach (Gtk.TreePath path in paths) {
            model.get_iter(out iter, path);
            model.get_value(iter, 2, out filepath);
            list.append((string)filepath);
        }
        return list;
    }

    public void execute_command_async(string item_name) {
        try {
            Process.spawn_command_line_async(item_name);
        } catch (GLib.Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }

    public void execute_command_sync(string item_name) {
        try {
            Process.spawn_command_line_sync(item_name);
        } catch (GLib.Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }
}
}