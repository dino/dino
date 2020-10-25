#pragma once

#ifdef _WIN32
#ifdef DINOWINTOASTLIB_EXPORTS
#define DINOWINTOASTLIB_API __declspec(dllexport)
#else
#define DINOWINTOASTLIB_API __declspec(dllimport)
#endif
#else
#define DINOWINTOASTLIB_API
#endif

#ifdef __cplusplus
extern "C" {
#endif
  int DINOWINTOASTLIB_API dinoWinToastLibInit();
#ifdef __cplusplus
} // extern "C"
#endif

#ifdef __cplusplus
extern "C" {
#endif
  int DINOWINTOASTLIB_API dinoWinToastLibShowMessage(const char* sender, const char* message, const char* imagePath, int conv_id, void(*click_callback)(int conv_id, void* callback_target), void* callback_target);
#ifdef __cplusplus
} // extern "C"
#endif