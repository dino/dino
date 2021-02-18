#pragma once

#ifdef __cplusplus
extern "C"
{
#endif

    typedef enum {
        Dismissed_Reason_Activated = 0,
        Dismissed_Reason_ApplicationHidden,
        Dismissed_Reason_TimedOut
    } Dismissed_Reason;

#ifdef __cplusplus
}
#endif