// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_System_RemoteSystems_0_H
#define WINRT_Windows_System_RemoteSystems_0_H
namespace winrt::Windows::ApplicationModel::AppService
{
    struct AppServiceConnection;
}
namespace winrt::Windows::Foundation
{
    struct Deferral;
    struct EventRegistrationToken;
    template <typename TSender, typename TResult> struct TypedEventHandler;
}
namespace winrt::Windows::Foundation::Collections
{
    template <typename T> struct IIterable;
    struct ValueSet;
}
namespace winrt::Windows::Networking
{
    struct HostName;
}
namespace winrt::Windows::Security::Credentials
{
    struct WebAccount;
}
namespace winrt::Windows::System
{
    struct User;
}
namespace winrt::Windows::System::RemoteSystems
{
    enum class RemoteSystemAccessStatus : int32_t
    {
        Unspecified = 0,
        Allowed = 1,
        DeniedByUser = 2,
        DeniedBySystem = 3,
    };
    enum class RemoteSystemAuthorizationKind : int32_t
    {
        SameUser = 0,
        Anonymous = 1,
    };
    enum class RemoteSystemDiscoveryType : int32_t
    {
        Any = 0,
        Proximal = 1,
        Cloud = 2,
        SpatiallyProximal = 3,
    };
    enum class RemoteSystemPlatform : int32_t
    {
        Unknown = 0,
        Windows = 1,
        Android = 2,
        Ios = 3,
        Linux = 4,
    };
    enum class RemoteSystemSessionCreationStatus : int32_t
    {
        Success = 0,
        SessionLimitsExceeded = 1,
        OperationAborted = 2,
    };
    enum class RemoteSystemSessionDisconnectedReason : int32_t
    {
        SessionUnavailable = 0,
        RemovedByController = 1,
        SessionClosed = 2,
    };
    enum class RemoteSystemSessionJoinStatus : int32_t
    {
        Success = 0,
        SessionLimitsExceeded = 1,
        OperationAborted = 2,
        SessionUnavailable = 3,
        RejectedByController = 4,
    };
    enum class RemoteSystemSessionMessageChannelReliability : int32_t
    {
        Reliable = 0,
        Unreliable = 1,
    };
    enum class RemoteSystemSessionParticipantWatcherStatus : int32_t
    {
        Created = 0,
        Started = 1,
        EnumerationCompleted = 2,
        Stopping = 3,
        Stopped = 4,
        Aborted = 5,
    };
    enum class RemoteSystemSessionWatcherStatus : int32_t
    {
        Created = 0,
        Started = 1,
        EnumerationCompleted = 2,
        Stopping = 3,
        Stopped = 4,
        Aborted = 5,
    };
    enum class RemoteSystemStatus : int32_t
    {
        Unavailable = 0,
        DiscoveringAvailability = 1,
        Available = 2,
        Unknown = 3,
    };
    enum class RemoteSystemStatusType : int32_t
    {
        Any = 0,
        Available = 1,
    };
    enum class RemoteSystemWatcherError : int32_t
    {
        Unknown = 0,
        InternetNotAvailable = 1,
        AuthenticationError = 2,
    };
    struct IKnownRemoteSystemCapabilitiesStatics;
    struct IRemoteSystem;
    struct IRemoteSystem2;
    struct IRemoteSystem3;
    struct IRemoteSystem4;
    struct IRemoteSystem5;
    struct IRemoteSystem6;
    struct IRemoteSystemAddedEventArgs;
    struct IRemoteSystemApp;
    struct IRemoteSystemApp2;
    struct IRemoteSystemAppRegistration;
    struct IRemoteSystemAppRegistrationStatics;
    struct IRemoteSystemAuthorizationKindFilter;
    struct IRemoteSystemAuthorizationKindFilterFactory;
    struct IRemoteSystemConnectionInfo;
    struct IRemoteSystemConnectionInfoStatics;
    struct IRemoteSystemConnectionRequest;
    struct IRemoteSystemConnectionRequest2;
    struct IRemoteSystemConnectionRequest3;
    struct IRemoteSystemConnectionRequestFactory;
    struct IRemoteSystemConnectionRequestStatics;
    struct IRemoteSystemConnectionRequestStatics2;
    struct IRemoteSystemDiscoveryTypeFilter;
    struct IRemoteSystemDiscoveryTypeFilterFactory;
    struct IRemoteSystemEnumerationCompletedEventArgs;
    struct IRemoteSystemFilter;
    struct IRemoteSystemKindFilter;
    struct IRemoteSystemKindFilterFactory;
    struct IRemoteSystemKindStatics;
    struct IRemoteSystemKindStatics2;
    struct IRemoteSystemRemovedEventArgs;
    struct IRemoteSystemSession;
    struct IRemoteSystemSessionAddedEventArgs;
    struct IRemoteSystemSessionController;
    struct IRemoteSystemSessionControllerFactory;
    struct IRemoteSystemSessionCreationResult;
    struct IRemoteSystemSessionDisconnectedEventArgs;
    struct IRemoteSystemSessionInfo;
    struct IRemoteSystemSessionInvitation;
    struct IRemoteSystemSessionInvitationListener;
    struct IRemoteSystemSessionInvitationReceivedEventArgs;
    struct IRemoteSystemSessionJoinRequest;
    struct IRemoteSystemSessionJoinRequestedEventArgs;
    struct IRemoteSystemSessionJoinResult;
    struct IRemoteSystemSessionMessageChannel;
    struct IRemoteSystemSessionMessageChannelFactory;
    struct IRemoteSystemSessionOptions;
    struct IRemoteSystemSessionParticipant;
    struct IRemoteSystemSessionParticipantAddedEventArgs;
    struct IRemoteSystemSessionParticipantRemovedEventArgs;
    struct IRemoteSystemSessionParticipantWatcher;
    struct IRemoteSystemSessionRemovedEventArgs;
    struct IRemoteSystemSessionStatics;
    struct IRemoteSystemSessionUpdatedEventArgs;
    struct IRemoteSystemSessionValueSetReceivedEventArgs;
    struct IRemoteSystemSessionWatcher;
    struct IRemoteSystemStatics;
    struct IRemoteSystemStatics2;
    struct IRemoteSystemStatics3;
    struct IRemoteSystemStatusTypeFilter;
    struct IRemoteSystemStatusTypeFilterFactory;
    struct IRemoteSystemUpdatedEventArgs;
    struct IRemoteSystemWatcher;
    struct IRemoteSystemWatcher2;
    struct IRemoteSystemWatcher3;
    struct IRemoteSystemWatcherErrorOccurredEventArgs;
    struct IRemoteSystemWebAccountFilter;
    struct IRemoteSystemWebAccountFilterFactory;
    struct KnownRemoteSystemCapabilities;
    struct RemoteSystem;
    struct RemoteSystemAddedEventArgs;
    struct RemoteSystemApp;
    struct RemoteSystemAppRegistration;
    struct RemoteSystemAuthorizationKindFilter;
    struct RemoteSystemConnectionInfo;
    struct RemoteSystemConnectionRequest;
    struct RemoteSystemDiscoveryTypeFilter;
    struct RemoteSystemEnumerationCompletedEventArgs;
    struct RemoteSystemKindFilter;
    struct RemoteSystemKinds;
    struct RemoteSystemRemovedEventArgs;
    struct RemoteSystemSession;
    struct RemoteSystemSessionAddedEventArgs;
    struct RemoteSystemSessionController;
    struct RemoteSystemSessionCreationResult;
    struct RemoteSystemSessionDisconnectedEventArgs;
    struct RemoteSystemSessionInfo;
    struct RemoteSystemSessionInvitation;
    struct RemoteSystemSessionInvitationListener;
    struct RemoteSystemSessionInvitationReceivedEventArgs;
    struct RemoteSystemSessionJoinRequest;
    struct RemoteSystemSessionJoinRequestedEventArgs;
    struct RemoteSystemSessionJoinResult;
    struct RemoteSystemSessionMessageChannel;
    struct RemoteSystemSessionOptions;
    struct RemoteSystemSessionParticipant;
    struct RemoteSystemSessionParticipantAddedEventArgs;
    struct RemoteSystemSessionParticipantRemovedEventArgs;
    struct RemoteSystemSessionParticipantWatcher;
    struct RemoteSystemSessionRemovedEventArgs;
    struct RemoteSystemSessionUpdatedEventArgs;
    struct RemoteSystemSessionValueSetReceivedEventArgs;
    struct RemoteSystemSessionWatcher;
    struct RemoteSystemStatusTypeFilter;
    struct RemoteSystemUpdatedEventArgs;
    struct RemoteSystemWatcher;
    struct RemoteSystemWatcherErrorOccurredEventArgs;
    struct RemoteSystemWebAccountFilter;
}
namespace winrt::impl
{
    template <> struct category<Windows::System::RemoteSystems::IKnownRemoteSystemCapabilitiesStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystem>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystem2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystem3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystem4>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystem5>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystem6>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemAddedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemApp>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemApp2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemAppRegistration>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemAppRegistrationStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilter>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilterFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemConnectionInfo>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemConnectionInfoStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilter>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilterFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemEnumerationCompletedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemFilter>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemKindFilter>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemKindFilterFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemKindStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemKindStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemRemovedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSession>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionAddedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionController>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionControllerFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionCreationResult>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionDisconnectedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionInfo>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionInvitation>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationListener>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationReceivedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequest>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequestedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionJoinResult>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannel>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannelFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionOptions>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionParticipant>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantAddedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantRemovedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionRemovedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionUpdatedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionValueSetReceivedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemStatics3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilter>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilterFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemUpdatedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemWatcher>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemWatcher2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemWatcher3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemWatcherErrorOccurredEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilter>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilterFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::System::RemoteSystems::KnownRemoteSystemCapabilities>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystem>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemAddedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemApp>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemAppRegistration>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemAuthorizationKindFilter>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemConnectionInfo>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemConnectionRequest>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemDiscoveryTypeFilter>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemEnumerationCompletedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemKindFilter>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemKinds>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemRemovedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSession>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionAddedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionController>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionCreationResult>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionDisconnectedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionInfo>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionInvitation>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionInvitationListener>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionInvitationReceivedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionJoinRequest>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionJoinRequestedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionJoinResult>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionMessageChannel>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionOptions>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionParticipant>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionParticipantAddedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionParticipantRemovedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcher>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionRemovedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionUpdatedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionValueSetReceivedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionWatcher>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemStatusTypeFilter>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemUpdatedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemWatcher>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemWatcherErrorOccurredEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemWebAccountFilter>
    {
        using type = class_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemAccessStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemAuthorizationKind>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemDiscoveryType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemPlatform>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionCreationStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionDisconnectedReason>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionJoinStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionMessageChannelReliability>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcherStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemSessionWatcherStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemStatusType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::System::RemoteSystems::RemoteSystemWatcherError>
    {
        using type = enum_category;
    };
    template <> struct name<Windows::System::RemoteSystems::IKnownRemoteSystemCapabilitiesStatics>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IKnownRemoteSystemCapabilitiesStatics" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystem>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystem" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystem2>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystem2" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystem3>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystem3" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystem4>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystem4" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystem5>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystem5" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystem6>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystem6" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemAddedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemAddedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemApp>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemApp" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemApp2>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemApp2" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemAppRegistration>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemAppRegistration" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemAppRegistrationStatics>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemAppRegistrationStatics" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemAuthorizationKindFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilterFactory>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemAuthorizationKindFilterFactory" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemConnectionInfo>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemConnectionInfo" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemConnectionInfoStatics>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemConnectionInfoStatics" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemConnectionRequest" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest2>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemConnectionRequest2" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest3>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemConnectionRequest3" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestFactory>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemConnectionRequestFactory" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemConnectionRequestStatics" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics2>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemConnectionRequestStatics2" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemDiscoveryTypeFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilterFactory>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemDiscoveryTypeFilterFactory" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemEnumerationCompletedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemEnumerationCompletedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemKindFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemKindFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemKindFilterFactory>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemKindFilterFactory" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemKindStatics>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemKindStatics" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemKindStatics2>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemKindStatics2" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemRemovedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemRemovedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSession>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSession" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionAddedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionAddedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionController>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionController" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionControllerFactory>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionControllerFactory" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionCreationResult>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionCreationResult" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionDisconnectedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionDisconnectedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionInfo>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionInfo" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionInvitation>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionInvitation" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationListener>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionInvitationListener" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationReceivedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionInvitationReceivedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequest>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionJoinRequest" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequestedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionJoinRequestedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionJoinResult>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionJoinResult" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannel>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionMessageChannel" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannelFactory>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionMessageChannelFactory" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionOptions>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionOptions" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionParticipant>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionParticipant" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantAddedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionParticipantAddedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantRemovedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionParticipantRemovedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionParticipantWatcher" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionRemovedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionRemovedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionStatics>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionStatics" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionUpdatedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionUpdatedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionValueSetReceivedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionValueSetReceivedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemSessionWatcher" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemStatics>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemStatics" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemStatics2>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemStatics2" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemStatics3>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemStatics3" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemStatusTypeFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilterFactory>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemStatusTypeFilterFactory" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemUpdatedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemUpdatedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemWatcher>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemWatcher" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemWatcher2>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemWatcher2" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemWatcher3>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemWatcher3" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemWatcherErrorOccurredEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemWatcherErrorOccurredEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemWebAccountFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilterFactory>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.IRemoteSystemWebAccountFilterFactory" };
    };
    template <> struct name<Windows::System::RemoteSystems::KnownRemoteSystemCapabilities>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.KnownRemoteSystemCapabilities" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystem>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystem" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemAddedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemAddedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemApp>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemApp" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemAppRegistration>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemAppRegistration" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemAuthorizationKindFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemAuthorizationKindFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemConnectionInfo>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemConnectionInfo" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemConnectionRequest>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemConnectionRequest" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemDiscoveryTypeFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemDiscoveryTypeFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemEnumerationCompletedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemEnumerationCompletedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemKindFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemKindFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemKinds>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemKinds" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemRemovedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemRemovedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSession>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSession" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionAddedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionAddedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionController>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionController" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionCreationResult>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionCreationResult" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionDisconnectedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionDisconnectedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionInfo>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionInfo" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionInvitation>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionInvitation" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionInvitationListener>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionInvitationListener" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionInvitationReceivedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionInvitationReceivedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionJoinRequest>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionJoinRequest" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionJoinRequestedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionJoinRequestedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionJoinResult>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionJoinResult" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionMessageChannel>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionMessageChannel" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionOptions>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionOptions" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionParticipant>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionParticipant" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionParticipantAddedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionParticipantAddedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionParticipantRemovedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionParticipantRemovedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcher>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionParticipantWatcher" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionRemovedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionRemovedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionUpdatedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionUpdatedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionValueSetReceivedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionValueSetReceivedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionWatcher>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionWatcher" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemStatusTypeFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemStatusTypeFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemUpdatedEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemUpdatedEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemWatcher>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemWatcher" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemWatcherErrorOccurredEventArgs>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemWatcherErrorOccurredEventArgs" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemWebAccountFilter>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemWebAccountFilter" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemAccessStatus>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemAccessStatus" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemAuthorizationKind>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemAuthorizationKind" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemDiscoveryType>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemDiscoveryType" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemPlatform>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemPlatform" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionCreationStatus>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionCreationStatus" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionDisconnectedReason>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionDisconnectedReason" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionJoinStatus>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionJoinStatus" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionMessageChannelReliability>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionMessageChannelReliability" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcherStatus>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionParticipantWatcherStatus" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemSessionWatcherStatus>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemSessionWatcherStatus" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemStatus>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemStatus" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemStatusType>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemStatusType" };
    };
    template <> struct name<Windows::System::RemoteSystems::RemoteSystemWatcherError>
    {
        static constexpr auto & value{ L"Windows.System.RemoteSystems.RemoteSystemWatcherError" };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IKnownRemoteSystemCapabilitiesStatics>
    {
        static constexpr guid value{ 0x8108E380,0x7F8A,0x44E4,{ 0x92,0xCD,0x03,0xB6,0x46,0x9B,0x94,0xA3 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystem>
    {
        static constexpr guid value{ 0xED5838CD,0x1E10,0x4A8C,{ 0xB4,0xA6,0x4E,0x5F,0xD6,0xF9,0x77,0x21 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystem2>
    {
        static constexpr guid value{ 0x09DFE4EC,0xFB8B,0x4A08,{ 0xA7,0x58,0x68,0x76,0x43,0x5D,0x76,0x9E } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystem3>
    {
        static constexpr guid value{ 0x72B4B495,0xB7C6,0x40BE,{ 0x83,0x1B,0x73,0x56,0x2F,0x12,0xFF,0xA8 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystem4>
    {
        static constexpr guid value{ 0xF164FFE5,0xB987,0x4CA5,{ 0x99,0x26,0xFA,0x04,0x38,0xBE,0x62,0x73 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystem5>
    {
        static constexpr guid value{ 0xEB2AD723,0xE5E2,0x4AE2,{ 0xA7,0xA7,0xA1,0x09,0x7A,0x09,0x8E,0x90 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystem6>
    {
        static constexpr guid value{ 0xD4CDA942,0xC027,0x533E,{ 0x93,0x84,0x3A,0x19,0xB4,0xF7,0xEE,0xF3 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemAddedEventArgs>
    {
        static constexpr guid value{ 0x8F39560F,0xE534,0x4697,{ 0x88,0x36,0x7A,0xBE,0xA1,0x51,0x51,0x6E } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemApp>
    {
        static constexpr guid value{ 0x80E5BCBD,0xD54D,0x41B1,{ 0x9B,0x16,0x68,0x10,0xA8,0x71,0xED,0x4F } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemApp2>
    {
        static constexpr guid value{ 0x6369BF15,0x0A96,0x577A,{ 0x8F,0xF6,0xC3,0x59,0x04,0xDF,0xA8,0xF3 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemAppRegistration>
    {
        static constexpr guid value{ 0xB47947B5,0x7035,0x4A5A,{ 0xB8,0xDF,0x96,0x2D,0x8F,0x84,0x31,0xF4 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemAppRegistrationStatics>
    {
        static constexpr guid value{ 0x01B99840,0xCFD2,0x453F,{ 0xAE,0x25,0xC2,0x53,0x9F,0x08,0x6A,0xFD } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilter>
    {
        static constexpr guid value{ 0x6B0DDE8E,0x04D0,0x40F4,{ 0xA2,0x7F,0xC2,0xAC,0xBB,0xD6,0xB7,0x34 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilterFactory>
    {
        static constexpr guid value{ 0xAD65DF4D,0xB66A,0x45A4,{ 0x81,0x77,0x8C,0xAE,0xD7,0x5D,0x9E,0x5A } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemConnectionInfo>
    {
        static constexpr guid value{ 0x23278BC3,0x0D09,0x52CB,{ 0x9C,0x6A,0xEE,0xD2,0x94,0x0B,0xEE,0x43 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemConnectionInfoStatics>
    {
        static constexpr guid value{ 0xAC831E2D,0x66C5,0x56D7,{ 0xA4,0xCE,0x70,0x5D,0x94,0x92,0x5A,0xD6 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest>
    {
        static constexpr guid value{ 0x84ED4104,0x8D5E,0x4D72,{ 0x82,0x38,0x76,0x21,0x57,0x6C,0x7A,0x67 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest2>
    {
        static constexpr guid value{ 0x12DF6D6F,0xBFFC,0x483A,{ 0x8A,0xBE,0xD3,0x4A,0x6C,0x19,0xF9,0x2B } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest3>
    {
        static constexpr guid value{ 0xDE86C3E7,0xC9CC,0x5A50,{ 0xB8,0xD9,0xBA,0x7B,0x34,0xBB,0x8D,0x0E } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestFactory>
    {
        static constexpr guid value{ 0xAA0A0A20,0xBAEB,0x4575,{ 0xB5,0x30,0x81,0x0B,0xB9,0x78,0x63,0x34 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics>
    {
        static constexpr guid value{ 0x86CA143D,0x8214,0x425C,{ 0x89,0x32,0xDB,0x49,0x03,0x2D,0x13,0x06 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics2>
    {
        static constexpr guid value{ 0x460F1027,0x64EC,0x598E,{ 0xA8,0x00,0x4F,0x2E,0xE5,0x8D,0xEF,0x19 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilter>
    {
        static constexpr guid value{ 0x42D9041F,0xEE5A,0x43DA,{ 0xAC,0x6A,0x6F,0xEE,0x25,0x46,0x07,0x41 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilterFactory>
    {
        static constexpr guid value{ 0x9F9EB993,0xC260,0x4161,{ 0x92,0xF2,0x9C,0x02,0x1F,0x23,0xFE,0x5D } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemEnumerationCompletedEventArgs>
    {
        static constexpr guid value{ 0xC6E83D5F,0x4030,0x4354,{ 0xA0,0x60,0x14,0xF1,0xB2,0x2C,0x54,0x5D } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemFilter>
    {
        static constexpr guid value{ 0x4A3BA9E4,0x99EB,0x45EB,{ 0xBA,0x16,0x03,0x67,0x72,0x8F,0xF3,0x74 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemKindFilter>
    {
        static constexpr guid value{ 0x38E1C9EC,0x22C3,0x4EF6,{ 0x90,0x1A,0xBB,0xB1,0xC7,0xAA,0xD4,0xED } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemKindFilterFactory>
    {
        static constexpr guid value{ 0xA1FB18EE,0x99EA,0x40BC,{ 0x9A,0x39,0xC6,0x70,0xAA,0x80,0x4A,0x28 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemKindStatics>
    {
        static constexpr guid value{ 0xF6317633,0xAB14,0x41D0,{ 0x95,0x53,0x79,0x6A,0xAD,0xB8,0x82,0xDB } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemKindStatics2>
    {
        static constexpr guid value{ 0xB9E3A3D0,0x0466,0x4749,{ 0x91,0xE8,0x65,0xF9,0xD1,0x9A,0x96,0xA5 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemRemovedEventArgs>
    {
        static constexpr guid value{ 0x8B3D16BB,0x7306,0x49EA,{ 0xB7,0xDF,0x67,0xD5,0x71,0x4C,0xB0,0x13 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSession>
    {
        static constexpr guid value{ 0x69476A01,0x9ADA,0x490F,{ 0x95,0x49,0xD3,0x1C,0xB1,0x4C,0x9E,0x95 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionAddedEventArgs>
    {
        static constexpr guid value{ 0xD585D754,0xBC97,0x4C39,{ 0x99,0xB4,0xBE,0xCA,0x76,0xE0,0x4C,0x3F } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionController>
    {
        static constexpr guid value{ 0xE48B2DD2,0x6820,0x4867,{ 0xB4,0x25,0xD8,0x9C,0x0A,0x3E,0xF7,0xBA } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionControllerFactory>
    {
        static constexpr guid value{ 0xBFCC2F6B,0xAC3D,0x4199,{ 0x82,0xCD,0x66,0x70,0xA7,0x73,0xEF,0x2E } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionCreationResult>
    {
        static constexpr guid value{ 0xA79812C2,0x37DE,0x448C,{ 0x8B,0x83,0xA3,0x0A,0xA3,0xC4,0xEA,0xD6 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionDisconnectedEventArgs>
    {
        static constexpr guid value{ 0xDE0BC69B,0x77C5,0x461C,{ 0x82,0x09,0x7C,0x6C,0x5D,0x31,0x11,0xAB } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionInfo>
    {
        static constexpr guid value{ 0xFF4DF648,0x8B0A,0x4E9A,{ 0x99,0x05,0x69,0xE4,0xB8,0x41,0xC5,0x88 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionInvitation>
    {
        static constexpr guid value{ 0x3E32CC91,0x51D7,0x4766,{ 0xA1,0x21,0x25,0x51,0x6C,0x3B,0x82,0x94 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationListener>
    {
        static constexpr guid value{ 0x08F4003F,0xBC71,0x49E1,{ 0x87,0x4A,0x31,0xDD,0xFF,0x9A,0x27,0xB9 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationReceivedEventArgs>
    {
        static constexpr guid value{ 0x5E964A2D,0xA10D,0x4EDB,{ 0x8D,0xEA,0x54,0xD2,0x0A,0xC1,0x95,0x43 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequest>
    {
        static constexpr guid value{ 0x20600068,0x7994,0x4331,{ 0x86,0xD1,0xD8,0x9D,0x88,0x25,0x85,0xEE } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequestedEventArgs>
    {
        static constexpr guid value{ 0xDBCA4FC3,0x82B9,0x4816,{ 0x9C,0x24,0xE4,0x0E,0x61,0x77,0x4B,0xD8 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionJoinResult>
    {
        static constexpr guid value{ 0xCE7B1F04,0xA03E,0x41A4,{ 0x90,0x0B,0x1E,0x79,0x32,0x8C,0x12,0x67 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannel>
    {
        static constexpr guid value{ 0x9524D12A,0x73D9,0x4C10,{ 0xB7,0x51,0xC2,0x67,0x84,0x43,0x71,0x27 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannelFactory>
    {
        static constexpr guid value{ 0x295E1C4A,0xBD16,0x4298,{ 0xB7,0xCE,0x41,0x54,0x82,0xB0,0xE1,0x1D } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionOptions>
    {
        static constexpr guid value{ 0x740ED755,0x8418,0x4F01,{ 0x93,0x53,0xE2,0x1C,0x9E,0xCC,0x6C,0xFC } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionParticipant>
    {
        static constexpr guid value{ 0x7E90058C,0xACF9,0x4729,{ 0x8A,0x17,0x44,0xE7,0xBA,0xED,0x5D,0xCC } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantAddedEventArgs>
    {
        static constexpr guid value{ 0xD35A57D8,0xC9A1,0x4BB7,{ 0xB6,0xB0,0x79,0xBB,0x91,0xAD,0xF9,0x3D } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantRemovedEventArgs>
    {
        static constexpr guid value{ 0x866EF088,0xDE68,0x4ABF,{ 0x88,0xA1,0xF9,0x0D,0x16,0x27,0x41,0x92 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher>
    {
        static constexpr guid value{ 0xDCDD02CC,0xAA87,0x4D79,{ 0xB6,0xCC,0x44,0x59,0xB3,0xE9,0x20,0x75 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionRemovedEventArgs>
    {
        static constexpr guid value{ 0xAF82914E,0x39A1,0x4DEA,{ 0x9D,0x63,0x43,0x79,0x8D,0x5B,0xBB,0xD0 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionStatics>
    {
        static constexpr guid value{ 0x8524899F,0xFD20,0x44E3,{ 0x95,0x65,0xE7,0x5A,0x3B,0x14,0xC6,0x6E } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionUpdatedEventArgs>
    {
        static constexpr guid value{ 0x16875069,0x231E,0x4C91,{ 0x8E,0xC8,0xB3,0xA3,0x9D,0x9E,0x55,0xA3 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionValueSetReceivedEventArgs>
    {
        static constexpr guid value{ 0x06F31785,0x2DA5,0x4E58,{ 0xA7,0x8F,0x9E,0x8D,0x07,0x84,0xEE,0x25 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher>
    {
        static constexpr guid value{ 0x8003E340,0x0C41,0x4A62,{ 0xB6,0xD7,0xBD,0xBE,0x2B,0x19,0xBE,0x2D } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemStatics>
    {
        static constexpr guid value{ 0xA485B392,0xFF2B,0x4B47,{ 0xBE,0x62,0x74,0x3F,0x2F,0x14,0x0F,0x30 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemStatics2>
    {
        static constexpr guid value{ 0x0C98EDCA,0x6F99,0x4C52,{ 0xA2,0x72,0xEA,0x4F,0x36,0x47,0x17,0x44 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemStatics3>
    {
        static constexpr guid value{ 0x9995F16F,0x0B3C,0x5AC5,{ 0xB3,0x25,0xCC,0x73,0xF4,0x37,0xDF,0xCD } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilter>
    {
        static constexpr guid value{ 0x0C39514E,0xCBB6,0x4777,{ 0x85,0x34,0x2E,0x0C,0x52,0x1A,0xFF,0xA2 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilterFactory>
    {
        static constexpr guid value{ 0x33CF78FA,0xD724,0x4125,{ 0xAC,0x7A,0x8D,0x28,0x1E,0x44,0xC9,0x49 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemUpdatedEventArgs>
    {
        static constexpr guid value{ 0x7502FF0E,0xDBCB,0x4155,{ 0xB4,0xCA,0xB3,0x0A,0x04,0xF2,0x76,0x27 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemWatcher>
    {
        static constexpr guid value{ 0x5D600C7E,0x2C07,0x48C5,{ 0x88,0x9C,0x45,0x5D,0x2B,0x09,0x97,0x71 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemWatcher2>
    {
        static constexpr guid value{ 0x73436700,0x19CA,0x48F9,{ 0xA4,0xCD,0x78,0x0F,0x7A,0xD5,0x8C,0x71 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemWatcher3>
    {
        static constexpr guid value{ 0xF79C0FCF,0xA913,0x55D3,{ 0x84,0x13,0x41,0x8F,0xCF,0x15,0xBA,0x54 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemWatcherErrorOccurredEventArgs>
    {
        static constexpr guid value{ 0x74C5C6AF,0x5114,0x4426,{ 0x92,0x16,0x20,0xD8,0x1F,0x85,0x19,0xAE } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilter>
    {
        static constexpr guid value{ 0x3FB75873,0x87C8,0x5D8F,{ 0x97,0x7E,0xF6,0x9F,0x96,0xD6,0x72,0x38 } };
    };
    template <> struct guid_storage<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilterFactory>
    {
        static constexpr guid value{ 0x348A2709,0x5F4D,0x5127,{ 0xB4,0xA7,0xBF,0x99,0xD5,0x25,0x2B,0x1B } };
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystem>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystem;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemAddedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemAddedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemApp>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemApp;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemAppRegistration>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemAppRegistration;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemAuthorizationKindFilter>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilter;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemConnectionInfo>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemConnectionInfo;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemConnectionRequest>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemConnectionRequest;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemDiscoveryTypeFilter>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilter;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemEnumerationCompletedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemEnumerationCompletedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemKindFilter>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemKindFilter;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemRemovedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemRemovedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSession>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSession;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionAddedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionAddedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionController>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionController;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionCreationResult>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionCreationResult;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionDisconnectedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionDisconnectedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionInfo>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionInfo;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionInvitation>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionInvitation;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionInvitationListener>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionInvitationListener;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionInvitationReceivedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionInvitationReceivedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionJoinRequest>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequest;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionJoinRequestedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequestedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionJoinResult>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionJoinResult;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionMessageChannel>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannel;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionOptions>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionOptions;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionParticipant>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionParticipant;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionParticipantAddedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionParticipantAddedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionParticipantRemovedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionParticipantRemovedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcher>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionRemovedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionRemovedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionUpdatedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionUpdatedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionValueSetReceivedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionValueSetReceivedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemSessionWatcher>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemSessionWatcher;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemStatusTypeFilter>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilter;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemUpdatedEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemUpdatedEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemWatcher>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemWatcher;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemWatcherErrorOccurredEventArgs>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemWatcherErrorOccurredEventArgs;
    };
    template <> struct default_interface<Windows::System::RemoteSystems::RemoteSystemWebAccountFilter>
    {
        using type = Windows::System::RemoteSystems::IRemoteSystemWebAccountFilter;
    };
    template <> struct abi<Windows::System::RemoteSystems::IKnownRemoteSystemCapabilitiesStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AppService(void**) noexcept = 0;
            virtual int32_t __stdcall get_LaunchUri(void**) noexcept = 0;
            virtual int32_t __stdcall get_RemoteSession(void**) noexcept = 0;
            virtual int32_t __stdcall get_SpatialEntity(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystem>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_DisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall get_Id(void**) noexcept = 0;
            virtual int32_t __stdcall get_Kind(void**) noexcept = 0;
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_IsAvailableByProximity(bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystem2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_IsAvailableBySpatialProximity(bool*) noexcept = 0;
            virtual int32_t __stdcall GetCapabilitySupportedAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystem3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ManufacturerDisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall get_ModelDisplayName(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystem4>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Platform(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystem5>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Apps(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystem6>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemAddedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystem(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemApp>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Id(void**) noexcept = 0;
            virtual int32_t __stdcall get_DisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall get_IsAvailableByProximity(bool*) noexcept = 0;
            virtual int32_t __stdcall get_IsAvailableBySpatialProximity(bool*) noexcept = 0;
            virtual int32_t __stdcall get_Attributes(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemApp2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
            virtual int32_t __stdcall get_ConnectionToken(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemAppRegistration>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
            virtual int32_t __stdcall get_Attributes(void**) noexcept = 0;
            virtual int32_t __stdcall SaveAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemAppRegistrationStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetDefault(void**) noexcept = 0;
            virtual int32_t __stdcall GetForUser(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilter>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystemAuthorizationKind(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilterFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemConnectionInfo>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_IsProximal(bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemConnectionInfoStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall TryCreateFromAppServiceConnection(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystem(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystemApp(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ConnectionToken(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateForApp(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateFromConnectionToken(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFromConnectionTokenForUser(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilter>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystemDiscoveryType(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilterFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemEnumerationCompletedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemFilter>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemKindFilter>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystemKinds(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemKindFilterFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemKindStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Phone(void**) noexcept = 0;
            virtual int32_t __stdcall get_Hub(void**) noexcept = 0;
            virtual int32_t __stdcall get_Holographic(void**) noexcept = 0;
            virtual int32_t __stdcall get_Desktop(void**) noexcept = 0;
            virtual int32_t __stdcall get_Xbox(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemKindStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Iot(void**) noexcept = 0;
            virtual int32_t __stdcall get_Tablet(void**) noexcept = 0;
            virtual int32_t __stdcall get_Laptop(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemRemovedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystemId(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSession>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Id(void**) noexcept = 0;
            virtual int32_t __stdcall get_DisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall get_ControllerDisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall add_Disconnected(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Disconnected(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall CreateParticipantWatcher(void**) noexcept = 0;
            virtual int32_t __stdcall SendInvitationAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionAddedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_SessionInfo(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionController>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall add_JoinRequested(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_JoinRequested(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall RemoveParticipantAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateSessionAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionControllerFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateController(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateControllerWithSessionOptions(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionCreationResult>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Session(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionDisconnectedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Reason(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionInfo>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_DisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall get_ControllerDisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall JoinAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionInvitation>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Sender(void**) noexcept = 0;
            virtual int32_t __stdcall get_SessionInfo(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationListener>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall add_InvitationReceived(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_InvitationReceived(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationReceivedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Invitation(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequest>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Participant(void**) noexcept = 0;
            virtual int32_t __stdcall Accept() noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequestedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_JoinRequest(void**) noexcept = 0;
            virtual int32_t __stdcall GetDeferral(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionJoinResult>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Session(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannel>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Session(void**) noexcept = 0;
            virtual int32_t __stdcall BroadcastValueSetAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall SendValueSetAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall SendValueSetToParticipantsAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall add_ValueSetReceived(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_ValueSetReceived(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannelFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateWithReliability(void*, void*, int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionOptions>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_IsInviteOnly(bool*) noexcept = 0;
            virtual int32_t __stdcall put_IsInviteOnly(bool) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionParticipant>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystem(void**) noexcept = 0;
            virtual int32_t __stdcall GetHostNames(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantAddedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Participant(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantRemovedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Participant(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Start() noexcept = 0;
            virtual int32_t __stdcall Stop() noexcept = 0;
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall add_Added(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Added(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Removed(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Removed(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_EnumerationCompleted(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_EnumerationCompleted(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionRemovedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_SessionInfo(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateWatcher(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionUpdatedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_SessionInfo(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionValueSetReceivedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Sender(void**) noexcept = 0;
            virtual int32_t __stdcall get_Message(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Start() noexcept = 0;
            virtual int32_t __stdcall Stop() noexcept = 0;
            virtual int32_t __stdcall get_Status(int32_t*) noexcept = 0;
            virtual int32_t __stdcall add_Added(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Added(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Updated(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Updated(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Removed(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Removed(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall FindByHostNameAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateWatcher(void**) noexcept = 0;
            virtual int32_t __stdcall CreateWatcherWithFilters(void*, void**) noexcept = 0;
            virtual int32_t __stdcall RequestAccessAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall IsAuthorizationKindEnabled(int32_t, bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemStatics3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateWatcherForUser(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateWatcherWithFiltersForUser(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilter>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystemStatusType(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilterFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemUpdatedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_RemoteSystem(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemWatcher>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Start() noexcept = 0;
            virtual int32_t __stdcall Stop() noexcept = 0;
            virtual int32_t __stdcall add_RemoteSystemAdded(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_RemoteSystemAdded(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_RemoteSystemUpdated(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_RemoteSystemUpdated(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_RemoteSystemRemoved(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_RemoteSystemRemoved(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemWatcher2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall add_EnumerationCompleted(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_EnumerationCompleted(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_ErrorOccurred(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_ErrorOccurred(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemWatcher3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemWatcherErrorOccurredEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Error(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilter>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Account(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilterFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(void*, void**) noexcept = 0;
        };
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IKnownRemoteSystemCapabilitiesStatics
    {
        [[nodiscard]] auto AppService() const;
        [[nodiscard]] auto LaunchUri() const;
        [[nodiscard]] auto RemoteSession() const;
        [[nodiscard]] auto SpatialEntity() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IKnownRemoteSystemCapabilitiesStatics>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IKnownRemoteSystemCapabilitiesStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystem
    {
        [[nodiscard]] auto DisplayName() const;
        [[nodiscard]] auto Id() const;
        [[nodiscard]] auto Kind() const;
        [[nodiscard]] auto Status() const;
        [[nodiscard]] auto IsAvailableByProximity() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystem>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystem<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystem2
    {
        [[nodiscard]] auto IsAvailableBySpatialProximity() const;
        auto GetCapabilitySupportedAsync(param::hstring const& capabilityName) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystem2>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystem2<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystem3
    {
        [[nodiscard]] auto ManufacturerDisplayName() const;
        [[nodiscard]] auto ModelDisplayName() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystem3>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystem3<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystem4
    {
        [[nodiscard]] auto Platform() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystem4>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystem4<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystem5
    {
        [[nodiscard]] auto Apps() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystem5>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystem5<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystem6
    {
        [[nodiscard]] auto User() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystem6>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystem6<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemAddedEventArgs
    {
        [[nodiscard]] auto RemoteSystem() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemAddedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemAddedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemApp
    {
        [[nodiscard]] auto Id() const;
        [[nodiscard]] auto DisplayName() const;
        [[nodiscard]] auto IsAvailableByProximity() const;
        [[nodiscard]] auto IsAvailableBySpatialProximity() const;
        [[nodiscard]] auto Attributes() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemApp>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemApp<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemApp2
    {
        [[nodiscard]] auto User() const;
        [[nodiscard]] auto ConnectionToken() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemApp2>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemApp2<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemAppRegistration
    {
        [[nodiscard]] auto User() const;
        [[nodiscard]] auto Attributes() const;
        auto SaveAsync() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemAppRegistration>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemAppRegistration<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemAppRegistrationStatics
    {
        auto GetDefault() const;
        auto GetForUser(Windows::System::User const& user) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemAppRegistrationStatics>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemAppRegistrationStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemAuthorizationKindFilter
    {
        [[nodiscard]] auto RemoteSystemAuthorizationKind() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilter>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemAuthorizationKindFilter<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemAuthorizationKindFilterFactory
    {
        auto Create(Windows::System::RemoteSystems::RemoteSystemAuthorizationKind const& remoteSystemAuthorizationKind) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemAuthorizationKindFilterFactory>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemAuthorizationKindFilterFactory<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemConnectionInfo
    {
        [[nodiscard]] auto IsProximal() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemConnectionInfo>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemConnectionInfo<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemConnectionInfoStatics
    {
        auto TryCreateFromAppServiceConnection(Windows::ApplicationModel::AppService::AppServiceConnection const& connection) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemConnectionInfoStatics>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemConnectionInfoStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequest
    {
        [[nodiscard]] auto RemoteSystem() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequest<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequest2
    {
        [[nodiscard]] auto RemoteSystemApp() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest2>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequest2<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequest3
    {
        [[nodiscard]] auto ConnectionToken() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemConnectionRequest3>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequest3<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequestFactory
    {
        auto Create(Windows::System::RemoteSystems::RemoteSystem const& remoteSystem) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestFactory>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequestFactory<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequestStatics
    {
        auto CreateForApp(Windows::System::RemoteSystems::RemoteSystemApp const& remoteSystemApp) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequestStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequestStatics2
    {
        auto CreateFromConnectionToken(param::hstring const& connectionToken) const;
        auto CreateFromConnectionTokenForUser(Windows::System::User const& user, param::hstring const& connectionToken) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemConnectionRequestStatics2>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemConnectionRequestStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemDiscoveryTypeFilter
    {
        [[nodiscard]] auto RemoteSystemDiscoveryType() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilter>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemDiscoveryTypeFilter<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemDiscoveryTypeFilterFactory
    {
        auto Create(Windows::System::RemoteSystems::RemoteSystemDiscoveryType const& discoveryType) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemDiscoveryTypeFilterFactory>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemDiscoveryTypeFilterFactory<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemEnumerationCompletedEventArgs
    {
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemEnumerationCompletedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemEnumerationCompletedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemFilter
    {
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemFilter>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemFilter<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemKindFilter
    {
        [[nodiscard]] auto RemoteSystemKinds() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemKindFilter>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemKindFilter<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemKindFilterFactory
    {
        auto Create(param::iterable<hstring> const& remoteSystemKinds) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemKindFilterFactory>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemKindFilterFactory<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemKindStatics
    {
        [[nodiscard]] auto Phone() const;
        [[nodiscard]] auto Hub() const;
        [[nodiscard]] auto Holographic() const;
        [[nodiscard]] auto Desktop() const;
        [[nodiscard]] auto Xbox() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemKindStatics>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemKindStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemKindStatics2
    {
        [[nodiscard]] auto Iot() const;
        [[nodiscard]] auto Tablet() const;
        [[nodiscard]] auto Laptop() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemKindStatics2>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemKindStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemRemovedEventArgs
    {
        [[nodiscard]] auto RemoteSystemId() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemRemovedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemRemovedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSession
    {
        [[nodiscard]] auto Id() const;
        [[nodiscard]] auto DisplayName() const;
        [[nodiscard]] auto ControllerDisplayName() const;
        auto Disconnected(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSession, Windows::System::RemoteSystems::RemoteSystemSessionDisconnectedEventArgs> const& handler) const;
        using Disconnected_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSession, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSession>::remove_Disconnected>;
        Disconnected_revoker Disconnected(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSession, Windows::System::RemoteSystems::RemoteSystemSessionDisconnectedEventArgs> const& handler) const;
        auto Disconnected(winrt::event_token const& token) const noexcept;
        auto CreateParticipantWatcher() const;
        auto SendInvitationAsync(Windows::System::RemoteSystems::RemoteSystem const& invitee) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSession>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSession<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionAddedEventArgs
    {
        [[nodiscard]] auto SessionInfo() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionAddedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionAddedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionController
    {
        auto JoinRequested(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionController, Windows::System::RemoteSystems::RemoteSystemSessionJoinRequestedEventArgs> const& handler) const;
        using JoinRequested_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSessionController, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSessionController>::remove_JoinRequested>;
        JoinRequested_revoker JoinRequested(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionController, Windows::System::RemoteSystems::RemoteSystemSessionJoinRequestedEventArgs> const& handler) const;
        auto JoinRequested(winrt::event_token const& token) const noexcept;
        auto RemoveParticipantAsync(Windows::System::RemoteSystems::RemoteSystemSessionParticipant const& pParticipant) const;
        auto CreateSessionAsync() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionController>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionController<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionControllerFactory
    {
        auto CreateController(param::hstring const& displayName) const;
        auto CreateController(param::hstring const& displayName, Windows::System::RemoteSystems::RemoteSystemSessionOptions const& options) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionControllerFactory>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionControllerFactory<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionCreationResult
    {
        [[nodiscard]] auto Status() const;
        [[nodiscard]] auto Session() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionCreationResult>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionCreationResult<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionDisconnectedEventArgs
    {
        [[nodiscard]] auto Reason() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionDisconnectedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionDisconnectedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionInfo
    {
        [[nodiscard]] auto DisplayName() const;
        [[nodiscard]] auto ControllerDisplayName() const;
        auto JoinAsync() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionInfo>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionInfo<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionInvitation
    {
        [[nodiscard]] auto Sender() const;
        [[nodiscard]] auto SessionInfo() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionInvitation>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionInvitation<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionInvitationListener
    {
        auto InvitationReceived(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionInvitationListener, Windows::System::RemoteSystems::RemoteSystemSessionInvitationReceivedEventArgs> const& handler) const;
        using InvitationReceived_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationListener, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationListener>::remove_InvitationReceived>;
        InvitationReceived_revoker InvitationReceived(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionInvitationListener, Windows::System::RemoteSystems::RemoteSystemSessionInvitationReceivedEventArgs> const& handler) const;
        auto InvitationReceived(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationListener>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionInvitationListener<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionInvitationReceivedEventArgs
    {
        [[nodiscard]] auto Invitation() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionInvitationReceivedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionInvitationReceivedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionJoinRequest
    {
        [[nodiscard]] auto Participant() const;
        auto Accept() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequest>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionJoinRequest<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionJoinRequestedEventArgs
    {
        [[nodiscard]] auto JoinRequest() const;
        auto GetDeferral() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionJoinRequestedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionJoinRequestedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionJoinResult
    {
        [[nodiscard]] auto Status() const;
        [[nodiscard]] auto Session() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionJoinResult>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionJoinResult<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionMessageChannel
    {
        [[nodiscard]] auto Session() const;
        auto BroadcastValueSetAsync(Windows::Foundation::Collections::ValueSet const& messageData) const;
        auto SendValueSetAsync(Windows::Foundation::Collections::ValueSet const& messageData, Windows::System::RemoteSystems::RemoteSystemSessionParticipant const& participant) const;
        auto SendValueSetToParticipantsAsync(Windows::Foundation::Collections::ValueSet const& messageData, param::async_iterable<Windows::System::RemoteSystems::RemoteSystemSessionParticipant> const& participants) const;
        auto ValueSetReceived(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionMessageChannel, Windows::System::RemoteSystems::RemoteSystemSessionValueSetReceivedEventArgs> const& handler) const;
        using ValueSetReceived_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannel, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannel>::remove_ValueSetReceived>;
        ValueSetReceived_revoker ValueSetReceived(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionMessageChannel, Windows::System::RemoteSystems::RemoteSystemSessionValueSetReceivedEventArgs> const& handler) const;
        auto ValueSetReceived(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannel>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionMessageChannel<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionMessageChannelFactory
    {
        auto Create(Windows::System::RemoteSystems::RemoteSystemSession const& session, param::hstring const& channelName) const;
        auto Create(Windows::System::RemoteSystems::RemoteSystemSession const& session, param::hstring const& channelName, Windows::System::RemoteSystems::RemoteSystemSessionMessageChannelReliability const& reliability) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionMessageChannelFactory>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionMessageChannelFactory<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionOptions
    {
        [[nodiscard]] auto IsInviteOnly() const;
        auto IsInviteOnly(bool value) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionOptions>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionOptions<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionParticipant
    {
        [[nodiscard]] auto RemoteSystem() const;
        auto GetHostNames() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionParticipant>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionParticipant<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionParticipantAddedEventArgs
    {
        [[nodiscard]] auto Participant() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantAddedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionParticipantAddedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionParticipantRemovedEventArgs
    {
        [[nodiscard]] auto Participant() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantRemovedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionParticipantRemovedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionParticipantWatcher
    {
        auto Start() const;
        auto Stop() const;
        [[nodiscard]] auto Status() const;
        auto Added(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcher, Windows::System::RemoteSystems::RemoteSystemSessionParticipantAddedEventArgs> const& handler) const;
        using Added_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher>::remove_Added>;
        Added_revoker Added(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcher, Windows::System::RemoteSystems::RemoteSystemSessionParticipantAddedEventArgs> const& handler) const;
        auto Added(winrt::event_token const& token) const noexcept;
        auto Removed(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcher, Windows::System::RemoteSystems::RemoteSystemSessionParticipantRemovedEventArgs> const& handler) const;
        using Removed_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher>::remove_Removed>;
        Removed_revoker Removed(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcher, Windows::System::RemoteSystems::RemoteSystemSessionParticipantRemovedEventArgs> const& handler) const;
        auto Removed(winrt::event_token const& token) const noexcept;
        auto EnumerationCompleted(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcher, Windows::Foundation::IInspectable> const& handler) const;
        using EnumerationCompleted_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher>::remove_EnumerationCompleted>;
        EnumerationCompleted_revoker EnumerationCompleted(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionParticipantWatcher, Windows::Foundation::IInspectable> const& handler) const;
        auto EnumerationCompleted(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionParticipantWatcher>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionParticipantWatcher<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionRemovedEventArgs
    {
        [[nodiscard]] auto SessionInfo() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionRemovedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionRemovedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionStatics
    {
        auto CreateWatcher() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionStatics>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionUpdatedEventArgs
    {
        [[nodiscard]] auto SessionInfo() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionUpdatedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionUpdatedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionValueSetReceivedEventArgs
    {
        [[nodiscard]] auto Sender() const;
        [[nodiscard]] auto Message() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionValueSetReceivedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionValueSetReceivedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemSessionWatcher
    {
        auto Start() const;
        auto Stop() const;
        [[nodiscard]] auto Status() const;
        auto Added(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionWatcher, Windows::System::RemoteSystems::RemoteSystemSessionAddedEventArgs> const& handler) const;
        using Added_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher>::remove_Added>;
        Added_revoker Added(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionWatcher, Windows::System::RemoteSystems::RemoteSystemSessionAddedEventArgs> const& handler) const;
        auto Added(winrt::event_token const& token) const noexcept;
        auto Updated(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionWatcher, Windows::System::RemoteSystems::RemoteSystemSessionUpdatedEventArgs> const& handler) const;
        using Updated_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher>::remove_Updated>;
        Updated_revoker Updated(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionWatcher, Windows::System::RemoteSystems::RemoteSystemSessionUpdatedEventArgs> const& handler) const;
        auto Updated(winrt::event_token const& token) const noexcept;
        auto Removed(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionWatcher, Windows::System::RemoteSystems::RemoteSystemSessionRemovedEventArgs> const& handler) const;
        using Removed_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher>::remove_Removed>;
        Removed_revoker Removed(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemSessionWatcher, Windows::System::RemoteSystems::RemoteSystemSessionRemovedEventArgs> const& handler) const;
        auto Removed(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemSessionWatcher>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemSessionWatcher<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemStatics
    {
        auto FindByHostNameAsync(Windows::Networking::HostName const& hostName) const;
        auto CreateWatcher() const;
        auto CreateWatcher(param::iterable<Windows::System::RemoteSystems::IRemoteSystemFilter> const& filters) const;
        auto RequestAccessAsync() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemStatics>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemStatics<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemStatics2
    {
        auto IsAuthorizationKindEnabled(Windows::System::RemoteSystems::RemoteSystemAuthorizationKind const& kind) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemStatics2>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemStatics3
    {
        auto CreateWatcherForUser(Windows::System::User const& user) const;
        auto CreateWatcherForUser(Windows::System::User const& user, param::iterable<Windows::System::RemoteSystems::IRemoteSystemFilter> const& filters) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemStatics3>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemStatics3<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemStatusTypeFilter
    {
        [[nodiscard]] auto RemoteSystemStatusType() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilter>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemStatusTypeFilter<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemStatusTypeFilterFactory
    {
        auto Create(Windows::System::RemoteSystems::RemoteSystemStatusType const& remoteSystemStatusType) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemStatusTypeFilterFactory>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemStatusTypeFilterFactory<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemUpdatedEventArgs
    {
        [[nodiscard]] auto RemoteSystem() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemUpdatedEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemUpdatedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemWatcher
    {
        auto Start() const;
        auto Stop() const;
        auto RemoteSystemAdded(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemAddedEventArgs> const& handler) const;
        using RemoteSystemAdded_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemWatcher, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemWatcher>::remove_RemoteSystemAdded>;
        RemoteSystemAdded_revoker RemoteSystemAdded(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemAddedEventArgs> const& handler) const;
        auto RemoteSystemAdded(winrt::event_token const& token) const noexcept;
        auto RemoteSystemUpdated(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemUpdatedEventArgs> const& handler) const;
        using RemoteSystemUpdated_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemWatcher, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemWatcher>::remove_RemoteSystemUpdated>;
        RemoteSystemUpdated_revoker RemoteSystemUpdated(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemUpdatedEventArgs> const& handler) const;
        auto RemoteSystemUpdated(winrt::event_token const& token) const noexcept;
        auto RemoteSystemRemoved(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemRemovedEventArgs> const& handler) const;
        using RemoteSystemRemoved_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemWatcher, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemWatcher>::remove_RemoteSystemRemoved>;
        RemoteSystemRemoved_revoker RemoteSystemRemoved(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemRemovedEventArgs> const& handler) const;
        auto RemoteSystemRemoved(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemWatcher>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemWatcher<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemWatcher2
    {
        auto EnumerationCompleted(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemEnumerationCompletedEventArgs> const& handler) const;
        using EnumerationCompleted_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemWatcher2, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemWatcher2>::remove_EnumerationCompleted>;
        EnumerationCompleted_revoker EnumerationCompleted(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemEnumerationCompletedEventArgs> const& handler) const;
        auto EnumerationCompleted(winrt::event_token const& token) const noexcept;
        auto ErrorOccurred(Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemWatcherErrorOccurredEventArgs> const& handler) const;
        using ErrorOccurred_revoker = impl::event_revoker<Windows::System::RemoteSystems::IRemoteSystemWatcher2, &impl::abi_t<Windows::System::RemoteSystems::IRemoteSystemWatcher2>::remove_ErrorOccurred>;
        ErrorOccurred_revoker ErrorOccurred(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::System::RemoteSystems::RemoteSystemWatcher, Windows::System::RemoteSystems::RemoteSystemWatcherErrorOccurredEventArgs> const& handler) const;
        auto ErrorOccurred(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemWatcher2>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemWatcher2<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemWatcher3
    {
        [[nodiscard]] auto User() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemWatcher3>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemWatcher3<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemWatcherErrorOccurredEventArgs
    {
        [[nodiscard]] auto Error() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemWatcherErrorOccurredEventArgs>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemWatcherErrorOccurredEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemWebAccountFilter
    {
        [[nodiscard]] auto Account() const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilter>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemWebAccountFilter<D>;
    };
    template <typename D>
    struct consume_Windows_System_RemoteSystems_IRemoteSystemWebAccountFilterFactory
    {
        auto Create(Windows::Security::Credentials::WebAccount const& account) const;
    };
    template <> struct consume<Windows::System::RemoteSystems::IRemoteSystemWebAccountFilterFactory>
    {
        template <typename D> using type = consume_Windows_System_RemoteSystems_IRemoteSystemWebAccountFilterFactory<D>;
    };
}
#endif
