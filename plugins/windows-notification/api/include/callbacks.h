#pragma once

#include "enums.h"

#ifdef __cplusplus
extern "C"
{
#endif

    // simple
    typedef void(*Notification_Callback_Simple)(void* userdata);

    typedef struct {
        Notification_Callback_Simple callback;
        void* context;
        void(*free)(void*);
    } SimpleNotificationCallback;

    SimpleNotificationCallback* NewSimpleNotificationCallback();
    void DestroySimpleNotificationCallback(SimpleNotificationCallback* callback);
    
    // with index
    typedef void(*Notification_Callback_ActivatedWithActionIndex)(int action_id, void* userdata);

    typedef struct {
        Notification_Callback_ActivatedWithActionIndex callback;
        void* context;
        void(*free)(void*);
    } ActivatedWithActionIndexNotificationCallback;

    ActivatedWithActionIndexNotificationCallback* NewActivatedWithActionIndexNotificationCallback();
    void DestroyActivatedWithActionIndexNotificationCallback(ActivatedWithActionIndexNotificationCallback* callback);

    // with dismissed reason
    typedef void(*Notification_Callback_Dismissed)(Dismissed_Reason reason, void* userdata);

    typedef struct {
        Notification_Callback_Dismissed callback;
        void* context;
        void(*free)(void*);
    } DismissedNotificationCallback;

    DismissedNotificationCallback* NewDismissedNotificationCallback();
    void DestroyDismissedNotificationCallback(DismissedNotificationCallback* callback);

#ifdef __cplusplus
}
#endif