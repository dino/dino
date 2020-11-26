#pragma once

#include "DinoWinToastDllExport.h"
#include "DinoWinToastTemplate.h"

#ifdef __cplusplus
extern "C" {
#endif
  typedef enum {
    Reason_Activated = 0,
    Reason_ApplicationHidden,
    Reason_TimedOut
  } dinoWinToastLib_Notification_Reason;

  typedef void(*dinoWinToastLib_Notification_Callback_Simple)(void* userdata);
  typedef void(*dinoWinToastLib_Notification_Callback_ActivatedWithActionIndex)(int action_id, void* userdata);
  typedef void(*dinoWinToastLib_Notification_Callback_Dismissed)(dinoWinToastLib_Notification_Reason reason, void* userdata);

  typedef struct {
    dinoWinToastLib_Notification_Callback_Simple activated;
    void* activated_context;
    void(*activated_free)(void*);

    dinoWinToastLib_Notification_Callback_ActivatedWithActionIndex activatedWithIndex;
    void* activatedWithIndex_context;
    void(*activatedWithIndex_free)(void*);

    dinoWinToastLib_Notification_Callback_Dismissed dismissed;
    void* dismissed_context;
    void(*dismissed_free)(void*);

    dinoWinToastLib_Notification_Callback_Simple failed;
    void* failed_context;
    void(*failed_free)(void*);

  } dinoWinToastLib_Notification_Callbacks;

  DINOWINTOASTLIB_API dinoWinToastLib_Notification_Callbacks* dinoWinToastLib_NewCallbacks();
  DINOWINTOASTLIB_API void dinoWinToastLib_DestroyCallbacks(dinoWinToastLib_Notification_Callbacks* callbacks);

  DINOWINTOASTLIB_API int dinoWinToastLib_Init();
  DINOWINTOASTLIB_API int dinoWinToastLib_ShowMessage(dino_wintoasttemplate templ, dinoWinToastLib_Notification_Callbacks* callbacks);
#ifdef __cplusplus
} // extern "C"
#endif