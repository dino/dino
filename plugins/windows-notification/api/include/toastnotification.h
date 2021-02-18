#pragma once

#include <glib.h>
#include "callbacks.h"

#ifdef __cplusplus
    #include <memory>

    class DinoToastNotification {
        private:
            SimpleNotificationCallback activated;
            ActivatedWithActionIndexNotificationCallback activatedWithIndex;
            DismissedNotificationCallback dismissed;
            SimpleNotificationCallback failed;
        
        public:
            DinoToastNotification() = default;
            ~DinoToastNotification();

            void SetActivated(const SimpleNotificationCallback& callback);
            void SetActivatedWithIndex(const ActivatedWithActionIndexNotificationCallback& callback);
            void SetDismissed(const DismissedNotificationCallback& callback);
            void SetFailed(const SimpleNotificationCallback& callback);

            // default move
            DinoToastNotification(DinoToastNotification&& other) = default;
            DinoToastNotification& operator=(DinoToastNotification&& other) = default;

            // delete copy
            DinoToastNotification(const DinoToastNotification& other) = delete;
            DinoToastNotification& operator=(const DinoToastNotification& other) = delete;
    };

extern "C" {
#endif
    #ifdef __cplusplus
    typedef  std::shared_ptr<DinoToastNotification>* DinoToastNotification_t;
    #else
    typedef void* DinoToastNotification_t;
    #endif

    DinoToastNotification_t NewNotification();
    void DestroyNotification(DinoToastNotification_t notification);
    DinoToastNotification_t CopyNotification();

    void set_Activated(DinoToastNotification_t notification, const SimpleNotificationCallback* callback);
    void set_ActivatedWithIndex(DinoToastNotification_t notification, const ActivatedWithActionIndexNotificationCallback* callback);
    void set_Dismissed(DinoToastNotification_t notification, const DismissedNotificationCallback* callback);
    void set_Failed(DinoToastNotification_t notification, const SimpleNotificationCallback* callback);
#ifdef __cplusplus
} // extern "C"
#endif