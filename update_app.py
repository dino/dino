with open("main/src/ui/application.vala", "r") as f:
    content = f.read()

# Add style manager call in startup or activate
target = "startup.connect(() => {"
replacement = """startup.connect(() => {
            var style_manager = Adw.StyleManager.get_default();
            if (settings != null) {
                style_manager.color_scheme = settings.dark_mode ? Adw.ColorScheme.FORCE_DARK : Adw.ColorScheme.DEFAULT;
                settings.notify["dark-mode"].connect(() => {
                    style_manager.color_scheme = settings.dark_mode ? Adw.ColorScheme.FORCE_DARK : Adw.ColorScheme.DEFAULT;
                });
            }"""

if "Adw.StyleManager.get_default()" not in content:
    content = content.replace(target, replacement, 1)
    with open("main/src/ui/application.vala", "w") as f:
        f.write(content)
    print("Successfully updated application.vala")
else:
    print("Already updated")
