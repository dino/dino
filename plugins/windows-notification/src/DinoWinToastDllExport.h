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