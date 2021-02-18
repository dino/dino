#include "toastnotification.h"

DinoToastNotification_t NewNotification() {
    return new std::shared_ptr<DinoToastNotification>();
}

void DestroyNotification(DinoToastNotification_t notification) {
    if (notification != nullptr) {
        delete notification;
    }
}

DinoToastNotification_t CopyNotification(DinoToastNotification_t notification)
{
    if (notification == nullptr) {
        return nullptr;
    }
    return new std::shared_ptr(*notification);
}

void set_Activated(DinoToastNotification_t notification, const SimpleNotificationCallback* callback)
{
  (*notification)->SetActivated(*callback);
}

void set_ActivatedWithIndex(DinoToastNotification_t notification, const ActivatedWithActionIndexNotificationCallback* callback)
{
  (*notification)->SetActivatedWithIndex(*callback);
}

void set_Dismissed(DinoToastNotification_t notification, const DismissedNotificationCallback* callback)
{
  (*notification)->SetDismissed(*callback);
}

void set_Failed(DinoToastNotification_t notification, const SimpleNotificationCallback* callback)
{
  (*notification)->SetFailed(*callback);
}

void DinoToastNotification::SetActivated(const SimpleNotificationCallback& callback)
{
  if (activated.callback != nullptr)
  {
    activated.free(activated.context);
    activated = SimpleNotificationCallback { 0 };
  }

  activated = callback;
}

void DinoToastNotification::SetActivatedWithIndex(const ActivatedWithActionIndexNotificationCallback& callback)
{
  if (activatedWithIndex.callback != nullptr)
  {
    activatedWithIndex.free(activatedWithIndex.context);
    activatedWithIndex = ActivatedWithActionIndexNotificationCallback { 0 };
  }

  activatedWithIndex = callback;
}

void DinoToastNotification::SetDismissed(const DismissedNotificationCallback& callback)
{
  if (dismissed.callback != nullptr)
  {
    dismissed.free(dismissed.context);
    dismissed = DismissedNotificationCallback { 0 };
  }

  dismissed = callback;
}

void DinoToastNotification::SetFailed(const SimpleNotificationCallback& callback)
{
  if (failed.callback != nullptr)
  {
    failed.free(failed.context);
    failed = SimpleNotificationCallback { 0 };
  }

  failed = callback;
}

DinoToastNotification::~DinoToastNotification()
{
  if (activated.context != nullptr &&
    activated.free != nullptr) {
    activated.free(activated.context);
  }

  if (activatedWithIndex.context != nullptr &&
    activatedWithIndex.free != nullptr) {
    activatedWithIndex.free(activatedWithIndex.context);
  }

  if (dismissed.context != nullptr &&
    dismissed.free != nullptr) {
    dismissed.free(dismissed.context);
  }

  if (failed.context != nullptr &&
    failed.free != nullptr) {
    failed.free(failed.context);
  }
}