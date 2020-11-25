#pragma once

#include <stdint.h>
#include "DinoWinToastDllExport.h"

#ifdef __cplusplus
extern "C" {
#endif
  typedef void* dino_wintoasttemplate;

  typedef enum {
    System,
    Short,
    Long
  } dino_wintoasttemplate_duration;

  typedef enum {
    Default = 0,
    Silent = 1,
    Loop = 2
  } dino_wintoasttemplate_audiooption;

  typedef enum {
    FirstLine = 0,
    SecondLine,
    ThirdLine
  } dino_wintoasttemplate_textfield;

  typedef enum {
    ImageAndText01 = 0,
    ImageAndText02,
    ImageAndText03,
    ImageAndText04,
    Text01,
    Text02,
    Text03,
    Text04,
    WinToastTemplateTypeCount
  } dino_wintoasttemplate_wintoasttemplatetype;

  DINOWINTOASTLIB_API dino_wintoasttemplate dino_wintoasttemplate_new(dino_wintoasttemplate_wintoasttemplatetype templ);
  DINOWINTOASTLIB_API void dino_wintoasttemplate_destroy(dino_wintoasttemplate templ);

  DINOWINTOASTLIB_API void dino_wintoasttemplate_setTextField(dino_wintoasttemplate templ, const char* txt, dino_wintoasttemplate_textfield pos);
  DINOWINTOASTLIB_API void dino_wintoasttemplate_setImagePath(dino_wintoasttemplate templ, const char* imgPath);
  DINOWINTOASTLIB_API void dino_wintoasttemplate_setAudioPath(dino_wintoasttemplate templ, const char* audioPath);
  DINOWINTOASTLIB_API void dino_wintoasttemplate_setAttributionText(dino_wintoasttemplate templ, const char* attributionText);
  DINOWINTOASTLIB_API void dino_wintoasttemplate_addAction(dino_wintoasttemplate templ, const char* label);
  DINOWINTOASTLIB_API void dino_wintoasttemplate_setAudioOption(dino_wintoasttemplate templ, dino_wintoasttemplate_audiooption audioOption);
  DINOWINTOASTLIB_API void dino_wintoasttemplate_setDuration(dino_wintoasttemplate templ, dino_wintoasttemplate_duration duration);
  DINOWINTOASTLIB_API void dino_wintoasttemplate_setExpiration(dino_wintoasttemplate templ, int64_t millisecondsFromNow);
#ifdef __cplusplus
} // extern C
#endif