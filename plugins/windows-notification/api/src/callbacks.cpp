#include "callbacks.h"

SimpleNotificationCallback* NewSimpleNotificationCallback()
{
    return new SimpleNotificationCallback();
}
void DestroySimpleNotificationCallback(SimpleNotificationCallback* callback)
{
    if (callback != nullptr)
    {
        delete callback;
    }
}

ActivatedWithActionIndexNotificationCallback* NewActivatedWithActionIndexNotificationCallback()
{
    return new ActivatedWithActionIndexNotificationCallback();
}
void DestroyActivatedWithActionIndexNotificationCallback(ActivatedWithActionIndexNotificationCallback* callback)
{
    if (callback != nullptr)
    {
        delete callback;
    }
}

DismissedNotificationCallback* NewDismissedNotificationCallback()
{
    return new DismissedNotificationCallback();
}
void DestroyDismissedNotificationCallback(DismissedNotificationCallback* callback)
{
    if (callback != nullptr)
    {
        delete callback;
    }
}