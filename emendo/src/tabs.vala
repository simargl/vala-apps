namespace Emendo {
public class Tabs: GLib.Object {
    public string get_path_at_tab(int pos) {
        string path = files.nth_data(pos);
        return path;
    }

    public Gtk.SourceView get_sourceview_at_tab(int pos) {
        var scrolled = (Gtk.ScrolledWindow) notebook.get_nth_page(pos);
        var view = (Gtk.SourceView) scrolled.get_child();
        return view;
    }

    public Gtk.Label get_label_at_tab(int pos) {
        var scrolled = (Gtk.ScrolledWindow) notebook.get_nth_page(pos);
        var grid = (Gtk.Grid) notebook.get_tab_label(scrolled);
        var eventbox = (Gtk.EventBox) grid.get_child_at(0, 0);
        var label = (Gtk.Label) eventbox.get_child();
        return label;
    }

    public string get_current_path() {
        string path = files.nth_data(notebook.get_current_page());
        return path;
    }

    public Gtk.SourceView get_current_sourceview() {
        var scrolled = (Gtk.ScrolledWindow) notebook.get_nth_page(
                           notebook.get_current_page());
        var view = (Gtk.SourceView) scrolled.get_child();
        return view;
    }

    public Gtk.Label get_current_label() {
        var scrolled = (Gtk.ScrolledWindow) notebook.get_nth_page(
                           notebook.get_current_page());
        var grid = (Gtk.Grid) notebook.get_tab_label(scrolled);
        var eventbox = (Gtk.EventBox) grid.get_child_at(0, 0);
        var label = (Gtk.Label) eventbox.get_child();
        return label;
    }

    public void check_notebook_for_file_name(string path) {
        notebook.get_current_page();
        for (int i = 0; i < files.length(); i++) {
            if (files.nth_data(i) == path) {
                var scrolled = (Gtk.ScrolledWindow) notebook.get_nth_page(i);
                var nbook = new Emendo.NBook();
                nbook.destroy_tab(scrolled, path);
                print("debug: removed tab number %d with: %s\n", i, path);
            }
        }
    }
}
}
