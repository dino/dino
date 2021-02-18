#pragma once

#include "typedefinitions.h"

class NotificationHandler {
private:
  dinoWinToastLib_Notification_Callbacks callbacks{};

public:
  WinToastHandler(dinoWinToastLib_Notification_Callbacks callbacks);
  ~WinToastHandler();

  // Public interfaces
  void toastActivated() const;
  void toastActivated(int actionIndex) const;
  void toastDismissed(WinToastLib::IWinToastHandler::WinToastDismissalReason state) const;
  void toastFailed() const;
};