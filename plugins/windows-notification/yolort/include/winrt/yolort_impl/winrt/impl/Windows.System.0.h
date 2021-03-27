// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_System_0_H
#define WINRT_Windows_System_0_H
namespace winrt::Windows::ApplicationModel
{
    struct AppInfo;
}
namespace winrt::Windows::Foundation
{
    struct Deferral;
    template <typename T> struct EventHandler;
    struct EventRegistrationToken;
    struct HResult;
    struct IAsyncAction;
    template <typename T> struct IReference;
    struct Point;
    struct Rect;
    template <typename TSender, typename TResult> struct TypedEventHandler;
    struct Uri;
}
namespace winrt::Windows::Foundation::Collections
{
    template <typename T> struct IIterable;
    template <typename T> struct IVectorView;
    struct ValueSet;
}
namespace winrt::Windows::Storage
{
    struct IStorageFile;
    struct IStorageFolder;
    struct StorageFile;
}
namespace winrt::Windows::Storage::Search
{
    struct StorageFileQueryResult;
}
namespace winrt::Windows::Storage::Streams
{
    struct IInputStream;
    struct IOutputStream;
}
namespace winrt::Windows::System::RemoteSystems
{
    struct RemoteSystemConnectionRequest;
}
namespace winrt::Windows::UI::Popups
{
    enum class Placement : int32_t;
}
namespace winrt::Windows::UI::ViewManagement
{
    enum class ViewSizePreference : int32_t;
}
namespace winrt::Windows::System
{
    enum class AppDiagnosticInfoWatcherStatus : int32_t
    {
        Created = 0,
        Started = 1,
        EnumerationCompleted = 2,
        Stopping = 3,
        Stopped = 4,
        Aborted = 5,
    };
    enum class AppMemoryUsageLevel : int32_t
    {
        Low = 0,
        Medium = 1,
        High = 2,
        OverLimit = 3,
    };
    enum class AppResourceGroupEnergyQuotaState : int32_t
    {
        Unknown = 0,
        Over = 1,
        Under = 2,
    };
    enum class AppResourceGroupExecutionState : int32_t
    {
        Unknown = 0,
        Running = 1,
        Suspending = 2,
        Suspended = 3,
        NotRunning = 4,
    };
    enum class AppResourceGroupInfoWatcherStatus : int32_t
    {
        Created = 0,
        Started = 1,
        EnumerationCompleted = 2,
        Stopping = 3,
        Stopped = 4,
        Aborted = 5,
    };
    enum class AutoUpdateTimeZoneStatus : int32_t
    {
        Attempted = 0,
        TimedOut = 1,
        Failed = 2,
    };
    enum class DiagnosticAccessStatus : int32_t
    {
        Unspecified = 0,
        Denied = 1,
        Limited = 2,
        Allowed = 3,
    };
    enum class DispatcherQueuePriority : int32_t
    {
        Low = -10,
        Normal = 0,
        High = 10,
    };
    enum class LaunchFileStatus : int32_t
    {
        Success = 0,
        AppUnavailable = 1,
        DeniedByPolicy = 2,
        FileTypeNotSupported = 3,
        Unknown = 4,
    };
    enum class LaunchQuerySupportStatus : int32_t
    {
        Available = 0,
        AppNotInstalled = 1,
        AppUnavailable = 2,
        NotSupported = 3,
        Unknown = 4,
    };
    enum class LaunchQuerySupportType : int32_t
    {
        Uri = 0,
        UriForResults = 1,
    };
    enum class LaunchUriStatus : int32_t
    {
        Success = 0,
        AppUnavailable = 1,
        ProtocolUnavailable = 2,
        Unknown = 3,
    };
    enum class PowerState : int32_t
    {
        ConnectedStandby = 0,
        SleepS3 = 1,
    };
    enum class ProcessorArchitecture : int32_t
    {
        X86 = 0,
        Arm = 5,
        X64 = 9,
        Neutral = 11,
        Arm64 = 12,
        X86OnArm64 = 14,
        Unknown = 65535,
    };
    enum class RemoteLaunchUriStatus : int32_t
    {
        Unknown = 0,
        Success = 1,
        AppUnavailable = 2,
        ProtocolUnavailable = 3,
        RemoteSystemUnavailable = 4,
        ValueSetTooLarge = 5,
        DeniedByLocalSystem = 6,
        DeniedByRemoteSystem = 7,
    };
    enum class ShutdownKind : int32_t
    {
        Shutdown = 0,
        Restart = 1,
    };
    enum class UserAuthenticationStatus : int32_t
    {
        Unauthenticated = 0,
        LocallyAuthenticated = 1,
        RemotelyAuthenticated = 2,
    };
    enum class UserPictureSize : int32_t
    {
        Size64x64 = 0,
        Size208x208 = 1,
        Size424x424 = 2,
        Size1080x1080 = 3,
    };
    enum class UserType : int32_t
    {
        LocalUser = 0,
        RemoteUser = 1,
        LocalGuest = 2,
        RemoteGuest = 3,
    };
    enum class UserWatcherStatus : int32_t
    {
        Created = 0,
        Started = 1,
        EnumerationCompleted = 2,
        Stopping = 3,
        Stopped = 4,
        Aborted = 5,
    };
    enum class UserWatcherUpdateKind : int32_t
    {
        Properties = 0,
        Picture = 1,
    };
    enum class VirtualKey : int32_t
    {
        None = 0,
        LeftButton = 1,
        RightButton = 2,
        Cancel = 3,
        MiddleButton = 4,
        XButton1 = 5,
        XButton2 = 6,
        Back = 8,
        Tab = 9,
        Clear = 12,
        Enter = 13,
        Shift = 16,
        Control = 17,
        Menu = 18,
        Pause = 19,
        CapitalLock = 20,
        Kana = 21,
        Hangul = 21,
        ImeOn = 22,
        Junja = 23,
        Final = 24,
        Hanja = 25,
        Kanji = 25,
        ImeOff = 26,
        Escape = 27,
        Convert = 28,
        NonConvert = 29,
        Accept = 30,
        ModeChange = 31,
        Space = 32,
        PageUp = 33,
        PageDown = 34,
        End = 35,
        Home = 36,
        Left = 37,
        Up = 38,
        Right = 39,
        Down = 40,
        Select = 41,
        Print = 42,
        Execute = 43,
        Snapshot = 44,
        Insert = 45,
        Delete = 46,
        Help = 47,
        Number0 = 48,
        Number1 = 49,
        Number2 = 50,
        Number3 = 51,
        Number4 = 52,
        Number5 = 53,
        Number6 = 54,
        Number7 = 55,
        Number8 = 56,
        Number9 = 57,
        A = 65,
        B = 66,
        C = 67,
        D = 68,
        E = 69,
        F = 70,
        G = 71,
        H = 72,
        I = 73,
        J = 74,
        K = 75,
        L = 76,
        M = 77,
        N = 78,
        O = 79,
        P = 80,
        Q = 81,
        R = 82,
        S = 83,
        T = 84,
        U = 85,
        V = 86,
        W = 87,
        X = 88,
        Y = 89,
        Z = 90,
        LeftWindows = 91,
        RightWindows = 92,
        Application = 93,
        Sleep = 95,
        NumberPad0 = 96,
        NumberPad1 = 97,
        NumberPad2 = 98,
        NumberPad3 = 99,
        NumberPad4 = 100,
        NumberPad5 = 101,
        NumberPad6 = 102,
        NumberPad7 = 103,
        NumberPad8 = 104,
        NumberPad9 = 105,
        Multiply = 106,
        Add = 107,
        Separator = 108,
        Subtract = 109,
        Decimal = 110,
        Divide = 111,
        F1 = 112,
        F2 = 113,
        F3 = 114,
        F4 = 115,
        F5 = 116,
        F6 = 117,
        F7 = 118,
        F8 = 119,
        F9 = 120,
        F10 = 121,
        F11 = 122,
        F12 = 123,
        F13 = 124,
        F14 = 125,
        F15 = 126,
        F16 = 127,
        F17 = 128,
        F18 = 129,
        F19 = 130,
        F20 = 131,
        F21 = 132,
        F22 = 133,
        F23 = 134,
        F24 = 135,
        NavigationView = 136,
        NavigationMenu = 137,
        NavigationUp = 138,
        NavigationDown = 139,
        NavigationLeft = 140,
        NavigationRight = 141,
        NavigationAccept = 142,
        NavigationCancel = 143,
        NumberKeyLock = 144,
        Scroll = 145,
        LeftShift = 160,
        RightShift = 161,
        LeftControl = 162,
        RightControl = 163,
        LeftMenu = 164,
        RightMenu = 165,
        GoBack = 166,
        GoForward = 167,
        Refresh = 168,
        Stop = 169,
        Search = 170,
        Favorites = 171,
        GoHome = 172,
        GamepadA = 195,
        GamepadB = 196,
        GamepadX = 197,
        GamepadY = 198,
        GamepadRightShoulder = 199,
        GamepadLeftShoulder = 200,
        GamepadLeftTrigger = 201,
        GamepadRightTrigger = 202,
        GamepadDPadUp = 203,
        GamepadDPadDown = 204,
        GamepadDPadLeft = 205,
        GamepadDPadRight = 206,
        GamepadMenu = 207,
        GamepadView = 208,
        GamepadLeftThumbstickButton = 209,
        GamepadRightThumbstickButton = 210,
        GamepadLeftThumbstickUp = 211,
        GamepadLeftThumbstickDown = 212,
        GamepadLeftThumbstickRight = 213,
        GamepadLeftThumbstickLeft = 214,
        GamepadRightThumbstickUp = 215,
        GamepadRightThumbstickDown = 216,
        GamepadRightThumbstickRight = 217,
        GamepadRightThumbstickLeft = 218,
    };
    enum class VirtualKeyModifiers : uint32_t
    {
        None = 0,
        Control = 0x1,
        Menu = 0x2,
        Shift = 0x4,
        Windows = 0x8,
    };
    struct IAppActivationResult;
    struct IAppDiagnosticInfo;
    struct IAppDiagnosticInfo2;
    struct IAppDiagnosticInfo3;
    struct IAppDiagnosticInfoStatics;
    struct IAppDiagnosticInfoStatics2;
    struct IAppDiagnosticInfoWatcher;
    struct IAppDiagnosticInfoWatcherEventArgs;
    struct IAppExecutionStateChangeResult;
    struct IAppMemoryReport;
    struct IAppMemoryReport2;
    struct IAppMemoryUsageLimitChangingEventArgs;
    struct IAppResourceGroupBackgroundTaskReport;
    struct IAppResourceGroupInfo;
    struct IAppResourceGroupInfo2;
    struct IAppResourceGroupInfoWatcher;
    struct IAppResourceGroupInfoWatcherEventArgs;
    struct IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs;
    struct IAppResourceGroupMemoryReport;
    struct IAppResourceGroupStateReport;
    struct IAppUriHandlerHost;
    struct IAppUriHandlerHostFactory;
    struct IAppUriHandlerRegistration;
    struct IAppUriHandlerRegistrationManager;
    struct IAppUriHandlerRegistrationManagerStatics;
    struct IDateTimeSettingsStatics;
    struct IDispatcherQueue;
    struct IDispatcherQueue2;
    struct IDispatcherQueueController;
    struct IDispatcherQueueControllerStatics;
    struct IDispatcherQueueShutdownStartingEventArgs;
    struct IDispatcherQueueStatics;
    struct IDispatcherQueueTimer;
    struct IFolderLauncherOptions;
    struct IKnownUserPropertiesStatics;
    struct ILaunchUriResult;
    struct ILauncherOptions;
    struct ILauncherOptions2;
    struct ILauncherOptions3;
    struct ILauncherOptions4;
    struct ILauncherStatics;
    struct ILauncherStatics2;
    struct ILauncherStatics3;
    struct ILauncherStatics4;
    struct ILauncherStatics5;
    struct ILauncherUIOptions;
    struct ILauncherViewOptions;
    struct IMemoryManagerStatics;
    struct IMemoryManagerStatics2;
    struct IMemoryManagerStatics3;
    struct IMemoryManagerStatics4;
    struct IProcessLauncherOptions;
    struct IProcessLauncherResult;
    struct IProcessLauncherStatics;
    struct IProcessMemoryReport;
    struct IProtocolForResultsOperation;
    struct IRemoteLauncherOptions;
    struct IRemoteLauncherStatics;
    struct IShutdownManagerStatics;
    struct IShutdownManagerStatics2;
    struct ITimeZoneSettingsStatics;
    struct ITimeZoneSettingsStatics2;
    struct IUser;
    struct IUserAuthenticationStatusChangeDeferral;
    struct IUserAuthenticationStatusChangingEventArgs;
    struct IUserChangedEventArgs;
    struct IUserChangedEventArgs2;
    struct IUserDeviceAssociationChangedEventArgs;
    struct IUserDeviceAssociationStatics;
    struct IUserPicker;
    struct IUserPickerStatics;
    struct IUserStatics;
    struct IUserWatcher;
    struct AppActivationResult;
    struct AppDiagnosticInfo;
    struct AppDiagnosticInfoWatcher;
    struct AppDiagnosticInfoWatcherEventArgs;
    struct AppExecutionStateChangeResult;
    struct AppMemoryReport;
    struct AppMemoryUsageLimitChangingEventArgs;
    struct AppResourceGroupBackgroundTaskReport;
    struct AppResourceGroupInfo;
    struct AppResourceGroupInfoWatcher;
    struct AppResourceGroupInfoWatcherEventArgs;
    struct AppResourceGroupInfoWatcherExecutionStateChangedEventArgs;
    struct AppResourceGroupMemoryReport;
    struct AppResourceGroupStateReport;
    struct AppUriHandlerHost;
    struct AppUriHandlerRegistration;
    struct AppUriHandlerRegistrationManager;
    struct DateTimeSettings;
    struct DispatcherQueue;
    struct DispatcherQueueController;
    struct DispatcherQueueShutdownStartingEventArgs;
    struct DispatcherQueueTimer;
    struct FolderLauncherOptions;
    struct KnownUserProperties;
    struct LaunchUriResult;
    struct Launcher;
    struct LauncherOptions;
    struct LauncherUIOptions;
    struct MemoryManager;
    struct ProcessLauncher;
    struct ProcessLauncherOptions;
    struct ProcessLauncherResult;
    struct ProcessMemoryReport;
    struct ProtocolForResultsOperation;
    struct RemoteLauncher;
    struct RemoteLauncherOptions;
    struct ShutdownManager;
    struct TimeZoneSettings;
    struct User;
    struct UserAuthenticationStatusChangeDeferral;
    struct UserAuthenticationStatusChangingEventArgs;
    struct UserChangedEventArgs;
    struct UserDeviceAssociation;
    struct UserDeviceAssociationChangedEventArgs;
    struct UserPicker;
    struct UserWatcher;
    struct DispatcherQueueHandler;
}
namespace winrt::impl
{
    template <> struct category<Windows::System::IAppActivationResult>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppDiagnosticInfo>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppDiagnosticInfo2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppDiagnosticInfo3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppDiagnosticInfoStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppDiagnosticInfoStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppDiagnosticInfoWatcher>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppDiagnosticInfoWatcherEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppExecutionStateChangeResult>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppMemoryReport>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppMemoryReport2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppMemoryUsageLimitChangingEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppResourceGroupBackgroundTaskReport>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppResourceGroupInfo>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppResourceGroupInfo2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppResourceGroupInfoWatcher>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppResourceGroupInfoWatcherEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppResourceGroupMemoryReport>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppResourceGroupStateReport>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppUriHandlerHost>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppUriHandlerHostFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppUriHandlerRegistration>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppUriHandlerRegistrationManager>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IAppUriHandlerRegistrationManagerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IDateTimeSettingsStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IDispatcherQueue>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IDispatcherQueue2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IDispatcherQueueController>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IDispatcherQueueControllerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IDispatcherQueueShutdownStartingEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IDispatcherQueueStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IDispatcherQueueTimer>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IFolderLauncherOptions>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IKnownUserPropertiesStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILaunchUriResult>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherOptions>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherOptions2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherOptions3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherOptions4>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherStatics3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherStatics4>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherStatics5>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherUIOptions>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ILauncherViewOptions>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IMemoryManagerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IMemoryManagerStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IMemoryManagerStatics3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IMemoryManagerStatics4>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IProcessLauncherOptions>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IProcessLauncherResult>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IProcessLauncherStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IProcessMemoryReport>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IProtocolForResultsOperation>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IRemoteLauncherOptions>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IRemoteLauncherStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IShutdownManagerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IShutdownManagerStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ITimeZoneSettingsStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::ITimeZoneSettingsStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUser>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserAuthenticationStatusChangeDeferral>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserAuthenticationStatusChangingEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserChangedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserChangedEventArgs2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserDeviceAssociationChangedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserDeviceAssociationStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserPicker>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserPickerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::IUserWatcher>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::AppActivationResult>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppDiagnosticInfo>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppDiagnosticInfoWatcher>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppDiagnosticInfoWatcherEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppExecutionStateChangeResult>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppMemoryReport>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppMemoryUsageLimitChangingEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppResourceGroupBackgroundTaskReport>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppResourceGroupInfo>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppResourceGroupInfoWatcher>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppResourceGroupInfoWatcherEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppResourceGroupInfoWatcherExecutionStateChangedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppResourceGroupMemoryReport>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppResourceGroupStateReport>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppUriHandlerHost>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppUriHandlerRegistration>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppUriHandlerRegistrationManager>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::DateTimeSettings>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::DispatcherQueue>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::DispatcherQueueController>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::DispatcherQueueShutdownStartingEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::DispatcherQueueTimer>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::FolderLauncherOptions>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::KnownUserProperties>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::LaunchUriResult>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::Launcher>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::LauncherOptions>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::LauncherUIOptions>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::MemoryManager>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::ProcessLauncher>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::ProcessLauncherOptions>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::ProcessLauncherResult>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::ProcessMemoryReport>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::ProtocolForResultsOperation>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteLauncher>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteLauncherOptions>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::ShutdownManager>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::TimeZoneSettings>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::User>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::UserAuthenticationStatusChangeDeferral>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::UserAuthenticationStatusChangingEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::UserChangedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::UserDeviceAssociation>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::UserDeviceAssociationChangedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::UserPicker>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::UserWatcher>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::AppDiagnosticInfoWatcherStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::AppMemoryUsageLevel>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::AppResourceGroupEnergyQuotaState>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::AppResourceGroupExecutionState>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::AppResourceGroupInfoWatcherStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::AutoUpdateTimeZoneStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::DiagnosticAccessStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::DispatcherQueuePriority>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::LaunchFileStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::LaunchQuerySupportStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::LaunchQuerySupportType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::LaunchUriStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::PowerState>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::ProcessorArchitecture>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteLaunchUriStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::ShutdownKind>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::UserAuthenticationStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::UserPictureSize>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::UserType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::UserWatcherStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::UserWatcherUpdateKind>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::VirtualKey>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::VirtualKeyModifiers>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::DispatcherQueueHandler>
    {
        using type = delegate_category;
    };
    template <> struct name<Windows::System::IAppActivationResult>
    {
        static constexpr auto & value{ L"Windows.System.IAppActivationResult" };
    };
    template <> struct name<Windows::System::IAppDiagnosticInfo>
    {
        static constexpr auto & value{ L"Windows.System.IAppDiagnosticInfo" };
    };
    template <> struct name<Windows::System::IAppDiagnosticInfo2>
    {
        static constexpr auto & value{ L"Windows.System.IAppDiagnosticInfo2" };
    };
    template <> struct name<Windows::System::IAppDiagnosticInfo3>
    {
        static constexpr auto & value{ L"Windows.System.IAppDiagnosticInfo3" };
    };
    template <> struct name<Windows::System::IAppDiagnosticInfoStatics>
    {
        static constexpr auto & value{ L"Windows.System.IAppDiagnosticInfoStatics" };
    };
    template <> struct name<Windows::System::IAppDiagnosticInfoStatics2>
    {
        static constexpr auto & value{ L"Windows.System.IAppDiagnosticInfoStatics2" };
    };
    template <> struct name<Windows::System::IAppDiagnosticInfoWatcher>
    {
        static constexpr auto & value{ L"Windows.System.IAppDiagnosticInfoWatcher" };
    };
    template <> struct name<Windows::System::IAppDiagnosticInfoWatcherEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.IAppDiagnosticInfoWatcherEventArgs" };
    };
    template <> struct name<Windows::System::IAppExecutionStateChangeResult>
    {
        static constexpr auto & value{ L"Windows.System.IAppExecutionStateChangeResult" };
    };
    template <> struct name<Windows::System::IAppMemoryReport>
    {
        static constexpr auto & value{ L"Windows.System.IAppMemoryReport" };
    };
    template <> struct name<Windows::System::IAppMemoryReport2>
    {
        static constexpr auto & value{ L"Windows.System.IAppMemoryReport2" };
    };
    template <> struct name<Windows::System::IAppMemoryUsageLimitChangingEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.IAppMemoryUsageLimitChangingEventArgs" };
    };
    template <> struct name<Windows::System::IAppResourceGroupBackgroundTaskReport>
    {
        static constexpr auto & value{ L"Windows.System.IAppResourceGroupBackgroundTaskReport" };
    };
    template <> struct name<Windows::System::IAppResourceGroupInfo>
    {
        static constexpr auto & value{ L"Windows.System.IAppResourceGroupInfo" };
    };
    template <> struct name<Windows::System::IAppResourceGroupInfo2>
    {
        static constexpr auto & value{ L"Windows.System.IAppResourceGroupInfo2" };
    };
    template <> struct name<Windows::System::IAppResourceGroupInfoWatcher>
    {
        static constexpr auto & value{ L"Windows.System.IAppResourceGroupInfoWatcher" };
    };
    template <> struct name<Windows::System::IAppResourceGroupInfoWatcherEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.IAppResourceGroupInfoWatcherEventArgs" };
    };
    template <> struct name<Windows::System::IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs" };
    };
    template <> struct name<Windows::System::IAppResourceGroupMemoryReport>
    {
        static constexpr auto & value{ L"Windows.System.IAppResourceGroupMemoryReport" };
    };
    template <> struct name<Windows::System::IAppResourceGroupStateReport>
    {
        static constexpr auto & value{ L"Windows.System.IAppResourceGroupStateReport" };
    };
    template <> struct name<Windows::System::IAppUriHandlerHost>
    {
        static constexpr auto & value{ L"Windows.System.IAppUriHandlerHost" };
    };
    template <> struct name<Windows::System::IAppUriHandlerHostFactory>
    {
        static constexpr auto & value{ L"Windows.System.IAppUriHandlerHostFactory" };
    };
    template <> struct name<Windows::System::IAppUriHandlerRegistration>
    {
        static constexpr auto & value{ L"Windows.System.IAppUriHandlerRegistration" };
    };
    template <> struct name<Windows::System::IAppUriHandlerRegistrationManager>
    {
        static constexpr auto & value{ L"Windows.System.IAppUriHandlerRegistrationManager" };
    };
    template <> struct name<Windows::System::IAppUriHandlerRegistrationManagerStatics>
    {
        static constexpr auto & value{ L"Windows.System.IAppUriHandlerRegistrationManagerStatics" };
    };
    template <> struct name<Windows::System::IDateTimeSettingsStatics>
    {
        static constexpr auto & value{ L"Windows.System.IDateTimeSettingsStatics" };
    };
    template <> struct name<Windows::System::IDispatcherQueue>
    {
        static constexpr auto & value{ L"Windows.System.IDispatcherQueue" };
    };
    template <> struct name<Windows::System::IDispatcherQueue2>
    {
        static constexpr auto & value{ L"Windows.System.IDispatcherQueue2" };
    };
    template <> struct name<Windows::System::IDispatcherQueueController>
    {
        static constexpr auto & value{ L"Windows.System.IDispatcherQueueController" };
    };
    template <> struct name<Windows::System::IDispatcherQueueControllerStatics>
    {
        static constexpr auto & value{ L"Windows.System.IDispatcherQueueControllerStatics" };
    };
    template <> struct name<Windows::System::IDispatcherQueueShutdownStartingEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.IDispatcherQueueShutdownStartingEventArgs" };
    };
    template <> struct name<Windows::System::IDispatcherQueueStatics>
    {
        static constexpr auto & value{ L"Windows.System.IDispatcherQueueStatics" };
    };
    template <> struct name<Windows::System::IDispatcherQueueTimer>
    {
        static constexpr auto & value{ L"Windows.System.IDispatcherQueueTimer" };
    };
    template <> struct name<Windows::System::IFolderLauncherOptions>
    {
        static constexpr auto & value{ L"Windows.System.IFolderLauncherOptions" };
    };
    template <> struct name<Windows::System::IKnownUserPropertiesStatics>
    {
        static constexpr auto & value{ L"Windows.System.IKnownUserPropertiesStatics" };
    };
    template <> struct name<Windows::System::ILaunchUriResult>
    {
        static constexpr auto & value{ L"Windows.System.ILaunchUriResult" };
    };
    template <> struct name<Windows::System::ILauncherOptions>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherOptions" };
    };
    template <> struct name<Windows::System::ILauncherOptions2>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherOptions2" };
    };
    template <> struct name<Windows::System::ILauncherOptions3>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherOptions3" };
    };
    template <> struct name<Windows::System::ILauncherOptions4>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherOptions4" };
    };
    template <> struct name<Windows::System::ILauncherStatics>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherStatics" };
    };
    template <> struct name<Windows::System::ILauncherStatics2>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherStatics2" };
    };
    template <> struct name<Windows::System::ILauncherStatics3>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherStatics3" };
    };
    template <> struct name<Windows::System::ILauncherStatics4>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherStatics4" };
    };
    template <> struct name<Windows::System::ILauncherStatics5>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherStatics5" };
    };
    template <> struct name<Windows::System::ILauncherUIOptions>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherUIOptions" };
    };
    template <> struct name<Windows::System::ILauncherViewOptions>
    {
        static constexpr auto & value{ L"Windows.System.ILauncherViewOptions" };
    };
    template <> struct name<Windows::System::IMemoryManagerStatics>
    {
        static constexpr auto & value{ L"Windows.System.IMemoryManagerStatics" };
    };
    template <> struct name<Windows::System::IMemoryManagerStatics2>
    {
        static constexpr auto & value{ L"Windows.System.IMemoryManagerStatics2" };
    };
    template <> struct name<Windows::System::IMemoryManagerStatics3>
    {
        static constexpr auto & value{ L"Windows.System.IMemoryManagerStatics3" };
    };
    template <> struct name<Windows::System::IMemoryManagerStatics4>
    {
        static constexpr auto & value{ L"Windows.System.IMemoryManagerStatics4" };
    };
    template <> struct name<Windows::System::IProcessLauncherOptions>
    {
        static constexpr auto & value{ L"Windows.System.IProcessLauncherOptions" };
    };
    template <> struct name<Windows::System::IProcessLauncherResult>
    {
        static constexpr auto & value{ L"Windows.System.IProcessLauncherResult" };
    };
    template <> struct name<Windows::System::IProcessLauncherStatics>
    {
        static constexpr auto & value{ L"Windows.System.IProcessLauncherStatics" };
    };
    template <> struct name<Windows::System::IProcessMemoryReport>
    {
        static constexpr auto & value{ L"Windows.System.IProcessMemoryReport" };
    };
    template <> struct name<Windows::System::IProtocolForResultsOperation>
    {
        static constexpr auto & value{ L"Windows.System.IProtocolForResultsOperation" };
    };
    template <> struct name<Windows::System::IRemoteLauncherOptions>
    {
        static constexpr auto & value{ L"Windows.System.IRemoteLauncherOptions" };
    };
    template <> struct name<Windows::System::IRemoteLauncherStatics>
    {
        static constexpr auto & value{ L"Windows.System.IRemoteLauncherStatics" };
    };
    template <> struct name<Windows::System::IShutdownManagerStatics>
    {
        static constexpr auto & value{ L"Windows.System.IShutdownManagerStatics" };
    };
    template <> struct name<Windows::System::IShutdownManagerStatics2>
    {
        static constexpr auto & value{ L"Windows.System.IShutdownManagerStatics2" };
    };
    template <> struct name<Windows::System::ITimeZoneSettingsStatics>
    {
        static constexpr auto & value{ L"Windows.System.ITimeZoneSettingsStatics" };
    };
    template <> struct name<Windows::System::ITimeZoneSettingsStatics2>
    {
        static constexpr auto & value{ L"Windows.System.ITimeZoneSettingsStatics2" };
    };
    template <> struct name<Windows::System::IUser>
    {
        static constexpr auto & value{ L"Windows.System.IUser" };
    };
    template <> struct name<Windows::System::IUserAuthenticationStatusChangeDeferral>
    {
        static constexpr auto & value{ L"Windows.System.IUserAuthenticationStatusChangeDeferral" };
    };
    template <> struct name<Windows::System::IUserAuthenticationStatusChangingEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.IUserAuthenticationStatusChangingEventArgs" };
    };
    template <> struct name<Windows::System::IUserChangedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.IUserChangedEventArgs" };
    };
    template <> struct name<Windows::System::IUserChangedEventArgs2>
    {
        static constexpr auto & value{ L"Windows.System.IUserChangedEventArgs2" };
    };
    template <> struct name<Windows::System::IUserDeviceAssociationChangedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.IUserDeviceAssociationChangedEventArgs" };
    };
    template <> struct name<Windows::System::IUserDeviceAssociationStatics>
    {
        static constexpr auto & value{ L"Windows.System.IUserDeviceAssociationStatics" };
    };
    template <> struct name<Windows::System::IUserPicker>
    {
        static constexpr auto & value{ L"Windows.System.IUserPicker" };
    };
    template <> struct name<Windows::System::IUserPickerStatics>
    {
        static constexpr auto & value{ L"Windows.System.IUserPickerStatics" };
    };
    template <> struct name<Windows::System::IUserStatics>
    {
        static constexpr auto & value{ L"Windows.System.IUserStatics" };
    };
    template <> struct name<Windows::System::IUserWatcher>
    {
        static constexpr auto & value{ L"Windows.System.IUserWatcher" };
    };
    template <> struct name<Windows::System::AppActivationResult>
    {
        static constexpr auto & value{ L"Windows.System.AppActivationResult" };
    };
    template <> struct name<Windows::System::AppDiagnosticInfo>
    {
        static constexpr auto & value{ L"Windows.System.AppDiagnosticInfo" };
    };
    template <> struct name<Windows::System::AppDiagnosticInfoWatcher>
    {
        static constexpr auto & value{ L"Windows.System.AppDiagnosticInfoWatcher" };
    };
    template <> struct name<Windows::System::AppDiagnosticInfoWatcherEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.AppDiagnosticInfoWatcherEventArgs" };
    };
    template <> struct name<Windows::System::AppExecutionStateChangeResult>
    {
        static constexpr auto & value{ L"Windows.System.AppExecutionStateChangeResult" };
    };
    template <> struct name<Windows::System::AppMemoryReport>
    {
        static constexpr auto & value{ L"Windows.System.AppMemoryReport" };
    };
    template <> struct name<Windows::System::AppMemoryUsageLimitChangingEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.AppMemoryUsageLimitChangingEventArgs" };
    };
    template <> struct name<Windows::System::AppResourceGroupBackgroundTaskReport>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupBackgroundTaskReport" };
    };
    template <> struct name<Windows::System::AppResourceGroupInfo>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupInfo" };
    };
    template <> struct name<Windows::System::AppResourceGroupInfoWatcher>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupInfoWatcher" };
    };
    template <> struct name<Windows::System::AppResourceGroupInfoWatcherEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupInfoWatcherEventArgs" };
    };
    template <> struct name<Windows::System::AppResourceGroupInfoWatcherExecutionStateChangedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupInfoWatcherExecutionStateChangedEventArgs" };
    };
    template <> struct name<Windows::System::AppResourceGroupMemoryReport>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupMemoryReport" };
    };
    template <> struct name<Windows::System::AppResourceGroupStateReport>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupStateReport" };
    };
    template <> struct name<Windows::System::AppUriHandlerHost>
    {
        static constexpr auto & value{ L"Windows.System.AppUriHandlerHost" };
    };
    template <> struct name<Windows::System::AppUriHandlerRegistration>
    {
        static constexpr auto & value{ L"Windows.System.AppUriHandlerRegistration" };
    };
    template <> struct name<Windows::System::AppUriHandlerRegistrationManager>
    {
        static constexpr auto & value{ L"Windows.System.AppUriHandlerRegistrationManager" };
    };
    template <> struct name<Windows::System::DateTimeSettings>
    {
        static constexpr auto & value{ L"Windows.System.DateTimeSettings" };
    };
    template <> struct name<Windows::System::DispatcherQueue>
    {
        static constexpr auto & value{ L"Windows.System.DispatcherQueue" };
    };
    template <> struct name<Windows::System::DispatcherQueueController>
    {
        static constexpr auto & value{ L"Windows.System.DispatcherQueueController" };
    };
    template <> struct name<Windows::System::DispatcherQueueShutdownStartingEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.DispatcherQueueShutdownStartingEventArgs" };
    };
    template <> struct name<Windows::System::DispatcherQueueTimer>
    {
        static constexpr auto & value{ L"Windows.System.DispatcherQueueTimer" };
    };
    template <> struct name<Windows::System::FolderLauncherOptions>
    {
        static constexpr auto & value{ L"Windows.System.FolderLauncherOptions" };
    };
    template <> struct name<Windows::System::KnownUserProperties>
    {
        static constexpr auto & value{ L"Windows.System.KnownUserProperties" };
    };
    template <> struct name<Windows::System::LaunchUriResult>
    {
        static constexpr auto & value{ L"Windows.System.LaunchUriResult" };
    };
    template <> struct name<Windows::System::Launcher>
    {
        static constexpr auto & value{ L"Windows.System.Launcher" };
    };
    template <> struct name<Windows::System::LauncherOptions>
    {
        static constexpr auto & value{ L"Windows.System.LauncherOptions" };
    };
    template <> struct name<Windows::System::LauncherUIOptions>
    {
        static constexpr auto & value{ L"Windows.System.LauncherUIOptions" };
    };
    template <> struct name<Windows::System::MemoryManager>
    {
        static constexpr auto & value{ L"Windows.System.MemoryManager" };
    };
    template <> struct name<Windows::System::ProcessLauncher>
    {
        static constexpr auto & value{ L"Windows.System.ProcessLauncher" };
    };
    template <> struct name<Windows::System::ProcessLauncherOptions>
    {
        static constexpr auto & value{ L"Windows.System.ProcessLauncherOptions" };
    };
    template <> struct name<Windows::System::ProcessLauncherResult>
    {
        static constexpr auto & value{ L"Windows.System.ProcessLauncherResult" };
    };
    template <> struct name<Windows::System::ProcessMemoryReport>
    {
        static constexpr auto & value{ L"Windows.System.ProcessMemoryReport" };
    };
    template <> struct name<Windows::System::ProtocolForResultsOperation>
    {
        static constexpr auto & value{ L"Windows.System.ProtocolForResultsOperation" };
    };
    template <> struct name<Windows::System::RemoteLauncher>
    {
        static constexpr auto & value{ L"Windows.System.RemoteLauncher" };
    };
    template <> struct name<Windows::System::RemoteLauncherOptions>
    {
        static constexpr auto & value{ L"Windows.System.RemoteLauncherOptions" };
    };
    template <> struct name<Windows::System::ShutdownManager>
    {
        static constexpr auto & value{ L"Windows.System.ShutdownManager" };
    };
    template <> struct name<Windows::System::TimeZoneSettings>
    {
        static constexpr auto & value{ L"Windows.System.TimeZoneSettings" };
    };
    template <> struct name<Windows::System::User>
    {
        static constexpr auto & value{ L"Windows.System.User" };
    };
    template <> struct name<Windows::System::UserAuthenticationStatusChangeDeferral>
    {
        static constexpr auto & value{ L"Windows.System.UserAuthenticationStatusChangeDeferral" };
    };
    template <> struct name<Windows::System::UserAuthenticationStatusChangingEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.UserAuthenticationStatusChangingEventArgs" };
    };
    template <> struct name<Windows::System::UserChangedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.UserChangedEventArgs" };
    };
    template <> struct name<Windows::System::UserDeviceAssociation>
    {
        static constexpr auto & value{ L"Windows.System.UserDeviceAssociation" };
    };
    template <> struct name<Windows::System::UserDeviceAssociationChangedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.UserDeviceAssociationChangedEventArgs" };
    };
    template <> struct name<Windows::System::UserPicker>
    {
        static constexpr auto & value{ L"Windows.System.UserPicker" };
    };
    template <> struct name<Windows::System::UserWatcher>
    {
        static constexpr auto & value{ L"Windows.System.UserWatcher" };
    };
    template <> struct name<Windows::System::AppDiagnosticInfoWatcherStatus>
    {
        static constexpr auto & value{ L"Windows.System.AppDiagnosticInfoWatcherStatus" };
    };
    template <> struct name<Windows::System::AppMemoryUsageLevel>
    {
        static constexpr auto & value{ L"Windows.System.AppMemoryUsageLevel" };
    };
    template <> struct name<Windows::System::AppResourceGroupEnergyQuotaState>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupEnergyQuotaState" };
    };
    template <> struct name<Windows::System::AppResourceGroupExecutionState>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupExecutionState" };
    };
    template <> struct name<Windows::System::AppResourceGroupInfoWatcherStatus>
    {
        static constexpr auto & value{ L"Windows.System.AppResourceGroupInfoWatcherStatus" };
    };
    template <> struct name<Windows::System::AutoUpdateTimeZoneStatus>
    {
        static constexpr auto & value{ L"Windows.System.AutoUpdateTimeZoneStatus" };
    };
    template <> struct name<Windows::System::DiagnosticAccessStatus>
    {
        static constexpr auto & value{ L"Windows.System.DiagnosticAccessStatus" };
    };
    template <> struct name<Windows::System::DispatcherQueuePriority>
    {
        static constexpr auto & value{ L"Windows.System.DispatcherQueuePriority" };
    };
    template <> struct name<Windows::System::LaunchFileStatus>
    {
        static constexpr auto & value{ L"Windows.System.LaunchFileStatus" };
    };
    template <> struct name<Windows::System::LaunchQuerySupportStatus>
    {
        static constexpr auto & value{ L"Windows.System.LaunchQuerySupportStatus" };
    };
    template <> struct name<Windows::System::LaunchQuerySupportType>
    {
        static constexpr auto & value{ L"Windows.System.LaunchQuerySupportType" };
    };
    template <> struct name<Windows::System::LaunchUriStatus>
    {
        static constexpr auto & value{ L"Windows.System.LaunchUriStatus" };
    };
    template <> struct name<Windows::System::PowerState>
    {
        static constexpr auto & value{ L"Windows.System.PowerState" };
    };
    template <> struct name<Windows::System::ProcessorArchitecture>
    {
        static constexpr auto & value{ L"Windows.System.ProcessorArchitecture" };
    };
    template <> struct name<Windows::System::RemoteLaunchUriStatus>
    {
        static constexpr auto & value{ L"Windows.System.RemoteLaunchUriStatus" };
    };
    template <> struct name<Windows::System::ShutdownKind>
    {
        static constexpr auto & value{ L"Windows.System.ShutdownKind" };
    };
    template <> struct name<Windows::System::UserAuthenticationStatus>
    {
        static constexpr auto & value{ L"Windows.System.UserAuthenticationStatus" };
    };
    template <> struct name<Windows::System::UserPictureSize>
    {
        static constexpr auto & value{ L"Windows.System.UserPictureSize" };
    };
    template <> struct name<Windows::System::UserType>
    {
        static constexpr auto & value{ L"Windows.System.UserType" };
    };
    template <> struct name<Windows::System::UserWatcherStatus>
    {
        static constexpr auto & value{ L"Windows.System.UserWatcherStatus" };
    };
    template <> struct name<Windows::System::UserWatcherUpdateKind>
    {
        static constexpr auto & value{ L"Windows.System.UserWatcherUpdateKind" };
    };
    template <> struct name<Windows::System::VirtualKey>
    {
        static constexpr auto & value{ L"Windows.System.VirtualKey" };
    };
    template <> struct name<Windows::System::VirtualKeyModifiers>
    {
        static constexpr auto & value{ L"Windows.System.VirtualKeyModifiers" };
    };
    template <> struct name<Windows::System::DispatcherQueueHandler>
    {
        static constexpr auto & value{ L"Windows.System.DispatcherQueueHandler" };
    };
    template <> struct guid_storage<Windows::System::IAppActivationResult>
    {
        static constexpr guid value{ 0x6B528900,0xF46E,0x4EB0,{ 0xAA,0x6C,0x38,0xAF,0x55,0x7C,0xF9,0xED } };
    };
    template <> struct guid_storage<Windows::System::IAppDiagnosticInfo>
    {
        static constexpr guid value{ 0xE348A69A,0x8889,0x4CA3,{ 0xBE,0x07,0xD5,0xFF,0xFF,0x5F,0x08,0x04 } };
    };
    template <> struct guid_storage<Windows::System::IAppDiagnosticInfo2>
    {
        static constexpr guid value{ 0xDF46FBD7,0x191A,0x446C,{ 0x94,0x73,0x8F,0xBC,0x23,0x74,0xA3,0x54 } };
    };
    template <> struct guid_storage<Windows::System::IAppDiagnosticInfo3>
    {
        static constexpr guid value{ 0xC895C63D,0xDD61,0x4C65,{ 0xBA,0xBD,0x81,0xA1,0x0B,0x4F,0x98,0x15 } };
    };
    template <> struct guid_storage<Windows::System::IAppDiagnosticInfoStatics>
    {
        static constexpr guid value{ 0xCE6925BF,0x10CA,0x40C8,{ 0xA9,0xCA,0xC5,0xC9,0x65,0x01,0x86,0x6E } };
    };
    template <> struct guid_storage<Windows::System::IAppDiagnosticInfoStatics2>
    {
        static constexpr guid value{ 0x05B24B86,0x1000,0x4C90,{ 0xBB,0x9F,0x72,0x35,0x07,0x1C,0x50,0xFE } };
    };
    template <> struct guid_storage<Windows::System::IAppDiagnosticInfoWatcher>
    {
        static constexpr guid value{ 0x75575070,0x01D3,0x489A,{ 0x93,0x25,0x52,0xF9,0xCC,0x6E,0xDE,0x0A } };
    };
    template <> struct guid_storage<Windows::System::IAppDiagnosticInfoWatcherEventArgs>
    {
        static constexpr guid value{ 0x7017C716,0xE1DA,0x4C65,{ 0x99,0xDF,0x04,0x6D,0xFF,0x5B,0xE7,0x1A } };
    };
    template <> struct guid_storage<Windows::System::IAppExecutionStateChangeResult>
    {
        static constexpr guid value{ 0x6F039BF0,0xF91B,0x4DF8,{ 0xAE,0x77,0x30,0x33,0xCC,0xB6,0x91,0x14 } };
    };
    template <> struct guid_storage<Windows::System::IAppMemoryReport>
    {
        static constexpr guid value{ 0x6D65339B,0x4D6F,0x45BC,{ 0x9C,0x5E,0xE4,0x9B,0x3F,0xF2,0x75,0x8D } };
    };
    template <> struct guid_storage<Windows::System::IAppMemoryReport2>
    {
        static constexpr guid value{ 0x5F7F3738,0x51B7,0x42DC,{ 0xB7,0xED,0x79,0xBA,0x46,0xD2,0x88,0x57 } };
    };
    template <> struct guid_storage<Windows::System::IAppMemoryUsageLimitChangingEventArgs>
    {
        static constexpr guid value{ 0x79F86664,0xFECA,0x4DA5,{ 0x9E,0x40,0x2B,0xC6,0x3E,0xFD,0xC9,0x79 } };
    };
    template <> struct guid_storage<Windows::System::IAppResourceGroupBackgroundTaskReport>
    {
        static constexpr guid value{ 0x2566E74E,0xB05D,0x40C2,{ 0x9D,0xC1,0x1A,0x4F,0x03,0x9E,0xA1,0x20 } };
    };
    template <> struct guid_storage<Windows::System::IAppResourceGroupInfo>
    {
        static constexpr guid value{ 0xB913F77A,0xE807,0x49F4,{ 0x84,0x5E,0x7B,0x8B,0xDC,0xFE,0x8E,0xE7 } };
    };
    template <> struct guid_storage<Windows::System::IAppResourceGroupInfo2>
    {
        static constexpr guid value{ 0xEE9B236D,0xD305,0x4D6B,{ 0x92,0xF7,0x6A,0xFD,0xAD,0x72,0xDE,0xDC } };
    };
    template <> struct guid_storage<Windows::System::IAppResourceGroupInfoWatcher>
    {
        static constexpr guid value{ 0xD9B0A0FD,0x6E5A,0x4C72,{ 0x8B,0x17,0x09,0xFE,0xC4,0xA2,0x12,0xBD } };
    };
    template <> struct guid_storage<Windows::System::IAppResourceGroupInfoWatcherEventArgs>
    {
        static constexpr guid value{ 0x7A787637,0x6302,0x4D2F,{ 0xBF,0x89,0x1C,0x12,0xD0,0xB2,0xA6,0xB9 } };
    };
    template <> struct guid_storage<Windows::System::IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs>
    {
        static constexpr guid value{ 0x1BDBEDD7,0xFEE6,0x4FD4,{ 0x98,0xDD,0xE9,0x2A,0x2C,0xC2,0x99,0xF3 } };
    };
    template <> struct guid_storage<Windows::System::IAppResourceGroupMemoryReport>
    {
        static constexpr guid value{ 0x2C8C06B1,0x7DB1,0x4C51,{ 0xA2,0x25,0x7F,0xAE,0x2D,0x49,0xE4,0x31 } };
    };
    template <> struct guid_storage<Windows::System::IAppResourceGroupStateReport>
    {
        static constexpr guid value{ 0x52849F18,0x2F70,0x4236,{ 0xAB,0x40,0xD0,0x4D,0xB0,0xC7,0xB9,0x31 } };
    };
    template <> struct guid_storage<Windows::System::IAppUriHandlerHost>
    {
        static constexpr guid value{ 0x5D50CAC5,0x92D2,0x5409,{ 0xB5,0x6F,0x7F,0x73,0xE1,0x0E,0xA4,0xC3 } };
    };
    template <> struct guid_storage<Windows::System::IAppUriHandlerHostFactory>
    {
        static constexpr guid value{ 0x257C3C96,0xCE04,0x5F98,{ 0x96,0xBB,0x3E,0xBD,0x3E,0x92,0x75,0xBB } };
    };
    template <> struct guid_storage<Windows::System::IAppUriHandlerRegistration>
    {
        static constexpr guid value{ 0x6F73AEB1,0x4569,0x5C3F,{ 0x9B,0xA0,0x99,0x12,0x3E,0xEA,0x32,0xC3 } };
    };
    template <> struct guid_storage<Windows::System::IAppUriHandlerRegistrationManager>
    {
        static constexpr guid value{ 0xE62C9A52,0xAC94,0x5750,{ 0xAC,0x1B,0x6C,0xFB,0x6F,0x25,0x02,0x63 } };
    };
    template <> struct guid_storage<Windows::System::IAppUriHandlerRegistrationManagerStatics>
    {
        static constexpr guid value{ 0xD5CEDD9F,0x5729,0x5B76,{ 0xA1,0xD4,0x02,0x85,0xF2,0x95,0xC1,0x24 } };
    };
    template <> struct guid_storage<Windows::System::IDateTimeSettingsStatics>
    {
        static constexpr guid value{ 0x5D2150D1,0x47EE,0x48AB,{ 0xA5,0x2B,0x9F,0x19,0x54,0x27,0x8D,0x82 } };
    };
    template <> struct guid_storage<Windows::System::IDispatcherQueue>
    {
        static constexpr guid value{ 0x603E88E4,0xA338,0x4FFE,{ 0xA4,0x57,0xA5,0xCF,0xB9,0xCE,0xB8,0x99 } };
    };
    template <> struct guid_storage<Windows::System::IDispatcherQueue2>
    {
        static constexpr guid value{ 0xC822C647,0x30EF,0x506E,{ 0xBD,0x1E,0xA6,0x47,0xAE,0x66,0x75,0xFF } };
    };
    template <> struct guid_storage<Windows::System::IDispatcherQueueController>
    {
        static constexpr guid value{ 0x22F34E66,0x50DB,0x4E36,{ 0xA9,0x8D,0x61,0xC0,0x1B,0x38,0x4D,0x20 } };
    };
    template <> struct guid_storage<Windows::System::IDispatcherQueueControllerStatics>
    {
        static constexpr guid value{ 0x0A6C98E0,0x5198,0x49A2,{ 0xA3,0x13,0x3F,0x70,0xD1,0xF1,0x3C,0x27 } };
    };
    template <> struct guid_storage<Windows::System::IDispatcherQueueShutdownStartingEventArgs>
    {
        static constexpr guid value{ 0xC4724C4C,0xFF97,0x40C0,{ 0xA2,0x26,0xCC,0x0A,0xAA,0x54,0x5E,0x89 } };
    };
    template <> struct guid_storage<Windows::System::IDispatcherQueueStatics>
    {
        static constexpr guid value{ 0xA96D83D7,0x9371,0x4517,{ 0x92,0x45,0xD0,0x82,0x4A,0xC1,0x2C,0x74 } };
    };
    template <> struct guid_storage<Windows::System::IDispatcherQueueTimer>
    {
        static constexpr guid value{ 0x5FEABB1D,0xA31C,0x4727,{ 0xB1,0xAC,0x37,0x45,0x46,0x49,0xD5,0x6A } };
    };
    template <> struct guid_storage<Windows::System::IFolderLauncherOptions>
    {
        static constexpr guid value{ 0xBB91C27D,0x6B87,0x432A,{ 0xBD,0x04,0x77,0x6C,0x6F,0x5F,0xB2,0xAB } };
    };
    template <> struct guid_storage<Windows::System::IKnownUserPropertiesStatics>
    {
        static constexpr guid value{ 0x7755911A,0x70C5,0x48E5,{ 0xB6,0x37,0x5B,0xA3,0x44,0x1E,0x4E,0xE4 } };
    };
    template <> struct guid_storage<Windows::System::ILaunchUriResult>
    {
        static constexpr guid value{ 0xEC27A8DF,0xF6D5,0x45CA,{ 0x91,0x3A,0x70,0xA4,0x0C,0x5C,0x82,0x21 } };
    };
    template <> struct guid_storage<Windows::System::ILauncherOptions>
    {
        static constexpr guid value{ 0xBAFA21D8,0xB071,0x4CD8,{ 0x85,0x3E,0x34,0x12,0x03,0xE5,0x57,0xD3 } };
    };
    template <> struct guid_storage<Windows::System::ILauncherOptions2>
    {
        static constexpr guid value{ 0x3BA08EB4,0x6E40,0x4DCE,{ 0xA1,0xA3,0x2F,0x53,0x95,0x0A,0xFB,0x49 } };
    };
    template <> struct guid_storage<Windows::System::ILauncherOptions3>
    {
        static constexpr guid value{ 0xF0770655,0x4B63,0x4E3A,{ 0x91,0x07,0x4E,0x68,0x78,0x41,0x92,0x3A } };
    };
    template <> struct guid_storage<Windows::System::ILauncherOptions4>
    {
        static constexpr guid value{ 0xEF6FD10E,0xE6FB,0x4814,{ 0xA4,0x4E,0x57,0xE8,0xB9,0xD9,0xA0,0x1B } };
    };
    template <> struct guid_storage<Windows::System::ILauncherStatics>
    {
        static constexpr guid value{ 0x277151C3,0x9E3E,0x42F6,{ 0x91,0xA4,0x5D,0xFD,0xEB,0x23,0x24,0x51 } };
    };
    template <> struct guid_storage<Windows::System::ILauncherStatics2>
    {
        static constexpr guid value{ 0x59BA2FBB,0x24CB,0x4C02,{ 0xA4,0xC4,0x82,0x94,0x56,0x9D,0x54,0xF1 } };
    };
    template <> struct guid_storage<Windows::System::ILauncherStatics3>
    {
        static constexpr guid value{ 0x234261A8,0x9DB3,0x4683,{ 0xAA,0x42,0xDC,0x6F,0x51,0xD3,0x38,0x47 } };
    };
    template <> struct guid_storage<Windows::System::ILauncherStatics4>
    {
        static constexpr guid value{ 0xB9EC819F,0xB5A5,0x41C6,{ 0xB3,0xB3,0xDD,0x1B,0x31,0x78,0xBC,0xF2 } };
    };
    template <> struct guid_storage<Windows::System::ILauncherStatics5>
    {
        static constexpr guid value{ 0x5B24EF84,0xD895,0x5FEA,{ 0x91,0x53,0x1A,0xC4,0x9A,0xED,0x9B,0xA9 } };
    };
    template <> struct guid_storage<Windows::System::ILauncherUIOptions>
    {
        static constexpr guid value{ 0x1B25DA6E,0x8AA6,0x41E9,{ 0x82,0x51,0x41,0x65,0xF5,0x98,0x5F,0x49 } };
    };
    template <> struct guid_storage<Windows::System::ILauncherViewOptions>
    {
        static constexpr guid value{ 0x8A9B29F1,0x7CA7,0x49DE,{ 0x9B,0xD3,0x3C,0x5B,0x71,0x84,0xF6,0x16 } };
    };
    template <> struct guid_storage<Windows::System::IMemoryManagerStatics>
    {
        static constexpr guid value{ 0x5C6C279C,0xD7CA,0x4779,{ 0x91,0x88,0x40,0x57,0x21,0x9C,0xE6,0x4C } };
    };
    template <> struct guid_storage<Windows::System::IMemoryManagerStatics2>
    {
        static constexpr guid value{ 0x6EEE351F,0x6D62,0x423F,{ 0x94,0x79,0xB0,0x1F,0x9C,0x9F,0x76,0x69 } };
    };
    template <> struct guid_storage<Windows::System::IMemoryManagerStatics3>
    {
        static constexpr guid value{ 0x149B59CE,0x92AD,0x4E35,{ 0x89,0xEB,0x50,0xDF,0xB4,0xC0,0xD9,0x1C } };
    };
    template <> struct guid_storage<Windows::System::IMemoryManagerStatics4>
    {
        static constexpr guid value{ 0xC5A94828,0xE84E,0x4886,{ 0x8A,0x0D,0x44,0xB3,0x19,0x0E,0x3B,0x72 } };
    };
    template <> struct guid_storage<Windows::System::IProcessLauncherOptions>
    {
        static constexpr guid value{ 0x3080B9CF,0xF444,0x4A83,{ 0xBE,0xAF,0xA5,0x49,0xA0,0xF3,0x22,0x9C } };
    };
    template <> struct guid_storage<Windows::System::IProcessLauncherResult>
    {
        static constexpr guid value{ 0x544C8934,0x86D8,0x4991,{ 0x8E,0x75,0xEC,0xE8,0xA4,0x3B,0x6B,0x6D } };
    };
    template <> struct guid_storage<Windows::System::IProcessLauncherStatics>
    {
        static constexpr guid value{ 0x33AB66E7,0x2D0E,0x448B,{ 0xA6,0xA0,0xC1,0x3C,0x38,0x36,0xD0,0x9C } };
    };
    template <> struct guid_storage<Windows::System::IProcessMemoryReport>
    {
        static constexpr guid value{ 0x087305A8,0x9B70,0x4782,{ 0x87,0x41,0x3A,0x98,0x2B,0x6C,0xE5,0xE4 } };
    };
    template <> struct guid_storage<Windows::System::IProtocolForResultsOperation>
    {
        static constexpr guid value{ 0xD581293A,0x6DE9,0x4D28,{ 0x93,0x78,0xF8,0x67,0x82,0xE1,0x82,0xBB } };
    };
    template <> struct guid_storage<Windows::System::IRemoteLauncherOptions>
    {
        static constexpr guid value{ 0x9E3A2788,0x2891,0x4CDF,{ 0xA2,0xD6,0x9D,0xFF,0x7D,0x02,0xE6,0x93 } };
    };
    template <> struct guid_storage<Windows::System::IRemoteLauncherStatics>
    {
        static constexpr guid value{ 0xD7DB7A93,0xA30C,0x48B7,{ 0x9F,0x21,0x05,0x10,0x26,0xA4,0xE5,0x17 } };
    };
    template <> struct guid_storage<Windows::System::IShutdownManagerStatics>
    {
        static constexpr guid value{ 0x72E247ED,0xDD5B,0x4D6C,{ 0xB1,0xD0,0xC5,0x7A,0x7B,0xBB,0x5F,0x94 } };
    };
    template <> struct guid_storage<Windows::System::IShutdownManagerStatics2>
    {
        static constexpr guid value{ 0x0F69A02F,0x9C34,0x43C7,{ 0xA8,0xC3,0x70,0xB3,0x0A,0x7F,0x75,0x04 } };
    };
    template <> struct guid_storage<Windows::System::ITimeZoneSettingsStatics>
    {
        static constexpr guid value{ 0x9B3B2BEA,0xA101,0x41AE,{ 0x9F,0xBD,0x02,0x87,0x28,0xBA,0xB7,0x3D } };
    };
    template <> struct guid_storage<Windows::System::ITimeZoneSettingsStatics2>
    {
        static constexpr guid value{ 0x555C0DB8,0x39A8,0x49FA,{ 0xB4,0xF6,0xA2,0xC7,0xFC,0x28,0x42,0xEC } };
    };
    template <> struct guid_storage<Windows::System::IUser>
    {
        static constexpr guid value{ 0xDF9A26C6,0xE746,0x4BCD,{ 0xB5,0xD4,0x12,0x01,0x03,0xC4,0x20,0x9B } };
    };
    template <> struct guid_storage<Windows::System::IUserAuthenticationStatusChangeDeferral>
    {
        static constexpr guid value{ 0x88B59568,0xBB30,0x42FB,{ 0xA2,0x70,0xE9,0x90,0x2E,0x40,0xEF,0xA7 } };
    };
    template <> struct guid_storage<Windows::System::IUserAuthenticationStatusChangingEventArgs>
    {
        static constexpr guid value{ 0x8C030F28,0xA711,0x4C1E,{ 0xAB,0x48,0x04,0x17,0x9C,0x15,0x93,0x8F } };
    };
    template <> struct guid_storage<Windows::System::IUserChangedEventArgs>
    {
        static constexpr guid value{ 0x086459DC,0x18C6,0x48DB,{ 0xBC,0x99,0x72,0x4F,0xB9,0x20,0x3C,0xCC } };
    };
    template <> struct guid_storage<Windows::System::IUserChangedEventArgs2>
    {
        static constexpr guid value{ 0x6B2CCB44,0x6F01,0x560C,{ 0x97,0xAD,0xFC,0x7F,0x32,0xEC,0x58,0x1F } };
    };
    template <> struct guid_storage<Windows::System::IUserDeviceAssociationChangedEventArgs>
    {
        static constexpr guid value{ 0xBD1F6F6C,0xBB5D,0x4D7B,{ 0xA5,0xF0,0xC8,0xCD,0x11,0xA3,0x8D,0x42 } };
    };
    template <> struct guid_storage<Windows::System::IUserDeviceAssociationStatics>
    {
        static constexpr guid value{ 0x7E491E14,0xF85A,0x4C07,{ 0x8D,0xA9,0x7F,0xE3,0xD0,0x54,0x23,0x43 } };
    };
    template <> struct guid_storage<Windows::System::IUserPicker>
    {
        static constexpr guid value{ 0x7D548008,0xF1E3,0x4A6C,{ 0x8D,0xDC,0xA9,0xBB,0x0F,0x48,0x8A,0xED } };
    };
    template <> struct guid_storage<Windows::System::IUserPickerStatics>
    {
        static constexpr guid value{ 0xDE3290DC,0x7E73,0x4DF6,{ 0xA1,0xAE,0x4D,0x7E,0xCA,0x82,0xB4,0x0D } };
    };
    template <> struct guid_storage<Windows::System::IUserStatics>
    {
        static constexpr guid value{ 0x155EB23B,0x242A,0x45E0,{ 0xA2,0xE9,0x31,0x71,0xFC,0x6A,0x7F,0xDD } };
    };
    template <> struct guid_storage<Windows::System::IUserWatcher>
    {
        static constexpr guid value{ 0x155EB23B,0x242A,0x45E0,{ 0xA2,0xE9,0x31,0x71,0xFC,0x6A,0x7F,0xBB } };
    };
    template <> struct guid_storage<Windows::System::DispatcherQueueHandler>
    {
        static constexpr guid value{ 0xDFA2DC9C,0x1A2D,0x4917,{ 0x98,0xF2,0x93,0x9A,0xF1,0xD6,0xE0,0xC8 } };
    };
    template <> struct default_interface<Windows::System::AppActivationResult>
    {
        using type = Windows::System::IAppActivationResult;
    };
    template <> struct default_interface<Windows::System::AppDiagnosticInfo>
    {
        using type = Windows::System::IAppDiagnosticInfo;
    };
    template <> struct default_interface<Windows::System::AppDiagnosticInfoWatcher>
    {
        using type = Windows::System::IAppDiagnosticInfoWatcher;
    };
    template <> struct default_interface<Windows::System::AppDiagnosticInfoWatcherEventArgs>
    {
        using type = Windows::System::IAppDiagnosticInfoWatcherEventArgs;
    };
    template <> struct default_interface<Windows::System::AppExecutionStateChangeResult>
    {
        using type = Windows::System::IAppExecutionStateChangeResult;
    };
    template <> struct default_interface<Windows::System::AppMemoryReport>
    {
        using type = Windows::System::IAppMemoryReport;
    };
    template <> struct default_interface<Windows::System::AppMemoryUsageLimitChangingEventArgs>
    {
        using type = Windows::System::IAppMemoryUsageLimitChangingEventArgs;
    };
    template <> struct default_interface<Windows::System::AppResourceGroupBackgroundTaskReport>
    {
        using type = Windows::System::IAppResourceGroupBackgroundTaskReport;
    };
    template <> struct default_interface<Windows::System::AppResourceGroupInfo>
    {
        using type = Windows::System::IAppResourceGroupInfo;
    };
    template <> struct default_interface<Windows::System::AppResourceGroupInfoWatcher>
    {
        using type = Windows::System::IAppResourceGroupInfoWatcher;
    };
    template <> struct default_interface<Windows::System::AppResourceGroupInfoWatcherEventArgs>
    {
        using type = Windows::System::IAppResourceGroupInfoWatcherEventArgs;
    };
    template <> struct default_interface<Windows::System::AppResourceGroupInfoWatcherExecutionStateChangedEventArgs>
    {
        using type = Windows::System::IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs;
    };
    template <> struct default_interface<Windows::System::AppResourceGroupMemoryReport>
    {
        using type = Windows::System::IAppResourceGroupMemoryReport;
    };
    template <> struct default_interface<Windows::System::AppResourceGroupStateReport>
    {
        using type = Windows::System::IAppResourceGroupStateReport;
    };
    template <> struct default_interface<Windows::System::AppUriHandlerHost>
    {
        using type = Windows::System::IAppUriHandlerHost;
    };
    template <> struct default_interface<Windows::System::AppUriHandlerRegistration>
    {
        using type = Windows::System::IAppUriHandlerRegistration;
    };
    template <> struct default_interface<Windows::System::AppUriHandlerRegistrationManager>
    {
        using type = Windows::System::IAppUriHandlerRegistrationManager;
    };
    template <> struct default_interface<Windows::System::DispatcherQueue>
    {
        using type = Windows::System::IDispatcherQueue;
    };
    template <> struct default_interface<Windows::System::DispatcherQueueController>
    {
        using type = Windows::System::IDispatcherQueueController;
    };
    template <> struct default_interface<Windows::System::DispatcherQueueShutdownStartingEventArgs>
    {
        using type = Windows::System::IDispatcherQueueShutdownStartingEventArgs;
    };
    template <> struct default_interface<Windows::System::DispatcherQueueTimer>
    {
        using type = Windows::System::IDispatcherQueueTimer;
    };
    template <> struct default_interface<Windows::System::FolderLauncherOptions>
    {
        using type = Windows::System::IFolderLauncherOptions;
    };
    template <> struct default_interface<Windows::System::LaunchUriResult>
    {
        using type = Windows::System::ILaunchUriResult;
    };
    template <> struct default_interface<Windows::System::LauncherOptions>
    {
        using type = Windows::System::ILauncherOptions;
    };
    template <> struct default_interface<Windows::System::LauncherUIOptions>
    {
        using type = Windows::System::ILauncherUIOptions;
    };
    template <> struct default_interface<Windows::System::ProcessLauncherOptions>
    {
        using type = Windows::System::IProcessLauncherOptions;
    };
    template <> struct default_interface<Windows::System::ProcessLauncherResult>
    {
        using type = Windows::System::IProcessLauncherResult;
    };
    template <> struct default_interface<Windows::System::ProcessMemoryReport>
    {
        using type = Windows::System::IProcessMemoryReport;
    };
    template <> struct default_interface<Windows::System::ProtocolForResultsOperation>
    {
        using type = Windows::System::IProtocolForResultsOperation;
    };
    template <> struct default_interface<Windows::System::RemoteLauncherOptions>
    {
        using type = Windows::System::IRemoteLauncherOptions;
    };
    template <> struct default_interface<Windows::System::User>
    {
        using type = Windows::System::IUser;
    };
    template <> struct default_interface<Windows::System::UserAuthenticationStatusChangeDeferral>
    {
        using type = Windows::System::IUserAuthenticationStatusChangeDeferral;
    };
    template <> struct default_interface<Windows::System::UserAuthenticationStatusChangingEventArgs>
    {
        using type = Windows::System::IUserAuthenticationStatusChangingEventArgs;
    };
    template <> struct default_interface<Windows::System::UserChangedEventArgs>
    {
        using type = Windows::System::IUserChangedEventArgs;
    };
    template <> struct default_interface<Windows::System::UserDeviceAssociationChangedEventArgs>
    {
        using type = Windows::System::IUserDeviceAssociationChangedEventArgs;
    };
    template <> struct default_interface<Windows::System::UserPicker>
    {
        using type = Windows::System::IUserPicker;
    };
    template <> struct default_interface<Windows::System::UserWatcher>
    {
        using type = Windows::System::IUserWatcher;
    };
    template <> struct abi<Windows::System::IAppActivationResult>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ExtendedError(winrt::hresult*) noexcept = 0;
            virtual int32_t __stdcall get_AppResourceGroupInfo(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppDiagnosticInfo>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AppInfo(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppDiagnosticInfo2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetResourceGroups(void**) noexcept = 0;
            virtual int32_t __stdcall CreateResourceGroupWatcher(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppDiagnosticInfo3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall LaunchAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppDiagnosticInfoStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall RequestInfoAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppDiagnosticInfoStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateWatcher(void**) noexcept = 0;
            virtual int32_t __stdcall RequestAccessAsync(void**) noexcept = 0;
            virtual int32_t __stdcall RequestInfoForPackageAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall RequestInfoForAppAsync(void**) noexcept = 0;
            virtual int32_t __stdcall RequestInfoForAppUserModelId(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppDiagnosticInfoWatcher>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall add_Added(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Added(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Removed(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Removed(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_EnumerationCompleted(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_EnumerationCompleted(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Stopped(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Stopped(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall Start() noexcept = 0;
            virtual int32_t __stdcall Stop() noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppDiagnosticInfoWatcherEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AppDiagnosticInfo(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppExecutionStateChangeResult>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ExtendedError(winrt::hresult*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppMemoryReport>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_PrivateCommitUsage(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall get_PeakPrivateCommitUsage(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall get_TotalCommitUsage(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall get_TotalCommitLimit(uint64_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppMemoryReport2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ExpectedTotalCommitLimit(uint64_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppMemoryUsageLimitChangingEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_OldLimit(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall get_NewLimit(uint64_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppResourceGroupBackgroundTaskReport>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_TaskId(winrt::guid*) noexcept = 0;
            virtual int32_t __stdcall get_Name(void**) noexcept = 0;
            virtual int32_t __stdcall get_Trigger(void**) noexcept = 0;
            virtual int32_t __stdcall get_EntryPoint(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppResourceGroupInfo>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_InstanceId(winrt::guid*) noexcept = 0;
            virtual int32_t __stdcall get_IsShared(bool*) noexcept = 0;
            virtual int32_t __stdcall GetBackgroundTaskReports(void**) noexcept = 0;
            virtual int32_t __stdcall GetMemoryReport(void**) noexcept = 0;
            virtual int32_t __stdcall GetProcessDiagnosticInfos(void**) noexcept = 0;
            virtual int32_t __stdcall GetStateReport(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppResourceGroupInfo2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall StartSuspendAsync(void**) noexcept = 0;
            virtual int32_t __stdcall StartResumeAsync(void**) noexcept = 0;
            virtual int32_t __stdcall StartTerminateAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppResourceGroupInfoWatcher>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall add_Added(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Added(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Removed(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Removed(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_EnumerationCompleted(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_EnumerationCompleted(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Stopped(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Stopped(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_ExecutionStateChanged(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_ExecutionStateChanged(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall Start() noexcept = 0;
            virtual int32_t __stdcall Stop() noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppResourceGroupInfoWatcherEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AppDiagnosticInfos(void**) noexcept = 0;
            virtual int32_t __stdcall get_AppResourceGroupInfo(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AppDiagnosticInfos(void**) noexcept = 0;
            virtual int32_t __stdcall get_AppResourceGroupInfo(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppResourceGroupMemoryReport>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_CommitUsageLimit(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall get_CommitUsageLevel(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_PrivateCommitUsage(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall get_TotalCommitUsage(uint64_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppResourceGroupStateReport>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ExecutionState(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_EnergyQuotaState(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppUriHandlerHost>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Name(void**) noexcept = 0;
            virtual int32_t __stdcall put_Name(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppUriHandlerHostFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateInstance(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppUriHandlerRegistration>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Name(void**) noexcept = 0;
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
            virtual int32_t __stdcall GetAppAddedHostsAsync(void**) noexcept = 0;
            virtual int32_t __stdcall SetAppAddedHostsAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppUriHandlerRegistrationManager>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
            virtual int32_t __stdcall TryGetRegistration(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IAppUriHandlerRegistrationManagerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetDefault(void**) noexcept = 0;
            virtual int32_t __stdcall GetForUser(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IDateTimeSettingsStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall SetSystemDateTime(int64_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IDispatcherQueue>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateTimer(void**) noexcept = 0;
            virtual int32_t __stdcall TryEnqueue(void*, bool*) noexcept = 0;
            virtual int32_t __stdcall TryEnqueueWithPriority(int32_t, void*, bool*) noexcept = 0;
            virtual int32_t __stdcall add_ShutdownStarting(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_ShutdownStarting(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_ShutdownCompleted(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_ShutdownCompleted(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IDispatcherQueue2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_HasThreadAccess(bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IDispatcherQueueController>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_DispatcherQueue(void**) noexcept = 0;
            virtual int32_t __stdcall ShutdownQueueAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IDispatcherQueueControllerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateOnDedicatedThread(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IDispatcherQueueShutdownStartingEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetDeferral(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IDispatcherQueueStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetForCurrentThread(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IDispatcherQueueTimer>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Interval(int64_t*) noexcept = 0;
            virtual int32_t __stdcall put_Interval(int64_t) noexcept = 0;
            virtual int32_t __stdcall get_IsRunning(bool*) noexcept = 0;
            virtual int32_t __stdcall get_IsRepeating(bool*) noexcept = 0;
            virtual int32_t __stdcall put_IsRepeating(bool) noexcept = 0;
            virtual int32_t __stdcall Start() noexcept = 0;
            virtual int32_t __stdcall Stop() noexcept = 0;
            virtual int32_t __stdcall add_Tick(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Tick(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IFolderLauncherOptions>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ItemsToSelect(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IKnownUserPropertiesStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_DisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall get_FirstName(void**) noexcept = 0;
            virtual int32_t __stdcall get_LastName(void**) noexcept = 0;
            virtual int32_t __stdcall get_ProviderName(void**) noexcept = 0;
            virtual int32_t __stdcall get_AccountName(void**) noexcept = 0;
            virtual int32_t __stdcall get_GuestHost(void**) noexcept = 0;
            virtual int32_t __stdcall get_PrincipalName(void**) noexcept = 0;
            virtual int32_t __stdcall get_DomainName(void**) noexcept = 0;
            virtual int32_t __stdcall get_SessionInitiationProtocolUri(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILaunchUriResult>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Result(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherOptions>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_TreatAsUntrusted(bool*) noexcept = 0;
            virtual int32_t __stdcall put_TreatAsUntrusted(bool) noexcept = 0;
            virtual int32_t __stdcall get_DisplayApplicationPicker(bool*) noexcept = 0;
            virtual int32_t __stdcall put_DisplayApplicationPicker(bool) noexcept = 0;
            virtual int32_t __stdcall get_UI(void**) noexcept = 0;
            virtual int32_t __stdcall get_PreferredApplicationPackageFamilyName(void**) noexcept = 0;
            virtual int32_t __stdcall put_PreferredApplicationPackageFamilyName(void*) noexcept = 0;
            virtual int32_t __stdcall get_PreferredApplicationDisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall put_PreferredApplicationDisplayName(void*) noexcept = 0;
            virtual int32_t __stdcall get_FallbackUri(void**) noexcept = 0;
            virtual int32_t __stdcall put_FallbackUri(void*) noexcept = 0;
            virtual int32_t __stdcall get_ContentType(void**) noexcept = 0;
            virtual int32_t __stdcall put_ContentType(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherOptions2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_TargetApplicationPackageFamilyName(void**) noexcept = 0;
            virtual int32_t __stdcall put_TargetApplicationPackageFamilyName(void*) noexcept = 0;
            virtual int32_t __stdcall get_NeighboringFilesQuery(void**) noexcept = 0;
            virtual int32_t __stdcall put_NeighboringFilesQuery(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherOptions3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_IgnoreAppUriHandlers(bool*) noexcept = 0;
            virtual int32_t __stdcall put_IgnoreAppUriHandlers(bool) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherOptions4>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_LimitPickerToCurrentAppAndAppUriHandlers(bool*) noexcept = 0;
            virtual int32_t __stdcall put_LimitPickerToCurrentAppAndAppUriHandlers(bool) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall LaunchFileAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchFileWithOptionsAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriWithOptionsAsync(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall LaunchUriForResultsAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriForResultsWithDataAsync(void*, void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriWithDataAsync(void*, void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall QueryUriSupportAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall QueryUriSupportWithPackageFamilyNameAsync(void*, int32_t, void*, void**) noexcept = 0;
            virtual int32_t __stdcall QueryFileSupportAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall QueryFileSupportWithPackageFamilyNameAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall FindUriSchemeHandlersAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall FindUriSchemeHandlersWithLaunchUriTypeAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall FindFileHandlersAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherStatics3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall LaunchFolderAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchFolderWithOptionsAsync(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherStatics4>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall QueryAppUriSupportAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall QueryAppUriSupportWithPackageFamilyNameAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall FindAppUriHandlersAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriForUserAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriWithOptionsForUserAsync(void*, void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriWithDataForUserAsync(void*, void*, void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriForResultsForUserAsync(void*, void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriForResultsWithDataForUserAsync(void*, void*, void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherStatics5>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall LaunchFolderPathAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchFolderPathWithOptionsAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchFolderPathForUserAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchFolderPathWithOptionsForUserAsync(void*, void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherUIOptions>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_InvocationPoint(void**) noexcept = 0;
            virtual int32_t __stdcall put_InvocationPoint(void*) noexcept = 0;
            virtual int32_t __stdcall get_SelectionRect(void**) noexcept = 0;
            virtual int32_t __stdcall put_SelectionRect(void*) noexcept = 0;
            virtual int32_t __stdcall get_PreferredPlacement(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_PreferredPlacement(int32_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ILauncherViewOptions>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_DesiredRemainingView(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_DesiredRemainingView(int32_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IMemoryManagerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AppMemoryUsage(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall get_AppMemoryUsageLimit(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall get_AppMemoryUsageLevel(int32_t*) noexcept = 0;
            virtual int32_t __stdcall add_AppMemoryUsageIncreased(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_AppMemoryUsageIncreased(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_AppMemoryUsageDecreased(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_AppMemoryUsageDecreased(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_AppMemoryUsageLimitChanging(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_AppMemoryUsageLimitChanging(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IMemoryManagerStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetAppMemoryReport(void**) noexcept = 0;
            virtual int32_t __stdcall GetProcessMemoryReport(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IMemoryManagerStatics3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall TrySetAppMemoryUsageLimit(uint64_t, bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IMemoryManagerStatics4>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ExpectedAppMemoryUsageLimit(uint64_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IProcessLauncherOptions>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_StandardInput(void**) noexcept = 0;
            virtual int32_t __stdcall put_StandardInput(void*) noexcept = 0;
            virtual int32_t __stdcall get_StandardOutput(void**) noexcept = 0;
            virtual int32_t __stdcall put_StandardOutput(void*) noexcept = 0;
            virtual int32_t __stdcall get_StandardError(void**) noexcept = 0;
            virtual int32_t __stdcall put_StandardError(void*) noexcept = 0;
            virtual int32_t __stdcall get_WorkingDirectory(void**) noexcept = 0;
            virtual int32_t __stdcall put_WorkingDirectory(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IProcessLauncherResult>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ExitCode(uint32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IProcessLauncherStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall RunToCompletionAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall RunToCompletionAsyncWithOptions(void*, void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IProcessMemoryReport>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_PrivateWorkingSetUsage(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall get_TotalWorkingSetUsage(uint64_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IProtocolForResultsOperation>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall ReportCompleted(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IRemoteLauncherOptions>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_FallbackUri(void**) noexcept = 0;
            virtual int32_t __stdcall put_FallbackUri(void*) noexcept = 0;
            virtual int32_t __stdcall get_PreferredAppIds(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IRemoteLauncherStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall LaunchUriAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriWithOptionsAsync(void*, void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LaunchUriWithDataAsync(void*, void*, void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IShutdownManagerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall BeginShutdown(int32_t, int64_t) noexcept = 0;
            virtual int32_t __stdcall CancelShutdown() noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IShutdownManagerStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall IsPowerStateSupported(int32_t, bool*) noexcept = 0;
            virtual int32_t __stdcall EnterPowerState(int32_t) noexcept = 0;
            virtual int32_t __stdcall EnterPowerStateWithTimeSpan(int32_t, int64_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ITimeZoneSettingsStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_CurrentTimeZoneDisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall get_SupportedTimeZoneDisplayNames(void**) noexcept = 0;
            virtual int32_t __stdcall get_CanChangeTimeZone(bool*) noexcept = 0;
            virtual int32_t __stdcall ChangeTimeZoneByDisplayName(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::ITimeZoneSettingsStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall AutoUpdateTimeZoneAsync(int64_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUser>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_NonRoamableId(void**) noexcept = 0;
            virtual int32_t __stdcall get_AuthenticationStatus(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Type(int32_t*) noexcept = 0;
            virtual int32_t __stdcall GetPropertyAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetPropertiesAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetPictureAsync(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserAuthenticationStatusChangeDeferral>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Complete() noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserAuthenticationStatusChangingEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetDeferral(void**) noexcept = 0;
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
            virtual int32_t __stdcall get_NewStatus(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_CurrentStatus(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserChangedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserChangedEventArgs2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ChangedPropertyKinds(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserDeviceAssociationChangedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_DeviceId(void**) noexcept = 0;
            virtual int32_t __stdcall get_NewUser(void**) noexcept = 0;
            virtual int32_t __stdcall get_OldUser(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserDeviceAssociationStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall FindUserFromDeviceId(void*, void**) noexcept = 0;
            virtual int32_t __stdcall add_UserDeviceAssociationChanged(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_UserDeviceAssociationChanged(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserPicker>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AllowGuestAccounts(bool*) noexcept = 0;
            virtual int32_t __stdcall put_AllowGuestAccounts(bool) noexcept = 0;
            virtual int32_t __stdcall get_SuggestedSelectedUser(void**) noexcept = 0;
            virtual int32_t __stdcall put_SuggestedSelectedUser(void*) noexcept = 0;
            virtual int32_t __stdcall PickSingleUserAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserPickerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall IsSupported(bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateWatcher(void**) noexcept = 0;
            virtual int32_t __stdcall FindAllAsync(void**) noexcept = 0;
            virtual int32_t __stdcall FindAllAsyncByType(int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall FindAllAsyncByTypeAndStatus(int32_t, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetFromId(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::IUserWatcher>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall Start() noexcept = 0;
            virtual int32_t __stdcall Stop() noexcept = 0;
            virtual int32_t __stdcall add_Added(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Added(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Removed(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Removed(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Updated(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Updated(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_AuthenticationStatusChanged(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_AuthenticationStatusChanged(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_AuthenticationStatusChanging(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_AuthenticationStatusChanging(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_EnumerationCompleted(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_EnumerationCompleted(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Stopped(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Stopped(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::DispatcherQueueHandler>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke() noexcept = 0;
        };
    };
    template <typename D>
    struct consume_Windows_System_IAppActivationResult
    {
        [[nodiscard]] auto ExtendedError() const;
        [[nodiscard]] auto AppResourceGroupInfo() const;
    };
    template <> struct consume<Windows::System::IAppActivationResult>
    {
        template <typename D> using type = consume_Windows_System_IAppActivationResult<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppDiagnosticInfo
    {
        [[nodiscard]] auto AppInfo() const;
    };
    template <> struct consume<Windows::System::IAppDiagnosticInfo>
    {
        template <typename D> using type = consume_Windows_System_IAppDiagnosticInfo<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppDiagnosticInfo2
    {
        auto GetResourceGroups() const;
        auto CreateResourceGroupWatcher() const;
    };
    template <> struct consume<Windows::System::IAppDiagnosticInfo2>
    {
        template <typename D> using type = consume_Windows_System_IAppDiagnosticInfo2<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppDiagnosticInfo3
    {
        auto LaunchAsync() const;
    };
    template <> struct consume<Windows::System::IAppDiagnosticInfo3>
    {
        template <typename D> using type = consume_Windows_System_IAppDiagnosticInfo3<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppDiagnosticInfoStatics
    {
        auto RequestInfoAsync() const;
    };
    template <> struct consume<Windows::System::IAppDiagnosticInfoStatics>
    {
        template <typename D> using type = consume_Windows_System_IAppDiagnosticInfoStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppDiagnosticInfoStatics2
    {
        auto CreateWatcher() const;
        auto RequestAccessAsync() const;
        auto RequestInfoForPackageAsync(param::hstring const& packageFamilyName) const;
        auto RequestInfoForAppAsync() const;
        auto RequestInfoForAppAsync(param::hstring const& appUserModelId) const;
    };
    template <> struct consume<Windows::System::IAppDiagnosticInfoStatics2>
    {
        template <typename D> using type = consume_Windows_System_IAppDiagnosticInfoStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppDiagnosticInfoWatcher
    {
        auto Added(Windows::Foundation::TypedEventHandler<Windows::System::AppDiagnosticInfoWatcher, Windows::System::AppDiagnosticInfoWatcherEventArgs> const& handler) const;
        using Added_revoker = impl::event_revoker<Windows::System::IAppDiagnosticInfoWatcher, &impl::abi_t<Windows::System::IAppDiagnosticInfoWatcher>::remove_Added>;
        Added_revoker Added(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::AppDiagnosticInfoWatcher, Windows::System::AppDiagnosticInfoWatcherEventArgs> const& handler) const;
        auto Added(winrt::event_token const& token) const noexcept;
        auto Removed(Windows::Foundation::TypedEventHandler<Windows::System::AppDiagnosticInfoWatcher, Windows::System::AppDiagnosticInfoWatcherEventArgs> const& handler) const;
        using Removed_revoker = impl::event_revoker<Windows::System::IAppDiagnosticInfoWatcher, &impl::abi_t<Windows::System::IAppDiagnosticInfoWatcher>::remove_Removed>;
        Removed_revoker Removed(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::AppDiagnosticInfoWatcher, Windows::System::AppDiagnosticInfoWatcherEventArgs> const& handler) const;
        auto Removed(winrt::event_token const& token) const noexcept;
        auto EnumerationCompleted(Windows::Foundation::TypedEventHandler<Windows::System::AppDiagnosticInfoWatcher, Windows::Foundation::IInspectable> const& handler) const;
        using EnumerationCompleted_revoker = impl::event_revoker<Windows::System::IAppDiagnosticInfoWatcher, &impl::abi_t<Windows::System::IAppDiagnosticInfoWatcher>::remove_EnumerationCompleted>;
        EnumerationCompleted_revoker EnumerationCompleted(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::AppDiagnosticInfoWatcher, Windows::Foundation::IInspectable> const& handler) const;
        auto EnumerationCompleted(winrt::event_token const& token) const noexcept;
        auto Stopped(Windows::Foundation::TypedEventHandler<Windows::System::AppDiagnosticInfoWatcher, Windows::Foundation::IInspectable> const& handler) const;
        using Stopped_revoker = impl::event_revoker<Windows::System::IAppDiagnosticInfoWatcher, &impl::abi_t<Windows::System::IAppDiagnosticInfoWatcher>::remove_Stopped>;
        Stopped_revoker Stopped(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::AppDiagnosticInfoWatcher, Windows::Foundation::IInspectable> const& handler) const;
        auto Stopped(winrt::event_token const& token) const noexcept;
        [[nodiscard]] auto Status() const;
        auto Start() const;
        auto Stop() const;
    };
    template <> struct consume<Windows::System::IAppDiagnosticInfoWatcher>
    {
        template <typename D> using type = consume_Windows_System_IAppDiagnosticInfoWatcher<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppDiagnosticInfoWatcherEventArgs
    {
        [[nodiscard]] auto AppDiagnosticInfo() const;
    };
    template <> struct consume<Windows::System::IAppDiagnosticInfoWatcherEventArgs>
    {
        template <typename D> using type = consume_Windows_System_IAppDiagnosticInfoWatcherEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppExecutionStateChangeResult
    {
        [[nodiscard]] auto ExtendedError() const;
    };
    template <> struct consume<Windows::System::IAppExecutionStateChangeResult>
    {
        template <typename D> using type = consume_Windows_System_IAppExecutionStateChangeResult<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppMemoryReport
    {
        [[nodiscard]] auto PrivateCommitUsage() const;
        [[nodiscard]] auto PeakPrivateCommitUsage() const;
        [[nodiscard]] auto TotalCommitUsage() const;
        [[nodiscard]] auto TotalCommitLimit() const;
    };
    template <> struct consume<Windows::System::IAppMemoryReport>
    {
        template <typename D> using type = consume_Windows_System_IAppMemoryReport<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppMemoryReport2
    {
        [[nodiscard]] auto ExpectedTotalCommitLimit() const;
    };
    template <> struct consume<Windows::System::IAppMemoryReport2>
    {
        template <typename D> using type = consume_Windows_System_IAppMemoryReport2<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppMemoryUsageLimitChangingEventArgs
    {
        [[nodiscard]] auto OldLimit() const;
        [[nodiscard]] auto NewLimit() const;
    };
    template <> struct consume<Windows::System::IAppMemoryUsageLimitChangingEventArgs>
    {
        template <typename D> using type = consume_Windows_System_IAppMemoryUsageLimitChangingEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppResourceGroupBackgroundTaskReport
    {
        [[nodiscard]] auto TaskId() const;
        [[nodiscard]] auto Name() const;
        [[nodiscard]] auto Trigger() const;
        [[nodiscard]] auto EntryPoint() const;
    };
    template <> struct consume<Windows::System::IAppResourceGroupBackgroundTaskReport>
    {
        template <typename D> using type = consume_Windows_System_IAppResourceGroupBackgroundTaskReport<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppResourceGroupInfo
    {
        [[nodiscard]] auto InstanceId() const;
        [[nodiscard]] auto IsShared() const;
        auto GetBackgroundTaskReports() const;
        auto GetMemoryReport() const;
        auto GetProcessDiagnosticInfos() const;
        auto GetStateReport() const;
    };
    template <> struct consume<Windows::System::IAppResourceGroupInfo>
    {
        template <typename D> using type = consume_Windows_System_IAppResourceGroupInfo<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppResourceGroupInfo2
    {
        auto StartSuspendAsync() const;
        auto StartResumeAsync() const;
        auto StartTerminateAsync() const;
    };
    template <> struct consume<Windows::System::IAppResourceGroupInfo2>
    {
        template <typename D> using type = consume_Windows_System_IAppResourceGroupInfo2<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppResourceGroupInfoWatcher
    {
        auto Added(Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::System::AppResourceGroupInfoWatcherEventArgs> const& handler) const;
        using Added_revoker = impl::event_revoker<Windows::System::IAppResourceGroupInfoWatcher, &impl::abi_t<Windows::System::IAppResourceGroupInfoWatcher>::remove_Added>;
        Added_revoker Added(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::System::AppResourceGroupInfoWatcherEventArgs> const& handler) const;
        auto Added(winrt::event_token const& token) const noexcept;
        auto Removed(Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::System::AppResourceGroupInfoWatcherEventArgs> const& handler) const;
        using Removed_revoker = impl::event_revoker<Windows::System::IAppResourceGroupInfoWatcher, &impl::abi_t<Windows::System::IAppResourceGroupInfoWatcher>::remove_Removed>;
        Removed_revoker Removed(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::System::AppResourceGroupInfoWatcherEventArgs> const& handler) const;
        auto Removed(winrt::event_token const& token) const noexcept;
        auto EnumerationCompleted(Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::Foundation::IInspectable> const& handler) const;
        using EnumerationCompleted_revoker = impl::event_revoker<Windows::System::IAppResourceGroupInfoWatcher, &impl::abi_t<Windows::System::IAppResourceGroupInfoWatcher>::remove_EnumerationCompleted>;
        EnumerationCompleted_revoker EnumerationCompleted(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::Foundation::IInspectable> const& handler) const;
        auto EnumerationCompleted(winrt::event_token const& token) const noexcept;
        auto Stopped(Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::Foundation::IInspectable> const& handler) const;
        using Stopped_revoker = impl::event_revoker<Windows::System::IAppResourceGroupInfoWatcher, &impl::abi_t<Windows::System::IAppResourceGroupInfoWatcher>::remove_Stopped>;
        Stopped_revoker Stopped(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::Foundation::IInspectable> const& handler) const;
        auto Stopped(winrt::event_token const& token) const noexcept;
        auto ExecutionStateChanged(Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::System::AppResourceGroupInfoWatcherExecutionStateChangedEventArgs> const& handler) const;
        using ExecutionStateChanged_revoker = impl::event_revoker<Windows::System::IAppResourceGroupInfoWatcher, &impl::abi_t<Windows::System::IAppResourceGroupInfoWatcher>::remove_ExecutionStateChanged>;
        ExecutionStateChanged_revoker ExecutionStateChanged(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::AppResourceGroupInfoWatcher, Windows::System::AppResourceGroupInfoWatcherExecutionStateChangedEventArgs> const& handler) const;
        auto ExecutionStateChanged(winrt::event_token const& token) const noexcept;
        [[nodiscard]] auto Status() const;
        auto Start() const;
        auto Stop() const;
    };
    template <> struct consume<Windows::System::IAppResourceGroupInfoWatcher>
    {
        template <typename D> using type = consume_Windows_System_IAppResourceGroupInfoWatcher<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppResourceGroupInfoWatcherEventArgs
    {
        [[nodiscard]] auto AppDiagnosticInfos() const;
        [[nodiscard]] auto AppResourceGroupInfo() const;
    };
    template <> struct consume<Windows::System::IAppResourceGroupInfoWatcherEventArgs>
    {
        template <typename D> using type = consume_Windows_System_IAppResourceGroupInfoWatcherEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs
    {
        [[nodiscard]] auto AppDiagnosticInfos() const;
        [[nodiscard]] auto AppResourceGroupInfo() const;
    };
    template <> struct consume<Windows::System::IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppResourceGroupMemoryReport
    {
        [[nodiscard]] auto CommitUsageLimit() const;
        [[nodiscard]] auto CommitUsageLevel() const;
        [[nodiscard]] auto PrivateCommitUsage() const;
        [[nodiscard]] auto TotalCommitUsage() const;
    };
    template <> struct consume<Windows::System::IAppResourceGroupMemoryReport>
    {
        template <typename D> using type = consume_Windows_System_IAppResourceGroupMemoryReport<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppResourceGroupStateReport
    {
        [[nodiscard]] auto ExecutionState() const;
        [[nodiscard]] auto EnergyQuotaState() const;
    };
    template <> struct consume<Windows::System::IAppResourceGroupStateReport>
    {
        template <typename D> using type = consume_Windows_System_IAppResourceGroupStateReport<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppUriHandlerHost
    {
        [[nodiscard]] auto Name() const;
        auto Name(param::hstring const& value) const;
    };
    template <> struct consume<Windows::System::IAppUriHandlerHost>
    {
        template <typename D> using type = consume_Windows_System_IAppUriHandlerHost<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppUriHandlerHostFactory
    {
        auto CreateInstance(param::hstring const& name) const;
    };
    template <> struct consume<Windows::System::IAppUriHandlerHostFactory>
    {
        template <typename D> using type = consume_Windows_System_IAppUriHandlerHostFactory<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppUriHandlerRegistration
    {
        [[nodiscard]] auto Name() const;
        [[nodiscard]] auto User() const;
        auto GetAppAddedHostsAsync() const;
        auto SetAppAddedHostsAsync(param::async_iterable<Windows::System::AppUriHandlerHost> const& hosts) const;
    };
    template <> struct consume<Windows::System::IAppUriHandlerRegistration>
    {
        template <typename D> using type = consume_Windows_System_IAppUriHandlerRegistration<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppUriHandlerRegistrationManager
    {
        [[nodiscard]] auto User() const;
        auto TryGetRegistration(param::hstring const& name) const;
    };
    template <> struct consume<Windows::System::IAppUriHandlerRegistrationManager>
    {
        template <typename D> using type = consume_Windows_System_IAppUriHandlerRegistrationManager<D>;
    };
    template <typename D>
    struct consume_Windows_System_IAppUriHandlerRegistrationManagerStatics
    {
        auto GetDefault() const;
        auto GetForUser(Windows::System::User const& user) const;
    };
    template <> struct consume<Windows::System::IAppUriHandlerRegistrationManagerStatics>
    {
        template <typename D> using type = consume_Windows_System_IAppUriHandlerRegistrationManagerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IDateTimeSettingsStatics
    {
        auto SetSystemDateTime(Windows::Foundation::DateTime const& utcDateTime) const;
    };
    template <> struct consume<Windows::System::IDateTimeSettingsStatics>
    {
        template <typename D> using type = consume_Windows_System_IDateTimeSettingsStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IDispatcherQueue
    {
        auto CreateTimer() const;
        auto TryEnqueue(Windows::System::DispatcherQueueHandler const& callback) const;
        auto TryEnqueue(Windows::System::DispatcherQueuePriority const& priority, Windows::System::DispatcherQueueHandler const& callback) const;
        auto ShutdownStarting(Windows::Foundation::TypedEventHandler<Windows::System::DispatcherQueue, Windows::System::DispatcherQueueShutdownStartingEventArgs> const& handler) const;
        using ShutdownStarting_revoker = impl::event_revoker<Windows::System::IDispatcherQueue, &impl::abi_t<Windows::System::IDispatcherQueue>::remove_ShutdownStarting>;
        ShutdownStarting_revoker ShutdownStarting(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::DispatcherQueue, Windows::System::DispatcherQueueShutdownStartingEventArgs> const& handler) const;
        auto ShutdownStarting(winrt::event_token const& token) const noexcept;
        auto ShutdownCompleted(Windows::Foundation::TypedEventHandler<Windows::System::DispatcherQueue, Windows::Foundation::IInspectable> const& handler) const;
        using ShutdownCompleted_revoker = impl::event_revoker<Windows::System::IDispatcherQueue, &impl::abi_t<Windows::System::IDispatcherQueue>::remove_ShutdownCompleted>;
        ShutdownCompleted_revoker ShutdownCompleted(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::DispatcherQueue, Windows::Foundation::IInspectable> const& handler) const;
        auto ShutdownCompleted(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::IDispatcherQueue>
    {
        template <typename D> using type = consume_Windows_System_IDispatcherQueue<D>;
    };
    template <typename D>
    struct consume_Windows_System_IDispatcherQueue2
    {
        [[nodiscard]] auto HasThreadAccess() const;
    };
    template <> struct consume<Windows::System::IDispatcherQueue2>
    {
        template <typename D> using type = consume_Windows_System_IDispatcherQueue2<D>;
    };
    template <typename D>
    struct consume_Windows_System_IDispatcherQueueController
    {
        [[nodiscard]] auto DispatcherQueue() const;
        auto ShutdownQueueAsync() const;
    };
    template <> struct consume<Windows::System::IDispatcherQueueController>
    {
        template <typename D> using type = consume_Windows_System_IDispatcherQueueController<D>;
    };
    template <typename D>
    struct consume_Windows_System_IDispatcherQueueControllerStatics
    {
        auto CreateOnDedicatedThread() const;
    };
    template <> struct consume<Windows::System::IDispatcherQueueControllerStatics>
    {
        template <typename D> using type = consume_Windows_System_IDispatcherQueueControllerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IDispatcherQueueShutdownStartingEventArgs
    {
        auto GetDeferral() const;
    };
    template <> struct consume<Windows::System::IDispatcherQueueShutdownStartingEventArgs>
    {
        template <typename D> using type = consume_Windows_System_IDispatcherQueueShutdownStartingEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_IDispatcherQueueStatics
    {
        auto GetForCurrentThread() const;
    };
    template <> struct consume<Windows::System::IDispatcherQueueStatics>
    {
        template <typename D> using type = consume_Windows_System_IDispatcherQueueStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IDispatcherQueueTimer
    {
        [[nodiscard]] auto Interval() const;
        auto Interval(Windows::Foundation::TimeSpan const& value) const;
        [[nodiscard]] auto IsRunning() const;
        [[nodiscard]] auto IsRepeating() const;
        auto IsRepeating(bool value) const;
        auto Start() const;
        auto Stop() const;
        auto Tick(Windows::Foundation::TypedEventHandler<Windows::System::DispatcherQueueTimer, Windows::Foundation::IInspectable> const& handler) const;
        using Tick_revoker = impl::event_revoker<Windows::System::IDispatcherQueueTimer, &impl::abi_t<Windows::System::IDispatcherQueueTimer>::remove_Tick>;
        Tick_revoker Tick(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::DispatcherQueueTimer, Windows::Foundation::IInspectable> const& handler) const;
        auto Tick(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::IDispatcherQueueTimer>
    {
        template <typename D> using type = consume_Windows_System_IDispatcherQueueTimer<D>;
    };
    template <typename D>
    struct consume_Windows_System_IFolderLauncherOptions
    {
        [[nodiscard]] auto ItemsToSelect() const;
    };
    template <> struct consume<Windows::System::IFolderLauncherOptions>
    {
        template <typename D> using type = consume_Windows_System_IFolderLauncherOptions<D>;
    };
    template <typename D>
    struct consume_Windows_System_IKnownUserPropertiesStatics
    {
        [[nodiscard]] auto DisplayName() const;
        [[nodiscard]] auto FirstName() const;
        [[nodiscard]] auto LastName() const;
        [[nodiscard]] auto ProviderName() const;
        [[nodiscard]] auto AccountName() const;
        [[nodiscard]] auto GuestHost() const;
        [[nodiscard]] auto PrincipalName() const;
        [[nodiscard]] auto DomainName() const;
        [[nodiscard]] auto SessionInitiationProtocolUri() const;
    };
    template <> struct consume<Windows::System::IKnownUserPropertiesStatics>
    {
        template <typename D> using type = consume_Windows_System_IKnownUserPropertiesStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILaunchUriResult
    {
        [[nodiscard]] auto Status() const;
        [[nodiscard]] auto Result() const;
    };
    template <> struct consume<Windows::System::ILaunchUriResult>
    {
        template <typename D> using type = consume_Windows_System_ILaunchUriResult<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherOptions
    {
        [[nodiscard]] auto TreatAsUntrusted() const;
        auto TreatAsUntrusted(bool value) const;
        [[nodiscard]] auto DisplayApplicationPicker() const;
        auto DisplayApplicationPicker(bool value) const;
        [[nodiscard]] auto UI() const;
        [[nodiscard]] auto PreferredApplicationPackageFamilyName() const;
        auto PreferredApplicationPackageFamilyName(param::hstring const& value) const;
        [[nodiscard]] auto PreferredApplicationDisplayName() const;
        auto PreferredApplicationDisplayName(param::hstring const& value) const;
        [[nodiscard]] auto FallbackUri() const;
        auto FallbackUri(Windows::Foundation::Uri const& value) const;
        [[nodiscard]] auto ContentType() const;
        auto ContentType(param::hstring const& value) const;
    };
    template <> struct consume<Windows::System::ILauncherOptions>
    {
        template <typename D> using type = consume_Windows_System_ILauncherOptions<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherOptions2
    {
        [[nodiscard]] auto TargetApplicationPackageFamilyName() const;
        auto TargetApplicationPackageFamilyName(param::hstring const& value) const;
        [[nodiscard]] auto NeighboringFilesQuery() const;
        auto NeighboringFilesQuery(Windows::Storage::Search::StorageFileQueryResult const& value) const;
    };
    template <> struct consume<Windows::System::ILauncherOptions2>
    {
        template <typename D> using type = consume_Windows_System_ILauncherOptions2<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherOptions3
    {
        [[nodiscard]] auto IgnoreAppUriHandlers() const;
        auto IgnoreAppUriHandlers(bool value) const;
    };
    template <> struct consume<Windows::System::ILauncherOptions3>
    {
        template <typename D> using type = consume_Windows_System_ILauncherOptions3<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherOptions4
    {
        [[nodiscard]] auto LimitPickerToCurrentAppAndAppUriHandlers() const;
        auto LimitPickerToCurrentAppAndAppUriHandlers(bool value) const;
    };
    template <> struct consume<Windows::System::ILauncherOptions4>
    {
        template <typename D> using type = consume_Windows_System_ILauncherOptions4<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherStatics
    {
        auto LaunchFileAsync(Windows::Storage::IStorageFile const& file) const;
        auto LaunchFileAsync(Windows::Storage::IStorageFile const& file, Windows::System::LauncherOptions const& options) const;
        auto LaunchUriAsync(Windows::Foundation::Uri const& uri) const;
        auto LaunchUriAsync(Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options) const;
    };
    template <> struct consume<Windows::System::ILauncherStatics>
    {
        template <typename D> using type = consume_Windows_System_ILauncherStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherStatics2
    {
        auto LaunchUriForResultsAsync(Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options) const;
        auto LaunchUriForResultsAsync(Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData) const;
        auto LaunchUriAsync(Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData) const;
        auto QueryUriSupportAsync(Windows::Foundation::Uri const& uri, Windows::System::LaunchQuerySupportType const& launchQuerySupportType) const;
        auto QueryUriSupportAsync(Windows::Foundation::Uri const& uri, Windows::System::LaunchQuerySupportType const& launchQuerySupportType, param::hstring const& packageFamilyName) const;
        auto QueryFileSupportAsync(Windows::Storage::StorageFile const& file) const;
        auto QueryFileSupportAsync(Windows::Storage::StorageFile const& file, param::hstring const& packageFamilyName) const;
        auto FindUriSchemeHandlersAsync(param::hstring const& scheme) const;
        auto FindUriSchemeHandlersAsync(param::hstring const& scheme, Windows::System::LaunchQuerySupportType const& launchQuerySupportType) const;
        auto FindFileHandlersAsync(param::hstring const& extension) const;
    };
    template <> struct consume<Windows::System::ILauncherStatics2>
    {
        template <typename D> using type = consume_Windows_System_ILauncherStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherStatics3
    {
        auto LaunchFolderAsync(Windows::Storage::IStorageFolder const& folder) const;
        auto LaunchFolderAsync(Windows::Storage::IStorageFolder const& folder, Windows::System::FolderLauncherOptions const& options) const;
    };
    template <> struct consume<Windows::System::ILauncherStatics3>
    {
        template <typename D> using type = consume_Windows_System_ILauncherStatics3<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherStatics4
    {
        auto QueryAppUriSupportAsync(Windows::Foundation::Uri const& uri) const;
        auto QueryAppUriSupportAsync(Windows::Foundation::Uri const& uri, param::hstring const& packageFamilyName) const;
        auto FindAppUriHandlersAsync(Windows::Foundation::Uri const& uri) const;
        auto LaunchUriForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri) const;
        auto LaunchUriForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options) const;
        auto LaunchUriForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData) const;
        auto LaunchUriForResultsForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options) const;
        auto LaunchUriForResultsForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData) const;
    };
    template <> struct consume<Windows::System::ILauncherStatics4>
    {
        template <typename D> using type = consume_Windows_System_ILauncherStatics4<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherStatics5
    {
        auto LaunchFolderPathAsync(param::hstring const& path) const;
        auto LaunchFolderPathAsync(param::hstring const& path, Windows::System::FolderLauncherOptions const& options) const;
        auto LaunchFolderPathForUserAsync(Windows::System::User const& user, param::hstring const& path) const;
        auto LaunchFolderPathForUserAsync(Windows::System::User const& user, param::hstring const& path, Windows::System::FolderLauncherOptions const& options) const;
    };
    template <> struct consume<Windows::System::ILauncherStatics5>
    {
        template <typename D> using type = consume_Windows_System_ILauncherStatics5<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherUIOptions
    {
        [[nodiscard]] auto InvocationPoint() const;
        auto InvocationPoint(Windows::Foundation::IReference<Windows::Foundation::Point> const& value) const;
        [[nodiscard]] auto SelectionRect() const;
        auto SelectionRect(Windows::Foundation::IReference<Windows::Foundation::Rect> const& value) const;
        [[nodiscard]] auto PreferredPlacement() const;
        auto PreferredPlacement(Windows::UI::Popups::Placement const& value) const;
    };
    template <> struct consume<Windows::System::ILauncherUIOptions>
    {
        template <typename D> using type = consume_Windows_System_ILauncherUIOptions<D>;
    };
    template <typename D>
    struct consume_Windows_System_ILauncherViewOptions
    {
        [[nodiscard]] auto DesiredRemainingView() const;
        auto DesiredRemainingView(Windows::UI::ViewManagement::ViewSizePreference const& value) const;
    };
    template <> struct consume<Windows::System::ILauncherViewOptions>
    {
        template <typename D> using type = consume_Windows_System_ILauncherViewOptions<D>;
    };
    template <typename D>
    struct consume_Windows_System_IMemoryManagerStatics
    {
        [[nodiscard]] auto AppMemoryUsage() const;
        [[nodiscard]] auto AppMemoryUsageLimit() const;
        [[nodiscard]] auto AppMemoryUsageLevel() const;
        auto AppMemoryUsageIncreased(Windows::Foundation::EventHandler<Windows::Foundation::IInspectable> const& handler) const;
        using AppMemoryUsageIncreased_revoker = impl::event_revoker<Windows::System::IMemoryManagerStatics, &impl::abi_t<Windows::System::IMemoryManagerStatics>::remove_AppMemoryUsageIncreased>;
        AppMemoryUsageIncreased_revoker AppMemoryUsageIncreased(auto_revoke_t, Windows::Foundation::EventHandler<Windows::Foundation::IInspectable> const& handler) const;
        auto AppMemoryUsageIncreased(winrt::event_token const& token) const noexcept;
        auto AppMemoryUsageDecreased(Windows::Foundation::EventHandler<Windows::Foundation::IInspectable> const& handler) const;
        using AppMemoryUsageDecreased_revoker = impl::event_revoker<Windows::System::IMemoryManagerStatics, &impl::abi_t<Windows::System::IMemoryManagerStatics>::remove_AppMemoryUsageDecreased>;
        AppMemoryUsageDecreased_revoker AppMemoryUsageDecreased(auto_revoke_t, Windows::Foundation::EventHandler<Windows::Foundation::IInspectable> const& handler) const;
        auto AppMemoryUsageDecreased(winrt::event_token const& token) const noexcept;
        auto AppMemoryUsageLimitChanging(Windows::Foundation::EventHandler<Windows::System::AppMemoryUsageLimitChangingEventArgs> const& handler) const;
        using AppMemoryUsageLimitChanging_revoker = impl::event_revoker<Windows::System::IMemoryManagerStatics, &impl::abi_t<Windows::System::IMemoryManagerStatics>::remove_AppMemoryUsageLimitChanging>;
        AppMemoryUsageLimitChanging_revoker AppMemoryUsageLimitChanging(auto_revoke_t, Windows::Foundation::EventHandler<Windows::System::AppMemoryUsageLimitChangingEventArgs> const& handler) const;
        auto AppMemoryUsageLimitChanging(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::IMemoryManagerStatics>
    {
        template <typename D> using type = consume_Windows_System_IMemoryManagerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IMemoryManagerStatics2
    {
        auto GetAppMemoryReport() const;
        auto GetProcessMemoryReport() const;
    };
    template <> struct consume<Windows::System::IMemoryManagerStatics2>
    {
        template <typename D> using type = consume_Windows_System_IMemoryManagerStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_System_IMemoryManagerStatics3
    {
        auto TrySetAppMemoryUsageLimit(uint64_t value) const;
    };
    template <> struct consume<Windows::System::IMemoryManagerStatics3>
    {
        template <typename D> using type = consume_Windows_System_IMemoryManagerStatics3<D>;
    };
    template <typename D>
    struct consume_Windows_System_IMemoryManagerStatics4
    {
        [[nodiscard]] auto ExpectedAppMemoryUsageLimit() const;
    };
    template <> struct consume<Windows::System::IMemoryManagerStatics4>
    {
        template <typename D> using type = consume_Windows_System_IMemoryManagerStatics4<D>;
    };
    template <typename D>
    struct consume_Windows_System_IProcessLauncherOptions
    {
        [[nodiscard]] auto StandardInput() const;
        auto StandardInput(Windows::Storage::Streams::IInputStream const& value) const;
        [[nodiscard]] auto StandardOutput() const;
        auto StandardOutput(Windows::Storage::Streams::IOutputStream const& value) const;
        [[nodiscard]] auto StandardError() const;
        auto StandardError(Windows::Storage::Streams::IOutputStream const& value) const;
        [[nodiscard]] auto WorkingDirectory() const;
        auto WorkingDirectory(param::hstring const& value) const;
    };
    template <> struct consume<Windows::System::IProcessLauncherOptions>
    {
        template <typename D> using type = consume_Windows_System_IProcessLauncherOptions<D>;
    };
    template <typename D>
    struct consume_Windows_System_IProcessLauncherResult
    {
        [[nodiscard]] auto ExitCode() const;
    };
    template <> struct consume<Windows::System::IProcessLauncherResult>
    {
        template <typename D> using type = consume_Windows_System_IProcessLauncherResult<D>;
    };
    template <typename D>
    struct consume_Windows_System_IProcessLauncherStatics
    {
        auto RunToCompletionAsync(param::hstring const& fileName, param::hstring const& args) const;
        auto RunToCompletionAsync(param::hstring const& fileName, param::hstring const& args, Windows::System::ProcessLauncherOptions const& options) const;
    };
    template <> struct consume<Windows::System::IProcessLauncherStatics>
    {
        template <typename D> using type = consume_Windows_System_IProcessLauncherStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IProcessMemoryReport
    {
        [[nodiscard]] auto PrivateWorkingSetUsage() const;
        [[nodiscard]] auto TotalWorkingSetUsage() const;
    };
    template <> struct consume<Windows::System::IProcessMemoryReport>
    {
        template <typename D> using type = consume_Windows_System_IProcessMemoryReport<D>;
    };
    template <typename D>
    struct consume_Windows_System_IProtocolForResultsOperation
    {
        auto ReportCompleted(Windows::Foundation::Collections::ValueSet const& data) const;
    };
    template <> struct consume<Windows::System::IProtocolForResultsOperation>
    {
        template <typename D> using type = consume_Windows_System_IProtocolForResultsOperation<D>;
    };
    template <typename D>
    struct consume_Windows_System_IRemoteLauncherOptions
    {
        [[nodiscard]] auto FallbackUri() const;
        auto FallbackUri(Windows::Foundation::Uri const& value) const;
        [[nodiscard]] auto PreferredAppIds() const;
    };
    template <> struct consume<Windows::System::IRemoteLauncherOptions>
    {
        template <typename D> using type = consume_Windows_System_IRemoteLauncherOptions<D>;
    };
    template <typename D>
    struct consume_Windows_System_IRemoteLauncherStatics
    {
        auto LaunchUriAsync(Windows::System::RemoteSystems::RemoteSystemConnectionRequest const& remoteSystemConnectionRequest, Windows::Foundation::Uri const& uri) const;
        auto LaunchUriAsync(Windows::System::RemoteSystems::RemoteSystemConnectionRequest const& remoteSystemConnectionRequest, Windows::Foundation::Uri const& uri, Windows::System::RemoteLauncherOptions const& options) const;
        auto LaunchUriAsync(Windows::System::RemoteSystems::RemoteSystemConnectionRequest const& remoteSystemConnectionRequest, Windows::Foundation::Uri const& uri, Windows::System::RemoteLauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData) const;
    };
    template <> struct consume<Windows::System::IRemoteLauncherStatics>
    {
        template <typename D> using type = consume_Windows_System_IRemoteLauncherStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IShutdownManagerStatics
    {
        auto BeginShutdown(Windows::System::ShutdownKind const& shutdownKind, Windows::Foundation::TimeSpan const& timeout) const;
        auto CancelShutdown() const;
    };
    template <> struct consume<Windows::System::IShutdownManagerStatics>
    {
        template <typename D> using type = consume_Windows_System_IShutdownManagerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IShutdownManagerStatics2
    {
        auto IsPowerStateSupported(Windows::System::PowerState const& powerState) const;
        auto EnterPowerState(Windows::System::PowerState const& powerState) const;
        auto EnterPowerState(Windows::System::PowerState const& powerState, Windows::Foundation::TimeSpan const& wakeUpAfter) const;
    };
    template <> struct consume<Windows::System::IShutdownManagerStatics2>
    {
        template <typename D> using type = consume_Windows_System_IShutdownManagerStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_System_ITimeZoneSettingsStatics
    {
        [[nodiscard]] auto CurrentTimeZoneDisplayName() const;
        [[nodiscard]] auto SupportedTimeZoneDisplayNames() const;
        [[nodiscard]] auto CanChangeTimeZone() const;
        auto ChangeTimeZoneByDisplayName(param::hstring const& timeZoneDisplayName) const;
    };
    template <> struct consume<Windows::System::ITimeZoneSettingsStatics>
    {
        template <typename D> using type = consume_Windows_System_ITimeZoneSettingsStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_ITimeZoneSettingsStatics2
    {
        auto AutoUpdateTimeZoneAsync(Windows::Foundation::TimeSpan const& timeout) const;
    };
    template <> struct consume<Windows::System::ITimeZoneSettingsStatics2>
    {
        template <typename D> using type = consume_Windows_System_ITimeZoneSettingsStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUser
    {
        [[nodiscard]] auto NonRoamableId() const;
        [[nodiscard]] auto AuthenticationStatus() const;
        [[nodiscard]] auto Type() const;
        auto GetPropertyAsync(param::hstring const& value) const;
        auto GetPropertiesAsync(param::async_vector_view<hstring> const& values) const;
        auto GetPictureAsync(Windows::System::UserPictureSize const& desiredSize) const;
    };
    template <> struct consume<Windows::System::IUser>
    {
        template <typename D> using type = consume_Windows_System_IUser<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserAuthenticationStatusChangeDeferral
    {
        auto Complete() const;
    };
    template <> struct consume<Windows::System::IUserAuthenticationStatusChangeDeferral>
    {
        template <typename D> using type = consume_Windows_System_IUserAuthenticationStatusChangeDeferral<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserAuthenticationStatusChangingEventArgs
    {
        auto GetDeferral() const;
        [[nodiscard]] auto User() const;
        [[nodiscard]] auto NewStatus() const;
        [[nodiscard]] auto CurrentStatus() const;
    };
    template <> struct consume<Windows::System::IUserAuthenticationStatusChangingEventArgs>
    {
        template <typename D> using type = consume_Windows_System_IUserAuthenticationStatusChangingEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserChangedEventArgs
    {
        [[nodiscard]] auto User() const;
    };
    template <> struct consume<Windows::System::IUserChangedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_IUserChangedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserChangedEventArgs2
    {
        [[nodiscard]] auto ChangedPropertyKinds() const;
    };
    template <> struct consume<Windows::System::IUserChangedEventArgs2>
    {
        template <typename D> using type = consume_Windows_System_IUserChangedEventArgs2<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserDeviceAssociationChangedEventArgs
    {
        [[nodiscard]] auto DeviceId() const;
        [[nodiscard]] auto NewUser() const;
        [[nodiscard]] auto OldUser() const;
    };
    template <> struct consume<Windows::System::IUserDeviceAssociationChangedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_IUserDeviceAssociationChangedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserDeviceAssociationStatics
    {
        auto FindUserFromDeviceId(param::hstring const& deviceId) const;
        auto UserDeviceAssociationChanged(Windows::Foundation::EventHandler<Windows::System::UserDeviceAssociationChangedEventArgs> const& handler) const;
        using UserDeviceAssociationChanged_revoker = impl::event_revoker<Windows::System::IUserDeviceAssociationStatics, &impl::abi_t<Windows::System::IUserDeviceAssociationStatics>::remove_UserDeviceAssociationChanged>;
        UserDeviceAssociationChanged_revoker UserDeviceAssociationChanged(auto_revoke_t, Windows::Foundation::EventHandler<Windows::System::UserDeviceAssociationChangedEventArgs> const& handler) const;
        auto UserDeviceAssociationChanged(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::IUserDeviceAssociationStatics>
    {
        template <typename D> using type = consume_Windows_System_IUserDeviceAssociationStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserPicker
    {
        [[nodiscard]] auto AllowGuestAccounts() const;
        auto AllowGuestAccounts(bool value) const;
        [[nodiscard]] auto SuggestedSelectedUser() const;
        auto SuggestedSelectedUser(Windows::System::User const& value) const;
        auto PickSingleUserAsync() const;
    };
    template <> struct consume<Windows::System::IUserPicker>
    {
        template <typename D> using type = consume_Windows_System_IUserPicker<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserPickerStatics
    {
        auto IsSupported() const;
    };
    template <> struct consume<Windows::System::IUserPickerStatics>
    {
        template <typename D> using type = consume_Windows_System_IUserPickerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserStatics
    {
        auto CreateWatcher() const;
        auto FindAllAsync() const;
        auto FindAllAsync(Windows::System::UserType const& type) const;
        auto FindAllAsync(Windows::System::UserType const& type, Windows::System::UserAuthenticationStatus const& status) const;
        auto GetFromId(param::hstring const& nonRoamableId) const;
    };
    template <> struct consume<Windows::System::IUserStatics>
    {
        template <typename D> using type = consume_Windows_System_IUserStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_IUserWatcher
    {
        [[nodiscard]] auto Status() const;
        auto Start() const;
        auto Stop() const;
        auto Added(Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserChangedEventArgs> const& handler) const;
        using Added_revoker = impl::event_revoker<Windows::System::IUserWatcher, &impl::abi_t<Windows::System::IUserWatcher>::remove_Added>;
        Added_revoker Added(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserChangedEventArgs> const& handler) const;
        auto Added(winrt::event_token const& token) const noexcept;
        auto Removed(Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserChangedEventArgs> const& handler) const;
        using Removed_revoker = impl::event_revoker<Windows::System::IUserWatcher, &impl::abi_t<Windows::System::IUserWatcher>::remove_Removed>;
        Removed_revoker Removed(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserChangedEventArgs> const& handler) const;
        auto Removed(winrt::event_token const& token) const noexcept;
        auto Updated(Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserChangedEventArgs> const& handler) const;
        using Updated_revoker = impl::event_revoker<Windows::System::IUserWatcher, &impl::abi_t<Windows::System::IUserWatcher>::remove_Updated>;
        Updated_revoker Updated(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserChangedEventArgs> const& handler) const;
        auto Updated(winrt::event_token const& token) const noexcept;
        auto AuthenticationStatusChanged(Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserChangedEventArgs> const& handler) const;
        using AuthenticationStatusChanged_revoker = impl::event_revoker<Windows::System::IUserWatcher, &impl::abi_t<Windows::System::IUserWatcher>::remove_AuthenticationStatusChanged>;
        AuthenticationStatusChanged_revoker AuthenticationStatusChanged(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserChangedEventArgs> const& handler) const;
        auto AuthenticationStatusChanged(winrt::event_token const& token) const noexcept;
        auto AuthenticationStatusChanging(Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserAuthenticationStatusChangingEventArgs> const& handler) const;
        using AuthenticationStatusChanging_revoker = impl::event_revoker<Windows::System::IUserWatcher, &impl::abi_t<Windows::System::IUserWatcher>::remove_AuthenticationStatusChanging>;
        AuthenticationStatusChanging_revoker AuthenticationStatusChanging(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::System::UserAuthenticationStatusChangingEventArgs> const& handler) const;
        auto AuthenticationStatusChanging(winrt::event_token const& token) const noexcept;
        auto EnumerationCompleted(Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::Foundation::IInspectable> const& handler) const;
        using EnumerationCompleted_revoker = impl::event_revoker<Windows::System::IUserWatcher, &impl::abi_t<Windows::System::IUserWatcher>::remove_EnumerationCompleted>;
        EnumerationCompleted_revoker EnumerationCompleted(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::Foundation::IInspectable> const& handler) const;
        auto EnumerationCompleted(winrt::event_token const& token) const noexcept;
        auto Stopped(Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::Foundation::IInspectable> const& handler) const;
        using Stopped_revoker = impl::event_revoker<Windows::System::IUserWatcher, &impl::abi_t<Windows::System::IUserWatcher>::remove_Stopped>;
        Stopped_revoker Stopped(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::UserWatcher, Windows::Foundation::IInspectable> const& handler) const;
        auto Stopped(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::IUserWatcher>
    {
        template <typename D> using type = consume_Windows_System_IUserWatcher<D>;
    };
}
#endif
