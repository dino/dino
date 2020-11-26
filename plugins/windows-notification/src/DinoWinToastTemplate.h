#pragma once

#include <stdint.h>
#include "DinoWinToastDllExport.h"

#ifdef __cplusplus
extern "C" {
#endif
  typedef void* dino_wintoasttemplate;

  typedef enum {
    Duration_System,
    Duration_Short,
    Duration_Long
  } dino_wintoasttemplate_duration;

  typedef enum {
    AudioOption_Default = 0,
    AudioOption_Silent = 1,
    AudioOption_Loop = 2
  } dino_wintoasttemplate_audiooption;

  typedef enum {
    TextField_FirstLine = 0,
    TextField_SecondLine,
    TextField_ThirdLine
  } dino_wintoasttemplate_textfield;

  typedef enum {
    TemplateType_ImageAndText01 = 0,
    TemplateType_ImageAndText02,
    TemplateType_ImageAndText03,
    TemplateType_ImageAndText04,
    TemplateType_Text01,
    TemplateType_Text02,
    TemplateType_Text03,
    TemplateType_Text04,
    TemplateType_WinToastTemplateTypeCount
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