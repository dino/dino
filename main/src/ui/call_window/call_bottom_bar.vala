using Dino.Entities;
using Gtk;
using Pango;

public class Dino.Ui.CallBottomBar : Gtk.Box {

    public signal void hang_up();

    public bool audio_enabled { get; set; }
    public bool video_enabled { get; set; }

    public string counterpart_display_name { get; set; }

    private Button audio_button = new Button() { height_request=45, width_request=45, halign=Align.START, valign=Align.START };
    private Overlay audio_button_overlay = new Overlay();
    private Image audio_image = new Image() { pixel_size=22 };
    private MenuButton audio_settings_button = new MenuButton() { halign=Align.END, valign=Align.END };
    public AudioSettingsPopover? audio_settings_popover;

    private Button video_button = new Button() { height_request=45, width_request=45, halign=Align.START, valign=Align.START };
    private Overlay video_button_overlay = new Overlay();
    private Image video_image = new Image() { pixel_size=22 };
    private MenuButton video_settings_button = new MenuButton() { halign=Align.END, valign=Align.END };
    public VideoSettingsPopover? video_settings_popover;

    private Label label = new Label("") { halign=Align.CENTER, valign=Align.CENTER, wrap=true, wrap_mode=Pango.WrapMode.WORD_CHAR, hexpand=true };
    private Stack stack = new Stack();

    public CallBottomBar() {
        Object(orientation:Orientation.HORIZONTAL, spacing:0);

        Box main_buttons = new Box(Orientation.HORIZONTAL, 20) { margin_start=40, margin_end=40, margin_bottom=20, margin_top=20, halign=Align.CENTER, hexpand=true };

        audio_button.set_child(audio_image);
        audio_button.add_css_class("call-button");
        audio_button.clicked.connect(() => { audio_enabled = !audio_enabled; });
        audio_button.margin_end = audio_button.margin_bottom = 5; // space for the small settings button
        audio_button_overlay.set_child(audio_button);
        audio_button_overlay.add_overlay(audio_settings_button);
        Util.menu_button_set_icon_with_size(audio_settings_button, "go-up-symbolic", 10);
        audio_settings_button.add_css_class("call-mediadevice-settings-button");
        main_buttons.append(audio_button_overlay);

        video_button.set_child(video_image);
        video_button.add_css_class("call-button");
        video_button.clicked.connect(() => { video_enabled = !video_enabled; });
        video_button.margin_end = video_button.margin_bottom = 5;
        video_button_overlay.set_child(video_button);
        video_button_overlay.add_overlay(video_settings_button);
        Util.menu_button_set_icon_with_size(video_settings_button, "go-up-symbolic", 10);
        video_settings_button.add_css_class("call-mediadevice-settings-button");
        main_buttons.append(video_button_overlay);

        Button button_hang = new Button() { height_request=45, width_request=45, halign=Align.START, valign=Align.START };
        button_hang.set_child(new Image() { icon_name="dino-phone-hangup-symbolic", pixel_size=22 });
        button_hang.add_css_class("call-button");
        button_hang.add_css_class("destructive-action");
        button_hang.clicked.connect(() => hang_up());
        main_buttons.append(button_hang);

        label.add_css_class("text-no-controls");

        stack.add_named(main_buttons, "control-buttons");
        stack.add_named(label, "label");
        this.append(stack);

        this.notify["audio-enabled"].connect(on_audio_enabled_changed);
        this.notify["video-enabled"].connect(on_video_enabled_changed);

        audio_enabled = true;
        video_enabled = false;

        on_audio_enabled_changed();
        on_video_enabled_changed();

        this.add_css_class("call-bottom-bar");
    }

    public AudioSettingsPopover? show_audio_device_choices(bool show) {
        audio_settings_button.visible = show;
        if (audio_settings_popover != null) audio_settings_popover.visible = false;
        if (!show) return null;

        audio_settings_popover = new AudioSettingsPopover();
        audio_settings_button.popover = audio_settings_popover;
        audio_settings_popover.microphone_selected.connect(() => { audio_settings_button.popdown(); });
        audio_settings_popover.speaker_selected.connect(() => { audio_settings_button.popdown(); });

        return audio_settings_popover;
    }

    public void show_audio_device_error() {
        audio_settings_button.set_icon_name("dialog-warning-symbolic");
        Util.force_error_color(audio_settings_button);
    }

    public VideoSettingsPopover? show_video_device_choices(bool show) {
        video_settings_button.visible = show;
        if (video_settings_popover != null) video_settings_popover.visible = false;
        if (!show) return null;

        video_settings_popover = new VideoSettingsPopover();
        video_settings_button.popover = video_settings_popover;
        video_settings_popover.camera_selected.connect(() => { video_settings_button.popdown(); });

        return video_settings_popover;
    }

    public void show_video_device_error() {
        video_settings_button.set_icon_name("dialog-warning-symbolic");
        Util.force_error_color(video_settings_button);
    }

    public void on_audio_enabled_changed() {
        if (audio_enabled) {
            audio_image.icon_name = "dino-microphone-symbolic";
            audio_button.add_css_class("white-button");
            audio_button.remove_css_class("transparent-white-button");
        } else {
            audio_image.icon_name = "dino-microphone-off-symbolic";
            audio_button.remove_css_class("white-button");
            audio_button.add_css_class("transparent-white-button");
        }
    }

    public void on_video_enabled_changed() {
        if (video_enabled) {
            video_image.icon_name = "dino-video-symbolic";
            video_button.add_css_class("white-button");
            video_button.remove_css_class("transparent-white-button");

        } else {
            video_image.icon_name = "dino-video-off-symbolic";
            video_button.remove_css_class("white-button");
            video_button.add_css_class("transparent-white-button");
        }
    }

    public void show_counterpart_ended(string text) {
        stack.set_visible_child_name("label");
        label.label = text;
    }

    public bool is_menu_active() {
        return (video_settings_button.popover != null && video_settings_button.popover.visible) ||
                (audio_settings_button.popover != null && audio_settings_button.popover.visible);
    }
}