using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;
using winrt.Windows.UI.Notifications;
using Dino.Plugins.WindowsNotification.Vapi.Win32Api;
using Xmpp;

namespace Dino.Plugins.WindowsNotification {
    private delegate void NodeFunction(StanzaNode node);

    public enum ActivationType {
        Foreground,
        Background
    }

    public enum Scenario {
        Basic,
        IncomingCall
    }

    private class Button {
        public string title;
        public string arguments;
        public string imageUri;
        public ActivationType activationType;
    }

    public class ToastNotificationBuilder  {
        private static bool _supportsModernFeatures = IsWindows10();
        private Gee.List<Button> _buttons = new Gee.ArrayList<Button>();
        private string _header = null;
        private string _body = null;
        private string _appLogo = null;
        private string _inlineImage = null;
        private Scenario _scenario = Scenario.Basic;

        public ToastNotificationBuilder() {
        }

        public ToastNotificationBuilder AddButton(string title, string arguments, string? imageUri = null, ActivationType activationType = ActivationType.Foreground) {
            _buttons.add(new Button() { title = title, arguments = arguments, imageUri = imageUri, activationType = activationType });
            return this;
        }

        public ToastNotificationBuilder SetHeader(string? header) {
            _header = header;
            return this;
        }

        public ToastNotificationBuilder SetBody(string? body) {
            _body = body;
            return this;
        }

        public ToastNotificationBuilder SetAppLogo(string? applogo_path) {
            _appLogo = applogo_path;
            return this;
        }

        public ToastNotificationBuilder SetInlineImage(string? image_path) {
            _inlineImage = image_path;
            return this;
        }

        public ToastNotificationBuilder SetScenario(Scenario scenario) {
            _scenario = scenario;
            return this;
        }

        public async ToastNotification Build() {
            if (!_supportsModernFeatures) {
                return yield BuildFromLegacyTemplate();
            }
            return BuildWithToastGeneric();
        }

        private async StanzaNode BuildStanzaFromXml(string xml) {
            var reader = new Xmpp.StanzaReader.for_string(xml);

            StanzaNode root_node = yield reader.read_node();

            ExecuteOnAllSubNodes(root_node, (node) => {
                node.ns_uri = "";
                foreach (var attr in node.attributes){
                    attr.ns_uri = "";
                }
            });

            return root_node;
        }

        private Gee.ArrayList<StanzaNode> FindRecursive(StanzaNode node, string tag_name, Gee.List<StanzaAttribute>? attributes) {
            var ret = new Gee.ArrayList<StanzaNode>();
            FindRecursiveInternal(node, tag_name, attributes, ret);
            return ret;
        }

        private void FindRecursiveInternal(StanzaNode root_node, string tag_name, Gee.List<StanzaAttribute>? attributes, Gee.List<StanzaNode> list) {
            if (root_node.name == tag_name) {
                if (attributes != null) {
                    foreach (var attr in attributes) {
                        var node_attr = root_node.get_attribute_raw(attr.name, attr.ns_uri);
                        if (node_attr != null && node_attr.equals(attr)) {
                            list.add(root_node);
                            break;
                        }
                    }
                }
                else {
                    list.add(root_node);
                }
            }
            foreach (var node in root_node.get_all_subnodes()) {
                FindRecursiveInternal(node, tag_name, attributes, list);
            }
        }

        private string ToXml(StanzaNode node) {
            var namespace_state = new NamespaceState();
            namespace_state.set_current("");
            return node.to_xml(namespace_state);
        }

        private void ExecuteOnAllSubNodes(StanzaNode root_node, NodeFunction func) {
            func(root_node);
            foreach (var node in root_node.get_all_subnodes()) {
                ExecuteOnAllSubNodes(node, func);
            }
        }

        // Legacy templates, works on both Windows 8.1 and Windows 10:
        // https://docs.microsoft.com/en-us/previous-versions/windows/apps/hh761494(v=win.10)
        private async ToastNotification BuildFromLegacyTemplate() {
            ToastTemplateType templateType = _header != null ? ToastTemplateType.ToastText02 : ToastTemplateType.ToastText01;
            if (_appLogo != null) {
                if (templateType == ToastTemplateType.ToastText02) {
                    templateType = ToastTemplateType.ToastImageAndText02;
                } else {
                    templateType = ToastTemplateType.ToastImageAndText01;
                }
            }

            var template = yield BuildStanzaFromXml(ToastNotificationManager.GetTemplateContent(templateType));
            { // add header and body
                var attributes = new Gee.ArrayList<StanzaAttribute>();
                attributes.add(new StanzaAttribute.build("", "id", "1"));
                attributes.add(new StanzaAttribute.build("", "id", "2"));
    
                var nodes = FindRecursive(template, "text", attributes);
                foreach (var node in nodes) {
                    var attr = node.get_attribute_raw("id", "");
                    if (attr != null) {
                        if (attr.val == "1") {
                            if (templateType == ToastTemplateType.ToastText02 || templateType ==  ToastTemplateType.ToastImageAndText02) {
                                node.put_node(new StanzaNode.text(_header));
                            } else {
                                node.put_node(new StanzaNode.text(_body));
                            }
                        } else if (attr.val == "2") {
                            node.put_node(new StanzaNode.text(_body));
                        }
                    }
                }
            }

            { // add image
                var nodes = FindRecursive(template, "image", null);
                foreach (var node in nodes) {
                    var attr = node.get_attribute_raw("src", "");
                    if (attr != null) {
                        attr.val = _appLogo;
                    }
                }
            }

            var xml = ToXml(template);
            return new ToastNotification(xml);
        }

        // Modern adaptive templates for Windows 10:
        // https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/adaptive-interactive-toasts?tabs=builder-syntax
        private ToastNotification BuildWithToastGeneric() {
            var toast = new StanzaNode.build("toast", "");
            if (_scenario == Scenario.IncomingCall) {
                toast.put_attribute("scenario", "incomingCall");
            }

            { // add content
                var visual = new StanzaNode.build("visual", "");
                {
                    var binding = new StanzaNode.build("binding", "");
                    binding.put_attribute("template", "ToastGeneric");

                    if (_header != null) {
                        var header = new StanzaNode.build("text", "");
                        header.put_node(new StanzaNode.text(_header));
                        binding.put_node(header);
                    }
    
                    if (_body != null) {
                        var body = new StanzaNode.build("text", "");
                        body.put_node(new StanzaNode.text(_body));
                        binding.put_node(body);
                    }
    
                    if (_appLogo != null) {
                        var appLogo = new StanzaNode.build("image", "");
                        appLogo.put_attribute("placement", "appLogoOverride");
                        appLogo.put_attribute("src", _appLogo);
                        binding.put_node(appLogo);
                    }

                    if (_inlineImage != null) {
                        var inlineImage = new StanzaNode.build("image", "");
                        inlineImage.put_attribute("src", _inlineImage);
                        binding.put_node(inlineImage);
                    }

                    visual.put_node(binding);
                }
                toast.put_node(visual);
            }

            if (_buttons.size > 0) { // add actions
                var actions = new StanzaNode.build("actions", "");
                foreach (var button in _buttons) {
                    var action = new StanzaNode.build("action", "");
                    action.put_attribute("content", button.title);
                    action.put_attribute("arguments", button.arguments);
                    if (button.activationType == ActivationType.Background) {
                        action.put_attribute("activationType", "background");
                    }
                    actions.put_node(action);
                }
                toast.put_node(actions);
            }

            return new ToastNotification(ToXml(toast));
        }
    }
}
