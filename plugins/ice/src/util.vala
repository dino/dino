using Gee;

namespace Dino.Plugins.Ice {

internal static bool is_component_ready(Nice.Agent agent, uint stream_id, uint component_id) {
    var state = agent.get_component_state(stream_id, component_id);
    return state == Nice.ComponentState.CONNECTED || state == Nice.ComponentState.READY;
}

internal Gee.List<string> get_local_ip_addresses() {
    Gee.List<string> result = new ArrayList<string>();
    foreach (string ip_address in Nice.interfaces_get_local_ips(false)) {
        result.add(ip_address);
    }
    return result;
}

}