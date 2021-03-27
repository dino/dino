// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_UI_Notifications_0_H
#define WINRT_Windows_UI_Notifications_0_H
namespace winrt::Windows::ApplicationModel
{
    struct AppInfo;
}
namespace winrt::Windows::Data::Xml::Dom
{
    struct XmlDocument;
}
namespace winrt::Windows::Foundation
{
    struct Deferral;
    struct EventRegistrationToken;
    struct HResult;
    struct IAsyncAction;
    template <typename T> struct IReference;
    template <typename TSender, typename TResult> struct TypedEventHandler;
    struct Uri;
}
namespace winrt::Windows::Foundation::Collections
{
    template <typename T> struct IIterable;
    template <typename K, typename V> struct IKeyValuePair;
    struct ValueSet;
}
namespace winrt::Windows::System
{
    struct User;
}
namespace winrt::Windows::UI::Notifications
{
    enum class AdaptiveNotificationContentKind : int32_t
    {
        Text = 0,
    };
    enum class BadgeTemplateType : int32_t
    {
        BadgeGlyph = 0,
        BadgeNumber = 1,
    };
    enum class NotificationKinds : uint32_t
    {
        Unknown = 0,
        Toast = 0x1,
    };
    enum class NotificationMirroring : int32_t
    {
        Allowed = 0,
        Disabled = 1,
    };
    enum class NotificationSetting : int32_t
    {
        Enabled = 0,
        DisabledForApplication = 1,
        DisabledForUser = 2,
        DisabledByGroupPolicy = 3,
        DisabledByManifest = 4,
    };
    enum class NotificationUpdateResult : int32_t
    {
        Succeeded = 0,
        Failed = 1,
        NotificationNotFound = 2,
    };
    enum class PeriodicUpdateRecurrence : int32_t
    {
        HalfHour = 0,
        Hour = 1,
        SixHours = 2,
        TwelveHours = 3,
        Daily = 4,
    };
    enum class TileFlyoutTemplateType : int32_t
    {
        TileFlyoutTemplate01 = 0,
    };
    enum class TileTemplateType : int32_t
    {
        TileSquareImage = 0,
        TileSquareBlock = 1,
        TileSquareText01 = 2,
        TileSquareText02 = 3,
        TileSquareText03 = 4,
        TileSquareText04 = 5,
        TileSquarePeekImageAndText01 = 6,
        TileSquarePeekImageAndText02 = 7,
        TileSquarePeekImageAndText03 = 8,
        TileSquarePeekImageAndText04 = 9,
        TileWideImage = 10,
        TileWideImageCollection = 11,
        TileWideImageAndText01 = 12,
        TileWideImageAndText02 = 13,
        TileWideBlockAndText01 = 14,
        TileWideBlockAndText02 = 15,
        TileWidePeekImageCollection01 = 16,
        TileWidePeekImageCollection02 = 17,
        TileWidePeekImageCollection03 = 18,
        TileWidePeekImageCollection04 = 19,
        TileWidePeekImageCollection05 = 20,
        TileWidePeekImageCollection06 = 21,
        TileWidePeekImageAndText01 = 22,
        TileWidePeekImageAndText02 = 23,
        TileWidePeekImage01 = 24,
        TileWidePeekImage02 = 25,
        TileWidePeekImage03 = 26,
        TileWidePeekImage04 = 27,
        TileWidePeekImage05 = 28,
        TileWidePeekImage06 = 29,
        TileWideSmallImageAndText01 = 30,
        TileWideSmallImageAndText02 = 31,
        TileWideSmallImageAndText03 = 32,
        TileWideSmallImageAndText04 = 33,
        TileWideSmallImageAndText05 = 34,
        TileWideText01 = 35,
        TileWideText02 = 36,
        TileWideText03 = 37,
        TileWideText04 = 38,
        TileWideText05 = 39,
        TileWideText06 = 40,
        TileWideText07 = 41,
        TileWideText08 = 42,
        TileWideText09 = 43,
        TileWideText10 = 44,
        TileWideText11 = 45,
        TileSquare150x150Image = 0,
        TileSquare150x150Block = 1,
        TileSquare150x150Text01 = 2,
        TileSquare150x150Text02 = 3,
        TileSquare150x150Text03 = 4,
        TileSquare150x150Text04 = 5,
        TileSquare150x150PeekImageAndText01 = 6,
        TileSquare150x150PeekImageAndText02 = 7,
        TileSquare150x150PeekImageAndText03 = 8,
        TileSquare150x150PeekImageAndText04 = 9,
        TileWide310x150Image = 10,
        TileWide310x150ImageCollection = 11,
        TileWide310x150ImageAndText01 = 12,
        TileWide310x150ImageAndText02 = 13,
        TileWide310x150BlockAndText01 = 14,
        TileWide310x150BlockAndText02 = 15,
        TileWide310x150PeekImageCollection01 = 16,
        TileWide310x150PeekImageCollection02 = 17,
        TileWide310x150PeekImageCollection03 = 18,
        TileWide310x150PeekImageCollection04 = 19,
        TileWide310x150PeekImageCollection05 = 20,
        TileWide310x150PeekImageCollection06 = 21,
        TileWide310x150PeekImageAndText01 = 22,
        TileWide310x150PeekImageAndText02 = 23,
        TileWide310x150PeekImage01 = 24,
        TileWide310x150PeekImage02 = 25,
        TileWide310x150PeekImage03 = 26,
        TileWide310x150PeekImage04 = 27,
        TileWide310x150PeekImage05 = 28,
        TileWide310x150PeekImage06 = 29,
        TileWide310x150SmallImageAndText01 = 30,
        TileWide310x150SmallImageAndText02 = 31,
        TileWide310x150SmallImageAndText03 = 32,
        TileWide310x150SmallImageAndText04 = 33,
        TileWide310x150SmallImageAndText05 = 34,
        TileWide310x150Text01 = 35,
        TileWide310x150Text02 = 36,
        TileWide310x150Text03 = 37,
        TileWide310x150Text04 = 38,
        TileWide310x150Text05 = 39,
        TileWide310x150Text06 = 40,
        TileWide310x150Text07 = 41,
        TileWide310x150Text08 = 42,
        TileWide310x150Text09 = 43,
        TileWide310x150Text10 = 44,
        TileWide310x150Text11 = 45,
        TileSquare310x310BlockAndText01 = 46,
        TileSquare310x310BlockAndText02 = 47,
        TileSquare310x310Image = 48,
        TileSquare310x310ImageAndText01 = 49,
        TileSquare310x310ImageAndText02 = 50,
        TileSquare310x310ImageAndTextOverlay01 = 51,
        TileSquare310x310ImageAndTextOverlay02 = 52,
        TileSquare310x310ImageAndTextOverlay03 = 53,
        TileSquare310x310ImageCollectionAndText01 = 54,
        TileSquare310x310ImageCollectionAndText02 = 55,
        TileSquare310x310ImageCollection = 56,
        TileSquare310x310SmallImagesAndTextList01 = 57,
        TileSquare310x310SmallImagesAndTextList02 = 58,
        TileSquare310x310SmallImagesAndTextList03 = 59,
        TileSquare310x310SmallImagesAndTextList04 = 60,
        TileSquare310x310Text01 = 61,
        TileSquare310x310Text02 = 62,
        TileSquare310x310Text03 = 63,
        TileSquare310x310Text04 = 64,
        TileSquare310x310Text05 = 65,
        TileSquare310x310Text06 = 66,
        TileSquare310x310Text07 = 67,
        TileSquare310x310Text08 = 68,
        TileSquare310x310TextList01 = 69,
        TileSquare310x310TextList02 = 70,
        TileSquare310x310TextList03 = 71,
        TileSquare310x310SmallImageAndText01 = 72,
        TileSquare310x310SmallImagesAndTextList05 = 73,
        TileSquare310x310Text09 = 74,
        TileSquare71x71IconWithBadge = 75,
        TileSquare150x150IconWithBadge = 76,
        TileWide310x150IconWithBadgeAndText = 77,
        TileSquare71x71Image = 78,
        TileTall150x310Image = 79,
    };
    enum class ToastDismissalReason : int32_t
    {
        UserCanceled = 0,
        ApplicationHidden = 1,
        TimedOut = 2,
    };
    enum class ToastHistoryChangedType : int32_t
    {
        Cleared = 0,
        Removed = 1,
        Expired = 2,
        Added = 3,
    };
    enum class ToastNotificationPriority : int32_t
    {
        Default = 0,
        High = 1,
    };
    enum class ToastTemplateType : int32_t
    {
        ToastImageAndText01 = 0,
        ToastImageAndText02 = 1,
        ToastImageAndText03 = 2,
        ToastImageAndText04 = 3,
        ToastText01 = 4,
        ToastText02 = 5,
        ToastText03 = 6,
        ToastText04 = 7,
    };
    enum class UserNotificationChangedKind : int32_t
    {
        Added = 0,
        Removed = 1,
    };
    struct IAdaptiveNotificationContent;
    struct IAdaptiveNotificationText;
    struct IBadgeNotification;
    struct IBadgeNotificationFactory;
    struct IBadgeUpdateManagerForUser;
    struct IBadgeUpdateManagerStatics;
    struct IBadgeUpdateManagerStatics2;
    struct IBadgeUpdater;
    struct IKnownAdaptiveNotificationHintsStatics;
    struct IKnownAdaptiveNotificationTextStylesStatics;
    struct IKnownNotificationBindingsStatics;
    struct INotification;
    struct INotificationBinding;
    struct INotificationData;
    struct INotificationDataFactory;
    struct INotificationVisual;
    struct IScheduledTileNotification;
    struct IScheduledTileNotificationFactory;
    struct IScheduledToastNotification;
    struct IScheduledToastNotification2;
    struct IScheduledToastNotification3;
    struct IScheduledToastNotification4;
    struct IScheduledToastNotificationFactory;
    struct IScheduledToastNotificationShowingEventArgs;
    struct IShownTileNotification;
    struct ITileFlyoutNotification;
    struct ITileFlyoutNotificationFactory;
    struct ITileFlyoutUpdateManagerStatics;
    struct ITileFlyoutUpdater;
    struct ITileNotification;
    struct ITileNotificationFactory;
    struct ITileUpdateManagerForUser;
    struct ITileUpdateManagerStatics;
    struct ITileUpdateManagerStatics2;
    struct ITileUpdater;
    struct ITileUpdater2;
    struct IToastActivatedEventArgs;
    struct IToastActivatedEventArgs2;
    struct IToastCollection;
    struct IToastCollectionFactory;
    struct IToastCollectionManager;
    struct IToastDismissedEventArgs;
    struct IToastFailedEventArgs;
    struct IToastNotification;
    struct IToastNotification2;
    struct IToastNotification3;
    struct IToastNotification4;
    struct IToastNotification6;
    struct IToastNotificationActionTriggerDetail;
    struct IToastNotificationFactory;
    struct IToastNotificationHistory;
    struct IToastNotificationHistory2;
    struct IToastNotificationHistoryChangedTriggerDetail;
    struct IToastNotificationHistoryChangedTriggerDetail2;
    struct IToastNotificationManagerForUser;
    struct IToastNotificationManagerForUser2;
    struct IToastNotificationManagerStatics;
    struct IToastNotificationManagerStatics2;
    struct IToastNotificationManagerStatics4;
    struct IToastNotificationManagerStatics5;
    struct IToastNotifier;
    struct IToastNotifier2;
    struct IToastNotifier3;
    struct IUserNotification;
    struct IUserNotificationChangedEventArgs;
    struct AdaptiveNotificationText;
    struct BadgeNotification;
    struct BadgeUpdateManager;
    struct BadgeUpdateManagerForUser;
    struct BadgeUpdater;
    struct KnownAdaptiveNotificationHints;
    struct KnownAdaptiveNotificationTextStyles;
    struct KnownNotificationBindings;
    struct Notification;
    struct NotificationBinding;
    struct NotificationData;
    struct NotificationVisual;
    struct ScheduledTileNotification;
    struct ScheduledToastNotification;
    struct ScheduledToastNotificationShowingEventArgs;
    struct ShownTileNotification;
    struct TileFlyoutNotification;
    struct TileFlyoutUpdateManager;
    struct TileFlyoutUpdater;
    struct TileNotification;
    struct TileUpdateManager;
    struct TileUpdateManagerForUser;
    struct TileUpdater;
    struct ToastActivatedEventArgs;
    struct ToastCollection;
    struct ToastCollectionManager;
    struct ToastDismissedEventArgs;
    struct ToastFailedEventArgs;
    struct ToastNotification;
    struct ToastNotificationActionTriggerDetail;
    struct ToastNotificationHistory;
    struct ToastNotificationHistoryChangedTriggerDetail;
    struct ToastNotificationManager;
    struct ToastNotificationManagerForUser;
    struct ToastNotifier;
    struct UserNotification;
    struct UserNotificationChangedEventArgs;
}
namespace winrt::impl
{
    template <> struct category<Windows::UI::Notifications::IAdaptiveNotificationContent>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IAdaptiveNotificationText>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IBadgeNotification>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IBadgeNotificationFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IBadgeUpdateManagerForUser>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IBadgeUpdateManagerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IBadgeUpdateManagerStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IBadgeUpdater>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IKnownAdaptiveNotificationHintsStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IKnownAdaptiveNotificationTextStylesStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IKnownNotificationBindingsStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::INotification>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::INotificationBinding>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::INotificationData>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::INotificationDataFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::INotificationVisual>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IScheduledTileNotification>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IScheduledTileNotificationFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IScheduledToastNotification>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IScheduledToastNotification2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IScheduledToastNotification3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IScheduledToastNotification4>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IScheduledToastNotificationFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IScheduledToastNotificationShowingEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IShownTileNotification>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileFlyoutNotification>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileFlyoutNotificationFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileFlyoutUpdateManagerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileFlyoutUpdater>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileNotification>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileNotificationFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileUpdateManagerForUser>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileUpdateManagerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileUpdateManagerStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileUpdater>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::ITileUpdater2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastActivatedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastActivatedEventArgs2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastCollection>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastCollectionFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastCollectionManager>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastDismissedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastFailedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotification>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotification2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotification3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotification4>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotification6>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationActionTriggerDetail>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationHistory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationHistory2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationManagerForUser>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationManagerForUser2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationManagerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationManagerStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationManagerStatics4>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotificationManagerStatics5>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotifier>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotifier2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IToastNotifier3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IUserNotification>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::IUserNotificationChangedEventArgs>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::UI::Notifications::AdaptiveNotificationText>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::BadgeNotification>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::BadgeUpdateManager>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::BadgeUpdateManagerForUser>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::BadgeUpdater>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::KnownAdaptiveNotificationHints>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::KnownAdaptiveNotificationTextStyles>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::KnownNotificationBindings>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::Notification>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::NotificationBinding>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::NotificationData>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::NotificationVisual>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ScheduledTileNotification>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ScheduledToastNotification>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ScheduledToastNotificationShowingEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ShownTileNotification>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::TileFlyoutNotification>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::TileFlyoutUpdateManager>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::TileFlyoutUpdater>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::TileNotification>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::TileUpdateManager>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::TileUpdateManagerForUser>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::TileUpdater>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastActivatedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastCollection>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastCollectionManager>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastDismissedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastFailedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastNotification>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastNotificationActionTriggerDetail>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastNotificationHistory>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastNotificationHistoryChangedTriggerDetail>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastNotificationManager>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastNotificationManagerForUser>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastNotifier>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::UserNotification>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::UserNotificationChangedEventArgs>
    {
        using type = class_category;
    };
    template <> struct category<Windows::UI::Notifications::AdaptiveNotificationContentKind>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::BadgeTemplateType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::NotificationKinds>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::NotificationMirroring>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::NotificationSetting>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::NotificationUpdateResult>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::PeriodicUpdateRecurrence>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::TileFlyoutTemplateType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::TileTemplateType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastDismissalReason>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastHistoryChangedType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastNotificationPriority>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::ToastTemplateType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::UI::Notifications::UserNotificationChangedKind>
    {
        using type = enum_category;
    };
    template <> struct name<Windows::UI::Notifications::IAdaptiveNotificationContent>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IAdaptiveNotificationContent" };
    };
    template <> struct name<Windows::UI::Notifications::IAdaptiveNotificationText>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IAdaptiveNotificationText" };
    };
    template <> struct name<Windows::UI::Notifications::IBadgeNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IBadgeNotification" };
    };
    template <> struct name<Windows::UI::Notifications::IBadgeNotificationFactory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IBadgeNotificationFactory" };
    };
    template <> struct name<Windows::UI::Notifications::IBadgeUpdateManagerForUser>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IBadgeUpdateManagerForUser" };
    };
    template <> struct name<Windows::UI::Notifications::IBadgeUpdateManagerStatics>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IBadgeUpdateManagerStatics" };
    };
    template <> struct name<Windows::UI::Notifications::IBadgeUpdateManagerStatics2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IBadgeUpdateManagerStatics2" };
    };
    template <> struct name<Windows::UI::Notifications::IBadgeUpdater>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IBadgeUpdater" };
    };
    template <> struct name<Windows::UI::Notifications::IKnownAdaptiveNotificationHintsStatics>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IKnownAdaptiveNotificationHintsStatics" };
    };
    template <> struct name<Windows::UI::Notifications::IKnownAdaptiveNotificationTextStylesStatics>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IKnownAdaptiveNotificationTextStylesStatics" };
    };
    template <> struct name<Windows::UI::Notifications::IKnownNotificationBindingsStatics>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IKnownNotificationBindingsStatics" };
    };
    template <> struct name<Windows::UI::Notifications::INotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.INotification" };
    };
    template <> struct name<Windows::UI::Notifications::INotificationBinding>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.INotificationBinding" };
    };
    template <> struct name<Windows::UI::Notifications::INotificationData>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.INotificationData" };
    };
    template <> struct name<Windows::UI::Notifications::INotificationDataFactory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.INotificationDataFactory" };
    };
    template <> struct name<Windows::UI::Notifications::INotificationVisual>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.INotificationVisual" };
    };
    template <> struct name<Windows::UI::Notifications::IScheduledTileNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IScheduledTileNotification" };
    };
    template <> struct name<Windows::UI::Notifications::IScheduledTileNotificationFactory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IScheduledTileNotificationFactory" };
    };
    template <> struct name<Windows::UI::Notifications::IScheduledToastNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IScheduledToastNotification" };
    };
    template <> struct name<Windows::UI::Notifications::IScheduledToastNotification2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IScheduledToastNotification2" };
    };
    template <> struct name<Windows::UI::Notifications::IScheduledToastNotification3>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IScheduledToastNotification3" };
    };
    template <> struct name<Windows::UI::Notifications::IScheduledToastNotification4>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IScheduledToastNotification4" };
    };
    template <> struct name<Windows::UI::Notifications::IScheduledToastNotificationFactory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IScheduledToastNotificationFactory" };
    };
    template <> struct name<Windows::UI::Notifications::IScheduledToastNotificationShowingEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IScheduledToastNotificationShowingEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::IShownTileNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IShownTileNotification" };
    };
    template <> struct name<Windows::UI::Notifications::ITileFlyoutNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileFlyoutNotification" };
    };
    template <> struct name<Windows::UI::Notifications::ITileFlyoutNotificationFactory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileFlyoutNotificationFactory" };
    };
    template <> struct name<Windows::UI::Notifications::ITileFlyoutUpdateManagerStatics>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileFlyoutUpdateManagerStatics" };
    };
    template <> struct name<Windows::UI::Notifications::ITileFlyoutUpdater>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileFlyoutUpdater" };
    };
    template <> struct name<Windows::UI::Notifications::ITileNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileNotification" };
    };
    template <> struct name<Windows::UI::Notifications::ITileNotificationFactory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileNotificationFactory" };
    };
    template <> struct name<Windows::UI::Notifications::ITileUpdateManagerForUser>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileUpdateManagerForUser" };
    };
    template <> struct name<Windows::UI::Notifications::ITileUpdateManagerStatics>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileUpdateManagerStatics" };
    };
    template <> struct name<Windows::UI::Notifications::ITileUpdateManagerStatics2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileUpdateManagerStatics2" };
    };
    template <> struct name<Windows::UI::Notifications::ITileUpdater>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileUpdater" };
    };
    template <> struct name<Windows::UI::Notifications::ITileUpdater2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ITileUpdater2" };
    };
    template <> struct name<Windows::UI::Notifications::IToastActivatedEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastActivatedEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::IToastActivatedEventArgs2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastActivatedEventArgs2" };
    };
    template <> struct name<Windows::UI::Notifications::IToastCollection>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastCollection" };
    };
    template <> struct name<Windows::UI::Notifications::IToastCollectionFactory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastCollectionFactory" };
    };
    template <> struct name<Windows::UI::Notifications::IToastCollectionManager>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastCollectionManager" };
    };
    template <> struct name<Windows::UI::Notifications::IToastDismissedEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastDismissedEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::IToastFailedEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastFailedEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotification" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotification2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotification2" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotification3>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotification3" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotification4>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotification4" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotification6>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotification6" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationActionTriggerDetail>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationActionTriggerDetail" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationFactory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationFactory" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationHistory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationHistory" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationHistory2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationHistory2" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationHistoryChangedTriggerDetail" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationHistoryChangedTriggerDetail2" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationManagerForUser>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationManagerForUser" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationManagerForUser2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationManagerForUser2" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationManagerStatics>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationManagerStatics" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationManagerStatics2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationManagerStatics2" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationManagerStatics4>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationManagerStatics4" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotificationManagerStatics5>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotificationManagerStatics5" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotifier>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotifier" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotifier2>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotifier2" };
    };
    template <> struct name<Windows::UI::Notifications::IToastNotifier3>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IToastNotifier3" };
    };
    template <> struct name<Windows::UI::Notifications::IUserNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IUserNotification" };
    };
    template <> struct name<Windows::UI::Notifications::IUserNotificationChangedEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.IUserNotificationChangedEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::AdaptiveNotificationText>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.AdaptiveNotificationText" };
    };
    template <> struct name<Windows::UI::Notifications::BadgeNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.BadgeNotification" };
    };
    template <> struct name<Windows::UI::Notifications::BadgeUpdateManager>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.BadgeUpdateManager" };
    };
    template <> struct name<Windows::UI::Notifications::BadgeUpdateManagerForUser>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.BadgeUpdateManagerForUser" };
    };
    template <> struct name<Windows::UI::Notifications::BadgeUpdater>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.BadgeUpdater" };
    };
    template <> struct name<Windows::UI::Notifications::KnownAdaptiveNotificationHints>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.KnownAdaptiveNotificationHints" };
    };
    template <> struct name<Windows::UI::Notifications::KnownAdaptiveNotificationTextStyles>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.KnownAdaptiveNotificationTextStyles" };
    };
    template <> struct name<Windows::UI::Notifications::KnownNotificationBindings>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.KnownNotificationBindings" };
    };
    template <> struct name<Windows::UI::Notifications::Notification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.Notification" };
    };
    template <> struct name<Windows::UI::Notifications::NotificationBinding>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.NotificationBinding" };
    };
    template <> struct name<Windows::UI::Notifications::NotificationData>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.NotificationData" };
    };
    template <> struct name<Windows::UI::Notifications::NotificationVisual>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.NotificationVisual" };
    };
    template <> struct name<Windows::UI::Notifications::ScheduledTileNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ScheduledTileNotification" };
    };
    template <> struct name<Windows::UI::Notifications::ScheduledToastNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ScheduledToastNotification" };
    };
    template <> struct name<Windows::UI::Notifications::ScheduledToastNotificationShowingEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ScheduledToastNotificationShowingEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::ShownTileNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ShownTileNotification" };
    };
    template <> struct name<Windows::UI::Notifications::TileFlyoutNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.TileFlyoutNotification" };
    };
    template <> struct name<Windows::UI::Notifications::TileFlyoutUpdateManager>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.TileFlyoutUpdateManager" };
    };
    template <> struct name<Windows::UI::Notifications::TileFlyoutUpdater>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.TileFlyoutUpdater" };
    };
    template <> struct name<Windows::UI::Notifications::TileNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.TileNotification" };
    };
    template <> struct name<Windows::UI::Notifications::TileUpdateManager>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.TileUpdateManager" };
    };
    template <> struct name<Windows::UI::Notifications::TileUpdateManagerForUser>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.TileUpdateManagerForUser" };
    };
    template <> struct name<Windows::UI::Notifications::TileUpdater>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.TileUpdater" };
    };
    template <> struct name<Windows::UI::Notifications::ToastActivatedEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastActivatedEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::ToastCollection>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastCollection" };
    };
    template <> struct name<Windows::UI::Notifications::ToastCollectionManager>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastCollectionManager" };
    };
    template <> struct name<Windows::UI::Notifications::ToastDismissedEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastDismissedEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::ToastFailedEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastFailedEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::ToastNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastNotification" };
    };
    template <> struct name<Windows::UI::Notifications::ToastNotificationActionTriggerDetail>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastNotificationActionTriggerDetail" };
    };
    template <> struct name<Windows::UI::Notifications::ToastNotificationHistory>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastNotificationHistory" };
    };
    template <> struct name<Windows::UI::Notifications::ToastNotificationHistoryChangedTriggerDetail>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastNotificationHistoryChangedTriggerDetail" };
    };
    template <> struct name<Windows::UI::Notifications::ToastNotificationManager>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastNotificationManager" };
    };
    template <> struct name<Windows::UI::Notifications::ToastNotificationManagerForUser>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastNotificationManagerForUser" };
    };
    template <> struct name<Windows::UI::Notifications::ToastNotifier>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastNotifier" };
    };
    template <> struct name<Windows::UI::Notifications::UserNotification>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.UserNotification" };
    };
    template <> struct name<Windows::UI::Notifications::UserNotificationChangedEventArgs>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.UserNotificationChangedEventArgs" };
    };
    template <> struct name<Windows::UI::Notifications::AdaptiveNotificationContentKind>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.AdaptiveNotificationContentKind" };
    };
    template <> struct name<Windows::UI::Notifications::BadgeTemplateType>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.BadgeTemplateType" };
    };
    template <> struct name<Windows::UI::Notifications::NotificationKinds>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.NotificationKinds" };
    };
    template <> struct name<Windows::UI::Notifications::NotificationMirroring>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.NotificationMirroring" };
    };
    template <> struct name<Windows::UI::Notifications::NotificationSetting>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.NotificationSetting" };
    };
    template <> struct name<Windows::UI::Notifications::NotificationUpdateResult>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.NotificationUpdateResult" };
    };
    template <> struct name<Windows::UI::Notifications::PeriodicUpdateRecurrence>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.PeriodicUpdateRecurrence" };
    };
    template <> struct name<Windows::UI::Notifications::TileFlyoutTemplateType>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.TileFlyoutTemplateType" };
    };
    template <> struct name<Windows::UI::Notifications::TileTemplateType>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.TileTemplateType" };
    };
    template <> struct name<Windows::UI::Notifications::ToastDismissalReason>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastDismissalReason" };
    };
    template <> struct name<Windows::UI::Notifications::ToastHistoryChangedType>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastHistoryChangedType" };
    };
    template <> struct name<Windows::UI::Notifications::ToastNotificationPriority>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastNotificationPriority" };
    };
    template <> struct name<Windows::UI::Notifications::ToastTemplateType>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.ToastTemplateType" };
    };
    template <> struct name<Windows::UI::Notifications::UserNotificationChangedKind>
    {
        static constexpr auto & value{ L"Windows.UI.Notifications.UserNotificationChangedKind" };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IAdaptiveNotificationContent>
    {
        static constexpr guid value{ 0xEB0DBE66,0x7448,0x448D,{ 0x9D,0xB8,0xD7,0x8A,0xCD,0x2A,0xBB,0xA9 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IAdaptiveNotificationText>
    {
        static constexpr guid value{ 0x46D4A3BE,0x609A,0x4326,{ 0xA4,0x0B,0xBF,0xDE,0x87,0x20,0x34,0xA3 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IBadgeNotification>
    {
        static constexpr guid value{ 0x075CB4CA,0xD08A,0x4E2F,{ 0x92,0x33,0x7E,0x28,0x9C,0x1F,0x77,0x22 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IBadgeNotificationFactory>
    {
        static constexpr guid value{ 0xEDF255CE,0x0618,0x4D59,{ 0x94,0x8A,0x5A,0x61,0x04,0x0C,0x52,0xF9 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IBadgeUpdateManagerForUser>
    {
        static constexpr guid value{ 0x996B21BC,0x0386,0x44E5,{ 0xBA,0x8D,0x0C,0x10,0x77,0xA6,0x2E,0x92 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IBadgeUpdateManagerStatics>
    {
        static constexpr guid value{ 0x33400FAA,0x6DD5,0x4105,{ 0xAE,0xBC,0x9B,0x50,0xFC,0xA4,0x92,0xDA } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IBadgeUpdateManagerStatics2>
    {
        static constexpr guid value{ 0x979A35CE,0xF940,0x48BF,{ 0x94,0xE8,0xCA,0x24,0x4D,0x40,0x0B,0x41 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IBadgeUpdater>
    {
        static constexpr guid value{ 0xB5FA1FD4,0x7562,0x4F6C,{ 0xBF,0xA3,0x1B,0x6E,0xD2,0xE5,0x7F,0x2F } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IKnownAdaptiveNotificationHintsStatics>
    {
        static constexpr guid value{ 0x06206598,0xD496,0x497D,{ 0x86,0x92,0x4F,0x7D,0x7C,0x27,0x70,0xDF } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IKnownAdaptiveNotificationTextStylesStatics>
    {
        static constexpr guid value{ 0x202192D7,0x8996,0x45AA,{ 0x8B,0xA1,0xD4,0x61,0xD7,0x2C,0x2A,0x1B } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IKnownNotificationBindingsStatics>
    {
        static constexpr guid value{ 0x79427BAE,0xA8B7,0x4D58,{ 0x89,0xEA,0x76,0xA7,0xB7,0xBC,0xCD,0xED } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::INotification>
    {
        static constexpr guid value{ 0x108037FE,0xEB76,0x4F82,{ 0x97,0xBC,0xDA,0x07,0x53,0x0A,0x2E,0x20 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::INotificationBinding>
    {
        static constexpr guid value{ 0xF29E4B85,0x0370,0x4AD3,{ 0xB4,0xEA,0xDA,0x9E,0x35,0xE7,0xEA,0xBF } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::INotificationData>
    {
        static constexpr guid value{ 0x9FFD2312,0x9D6A,0x4AAF,{ 0xB6,0xAC,0xFF,0x17,0xF0,0xC1,0xF2,0x80 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::INotificationDataFactory>
    {
        static constexpr guid value{ 0x23C1E33A,0x1C10,0x46FB,{ 0x80,0x40,0xDE,0xC3,0x84,0x62,0x1C,0xF8 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::INotificationVisual>
    {
        static constexpr guid value{ 0x68835B8E,0xAA56,0x4E11,{ 0x86,0xD3,0x5F,0x9A,0x69,0x57,0xBC,0x5B } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IScheduledTileNotification>
    {
        static constexpr guid value{ 0x0ABCA6D5,0x99DC,0x4C78,{ 0xA1,0x1C,0xC9,0xE7,0xF8,0x6D,0x7E,0xF7 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IScheduledTileNotificationFactory>
    {
        static constexpr guid value{ 0x3383138A,0x98C0,0x4C3B,{ 0xBB,0xD6,0x4A,0x63,0x3C,0x7C,0xFC,0x29 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IScheduledToastNotification>
    {
        static constexpr guid value{ 0x79F577F8,0x0DE7,0x48CD,{ 0x97,0x40,0x9B,0x37,0x04,0x90,0xC8,0x38 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IScheduledToastNotification2>
    {
        static constexpr guid value{ 0xA66EA09C,0x31B4,0x43B0,{ 0xB5,0xDD,0x7A,0x40,0xE8,0x53,0x63,0xB1 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IScheduledToastNotification3>
    {
        static constexpr guid value{ 0x98429E8B,0xBD32,0x4A3B,{ 0x9D,0x15,0x22,0xAE,0xA4,0x94,0x62,0xA1 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IScheduledToastNotification4>
    {
        static constexpr guid value{ 0x1D4761FD,0xBDEF,0x4E4A,{ 0x96,0xBE,0x01,0x01,0x36,0x9B,0x58,0xD2 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IScheduledToastNotificationFactory>
    {
        static constexpr guid value{ 0xE7BED191,0x0BB9,0x4189,{ 0x83,0x94,0x31,0x76,0x1B,0x47,0x6F,0xD7 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IScheduledToastNotificationShowingEventArgs>
    {
        static constexpr guid value{ 0x6173F6B4,0x412A,0x5E2C,{ 0xA6,0xED,0xA0,0x20,0x9A,0xEF,0x9A,0x09 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IShownTileNotification>
    {
        static constexpr guid value{ 0x342D8988,0x5AF2,0x481A,{ 0xA6,0xA3,0xF2,0xFD,0xC7,0x8D,0xE8,0x8E } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileFlyoutNotification>
    {
        static constexpr guid value{ 0x9A53B261,0xC70C,0x42BE,{ 0xB2,0xF3,0xF4,0x2A,0xA9,0x7D,0x34,0xE5 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileFlyoutNotificationFactory>
    {
        static constexpr guid value{ 0xEF556FF5,0x5226,0x4F2B,{ 0xB2,0x78,0x88,0xA3,0x5D,0xFE,0x56,0x9F } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileFlyoutUpdateManagerStatics>
    {
        static constexpr guid value{ 0x04363B0B,0x1AC0,0x4B99,{ 0x88,0xE7,0xAD,0xA8,0x3E,0x95,0x3D,0x48 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileFlyoutUpdater>
    {
        static constexpr guid value{ 0x8D40C76A,0xC465,0x4052,{ 0xA7,0x40,0x5C,0x26,0x54,0xC1,0xA0,0x89 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileNotification>
    {
        static constexpr guid value{ 0xEBAEC8FA,0x50EC,0x4C18,{ 0xB4,0xD0,0x3A,0xF0,0x2E,0x55,0x40,0xAB } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileNotificationFactory>
    {
        static constexpr guid value{ 0xC6ABDD6E,0x4928,0x46C8,{ 0xBD,0xBF,0x81,0xA0,0x47,0xDE,0xA0,0xD4 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileUpdateManagerForUser>
    {
        static constexpr guid value{ 0x55141348,0x2EE2,0x4E2D,{ 0x9C,0xC1,0x21,0x6A,0x20,0xDE,0xCC,0x9F } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileUpdateManagerStatics>
    {
        static constexpr guid value{ 0xDA159E5D,0x3EA9,0x4986,{ 0x8D,0x84,0xB0,0x9D,0x5E,0x12,0x27,0x6D } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileUpdateManagerStatics2>
    {
        static constexpr guid value{ 0x731C1DDC,0x8E14,0x4B7C,{ 0xA3,0x4B,0x9D,0x22,0xDE,0x76,0xC8,0x4D } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileUpdater>
    {
        static constexpr guid value{ 0x0942A48B,0x1D91,0x44EC,{ 0x92,0x43,0xC1,0xE8,0x21,0xC2,0x9A,0x20 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::ITileUpdater2>
    {
        static constexpr guid value{ 0xA2266E12,0x15EE,0x43ED,{ 0x83,0xF5,0x65,0xB3,0x52,0xBB,0x1A,0x84 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastActivatedEventArgs>
    {
        static constexpr guid value{ 0xE3BF92F3,0xC197,0x436F,{ 0x82,0x65,0x06,0x25,0x82,0x4F,0x8D,0xAC } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastActivatedEventArgs2>
    {
        static constexpr guid value{ 0xAB7DA512,0xCC61,0x568E,{ 0x81,0xBE,0x30,0x4A,0xC3,0x10,0x38,0xFA } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastCollection>
    {
        static constexpr guid value{ 0x0A8BC3B0,0xE0BE,0x4858,{ 0xBC,0x2A,0x89,0xDF,0xE0,0xB3,0x28,0x63 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastCollectionFactory>
    {
        static constexpr guid value{ 0x164DD3D7,0x73C4,0x44F7,{ 0xB4,0xFF,0xFB,0x6D,0x4B,0xF1,0xF4,0xC6 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastCollectionManager>
    {
        static constexpr guid value{ 0x2A1821FE,0x179D,0x49BC,{ 0xB7,0x9D,0xA5,0x27,0x92,0x0D,0x36,0x65 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastDismissedEventArgs>
    {
        static constexpr guid value{ 0x3F89D935,0xD9CB,0x4538,{ 0xA0,0xF0,0xFF,0xE7,0x65,0x99,0x38,0xF8 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastFailedEventArgs>
    {
        static constexpr guid value{ 0x35176862,0xCFD4,0x44F8,{ 0xAD,0x64,0xF5,0x00,0xFD,0x89,0x6C,0x3B } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotification>
    {
        static constexpr guid value{ 0x997E2675,0x059E,0x4E60,{ 0x8B,0x06,0x17,0x60,0x91,0x7C,0x8B,0x80 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotification2>
    {
        static constexpr guid value{ 0x9DFB9FD1,0x143A,0x490E,{ 0x90,0xBF,0xB9,0xFB,0xA7,0x13,0x2D,0xE7 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotification3>
    {
        static constexpr guid value{ 0x31E8AED8,0x8141,0x4F99,{ 0xBC,0x0A,0xC4,0xED,0x21,0x29,0x7D,0x77 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotification4>
    {
        static constexpr guid value{ 0x15154935,0x28EA,0x4727,{ 0x88,0xE9,0xC5,0x86,0x80,0xE2,0xD1,0x18 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotification6>
    {
        static constexpr guid value{ 0x43EBFE53,0x89AE,0x5C1E,{ 0xA2,0x79,0x3A,0xEC,0xFE,0x9B,0x6F,0x54 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationActionTriggerDetail>
    {
        static constexpr guid value{ 0x9445135A,0x38F3,0x42F6,{ 0x96,0xAA,0x79,0x55,0xB0,0xF0,0x3D,0xA2 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationFactory>
    {
        static constexpr guid value{ 0x04124B20,0x82C6,0x4229,{ 0xB1,0x09,0xFD,0x9E,0xD4,0x66,0x2B,0x53 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationHistory>
    {
        static constexpr guid value{ 0x5CADDC63,0x01D3,0x4C97,{ 0x98,0x6F,0x05,0x33,0x48,0x3F,0xEE,0x14 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationHistory2>
    {
        static constexpr guid value{ 0x3BC3D253,0x2F31,0x4092,{ 0x91,0x29,0x8A,0xD5,0xAB,0xF0,0x67,0xDA } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail>
    {
        static constexpr guid value{ 0xDB037FFA,0x0068,0x412C,{ 0x9C,0x83,0x26,0x7C,0x37,0xF6,0x56,0x70 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail2>
    {
        static constexpr guid value{ 0x0B36E982,0xC871,0x49FB,{ 0xBA,0xBB,0x25,0xBD,0xBC,0x4C,0xC4,0x5B } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationManagerForUser>
    {
        static constexpr guid value{ 0x79AB57F6,0x43FE,0x487B,{ 0x8A,0x7F,0x99,0x56,0x72,0x00,0xAE,0x94 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationManagerForUser2>
    {
        static constexpr guid value{ 0x679C64B7,0x81AB,0x42C2,{ 0x88,0x19,0xC9,0x58,0x76,0x77,0x53,0xF4 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationManagerStatics>
    {
        static constexpr guid value{ 0x50AC103F,0xD235,0x4598,{ 0xBB,0xEF,0x98,0xFE,0x4D,0x1A,0x3A,0xD4 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationManagerStatics2>
    {
        static constexpr guid value{ 0x7AB93C52,0x0E48,0x4750,{ 0xBA,0x9D,0x1A,0x41,0x13,0x98,0x18,0x47 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationManagerStatics4>
    {
        static constexpr guid value{ 0x8F993FD3,0xE516,0x45FB,{ 0x81,0x30,0x39,0x8E,0x93,0xFA,0x52,0xC3 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotificationManagerStatics5>
    {
        static constexpr guid value{ 0xD6F5F569,0xD40D,0x407C,{ 0x89,0x89,0x88,0xCA,0xB4,0x2C,0xFD,0x14 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotifier>
    {
        static constexpr guid value{ 0x75927B93,0x03F3,0x41EC,{ 0x91,0xD3,0x6E,0x5B,0xAC,0x1B,0x38,0xE7 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotifier2>
    {
        static constexpr guid value{ 0x354389C6,0x7C01,0x4BD5,{ 0x9C,0x20,0x60,0x43,0x40,0xCD,0x2B,0x74 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IToastNotifier3>
    {
        static constexpr guid value{ 0xAE75A04A,0x3B0C,0x51AD,{ 0xB7,0xE8,0xB0,0x8A,0xB6,0x05,0x25,0x49 } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IUserNotification>
    {
        static constexpr guid value{ 0xADF7E52F,0x4E53,0x42D5,{ 0x9C,0x33,0xEB,0x5E,0xA5,0x15,0xB2,0x3E } };
    };
    template <> struct guid_storage<Windows::UI::Notifications::IUserNotificationChangedEventArgs>
    {
        static constexpr guid value{ 0xB6BD6839,0x79CF,0x4B25,{ 0x82,0xC0,0x0C,0xE1,0xEE,0xF8,0x1F,0x8C } };
    };
    template <> struct default_interface<Windows::UI::Notifications::AdaptiveNotificationText>
    {
        using type = Windows::UI::Notifications::IAdaptiveNotificationText;
    };
    template <> struct default_interface<Windows::UI::Notifications::BadgeNotification>
    {
        using type = Windows::UI::Notifications::IBadgeNotification;
    };
    template <> struct default_interface<Windows::UI::Notifications::BadgeUpdateManagerForUser>
    {
        using type = Windows::UI::Notifications::IBadgeUpdateManagerForUser;
    };
    template <> struct default_interface<Windows::UI::Notifications::BadgeUpdater>
    {
        using type = Windows::UI::Notifications::IBadgeUpdater;
    };
    template <> struct default_interface<Windows::UI::Notifications::Notification>
    {
        using type = Windows::UI::Notifications::INotification;
    };
    template <> struct default_interface<Windows::UI::Notifications::NotificationBinding>
    {
        using type = Windows::UI::Notifications::INotificationBinding;
    };
    template <> struct default_interface<Windows::UI::Notifications::NotificationData>
    {
        using type = Windows::UI::Notifications::INotificationData;
    };
    template <> struct default_interface<Windows::UI::Notifications::NotificationVisual>
    {
        using type = Windows::UI::Notifications::INotificationVisual;
    };
    template <> struct default_interface<Windows::UI::Notifications::ScheduledTileNotification>
    {
        using type = Windows::UI::Notifications::IScheduledTileNotification;
    };
    template <> struct default_interface<Windows::UI::Notifications::ScheduledToastNotification>
    {
        using type = Windows::UI::Notifications::IScheduledToastNotification;
    };
    template <> struct default_interface<Windows::UI::Notifications::ScheduledToastNotificationShowingEventArgs>
    {
        using type = Windows::UI::Notifications::IScheduledToastNotificationShowingEventArgs;
    };
    template <> struct default_interface<Windows::UI::Notifications::ShownTileNotification>
    {
        using type = Windows::UI::Notifications::IShownTileNotification;
    };
    template <> struct default_interface<Windows::UI::Notifications::TileFlyoutNotification>
    {
        using type = Windows::UI::Notifications::ITileFlyoutNotification;
    };
    template <> struct default_interface<Windows::UI::Notifications::TileFlyoutUpdater>
    {
        using type = Windows::UI::Notifications::ITileFlyoutUpdater;
    };
    template <> struct default_interface<Windows::UI::Notifications::TileNotification>
    {
        using type = Windows::UI::Notifications::ITileNotification;
    };
    template <> struct default_interface<Windows::UI::Notifications::TileUpdateManagerForUser>
    {
        using type = Windows::UI::Notifications::ITileUpdateManagerForUser;
    };
    template <> struct default_interface<Windows::UI::Notifications::TileUpdater>
    {
        using type = Windows::UI::Notifications::ITileUpdater;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastActivatedEventArgs>
    {
        using type = Windows::UI::Notifications::IToastActivatedEventArgs;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastCollection>
    {
        using type = Windows::UI::Notifications::IToastCollection;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastCollectionManager>
    {
        using type = Windows::UI::Notifications::IToastCollectionManager;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastDismissedEventArgs>
    {
        using type = Windows::UI::Notifications::IToastDismissedEventArgs;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastFailedEventArgs>
    {
        using type = Windows::UI::Notifications::IToastFailedEventArgs;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastNotification>
    {
        using type = Windows::UI::Notifications::IToastNotification;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastNotificationActionTriggerDetail>
    {
        using type = Windows::UI::Notifications::IToastNotificationActionTriggerDetail;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastNotificationHistory>
    {
        using type = Windows::UI::Notifications::IToastNotificationHistory;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastNotificationHistoryChangedTriggerDetail>
    {
        using type = Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastNotificationManagerForUser>
    {
        using type = Windows::UI::Notifications::IToastNotificationManagerForUser;
    };
    template <> struct default_interface<Windows::UI::Notifications::ToastNotifier>
    {
        using type = Windows::UI::Notifications::IToastNotifier;
    };
    template <> struct default_interface<Windows::UI::Notifications::UserNotification>
    {
        using type = Windows::UI::Notifications::IUserNotification;
    };
    template <> struct default_interface<Windows::UI::Notifications::UserNotificationChangedEventArgs>
    {
        using type = Windows::UI::Notifications::IUserNotificationChangedEventArgs;
    };
    template <> struct abi<Windows::UI::Notifications::IAdaptiveNotificationContent>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Kind(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Hints(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IAdaptiveNotificationText>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Text(void**) noexcept = 0;
            virtual int32_t __stdcall put_Text(void*) noexcept = 0;
            virtual int32_t __stdcall get_Language(void**) noexcept = 0;
            virtual int32_t __stdcall put_Language(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IBadgeNotification>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Content(void**) noexcept = 0;
            virtual int32_t __stdcall put_ExpirationTime(void*) noexcept = 0;
            virtual int32_t __stdcall get_ExpirationTime(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IBadgeNotificationFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateBadgeNotification(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IBadgeUpdateManagerForUser>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateBadgeUpdaterForApplication(void**) noexcept = 0;
            virtual int32_t __stdcall CreateBadgeUpdaterForApplicationWithId(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateBadgeUpdaterForSecondaryTile(void*, void**) noexcept = 0;
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IBadgeUpdateManagerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateBadgeUpdaterForApplication(void**) noexcept = 0;
            virtual int32_t __stdcall CreateBadgeUpdaterForApplicationWithId(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateBadgeUpdaterForSecondaryTile(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetTemplateContent(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IBadgeUpdateManagerStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetForUser(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IBadgeUpdater>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Update(void*) noexcept = 0;
            virtual int32_t __stdcall Clear() noexcept = 0;
            virtual int32_t __stdcall StartPeriodicUpdate(void*, int32_t) noexcept = 0;
            virtual int32_t __stdcall StartPeriodicUpdateAtTime(void*, int64_t, int32_t) noexcept = 0;
            virtual int32_t __stdcall StopPeriodicUpdate() noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IKnownAdaptiveNotificationHintsStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Style(void**) noexcept = 0;
            virtual int32_t __stdcall get_Wrap(void**) noexcept = 0;
            virtual int32_t __stdcall get_MaxLines(void**) noexcept = 0;
            virtual int32_t __stdcall get_MinLines(void**) noexcept = 0;
            virtual int32_t __stdcall get_TextStacking(void**) noexcept = 0;
            virtual int32_t __stdcall get_Align(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IKnownAdaptiveNotificationTextStylesStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Caption(void**) noexcept = 0;
            virtual int32_t __stdcall get_Body(void**) noexcept = 0;
            virtual int32_t __stdcall get_Base(void**) noexcept = 0;
            virtual int32_t __stdcall get_Subtitle(void**) noexcept = 0;
            virtual int32_t __stdcall get_Title(void**) noexcept = 0;
            virtual int32_t __stdcall get_Subheader(void**) noexcept = 0;
            virtual int32_t __stdcall get_Header(void**) noexcept = 0;
            virtual int32_t __stdcall get_TitleNumeral(void**) noexcept = 0;
            virtual int32_t __stdcall get_SubheaderNumeral(void**) noexcept = 0;
            virtual int32_t __stdcall get_HeaderNumeral(void**) noexcept = 0;
            virtual int32_t __stdcall get_CaptionSubtle(void**) noexcept = 0;
            virtual int32_t __stdcall get_BodySubtle(void**) noexcept = 0;
            virtual int32_t __stdcall get_BaseSubtle(void**) noexcept = 0;
            virtual int32_t __stdcall get_SubtitleSubtle(void**) noexcept = 0;
            virtual int32_t __stdcall get_TitleSubtle(void**) noexcept = 0;
            virtual int32_t __stdcall get_SubheaderSubtle(void**) noexcept = 0;
            virtual int32_t __stdcall get_SubheaderNumeralSubtle(void**) noexcept = 0;
            virtual int32_t __stdcall get_HeaderSubtle(void**) noexcept = 0;
            virtual int32_t __stdcall get_HeaderNumeralSubtle(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IKnownNotificationBindingsStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ToastGeneric(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::INotification>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ExpirationTime(void**) noexcept = 0;
            virtual int32_t __stdcall put_ExpirationTime(void*) noexcept = 0;
            virtual int32_t __stdcall get_Visual(void**) noexcept = 0;
            virtual int32_t __stdcall put_Visual(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::INotificationBinding>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Template(void**) noexcept = 0;
            virtual int32_t __stdcall put_Template(void*) noexcept = 0;
            virtual int32_t __stdcall get_Language(void**) noexcept = 0;
            virtual int32_t __stdcall put_Language(void*) noexcept = 0;
            virtual int32_t __stdcall get_Hints(void**) noexcept = 0;
            virtual int32_t __stdcall GetTextElements(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::INotificationData>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Values(void**) noexcept = 0;
            virtual int32_t __stdcall get_SequenceNumber(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall put_SequenceNumber(uint32_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::INotificationDataFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateNotificationDataWithValuesAndSequenceNumber(void*, uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateNotificationDataWithValues(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::INotificationVisual>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Language(void**) noexcept = 0;
            virtual int32_t __stdcall put_Language(void*) noexcept = 0;
            virtual int32_t __stdcall get_Bindings(void**) noexcept = 0;
            virtual int32_t __stdcall GetBinding(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IScheduledTileNotification>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Content(void**) noexcept = 0;
            virtual int32_t __stdcall get_DeliveryTime(int64_t*) noexcept = 0;
            virtual int32_t __stdcall put_ExpirationTime(void*) noexcept = 0;
            virtual int32_t __stdcall get_ExpirationTime(void**) noexcept = 0;
            virtual int32_t __stdcall put_Tag(void*) noexcept = 0;
            virtual int32_t __stdcall get_Tag(void**) noexcept = 0;
            virtual int32_t __stdcall put_Id(void*) noexcept = 0;
            virtual int32_t __stdcall get_Id(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IScheduledTileNotificationFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateScheduledTileNotification(void*, int64_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IScheduledToastNotification>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Content(void**) noexcept = 0;
            virtual int32_t __stdcall get_DeliveryTime(int64_t*) noexcept = 0;
            virtual int32_t __stdcall get_SnoozeInterval(void**) noexcept = 0;
            virtual int32_t __stdcall get_MaximumSnoozeCount(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall put_Id(void*) noexcept = 0;
            virtual int32_t __stdcall get_Id(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IScheduledToastNotification2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall put_Tag(void*) noexcept = 0;
            virtual int32_t __stdcall get_Tag(void**) noexcept = 0;
            virtual int32_t __stdcall put_Group(void*) noexcept = 0;
            virtual int32_t __stdcall get_Group(void**) noexcept = 0;
            virtual int32_t __stdcall put_SuppressPopup(bool) noexcept = 0;
            virtual int32_t __stdcall get_SuppressPopup(bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IScheduledToastNotification3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_NotificationMirroring(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_NotificationMirroring(int32_t) noexcept = 0;
            virtual int32_t __stdcall get_RemoteId(void**) noexcept = 0;
            virtual int32_t __stdcall put_RemoteId(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IScheduledToastNotification4>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ExpirationTime(void**) noexcept = 0;
            virtual int32_t __stdcall put_ExpirationTime(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IScheduledToastNotificationFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateScheduledToastNotification(void*, int64_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateScheduledToastNotificationRecurring(void*, int64_t, int64_t, uint32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IScheduledToastNotificationShowingEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Cancel(bool*) noexcept = 0;
            virtual int32_t __stdcall put_Cancel(bool) noexcept = 0;
            virtual int32_t __stdcall get_ScheduledToastNotification(void**) noexcept = 0;
            virtual int32_t __stdcall GetDeferral(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IShownTileNotification>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Arguments(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileFlyoutNotification>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Content(void**) noexcept = 0;
            virtual int32_t __stdcall put_ExpirationTime(void*) noexcept = 0;
            virtual int32_t __stdcall get_ExpirationTime(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileFlyoutNotificationFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateTileFlyoutNotification(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileFlyoutUpdateManagerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateTileFlyoutUpdaterForApplication(void**) noexcept = 0;
            virtual int32_t __stdcall CreateTileFlyoutUpdaterForApplicationWithId(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateTileFlyoutUpdaterForSecondaryTile(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetTemplateContent(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileFlyoutUpdater>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Update(void*) noexcept = 0;
            virtual int32_t __stdcall Clear() noexcept = 0;
            virtual int32_t __stdcall StartPeriodicUpdate(void*, int32_t) noexcept = 0;
            virtual int32_t __stdcall StartPeriodicUpdateAtTime(void*, int64_t, int32_t) noexcept = 0;
            virtual int32_t __stdcall StopPeriodicUpdate() noexcept = 0;
            virtual int32_t __stdcall get_Setting(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileNotification>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Content(void**) noexcept = 0;
            virtual int32_t __stdcall put_ExpirationTime(void*) noexcept = 0;
            virtual int32_t __stdcall get_ExpirationTime(void**) noexcept = 0;
            virtual int32_t __stdcall put_Tag(void*) noexcept = 0;
            virtual int32_t __stdcall get_Tag(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileNotificationFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateTileNotification(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileUpdateManagerForUser>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateTileUpdaterForApplication(void**) noexcept = 0;
            virtual int32_t __stdcall CreateTileUpdaterForApplicationWithId(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateTileUpdaterForSecondaryTile(void*, void**) noexcept = 0;
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileUpdateManagerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateTileUpdaterForApplication(void**) noexcept = 0;
            virtual int32_t __stdcall CreateTileUpdaterForApplicationWithId(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateTileUpdaterForSecondaryTile(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetTemplateContent(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileUpdateManagerStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetForUser(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileUpdater>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Update(void*) noexcept = 0;
            virtual int32_t __stdcall Clear() noexcept = 0;
            virtual int32_t __stdcall EnableNotificationQueue(bool) noexcept = 0;
            virtual int32_t __stdcall get_Setting(int32_t*) noexcept = 0;
            virtual int32_t __stdcall AddToSchedule(void*) noexcept = 0;
            virtual int32_t __stdcall RemoveFromSchedule(void*) noexcept = 0;
            virtual int32_t __stdcall GetScheduledTileNotifications(void**) noexcept = 0;
            virtual int32_t __stdcall StartPeriodicUpdate(void*, int32_t) noexcept = 0;
            virtual int32_t __stdcall StartPeriodicUpdateAtTime(void*, int64_t, int32_t) noexcept = 0;
            virtual int32_t __stdcall StopPeriodicUpdate() noexcept = 0;
            virtual int32_t __stdcall StartPeriodicUpdateBatch(void*, int32_t) noexcept = 0;
            virtual int32_t __stdcall StartPeriodicUpdateBatchAtTime(void*, int64_t, int32_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::ITileUpdater2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall EnableNotificationQueueForSquare150x150(bool) noexcept = 0;
            virtual int32_t __stdcall EnableNotificationQueueForWide310x150(bool) noexcept = 0;
            virtual int32_t __stdcall EnableNotificationQueueForSquare310x310(bool) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastActivatedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Arguments(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastActivatedEventArgs2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_UserInput(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastCollection>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Id(void**) noexcept = 0;
            virtual int32_t __stdcall get_DisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall put_DisplayName(void*) noexcept = 0;
            virtual int32_t __stdcall get_LaunchArgs(void**) noexcept = 0;
            virtual int32_t __stdcall put_LaunchArgs(void*) noexcept = 0;
            virtual int32_t __stdcall get_Icon(void**) noexcept = 0;
            virtual int32_t __stdcall put_Icon(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastCollectionFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateInstance(void*, void*, void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastCollectionManager>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall SaveToastCollectionAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall FindAllToastCollectionsAsync(void**) noexcept = 0;
            virtual int32_t __stdcall GetToastCollectionAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall RemoveToastCollectionAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall RemoveAllToastCollectionsAsync(void**) noexcept = 0;
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
            virtual int32_t __stdcall get_AppId(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastDismissedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Reason(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastFailedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ErrorCode(winrt::hresult*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotification>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Content(void**) noexcept = 0;
            virtual int32_t __stdcall put_ExpirationTime(void*) noexcept = 0;
            virtual int32_t __stdcall get_ExpirationTime(void**) noexcept = 0;
            virtual int32_t __stdcall add_Dismissed(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Dismissed(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Activated(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Activated(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall add_Failed(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_Failed(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotification2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall put_Tag(void*) noexcept = 0;
            virtual int32_t __stdcall get_Tag(void**) noexcept = 0;
            virtual int32_t __stdcall put_Group(void*) noexcept = 0;
            virtual int32_t __stdcall get_Group(void**) noexcept = 0;
            virtual int32_t __stdcall put_SuppressPopup(bool) noexcept = 0;
            virtual int32_t __stdcall get_SuppressPopup(bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotification3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_NotificationMirroring(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_NotificationMirroring(int32_t) noexcept = 0;
            virtual int32_t __stdcall get_RemoteId(void**) noexcept = 0;
            virtual int32_t __stdcall put_RemoteId(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotification4>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Data(void**) noexcept = 0;
            virtual int32_t __stdcall put_Data(void*) noexcept = 0;
            virtual int32_t __stdcall get_Priority(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_Priority(int32_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotification6>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ExpiresOnReboot(bool*) noexcept = 0;
            virtual int32_t __stdcall put_ExpiresOnReboot(bool) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationActionTriggerDetail>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Argument(void**) noexcept = 0;
            virtual int32_t __stdcall get_UserInput(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateToastNotification(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationHistory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall RemoveGroup(void*) noexcept = 0;
            virtual int32_t __stdcall RemoveGroupWithId(void*, void*) noexcept = 0;
            virtual int32_t __stdcall RemoveGroupedTagWithId(void*, void*, void*) noexcept = 0;
            virtual int32_t __stdcall RemoveGroupedTag(void*, void*) noexcept = 0;
            virtual int32_t __stdcall Remove(void*) noexcept = 0;
            virtual int32_t __stdcall Clear() noexcept = 0;
            virtual int32_t __stdcall ClearWithId(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationHistory2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetHistory(void**) noexcept = 0;
            virtual int32_t __stdcall GetHistoryWithId(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ChangeType(int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_CollectionId(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationManagerForUser>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateToastNotifier(void**) noexcept = 0;
            virtual int32_t __stdcall CreateToastNotifierWithId(void*, void**) noexcept = 0;
            virtual int32_t __stdcall get_History(void**) noexcept = 0;
            virtual int32_t __stdcall get_User(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationManagerForUser2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetToastNotifierForToastCollectionIdAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetHistoryForToastCollectionIdAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetToastCollectionManager(void**) noexcept = 0;
            virtual int32_t __stdcall GetToastCollectionManagerWithAppId(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationManagerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateToastNotifier(void**) noexcept = 0;
            virtual int32_t __stdcall CreateToastNotifierWithId(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetTemplateContent(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationManagerStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_History(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationManagerStatics4>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetForUser(void*, void**) noexcept = 0;
            virtual int32_t __stdcall ConfigureNotificationMirroring(int32_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotificationManagerStatics5>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetDefault(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotifier>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Show(void*) noexcept = 0;
            virtual int32_t __stdcall Hide(void*) noexcept = 0;
            virtual int32_t __stdcall get_Setting(int32_t*) noexcept = 0;
            virtual int32_t __stdcall AddToSchedule(void*) noexcept = 0;
            virtual int32_t __stdcall RemoveFromSchedule(void*) noexcept = 0;
            virtual int32_t __stdcall GetScheduledToastNotifications(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotifier2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall UpdateWithTagAndGroup(void*, void*, void*, int32_t*) noexcept = 0;
            virtual int32_t __stdcall UpdateWithTag(void*, void*, int32_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IToastNotifier3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall add_ScheduledToastNotificationShowing(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_ScheduledToastNotificationShowing(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IUserNotification>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Notification(void**) noexcept = 0;
            virtual int32_t __stdcall get_AppInfo(void**) noexcept = 0;
            virtual int32_t __stdcall get_Id(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall get_CreationTime(int64_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::UI::Notifications::IUserNotificationChangedEventArgs>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ChangeKind(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_UserNotificationId(uint32_t*) noexcept = 0;
        };
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IAdaptiveNotificationContent
    {
        [[nodiscard]] auto Kind() const;
        [[nodiscard]] auto Hints() const;
    };
    template <> struct consume<Windows::UI::Notifications::IAdaptiveNotificationContent>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IAdaptiveNotificationContent<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IAdaptiveNotificationText
    {
        [[nodiscard]] auto Text() const;
        auto Text(param::hstring const& value) const;
        [[nodiscard]] auto Language() const;
        auto Language(param::hstring const& value) const;
    };
    template <> struct consume<Windows::UI::Notifications::IAdaptiveNotificationText>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IAdaptiveNotificationText<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IBadgeNotification
    {
        [[nodiscard]] auto Content() const;
        auto ExpirationTime(Windows::Foundation::IReference<Windows::Foundation::DateTime> const& value) const;
        [[nodiscard]] auto ExpirationTime() const;
    };
    template <> struct consume<Windows::UI::Notifications::IBadgeNotification>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IBadgeNotification<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IBadgeNotificationFactory
    {
        auto CreateBadgeNotification(Windows::Data::Xml::Dom::XmlDocument const& content) const;
    };
    template <> struct consume<Windows::UI::Notifications::IBadgeNotificationFactory>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IBadgeNotificationFactory<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IBadgeUpdateManagerForUser
    {
        auto CreateBadgeUpdaterForApplication() const;
        auto CreateBadgeUpdaterForApplication(param::hstring const& applicationId) const;
        auto CreateBadgeUpdaterForSecondaryTile(param::hstring const& tileId) const;
        [[nodiscard]] auto User() const;
    };
    template <> struct consume<Windows::UI::Notifications::IBadgeUpdateManagerForUser>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IBadgeUpdateManagerForUser<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IBadgeUpdateManagerStatics
    {
        auto CreateBadgeUpdaterForApplication() const;
        auto CreateBadgeUpdaterForApplication(param::hstring const& applicationId) const;
        auto CreateBadgeUpdaterForSecondaryTile(param::hstring const& tileId) const;
        auto GetTemplateContent(Windows::UI::Notifications::BadgeTemplateType const& type) const;
    };
    template <> struct consume<Windows::UI::Notifications::IBadgeUpdateManagerStatics>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IBadgeUpdateManagerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IBadgeUpdateManagerStatics2
    {
        auto GetForUser(Windows::System::User const& user) const;
    };
    template <> struct consume<Windows::UI::Notifications::IBadgeUpdateManagerStatics2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IBadgeUpdateManagerStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IBadgeUpdater
    {
        auto Update(Windows::UI::Notifications::BadgeNotification const& notification) const;
        auto Clear() const;
        auto StartPeriodicUpdate(Windows::Foundation::Uri const& badgeContent, Windows::UI::Notifications::PeriodicUpdateRecurrence const& requestedInterval) const;
        auto StartPeriodicUpdate(Windows::Foundation::Uri const& badgeContent, Windows::Foundation::DateTime const& startTime, Windows::UI::Notifications::PeriodicUpdateRecurrence const& requestedInterval) const;
        auto StopPeriodicUpdate() const;
    };
    template <> struct consume<Windows::UI::Notifications::IBadgeUpdater>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IBadgeUpdater<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IKnownAdaptiveNotificationHintsStatics
    {
        [[nodiscard]] auto Style() const;
        [[nodiscard]] auto Wrap() const;
        [[nodiscard]] auto MaxLines() const;
        [[nodiscard]] auto MinLines() const;
        [[nodiscard]] auto TextStacking() const;
        [[nodiscard]] auto Align() const;
    };
    template <> struct consume<Windows::UI::Notifications::IKnownAdaptiveNotificationHintsStatics>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IKnownAdaptiveNotificationHintsStatics<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IKnownAdaptiveNotificationTextStylesStatics
    {
        [[nodiscard]] auto Caption() const;
        [[nodiscard]] auto Body() const;
        [[nodiscard]] auto Base() const;
        [[nodiscard]] auto Subtitle() const;
        [[nodiscard]] auto Title() const;
        [[nodiscard]] auto Subheader() const;
        [[nodiscard]] auto Header() const;
        [[nodiscard]] auto TitleNumeral() const;
        [[nodiscard]] auto SubheaderNumeral() const;
        [[nodiscard]] auto HeaderNumeral() const;
        [[nodiscard]] auto CaptionSubtle() const;
        [[nodiscard]] auto BodySubtle() const;
        [[nodiscard]] auto BaseSubtle() const;
        [[nodiscard]] auto SubtitleSubtle() const;
        [[nodiscard]] auto TitleSubtle() const;
        [[nodiscard]] auto SubheaderSubtle() const;
        [[nodiscard]] auto SubheaderNumeralSubtle() const;
        [[nodiscard]] auto HeaderSubtle() const;
        [[nodiscard]] auto HeaderNumeralSubtle() const;
    };
    template <> struct consume<Windows::UI::Notifications::IKnownAdaptiveNotificationTextStylesStatics>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IKnownAdaptiveNotificationTextStylesStatics<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IKnownNotificationBindingsStatics
    {
        [[nodiscard]] auto ToastGeneric() const;
    };
    template <> struct consume<Windows::UI::Notifications::IKnownNotificationBindingsStatics>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IKnownNotificationBindingsStatics<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_INotification
    {
        [[nodiscard]] auto ExpirationTime() const;
        auto ExpirationTime(Windows::Foundation::IReference<Windows::Foundation::DateTime> const& value) const;
        [[nodiscard]] auto Visual() const;
        auto Visual(Windows::UI::Notifications::NotificationVisual const& value) const;
    };
    template <> struct consume<Windows::UI::Notifications::INotification>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_INotification<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_INotificationBinding
    {
        [[nodiscard]] auto Template() const;
        auto Template(param::hstring const& value) const;
        [[nodiscard]] auto Language() const;
        auto Language(param::hstring const& value) const;
        [[nodiscard]] auto Hints() const;
        auto GetTextElements() const;
    };
    template <> struct consume<Windows::UI::Notifications::INotificationBinding>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_INotificationBinding<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_INotificationData
    {
        [[nodiscard]] auto Values() const;
        [[nodiscard]] auto SequenceNumber() const;
        auto SequenceNumber(uint32_t value) const;
    };
    template <> struct consume<Windows::UI::Notifications::INotificationData>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_INotificationData<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_INotificationDataFactory
    {
        auto CreateNotificationData(param::iterable<Windows::Foundation::Collections::IKeyValuePair<hstring, hstring>> const& initialValues, uint32_t sequenceNumber) const;
        auto CreateNotificationData(param::iterable<Windows::Foundation::Collections::IKeyValuePair<hstring, hstring>> const& initialValues) const;
    };
    template <> struct consume<Windows::UI::Notifications::INotificationDataFactory>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_INotificationDataFactory<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_INotificationVisual
    {
        [[nodiscard]] auto Language() const;
        auto Language(param::hstring const& value) const;
        [[nodiscard]] auto Bindings() const;
        auto GetBinding(param::hstring const& templateName) const;
    };
    template <> struct consume<Windows::UI::Notifications::INotificationVisual>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_INotificationVisual<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IScheduledTileNotification
    {
        [[nodiscard]] auto Content() const;
        [[nodiscard]] auto DeliveryTime() const;
        auto ExpirationTime(Windows::Foundation::IReference<Windows::Foundation::DateTime> const& value) const;
        [[nodiscard]] auto ExpirationTime() const;
        auto Tag(param::hstring const& value) const;
        [[nodiscard]] auto Tag() const;
        auto Id(param::hstring const& value) const;
        [[nodiscard]] auto Id() const;
    };
    template <> struct consume<Windows::UI::Notifications::IScheduledTileNotification>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IScheduledTileNotification<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IScheduledTileNotificationFactory
    {
        auto CreateScheduledTileNotification(Windows::Data::Xml::Dom::XmlDocument const& content, Windows::Foundation::DateTime const& deliveryTime) const;
    };
    template <> struct consume<Windows::UI::Notifications::IScheduledTileNotificationFactory>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IScheduledTileNotificationFactory<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IScheduledToastNotification
    {
        [[nodiscard]] auto Content() const;
        [[nodiscard]] auto DeliveryTime() const;
        [[nodiscard]] auto SnoozeInterval() const;
        [[nodiscard]] auto MaximumSnoozeCount() const;
        auto Id(param::hstring const& value) const;
        [[nodiscard]] auto Id() const;
    };
    template <> struct consume<Windows::UI::Notifications::IScheduledToastNotification>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IScheduledToastNotification<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IScheduledToastNotification2
    {
        auto Tag(param::hstring const& value) const;
        [[nodiscard]] auto Tag() const;
        auto Group(param::hstring const& value) const;
        [[nodiscard]] auto Group() const;
        auto SuppressPopup(bool value) const;
        [[nodiscard]] auto SuppressPopup() const;
    };
    template <> struct consume<Windows::UI::Notifications::IScheduledToastNotification2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IScheduledToastNotification2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IScheduledToastNotification3
    {
        [[nodiscard]] auto NotificationMirroring() const;
        auto NotificationMirroring(Windows::UI::Notifications::NotificationMirroring const& value) const;
        [[nodiscard]] auto RemoteId() const;
        auto RemoteId(param::hstring const& value) const;
    };
    template <> struct consume<Windows::UI::Notifications::IScheduledToastNotification3>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IScheduledToastNotification3<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IScheduledToastNotification4
    {
        [[nodiscard]] auto ExpirationTime() const;
        auto ExpirationTime(Windows::Foundation::IReference<Windows::Foundation::DateTime> const& value) const;
    };
    template <> struct consume<Windows::UI::Notifications::IScheduledToastNotification4>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IScheduledToastNotification4<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IScheduledToastNotificationFactory
    {
        auto CreateScheduledToastNotification(Windows::Data::Xml::Dom::XmlDocument const& content, Windows::Foundation::DateTime const& deliveryTime) const;
        auto CreateScheduledToastNotificationRecurring(Windows::Data::Xml::Dom::XmlDocument const& content, Windows::Foundation::DateTime const& deliveryTime, Windows::Foundation::TimeSpan const& snoozeInterval, uint32_t maximumSnoozeCount) const;
    };
    template <> struct consume<Windows::UI::Notifications::IScheduledToastNotificationFactory>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IScheduledToastNotificationFactory<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IScheduledToastNotificationShowingEventArgs
    {
        [[nodiscard]] auto Cancel() const;
        auto Cancel(bool value) const;
        [[nodiscard]] auto ScheduledToastNotification() const;
        auto GetDeferral() const;
    };
    template <> struct consume<Windows::UI::Notifications::IScheduledToastNotificationShowingEventArgs>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IScheduledToastNotificationShowingEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IShownTileNotification
    {
        [[nodiscard]] auto Arguments() const;
    };
    template <> struct consume<Windows::UI::Notifications::IShownTileNotification>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IShownTileNotification<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileFlyoutNotification
    {
        [[nodiscard]] auto Content() const;
        auto ExpirationTime(Windows::Foundation::IReference<Windows::Foundation::DateTime> const& value) const;
        [[nodiscard]] auto ExpirationTime() const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileFlyoutNotification>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileFlyoutNotification<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileFlyoutNotificationFactory
    {
        auto CreateTileFlyoutNotification(Windows::Data::Xml::Dom::XmlDocument const& content) const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileFlyoutNotificationFactory>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileFlyoutNotificationFactory<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileFlyoutUpdateManagerStatics
    {
        auto CreateTileFlyoutUpdaterForApplication() const;
        auto CreateTileFlyoutUpdaterForApplication(param::hstring const& applicationId) const;
        auto CreateTileFlyoutUpdaterForSecondaryTile(param::hstring const& tileId) const;
        auto GetTemplateContent(Windows::UI::Notifications::TileFlyoutTemplateType const& type) const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileFlyoutUpdateManagerStatics>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileFlyoutUpdateManagerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileFlyoutUpdater
    {
        auto Update(Windows::UI::Notifications::TileFlyoutNotification const& notification) const;
        auto Clear() const;
        auto StartPeriodicUpdate(Windows::Foundation::Uri const& tileFlyoutContent, Windows::UI::Notifications::PeriodicUpdateRecurrence const& requestedInterval) const;
        auto StartPeriodicUpdate(Windows::Foundation::Uri const& tileFlyoutContent, Windows::Foundation::DateTime const& startTime, Windows::UI::Notifications::PeriodicUpdateRecurrence const& requestedInterval) const;
        auto StopPeriodicUpdate() const;
        [[nodiscard]] auto Setting() const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileFlyoutUpdater>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileFlyoutUpdater<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileNotification
    {
        [[nodiscard]] auto Content() const;
        auto ExpirationTime(Windows::Foundation::IReference<Windows::Foundation::DateTime> const& value) const;
        [[nodiscard]] auto ExpirationTime() const;
        auto Tag(param::hstring const& value) const;
        [[nodiscard]] auto Tag() const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileNotification>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileNotification<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileNotificationFactory
    {
        auto CreateTileNotification(Windows::Data::Xml::Dom::XmlDocument const& content) const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileNotificationFactory>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileNotificationFactory<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileUpdateManagerForUser
    {
        auto CreateTileUpdaterForApplicationForUser() const;
        auto CreateTileUpdaterForApplication(param::hstring const& applicationId) const;
        auto CreateTileUpdaterForSecondaryTile(param::hstring const& tileId) const;
        [[nodiscard]] auto User() const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileUpdateManagerForUser>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileUpdateManagerForUser<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileUpdateManagerStatics
    {
        auto CreateTileUpdaterForApplication() const;
        auto CreateTileUpdaterForApplication(param::hstring const& applicationId) const;
        auto CreateTileUpdaterForSecondaryTile(param::hstring const& tileId) const;
        auto GetTemplateContent(Windows::UI::Notifications::TileTemplateType const& type) const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileUpdateManagerStatics>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileUpdateManagerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileUpdateManagerStatics2
    {
        auto GetForUser(Windows::System::User const& user) const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileUpdateManagerStatics2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileUpdateManagerStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileUpdater
    {
        auto Update(Windows::UI::Notifications::TileNotification const& notification) const;
        auto Clear() const;
        auto EnableNotificationQueue(bool enable) const;
        [[nodiscard]] auto Setting() const;
        auto AddToSchedule(Windows::UI::Notifications::ScheduledTileNotification const& scheduledTile) const;
        auto RemoveFromSchedule(Windows::UI::Notifications::ScheduledTileNotification const& scheduledTile) const;
        auto GetScheduledTileNotifications() const;
        auto StartPeriodicUpdate(Windows::Foundation::Uri const& tileContent, Windows::UI::Notifications::PeriodicUpdateRecurrence const& requestedInterval) const;
        auto StartPeriodicUpdate(Windows::Foundation::Uri const& tileContent, Windows::Foundation::DateTime const& startTime, Windows::UI::Notifications::PeriodicUpdateRecurrence const& requestedInterval) const;
        auto StopPeriodicUpdate() const;
        auto StartPeriodicUpdateBatch(param::iterable<Windows::Foundation::Uri> const& tileContents, Windows::UI::Notifications::PeriodicUpdateRecurrence const& requestedInterval) const;
        auto StartPeriodicUpdateBatch(param::iterable<Windows::Foundation::Uri> const& tileContents, Windows::Foundation::DateTime const& startTime, Windows::UI::Notifications::PeriodicUpdateRecurrence const& requestedInterval) const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileUpdater>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileUpdater<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_ITileUpdater2
    {
        auto EnableNotificationQueueForSquare150x150(bool enable) const;
        auto EnableNotificationQueueForWide310x150(bool enable) const;
        auto EnableNotificationQueueForSquare310x310(bool enable) const;
    };
    template <> struct consume<Windows::UI::Notifications::ITileUpdater2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_ITileUpdater2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastActivatedEventArgs
    {
        [[nodiscard]] auto Arguments() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastActivatedEventArgs>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastActivatedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastActivatedEventArgs2
    {
        [[nodiscard]] auto UserInput() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastActivatedEventArgs2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastActivatedEventArgs2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastCollection
    {
        [[nodiscard]] auto Id() const;
        [[nodiscard]] auto DisplayName() const;
        auto DisplayName(param::hstring const& value) const;
        [[nodiscard]] auto LaunchArgs() const;
        auto LaunchArgs(param::hstring const& value) const;
        [[nodiscard]] auto Icon() const;
        auto Icon(Windows::Foundation::Uri const& value) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastCollection>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastCollection<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastCollectionFactory
    {
        auto CreateInstance(param::hstring const& collectionId, param::hstring const& displayName, param::hstring const& launchArgs, Windows::Foundation::Uri const& iconUri) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastCollectionFactory>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastCollectionFactory<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastCollectionManager
    {
        auto SaveToastCollectionAsync(Windows::UI::Notifications::ToastCollection const& collection) const;
        auto FindAllToastCollectionsAsync() const;
        auto GetToastCollectionAsync(param::hstring const& collectionId) const;
        auto RemoveToastCollectionAsync(param::hstring const& collectionId) const;
        auto RemoveAllToastCollectionsAsync() const;
        [[nodiscard]] auto User() const;
        [[nodiscard]] auto AppId() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastCollectionManager>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastCollectionManager<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastDismissedEventArgs
    {
        [[nodiscard]] auto Reason() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastDismissedEventArgs>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastDismissedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastFailedEventArgs
    {
        [[nodiscard]] auto ErrorCode() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastFailedEventArgs>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastFailedEventArgs<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotification
    {
        [[nodiscard]] auto Content() const;
        auto ExpirationTime(Windows::Foundation::IReference<Windows::Foundation::DateTime> const& value) const;
        [[nodiscard]] auto ExpirationTime() const;
        auto Dismissed(Windows::Foundation::TypedEventHandler<Windows::UI::Notifications::ToastNotification, Windows::UI::Notifications::ToastDismissedEventArgs> const& handler) const;
        using Dismissed_revoker = impl::event_revoker<Windows::UI::Notifications::IToastNotification, &impl::abi_t<Windows::UI::Notifications::IToastNotification>::remove_Dismissed>;
        Dismissed_revoker Dismissed(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::UI::Notifications::ToastNotification, Windows::UI::Notifications::ToastDismissedEventArgs> const& handler) const;
        auto Dismissed(winrt::event_token const& token) const noexcept;
        auto Activated(Windows::Foundation::TypedEventHandler<Windows::UI::Notifications::ToastNotification, Windows::Foundation::IInspectable> const& handler) const;
        using Activated_revoker = impl::event_revoker<Windows::UI::Notifications::IToastNotification, &impl::abi_t<Windows::UI::Notifications::IToastNotification>::remove_Activated>;
        Activated_revoker Activated(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::UI::Notifications::ToastNotification, Windows::Foundation::IInspectable> const& handler) const;
        auto Activated(winrt::event_token const& token) const noexcept;
        auto Failed(Windows::Foundation::TypedEventHandler<Windows::UI::Notifications::ToastNotification, Windows::UI::Notifications::ToastFailedEventArgs> const& handler) const;
        using Failed_revoker = impl::event_revoker<Windows::UI::Notifications::IToastNotification, &impl::abi_t<Windows::UI::Notifications::IToastNotification>::remove_Failed>;
        Failed_revoker Failed(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::UI::Notifications::ToastNotification, Windows::UI::Notifications::ToastFailedEventArgs> const& handler) const;
        auto Failed(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotification>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotification<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotification2
    {
        auto Tag(param::hstring const& value) const;
        [[nodiscard]] auto Tag() const;
        auto Group(param::hstring const& value) const;
        [[nodiscard]] auto Group() const;
        auto SuppressPopup(bool value) const;
        [[nodiscard]] auto SuppressPopup() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotification2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotification2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotification3
    {
        [[nodiscard]] auto NotificationMirroring() const;
        auto NotificationMirroring(Windows::UI::Notifications::NotificationMirroring const& value) const;
        [[nodiscard]] auto RemoteId() const;
        auto RemoteId(param::hstring const& value) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotification3>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotification3<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotification4
    {
        [[nodiscard]] auto Data() const;
        auto Data(Windows::UI::Notifications::NotificationData const& value) const;
        [[nodiscard]] auto Priority() const;
        auto Priority(Windows::UI::Notifications::ToastNotificationPriority const& value) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotification4>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotification4<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotification6
    {
        [[nodiscard]] auto ExpiresOnReboot() const;
        auto ExpiresOnReboot(bool value) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotification6>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotification6<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationActionTriggerDetail
    {
        [[nodiscard]] auto Argument() const;
        [[nodiscard]] auto UserInput() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationActionTriggerDetail>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationActionTriggerDetail<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationFactory
    {
        auto CreateToastNotification(Windows::Data::Xml::Dom::XmlDocument const& content) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationFactory>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationFactory<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationHistory
    {
        auto RemoveGroup(param::hstring const& group) const;
        auto RemoveGroup(param::hstring const& group, param::hstring const& applicationId) const;
        auto Remove(param::hstring const& tag, param::hstring const& group, param::hstring const& applicationId) const;
        auto Remove(param::hstring const& tag, param::hstring const& group) const;
        auto Remove(param::hstring const& tag) const;
        auto Clear() const;
        auto Clear(param::hstring const& applicationId) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationHistory>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationHistory<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationHistory2
    {
        auto GetHistory() const;
        auto GetHistory(param::hstring const& applicationId) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationHistory2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationHistory2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationHistoryChangedTriggerDetail
    {
        [[nodiscard]] auto ChangeType() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationHistoryChangedTriggerDetail<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationHistoryChangedTriggerDetail2
    {
        [[nodiscard]] auto CollectionId() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationHistoryChangedTriggerDetail2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationHistoryChangedTriggerDetail2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationManagerForUser
    {
        auto CreateToastNotifier() const;
        auto CreateToastNotifier(param::hstring const& applicationId) const;
        [[nodiscard]] auto History() const;
        [[nodiscard]] auto User() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationManagerForUser>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationManagerForUser<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationManagerForUser2
    {
        auto GetToastNotifierForToastCollectionIdAsync(param::hstring const& collectionId) const;
        auto GetHistoryForToastCollectionIdAsync(param::hstring const& collectionId) const;
        auto GetToastCollectionManager() const;
        auto GetToastCollectionManager(param::hstring const& appId) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationManagerForUser2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationManagerForUser2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationManagerStatics
    {
        auto CreateToastNotifier() const;
        auto CreateToastNotifier(param::hstring const& applicationId) const;
        auto GetTemplateContent(Windows::UI::Notifications::ToastTemplateType const& type) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationManagerStatics>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationManagerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationManagerStatics2
    {
        [[nodiscard]] auto History() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationManagerStatics2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationManagerStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationManagerStatics4
    {
        auto GetForUser(Windows::System::User const& user) const;
        auto ConfigureNotificationMirroring(Windows::UI::Notifications::NotificationMirroring const& value) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationManagerStatics4>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationManagerStatics4<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotificationManagerStatics5
    {
        auto GetDefault() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotificationManagerStatics5>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotificationManagerStatics5<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotifier
    {
        auto Show(Windows::UI::Notifications::ToastNotification const& notification) const;
        auto Hide(Windows::UI::Notifications::ToastNotification const& notification) const;
        [[nodiscard]] auto Setting() const;
        auto AddToSchedule(Windows::UI::Notifications::ScheduledToastNotification const& scheduledToast) const;
        auto RemoveFromSchedule(Windows::UI::Notifications::ScheduledToastNotification const& scheduledToast) const;
        auto GetScheduledToastNotifications() const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotifier>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotifier<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotifier2
    {
        auto Update(Windows::UI::Notifications::NotificationData const& data, param::hstring const& tag, param::hstring const& group) const;
        auto Update(Windows::UI::Notifications::NotificationData const& data, param::hstring const& tag) const;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotifier2>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotifier2<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IToastNotifier3
    {
        auto ScheduledToastNotificationShowing(Windows::Foundation::TypedEventHandler<Windows::UI::Notifications::ToastNotifier, Windows::UI::Notifications::ScheduledToastNotificationShowingEventArgs> const& handler) const;
        using ScheduledToastNotificationShowing_revoker = impl::event_revoker<Windows::UI::Notifications::IToastNotifier3, &impl::abi_t<Windows::UI::Notifications::IToastNotifier3>::remove_ScheduledToastNotificationShowing>;
        ScheduledToastNotificationShowing_revoker ScheduledToastNotificationShowing(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::UI::Notifications::ToastNotifier, Windows::UI::Notifications::ScheduledToastNotificationShowingEventArgs> const& handler) const;
        auto ScheduledToastNotificationShowing(winrt::event_token const& token) const noexcept;
    };
    template <> struct consume<Windows::UI::Notifications::IToastNotifier3>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IToastNotifier3<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IUserNotification
    {
        [[nodiscard]] auto Notification() const;
        [[nodiscard]] auto AppInfo() const;
        [[nodiscard]] auto Id() const;
        [[nodiscard]] auto CreationTime() const;
    };
    template <> struct consume<Windows::UI::Notifications::IUserNotification>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IUserNotification<D>;
    };
    template <typename D>
    struct consume_Windows_UI_Notifications_IUserNotificationChangedEventArgs
    {
        [[nodiscard]] auto ChangeKind() const;
        [[nodiscard]] auto UserNotificationId() const;
    };
    template <> struct consume<Windows::UI::Notifications::IUserNotificationChangedEventArgs>
    {
        template <typename D> using type = consume_Windows_UI_Notifications_IUserNotificationChangedEventArgs<D>;
    };
}
#endif
