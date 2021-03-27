// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_System_2_H
#define WINRT_Windows_System_2_H
#include "Windows.Foundation.1.h"
#include "Windows.Foundation.Collections.1.h"
#include "Windows.Storage.1.h"
#include "Windows.System.RemoteSystems.1.h"
#include "Windows.System.1.h"
namespace winrt::Windows::System
{
    struct DispatcherQueueHandler : Windows::Foundation::IUnknown
    {
        DispatcherQueueHandler(std::nullptr_t = nullptr) noexcept {}
        DispatcherQueueHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> DispatcherQueueHandler(L lambda);
        template <typename F> DispatcherQueueHandler(F* function);
        template <typename O, typename M> DispatcherQueueHandler(O* object, M method);
        template <typename O, typename M> DispatcherQueueHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> DispatcherQueueHandler(weak_ref<O>&& object, M method);
        auto operator()() const;
    };
    struct __declspec(empty_bases) AppActivationResult : Windows::System::IAppActivationResult
    {
        AppActivationResult(std::nullptr_t) noexcept {}
        AppActivationResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppActivationResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppDiagnosticInfo : Windows::System::IAppDiagnosticInfo,
        impl::require<AppDiagnosticInfo, Windows::System::IAppDiagnosticInfo2, Windows::System::IAppDiagnosticInfo3>
    {
        AppDiagnosticInfo(std::nullptr_t) noexcept {}
        AppDiagnosticInfo(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppDiagnosticInfo(ptr, take_ownership_from_abi) {}
        static auto RequestInfoAsync();
        static auto CreateWatcher();
        static auto RequestAccessAsync();
        static auto RequestInfoForPackageAsync(param::hstring const& packageFamilyName);
        static auto RequestInfoForAppAsync();
        static auto RequestInfoForAppAsync(param::hstring const& appUserModelId);
    };
    struct __declspec(empty_bases) AppDiagnosticInfoWatcher : Windows::System::IAppDiagnosticInfoWatcher
    {
        AppDiagnosticInfoWatcher(std::nullptr_t) noexcept {}
        AppDiagnosticInfoWatcher(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppDiagnosticInfoWatcher(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppDiagnosticInfoWatcherEventArgs : Windows::System::IAppDiagnosticInfoWatcherEventArgs
    {
        AppDiagnosticInfoWatcherEventArgs(std::nullptr_t) noexcept {}
        AppDiagnosticInfoWatcherEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppDiagnosticInfoWatcherEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppExecutionStateChangeResult : Windows::System::IAppExecutionStateChangeResult
    {
        AppExecutionStateChangeResult(std::nullptr_t) noexcept {}
        AppExecutionStateChangeResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppExecutionStateChangeResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppMemoryReport : Windows::System::IAppMemoryReport,
        impl::require<AppMemoryReport, Windows::System::IAppMemoryReport2>
    {
        AppMemoryReport(std::nullptr_t) noexcept {}
        AppMemoryReport(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppMemoryReport(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppMemoryUsageLimitChangingEventArgs : Windows::System::IAppMemoryUsageLimitChangingEventArgs
    {
        AppMemoryUsageLimitChangingEventArgs(std::nullptr_t) noexcept {}
        AppMemoryUsageLimitChangingEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppMemoryUsageLimitChangingEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppResourceGroupBackgroundTaskReport : Windows::System::IAppResourceGroupBackgroundTaskReport
    {
        AppResourceGroupBackgroundTaskReport(std::nullptr_t) noexcept {}
        AppResourceGroupBackgroundTaskReport(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppResourceGroupBackgroundTaskReport(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppResourceGroupInfo : Windows::System::IAppResourceGroupInfo,
        impl::require<AppResourceGroupInfo, Windows::System::IAppResourceGroupInfo2>
    {
        AppResourceGroupInfo(std::nullptr_t) noexcept {}
        AppResourceGroupInfo(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppResourceGroupInfo(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppResourceGroupInfoWatcher : Windows::System::IAppResourceGroupInfoWatcher
    {
        AppResourceGroupInfoWatcher(std::nullptr_t) noexcept {}
        AppResourceGroupInfoWatcher(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppResourceGroupInfoWatcher(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppResourceGroupInfoWatcherEventArgs : Windows::System::IAppResourceGroupInfoWatcherEventArgs
    {
        AppResourceGroupInfoWatcherEventArgs(std::nullptr_t) noexcept {}
        AppResourceGroupInfoWatcherEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppResourceGroupInfoWatcherEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppResourceGroupInfoWatcherExecutionStateChangedEventArgs : Windows::System::IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs
    {
        AppResourceGroupInfoWatcherExecutionStateChangedEventArgs(std::nullptr_t) noexcept {}
        AppResourceGroupInfoWatcherExecutionStateChangedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppResourceGroupInfoWatcherExecutionStateChangedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppResourceGroupMemoryReport : Windows::System::IAppResourceGroupMemoryReport
    {
        AppResourceGroupMemoryReport(std::nullptr_t) noexcept {}
        AppResourceGroupMemoryReport(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppResourceGroupMemoryReport(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppResourceGroupStateReport : Windows::System::IAppResourceGroupStateReport
    {
        AppResourceGroupStateReport(std::nullptr_t) noexcept {}
        AppResourceGroupStateReport(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppResourceGroupStateReport(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppUriHandlerHost : Windows::System::IAppUriHandlerHost
    {
        AppUriHandlerHost(std::nullptr_t) noexcept {}
        AppUriHandlerHost(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppUriHandlerHost(ptr, take_ownership_from_abi) {}
        AppUriHandlerHost();
        AppUriHandlerHost(param::hstring const& name);
    };
    struct __declspec(empty_bases) AppUriHandlerRegistration : Windows::System::IAppUriHandlerRegistration
    {
        AppUriHandlerRegistration(std::nullptr_t) noexcept {}
        AppUriHandlerRegistration(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppUriHandlerRegistration(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppUriHandlerRegistrationManager : Windows::System::IAppUriHandlerRegistrationManager
    {
        AppUriHandlerRegistrationManager(std::nullptr_t) noexcept {}
        AppUriHandlerRegistrationManager(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IAppUriHandlerRegistrationManager(ptr, take_ownership_from_abi) {}
        static auto GetDefault();
        static auto GetForUser(Windows::System::User const& user);
    };
    struct DateTimeSettings
    {
        DateTimeSettings() = delete;
        static auto SetSystemDateTime(Windows::Foundation::DateTime const& utcDateTime);
    };
    struct __declspec(empty_bases) DispatcherQueue : Windows::System::IDispatcherQueue,
        impl::require<DispatcherQueue, Windows::System::IDispatcherQueue2>
    {
        DispatcherQueue(std::nullptr_t) noexcept {}
        DispatcherQueue(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IDispatcherQueue(ptr, take_ownership_from_abi) {}
        static auto GetForCurrentThread();
    };
    struct __declspec(empty_bases) DispatcherQueueController : Windows::System::IDispatcherQueueController
    {
        DispatcherQueueController(std::nullptr_t) noexcept {}
        DispatcherQueueController(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IDispatcherQueueController(ptr, take_ownership_from_abi) {}
        static auto CreateOnDedicatedThread();
    };
    struct __declspec(empty_bases) DispatcherQueueShutdownStartingEventArgs : Windows::System::IDispatcherQueueShutdownStartingEventArgs
    {
        DispatcherQueueShutdownStartingEventArgs(std::nullptr_t) noexcept {}
        DispatcherQueueShutdownStartingEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IDispatcherQueueShutdownStartingEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) DispatcherQueueTimer : Windows::System::IDispatcherQueueTimer
    {
        DispatcherQueueTimer(std::nullptr_t) noexcept {}
        DispatcherQueueTimer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IDispatcherQueueTimer(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) FolderLauncherOptions : Windows::System::IFolderLauncherOptions,
        impl::require<FolderLauncherOptions, Windows::System::ILauncherViewOptions>
    {
        FolderLauncherOptions(std::nullptr_t) noexcept {}
        FolderLauncherOptions(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IFolderLauncherOptions(ptr, take_ownership_from_abi) {}
        FolderLauncherOptions();
    };
    struct KnownUserProperties
    {
        KnownUserProperties() = delete;
        [[nodiscard]] static auto DisplayName();
        [[nodiscard]] static auto FirstName();
        [[nodiscard]] static auto LastName();
        [[nodiscard]] static auto ProviderName();
        [[nodiscard]] static auto AccountName();
        [[nodiscard]] static auto GuestHost();
        [[nodiscard]] static auto PrincipalName();
        [[nodiscard]] static auto DomainName();
        [[nodiscard]] static auto SessionInitiationProtocolUri();
    };
    struct __declspec(empty_bases) LaunchUriResult : Windows::System::ILaunchUriResult
    {
        LaunchUriResult(std::nullptr_t) noexcept {}
        LaunchUriResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::ILaunchUriResult(ptr, take_ownership_from_abi) {}
    };
    struct Launcher
    {
        Launcher() = delete;
        static auto LaunchFileAsync(Windows::Storage::IStorageFile const& file);
        static auto LaunchFileAsync(Windows::Storage::IStorageFile const& file, Windows::System::LauncherOptions const& options);
        static auto LaunchUriAsync(Windows::Foundation::Uri const& uri);
        static auto LaunchUriAsync(Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options);
        static auto LaunchUriForResultsAsync(Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options);
        static auto LaunchUriForResultsAsync(Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData);
        static auto LaunchUriAsync(Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData);
        static auto QueryUriSupportAsync(Windows::Foundation::Uri const& uri, Windows::System::LaunchQuerySupportType const& launchQuerySupportType);
        static auto QueryUriSupportAsync(Windows::Foundation::Uri const& uri, Windows::System::LaunchQuerySupportType const& launchQuerySupportType, param::hstring const& packageFamilyName);
        static auto QueryFileSupportAsync(Windows::Storage::StorageFile const& file);
        static auto QueryFileSupportAsync(Windows::Storage::StorageFile const& file, param::hstring const& packageFamilyName);
        static auto FindUriSchemeHandlersAsync(param::hstring const& scheme);
        static auto FindUriSchemeHandlersAsync(param::hstring const& scheme, Windows::System::LaunchQuerySupportType const& launchQuerySupportType);
        static auto FindFileHandlersAsync(param::hstring const& extension);
        static auto LaunchFolderAsync(Windows::Storage::IStorageFolder const& folder);
        static auto LaunchFolderAsync(Windows::Storage::IStorageFolder const& folder, Windows::System::FolderLauncherOptions const& options);
        static auto QueryAppUriSupportAsync(Windows::Foundation::Uri const& uri);
        static auto QueryAppUriSupportAsync(Windows::Foundation::Uri const& uri, param::hstring const& packageFamilyName);
        static auto FindAppUriHandlersAsync(Windows::Foundation::Uri const& uri);
        static auto LaunchUriForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri);
        static auto LaunchUriForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options);
        static auto LaunchUriForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData);
        static auto LaunchUriForResultsForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options);
        static auto LaunchUriForResultsForUserAsync(Windows::System::User const& user, Windows::Foundation::Uri const& uri, Windows::System::LauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData);
        static auto LaunchFolderPathAsync(param::hstring const& path);
        static auto LaunchFolderPathAsync(param::hstring const& path, Windows::System::FolderLauncherOptions const& options);
        static auto LaunchFolderPathForUserAsync(Windows::System::User const& user, param::hstring const& path);
        static auto LaunchFolderPathForUserAsync(Windows::System::User const& user, param::hstring const& path, Windows::System::FolderLauncherOptions const& options);
    };
    struct __declspec(empty_bases) LauncherOptions : Windows::System::ILauncherOptions,
        impl::require<LauncherOptions, Windows::System::ILauncherOptions2, Windows::System::ILauncherOptions3, Windows::System::ILauncherOptions4, Windows::System::ILauncherViewOptions>
    {
        LauncherOptions(std::nullptr_t) noexcept {}
        LauncherOptions(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::ILauncherOptions(ptr, take_ownership_from_abi) {}
        LauncherOptions();
    };
    struct __declspec(empty_bases) LauncherUIOptions : Windows::System::ILauncherUIOptions
    {
        LauncherUIOptions(std::nullptr_t) noexcept {}
        LauncherUIOptions(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::ILauncherUIOptions(ptr, take_ownership_from_abi) {}
    };
    struct MemoryManager
    {
        MemoryManager() = delete;
        [[nodiscard]] static auto AppMemoryUsage();
        [[nodiscard]] static auto AppMemoryUsageLimit();
        [[nodiscard]] static auto AppMemoryUsageLevel();
        static auto AppMemoryUsageIncreased(Windows::Foundation::EventHandler<Windows::Foundation::IInspectable> const& handler);
        using AppMemoryUsageIncreased_revoker = impl::factory_event_revoker<Windows::System::IMemoryManagerStatics, &impl::abi_t<Windows::System::IMemoryManagerStatics>::remove_AppMemoryUsageIncreased>;
        static AppMemoryUsageIncreased_revoker AppMemoryUsageIncreased(auto_revoke_t, Windows::Foundation::EventHandler<Windows::Foundation::IInspectable> const& handler);
        static auto AppMemoryUsageIncreased(winrt::event_token const& token);
        static auto AppMemoryUsageDecreased(Windows::Foundation::EventHandler<Windows::Foundation::IInspectable> const& handler);
        using AppMemoryUsageDecreased_revoker = impl::factory_event_revoker<Windows::System::IMemoryManagerStatics, &impl::abi_t<Windows::System::IMemoryManagerStatics>::remove_AppMemoryUsageDecreased>;
        static AppMemoryUsageDecreased_revoker AppMemoryUsageDecreased(auto_revoke_t, Windows::Foundation::EventHandler<Windows::Foundation::IInspectable> const& handler);
        static auto AppMemoryUsageDecreased(winrt::event_token const& token);
        static auto AppMemoryUsageLimitChanging(Windows::Foundation::EventHandler<Windows::System::AppMemoryUsageLimitChangingEventArgs> const& handler);
        using AppMemoryUsageLimitChanging_revoker = impl::factory_event_revoker<Windows::System::IMemoryManagerStatics, &impl::abi_t<Windows::System::IMemoryManagerStatics>::remove_AppMemoryUsageLimitChanging>;
        static AppMemoryUsageLimitChanging_revoker AppMemoryUsageLimitChanging(auto_revoke_t, Windows::Foundation::EventHandler<Windows::System::AppMemoryUsageLimitChangingEventArgs> const& handler);
        static auto AppMemoryUsageLimitChanging(winrt::event_token const& token);
        static auto GetAppMemoryReport();
        static auto GetProcessMemoryReport();
        static auto TrySetAppMemoryUsageLimit(uint64_t value);
        [[nodiscard]] static auto ExpectedAppMemoryUsageLimit();
    };
    struct ProcessLauncher
    {
        ProcessLauncher() = delete;
        static auto RunToCompletionAsync(param::hstring const& fileName, param::hstring const& args);
        static auto RunToCompletionAsync(param::hstring const& fileName, param::hstring const& args, Windows::System::ProcessLauncherOptions const& options);
    };
    struct __declspec(empty_bases) ProcessLauncherOptions : Windows::System::IProcessLauncherOptions
    {
        ProcessLauncherOptions(std::nullptr_t) noexcept {}
        ProcessLauncherOptions(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IProcessLauncherOptions(ptr, take_ownership_from_abi) {}
        ProcessLauncherOptions();
    };
    struct __declspec(empty_bases) ProcessLauncherResult : Windows::System::IProcessLauncherResult
    {
        ProcessLauncherResult(std::nullptr_t) noexcept {}
        ProcessLauncherResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IProcessLauncherResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ProcessMemoryReport : Windows::System::IProcessMemoryReport
    {
        ProcessMemoryReport(std::nullptr_t) noexcept {}
        ProcessMemoryReport(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IProcessMemoryReport(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ProtocolForResultsOperation : Windows::System::IProtocolForResultsOperation
    {
        ProtocolForResultsOperation(std::nullptr_t) noexcept {}
        ProtocolForResultsOperation(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IProtocolForResultsOperation(ptr, take_ownership_from_abi) {}
    };
    struct RemoteLauncher
    {
        RemoteLauncher() = delete;
        static auto LaunchUriAsync(Windows::System::RemoteSystems::RemoteSystemConnectionRequest const& remoteSystemConnectionRequest, Windows::Foundation::Uri const& uri);
        static auto LaunchUriAsync(Windows::System::RemoteSystems::RemoteSystemConnectionRequest const& remoteSystemConnectionRequest, Windows::Foundation::Uri const& uri, Windows::System::RemoteLauncherOptions const& options);
        static auto LaunchUriAsync(Windows::System::RemoteSystems::RemoteSystemConnectionRequest const& remoteSystemConnectionRequest, Windows::Foundation::Uri const& uri, Windows::System::RemoteLauncherOptions const& options, Windows::Foundation::Collections::ValueSet const& inputData);
    };
    struct __declspec(empty_bases) RemoteLauncherOptions : Windows::System::IRemoteLauncherOptions
    {
        RemoteLauncherOptions(std::nullptr_t) noexcept {}
        RemoteLauncherOptions(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IRemoteLauncherOptions(ptr, take_ownership_from_abi) {}
        RemoteLauncherOptions();
    };
    struct ShutdownManager
    {
        ShutdownManager() = delete;
        static auto BeginShutdown(Windows::System::ShutdownKind const& shutdownKind, Windows::Foundation::TimeSpan const& timeout);
        static auto CancelShutdown();
        static auto IsPowerStateSupported(Windows::System::PowerState const& powerState);
        static auto EnterPowerState(Windows::System::PowerState const& powerState);
        static auto EnterPowerState(Windows::System::PowerState const& powerState, Windows::Foundation::TimeSpan const& wakeUpAfter);
    };
    struct TimeZoneSettings
    {
        TimeZoneSettings() = delete;
        [[nodiscard]] static auto CurrentTimeZoneDisplayName();
        [[nodiscard]] static auto SupportedTimeZoneDisplayNames();
        [[nodiscard]] static auto CanChangeTimeZone();
        static auto ChangeTimeZoneByDisplayName(param::hstring const& timeZoneDisplayName);
        static auto AutoUpdateTimeZoneAsync(Windows::Foundation::TimeSpan const& timeout);
    };
    struct __declspec(empty_bases) User : Windows::System::IUser
    {
        User(std::nullptr_t) noexcept {}
        User(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IUser(ptr, take_ownership_from_abi) {}
        static auto CreateWatcher();
        static auto FindAllAsync();
        static auto FindAllAsync(Windows::System::UserType const& type);
        static auto FindAllAsync(Windows::System::UserType const& type, Windows::System::UserAuthenticationStatus const& status);
        static auto GetFromId(param::hstring const& nonRoamableId);
    };
    struct __declspec(empty_bases) UserAuthenticationStatusChangeDeferral : Windows::System::IUserAuthenticationStatusChangeDeferral
    {
        UserAuthenticationStatusChangeDeferral(std::nullptr_t) noexcept {}
        UserAuthenticationStatusChangeDeferral(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IUserAuthenticationStatusChangeDeferral(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) UserAuthenticationStatusChangingEventArgs : Windows::System::IUserAuthenticationStatusChangingEventArgs
    {
        UserAuthenticationStatusChangingEventArgs(std::nullptr_t) noexcept {}
        UserAuthenticationStatusChangingEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IUserAuthenticationStatusChangingEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) UserChangedEventArgs : Windows::System::IUserChangedEventArgs,
        impl::require<UserChangedEventArgs, Windows::System::IUserChangedEventArgs2>
    {
        UserChangedEventArgs(std::nullptr_t) noexcept {}
        UserChangedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IUserChangedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct UserDeviceAssociation
    {
        UserDeviceAssociation() = delete;
        static auto FindUserFromDeviceId(param::hstring const& deviceId);
        static auto UserDeviceAssociationChanged(Windows::Foundation::EventHandler<Windows::System::UserDeviceAssociationChangedEventArgs> const& handler);
        using UserDeviceAssociationChanged_revoker = impl::factory_event_revoker<Windows::System::IUserDeviceAssociationStatics, &impl::abi_t<Windows::System::IUserDeviceAssociationStatics>::remove_UserDeviceAssociationChanged>;
        static UserDeviceAssociationChanged_revoker UserDeviceAssociationChanged(auto_revoke_t, Windows::Foundation::EventHandler<Windows::System::UserDeviceAssociationChangedEventArgs> const& handler);
        static auto UserDeviceAssociationChanged(winrt::event_token const& token);
    };
    struct __declspec(empty_bases) UserDeviceAssociationChangedEventArgs : Windows::System::IUserDeviceAssociationChangedEventArgs
    {
        UserDeviceAssociationChangedEventArgs(std::nullptr_t) noexcept {}
        UserDeviceAssociationChangedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IUserDeviceAssociationChangedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) UserPicker : Windows::System::IUserPicker
    {
        UserPicker(std::nullptr_t) noexcept {}
        UserPicker(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IUserPicker(ptr, take_ownership_from_abi) {}
        UserPicker();
        static auto IsSupported();
    };
    struct __declspec(empty_bases) UserWatcher : Windows::System::IUserWatcher
    {
        UserWatcher(std::nullptr_t) noexcept {}
        UserWatcher(void* ptr, take_ownership_from_abi_t) noexcept : Windows::System::IUserWatcher(ptr, take_ownership_from_abi) {}
    };
}
#endif
