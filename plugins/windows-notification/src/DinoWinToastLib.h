#pragma once

#include "DinoWinToastDllExport.h"
#include "DinoWinToastTemplate.h"

#ifdef __cplusplus
extern "C" {
#endif
  typedef void(*dinoWinToastLibNotificationCallback)(int conv_id, void* userdata);
  DINOWINTOASTLIB_API int dinoWinToastLibInit();
  DINOWINTOASTLIB_API int dinoWinToastLibShowMessage(dino_wintoasttemplate templ, int conv_id, dinoWinToastLibNotificationCallback click_callback, void* callback_target);
#ifdef __cplusplus
} // extern "C"
#endif