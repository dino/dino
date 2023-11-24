#include "helper.h"

signal_type_base* signal_type_ref_vapi(void* instance) {
    g_return_val_if_fail(instance != NULL, NULL);
    signal_type_ref(instance);
    return instance;
}

signal_type_base* signal_type_unref_vapi(void* instance) {
    g_return_val_if_fail(instance != NULL, NULL);
    signal_type_unref(instance);
    return NULL;
}

signal_protocol_address* signal_protocol_address_new(const gchar* name, int32_t device_id) {
    g_return_val_if_fail(name != NULL, NULL);
    signal_protocol_address* address = malloc(sizeof(signal_protocol_address));
    address->device_id = -1;
    address->name = NULL;
    signal_protocol_address_set_name(address, name);
    signal_protocol_address_set_device_id(address, device_id);
    return address;
}

void signal_protocol_address_free(signal_protocol_address* ptr) {
    g_return_if_fail(ptr != NULL);
    if (ptr->name) {
        g_free((void*)ptr->name);
    }
    return free(ptr);
}

void signal_protocol_address_set_name(signal_protocol_address* self, const gchar* name) {
    g_return_if_fail(self != NULL);
    g_return_if_fail(name != NULL);
    gchar* n = g_malloc(strlen(name)+1);
    memcpy(n, name, strlen(name));
    n[strlen(name)] = 0;
    if (self->name) {
        g_free((void*)self->name);
    }
    self->name = n;
    self->name_len = strlen(n);
}

gchar* signal_protocol_address_get_name(signal_protocol_address* self) {
    g_return_val_if_fail(self != NULL, NULL);
    g_return_val_if_fail(self->name != NULL, 0);
    gchar* res = g_malloc(sizeof(char) * (self->name_len + 1));
    memcpy(res, self->name, self->name_len);
    res[self->name_len] = 0;
    return res;
}

int32_t signal_protocol_address_get_device_id(signal_protocol_address* self) {
    g_return_val_if_fail(self != NULL, -1);
    return self->device_id;
}

void signal_protocol_address_set_device_id(signal_protocol_address* self, int32_t device_id) {
    g_return_if_fail(self != NULL);
    self->device_id = device_id;
}

