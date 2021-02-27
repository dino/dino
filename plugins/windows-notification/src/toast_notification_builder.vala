using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;
using winrt.Windows.UI.Notifications;
using Dino.Plugins.WindowsNotification.Vapi.Win32Api;
using Xmpp;

namespace Dino.Plugins.WindowsNotification {
    private delegate void NodeFunction(StanzaNode node);
    private class Button {
        public string title;
        public string arguments;
    }

    public class ToastNotificationBuilder  {
        private static bool _supportsModernFeatures = SupportsModernNotifications();
        private Gee.List<Button> _buttons = new Gee.ArrayList<Button>();
        private string _header = null;
        private string _body = null;
        private string _imagePath = null;

        public ToastNotificationBuilder() {
        }

        public ToastNotificationBuilder AddButton(string title, string arguments) {
            _buttons.add(new Button() { title = title, arguments = arguments });
            return this;
        }

        public ToastNotificationBuilder SetHeader(string header) {
            _header = header;
            return this;
        }

        public ToastNotificationBuilder SetBody(string body) {
            _body = body;
            return this;
        }

        public ToastNotificationBuilder SetImage(string image_path) {
            _imagePath = image_path;
            return this;
        }

        // Legacy templates, for both Windows 8.1 and Windows 10:
        // https://docs.microsoft.com/en-us/previous-versions/windows/apps/hh761494(v=win.10)
        // Eventually modern adaptive templates might be desired:
        // https://docs.microsoft.com/en-us/windows/uwp/design/shell/tiles-and-notifications/adaptive-interactive-toasts?tabs=builder-syntax
        public ToastNotification Build() {
            ToastTemplateType templateType = _header != null ? ToastTemplateType.ToastText02 : ToastTemplateType.ToastText01;
            if (_imagePath != null) {
                if (templateType == ToastTemplateType.ToastText02) {
                    templateType = ToastTemplateType.ToastImageAndText02;
                } else {
                    templateType = ToastTemplateType.ToastImageAndText01;
                }
            }

            var template = BuildStanzaFromXml(ToastNotificationManager.GetTemplateContent(templateType));
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
                        attr.val = _imagePath;
                    }
                }
            }

            if (_supportsModernFeatures && _buttons.size > 0) { // allow buttons
                var actions = new StanzaNode.build("actions", "", null, null);
                foreach (var button in _buttons) {
                    var attributes = new Gee.ArrayList<StanzaAttribute>();
                    attributes.add(new StanzaAttribute.build("", "content", button.title));
                    attributes.add(new StanzaAttribute.build("", "arguments", button.arguments));

                    var action = new StanzaNode.build("action", "", null, attributes);
                    actions.get_all_subnodes().add(action);
                }
                template.get_all_subnodes().add(actions);
            }

            var xml = ToXml(template);
            return new ToastNotification(xml);
        }

        private StanzaNode BuildStanzaFromXml(string xml) {
            var reader = new Xmpp.StanzaReader.for_string(xml);

            StanzaNode root_node = null;
            var loop = new MainLoop();
            reader.read_node
                .begin((obj, res) => {
                root_node = reader.read_node.end(res);
                loop.quit();
            });
            loop.run();

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
    }
}
