// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_ApplicationModel_2_H
#define WINRT_Windows_ApplicationModel_2_H
#include "Windows.System.1.h"
#include "Windows.ApplicationModel.1.h"
namespace winrt::Windows::ApplicationModel
{
    struct PackageInstallProgress
    {
        uint32_t PercentComplete;
    };
    inline bool operator==(PackageInstallProgress const& left, PackageInstallProgress const& right) noexcept
    {
        return left.PercentComplete == right.PercentComplete;
    }
    inline bool operator!=(PackageInstallProgress const& left, PackageInstallProgress const& right) noexcept
    {
        return !(left == right);
    }
    struct PackageVersion
    {
        uint16_t Major;
        uint16_t Minor;
        uint16_t Build;
        uint16_t Revision;
    };
    inline bool operator==(PackageVersion const& left, PackageVersion const& right) noexcept
    {
        return left.Major == right.Major && left.Minor == right.Minor && left.Build == right.Build && left.Revision == right.Revision;
    }
    inline bool operator!=(PackageVersion const& left, PackageVersion const& right) noexcept
    {
        return !(left == right);
    }
    struct __declspec(empty_bases) AppDisplayInfo : Windows::ApplicationModel::IAppDisplayInfo
    {
        AppDisplayInfo(std::nullptr_t) noexcept {}
        AppDisplayInfo(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IAppDisplayInfo(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppInfo : Windows::ApplicationModel::IAppInfo,
        impl::require<AppInfo, Windows::ApplicationModel::IAppInfo2>
    {
        AppInfo(std::nullptr_t) noexcept {}
        AppInfo(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IAppInfo(ptr, take_ownership_from_abi) {}
        [[nodiscard]] static auto Current();
        static auto GetFromAppUserModelId(param::hstring const& appUserModelId);
        static auto GetFromAppUserModelIdForUser(Windows::System::User const& user, param::hstring const& appUserModelId);
    };
    struct __declspec(empty_bases) AppInstallerInfo : Windows::ApplicationModel::IAppInstallerInfo
    {
        AppInstallerInfo(std::nullptr_t) noexcept {}
        AppInstallerInfo(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IAppInstallerInfo(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) AppInstance : Windows::ApplicationModel::IAppInstance
    {
        AppInstance(std::nullptr_t) noexcept {}
        AppInstance(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IAppInstance(ptr, take_ownership_from_abi) {}
        [[nodiscard]] static auto RecommendedInstance();
        static auto GetActivatedEventArgs();
        static auto FindOrRegisterInstanceForKey(param::hstring const& key);
        static auto Unregister();
        static auto GetInstances();
    };
    struct DesignMode
    {
        DesignMode() = delete;
        [[nodiscard]] static auto DesignModeEnabled();
        [[nodiscard]] static auto DesignMode2Enabled();
    };
    struct __declspec(empty_bases) EnteredBackgroundEventArgs : Windows::ApplicationModel::IEnteredBackgroundEventArgs
    {
        EnteredBackgroundEventArgs(std::nullptr_t) noexcept {}
        EnteredBackgroundEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IEnteredBackgroundEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct FullTrustProcessLauncher
    {
        FullTrustProcessLauncher() = delete;
        static auto LaunchFullTrustProcessForCurrentAppAsync();
        static auto LaunchFullTrustProcessForCurrentAppAsync(param::hstring const& parameterGroupId);
        static auto LaunchFullTrustProcessForAppAsync(param::hstring const& fullTrustPackageRelativeAppId);
        static auto LaunchFullTrustProcessForAppAsync(param::hstring const& fullTrustPackageRelativeAppId, param::hstring const& parameterGroupId);
    };
    struct __declspec(empty_bases) LeavingBackgroundEventArgs : Windows::ApplicationModel::ILeavingBackgroundEventArgs
    {
        LeavingBackgroundEventArgs(std::nullptr_t) noexcept {}
        LeavingBackgroundEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::ILeavingBackgroundEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) LimitedAccessFeatureRequestResult : Windows::ApplicationModel::ILimitedAccessFeatureRequestResult
    {
        LimitedAccessFeatureRequestResult(std::nullptr_t) noexcept {}
        LimitedAccessFeatureRequestResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::ILimitedAccessFeatureRequestResult(ptr, take_ownership_from_abi) {}
    };
    struct LimitedAccessFeatures
    {
        LimitedAccessFeatures() = delete;
        static auto TryUnlockFeature(param::hstring const& featureId, param::hstring const& token, param::hstring const& attestation);
    };
    struct __declspec(empty_bases) Package : Windows::ApplicationModel::IPackage,
        impl::require<Package, Windows::ApplicationModel::IPackage2, Windows::ApplicationModel::IPackage3, Windows::ApplicationModel::IPackageWithMetadata, Windows::ApplicationModel::IPackage4, Windows::ApplicationModel::IPackage5, Windows::ApplicationModel::IPackage6, Windows::ApplicationModel::IPackage7, Windows::ApplicationModel::IPackage8>
    {
        Package(std::nullptr_t) noexcept {}
        Package(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackage(ptr, take_ownership_from_abi) {}
        [[nodiscard]] static auto Current();
    };
    struct __declspec(empty_bases) PackageCatalog : Windows::ApplicationModel::IPackageCatalog,
        impl::require<PackageCatalog, Windows::ApplicationModel::IPackageCatalog2, Windows::ApplicationModel::IPackageCatalog3, Windows::ApplicationModel::IPackageCatalog4>
    {
        PackageCatalog(std::nullptr_t) noexcept {}
        PackageCatalog(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageCatalog(ptr, take_ownership_from_abi) {}
        static auto OpenForCurrentPackage();
        static auto OpenForCurrentUser();
    };
    struct __declspec(empty_bases) PackageCatalogAddOptionalPackageResult : Windows::ApplicationModel::IPackageCatalogAddOptionalPackageResult
    {
        PackageCatalogAddOptionalPackageResult(std::nullptr_t) noexcept {}
        PackageCatalogAddOptionalPackageResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageCatalogAddOptionalPackageResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageCatalogAddResourcePackageResult : Windows::ApplicationModel::IPackageCatalogAddResourcePackageResult
    {
        PackageCatalogAddResourcePackageResult(std::nullptr_t) noexcept {}
        PackageCatalogAddResourcePackageResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageCatalogAddResourcePackageResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageCatalogRemoveOptionalPackagesResult : Windows::ApplicationModel::IPackageCatalogRemoveOptionalPackagesResult
    {
        PackageCatalogRemoveOptionalPackagesResult(std::nullptr_t) noexcept {}
        PackageCatalogRemoveOptionalPackagesResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageCatalogRemoveOptionalPackagesResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageCatalogRemoveResourcePackagesResult : Windows::ApplicationModel::IPackageCatalogRemoveResourcePackagesResult
    {
        PackageCatalogRemoveResourcePackagesResult(std::nullptr_t) noexcept {}
        PackageCatalogRemoveResourcePackagesResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageCatalogRemoveResourcePackagesResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageContentGroup : Windows::ApplicationModel::IPackageContentGroup
    {
        PackageContentGroup(std::nullptr_t) noexcept {}
        PackageContentGroup(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageContentGroup(ptr, take_ownership_from_abi) {}
        [[nodiscard]] static auto RequiredGroupName();
    };
    struct __declspec(empty_bases) PackageContentGroupStagingEventArgs : Windows::ApplicationModel::IPackageContentGroupStagingEventArgs
    {
        PackageContentGroupStagingEventArgs(std::nullptr_t) noexcept {}
        PackageContentGroupStagingEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageContentGroupStagingEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageId : Windows::ApplicationModel::IPackageId,
        impl::require<PackageId, Windows::ApplicationModel::IPackageIdWithMetadata>
    {
        PackageId(std::nullptr_t) noexcept {}
        PackageId(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageId(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageInstallingEventArgs : Windows::ApplicationModel::IPackageInstallingEventArgs
    {
        PackageInstallingEventArgs(std::nullptr_t) noexcept {}
        PackageInstallingEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageInstallingEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageStagingEventArgs : Windows::ApplicationModel::IPackageStagingEventArgs
    {
        PackageStagingEventArgs(std::nullptr_t) noexcept {}
        PackageStagingEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageStagingEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageStatus : Windows::ApplicationModel::IPackageStatus,
        impl::require<PackageStatus, Windows::ApplicationModel::IPackageStatus2>
    {
        PackageStatus(std::nullptr_t) noexcept {}
        PackageStatus(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageStatus(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageStatusChangedEventArgs : Windows::ApplicationModel::IPackageStatusChangedEventArgs
    {
        PackageStatusChangedEventArgs(std::nullptr_t) noexcept {}
        PackageStatusChangedEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageStatusChangedEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageUninstallingEventArgs : Windows::ApplicationModel::IPackageUninstallingEventArgs
    {
        PackageUninstallingEventArgs(std::nullptr_t) noexcept {}
        PackageUninstallingEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageUninstallingEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageUpdateAvailabilityResult : Windows::ApplicationModel::IPackageUpdateAvailabilityResult
    {
        PackageUpdateAvailabilityResult(std::nullptr_t) noexcept {}
        PackageUpdateAvailabilityResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageUpdateAvailabilityResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) PackageUpdatingEventArgs : Windows::ApplicationModel::IPackageUpdatingEventArgs
    {
        PackageUpdatingEventArgs(std::nullptr_t) noexcept {}
        PackageUpdatingEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IPackageUpdatingEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StartupTask : Windows::ApplicationModel::IStartupTask
    {
        StartupTask(std::nullptr_t) noexcept {}
        StartupTask(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::IStartupTask(ptr, take_ownership_from_abi) {}
        static auto GetForCurrentPackageAsync();
        static auto GetAsync(param::hstring const& taskId);
    };
    struct __declspec(empty_bases) SuspendingDeferral : Windows::ApplicationModel::ISuspendingDeferral
    {
        SuspendingDeferral(std::nullptr_t) noexcept {}
        SuspendingDeferral(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::ISuspendingDeferral(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) SuspendingEventArgs : Windows::ApplicationModel::ISuspendingEventArgs
    {
        SuspendingEventArgs(std::nullptr_t) noexcept {}
        SuspendingEventArgs(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::ISuspendingEventArgs(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) SuspendingOperation : Windows::ApplicationModel::ISuspendingOperation
    {
        SuspendingOperation(std::nullptr_t) noexcept {}
        SuspendingOperation(void* ptr, take_ownership_from_abi_t) noexcept : Windows::ApplicationModel::ISuspendingOperation(ptr, take_ownership_from_abi) {}
    };
}
#endif
