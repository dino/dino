using Dino.Entities;
using Dino.Plugins.WindowsNotification.Vapi;
using winrt.Windows.UI.Notifications;
using Xmpp;

namespace Dino.Plugins.WindowsNotification {
public class Plugin : RootInterface, Object {

    private static string AUMID = "org.dino.Dino";
    private ToastNotifier notifier;
    private ToastNotification notification; // Notifications remove their actions when they get out of scope

    private delegate void NodeFunction(StanzaNode node);

    private StanzaNode Build(string xml) {
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

    public void registered(Dino.Application app) {
        if (!winrt.InitApartment())
        {
            // log error, return
        }

        if (!Win32Api.SetAppModelID(AUMID))
        {
            // log error, return
        }

        if (!ShortcutCreator.TryCreateShortcut(AUMID))
        {
            // log error, return
        }

        {
            var give_me_template = ToastTemplateType.ToastText02;
            var template = ToastNotificationManager.GetTemplateContent(give_me_template);
            var node = Build(template);
            {
                var attributes = new Gee.ArrayList<StanzaAttribute>();
                attributes.add(new StanzaAttribute.build("", "id", "1"));
                attributes.add(new StanzaAttribute.build("", "id", "2"));

                var nodes = FindRecursive(node, "text", attributes);
                foreach (var node_ in nodes) {
                    var attr = node_.get_attribute_raw("id", "");
                    if (attr != null) {
                        if (attr.val == "1") {
                            node_.put_node(new StanzaNode.text("Header!"));
                        } else if (attr.val == "2") {
                            node_.put_node(new StanzaNode.text("Text!"));
                        }
                    }
                }
            }
            
            this.notifier = new ToastNotifier(AUMID);
            this.notification = new ToastNotification(ToXml(node));
            var token = notification.Activated((c, d) => {
              stdout.printf("\nYay! Activated!\n");
              stdout.flush();
            });

            notifier.Show(notification);
        }
        
        //  var provider = new WindowsNotificationProvider(app, Win32Api.SupportsModernNotifications());
        //  app.stream_interactor.get_module(NotificationEvents.IDENTITY).register_notification_provider(provider);
    }

    public void shutdown() {
    }
}

}
