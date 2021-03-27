// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Storage_2_H
#define WINRT_Windows_Storage_2_H
#include "Windows.Foundation.1.h"
#include "Windows.Foundation.Collections.1.h"
#include "Windows.Storage.Search.1.h"
#include "Windows.Storage.Streams.1.h"
#include "Windows.System.1.h"
#include "Windows.Storage.1.h"
namespace winrt::Windows::Storage
{
    struct ApplicationDataSetVersionHandler : Windows::Foundation::IUnknown
    {
        ApplicationDataSetVersionHandler(std::nullptr_t = nullptr) noexcept {}
        ApplicationDataSetVersionHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> ApplicationDataSetVersionHandler(L lambda);
        template <typename F> ApplicationDataSetVersionHandler(F* function);
        template <typename O, typename M> ApplicationDataSetVersionHandler(O* object, M method);
        template <typename O, typename M> ApplicationDataSetVersionHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> ApplicationDataSetVersionHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Storage::SetVersionRequest const& setVersionRequest) const;
    };
    struct StreamedFileDataRequestedHandler : Windows::Foundation::IUnknown
    {
        StreamedFileDataRequestedHandler(std::nullptr_t = nullptr) noexcept {}
        StreamedFileDataRequestedHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> StreamedFileDataRequestedHandler(L lambda);
        template <typename F> StreamedFileDataRequestedHandler(F* function);
        template <typename O, typename M> StreamedFileDataRequestedHandler(O* object, M method);
        template <typename O, typename M> StreamedFileDataRequestedHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> StreamedFileDataRequestedHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Storage::StreamedFileDataRequest const& stream) const;
    };
    struct __declspec(empty_bases) AppDataPaths : Windows::Storage::IAppDataPaths
    {
        AppDataPaths(std::nullptr_t) noexcept {}
        AppDataPaths(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IAppDataPaths(ptr, take_ownership_from_abi) {}
        static auto GetForUser(Windows::System::User const& user);
        static auto GetDefault();
    };
    struct __declspec(empty_bases) ApplicationData : Windows::Storage::IApplicationData,
        impl::require<ApplicationData, Windows::Storage::IApplicationData2, Windows::Storage::IApplicationData3>
    {
        ApplicationData(std::nullptr_t) noexcept {}
        ApplicationData(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IApplicationData(ptr, take_ownership_from_abi) {}
        [[nodiscard]] static auto Current();
        static auto GetForUserAsync(Windows::System::User const& user);
    };
    struct __declspec(empty_bases) ApplicationDataCompositeValue : Windows::Foundation::Collections::IPropertySet
    {
        ApplicationDataCompositeValue(std::nullptr_t) noexcept {}
        ApplicationDataCompositeValue(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::Collections::IPropertySet(ptr, take_ownership_from_abi) {}
        ApplicationDataCompositeValue();
    };
    struct __declspec(empty_bases) ApplicationDataContainer : Windows::Storage::IApplicationDataContainer
    {
        ApplicationDataContainer(std::nullptr_t) noexcept {}
        ApplicationDataContainer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IApplicationDataContainer(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ApplicationDataContainerSettings : Windows::Foundation::Collections::IPropertySet
    {
        ApplicationDataContainerSettings(std::nullptr_t) noexcept {}
        ApplicationDataContainerSettings(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::Collections::IPropertySet(ptr, take_ownership_from_abi) {}
    };
    struct CachedFileManager
    {
        CachedFileManager() = delete;
        static auto DeferUpdates(Windows::Storage::IStorageFile const& file);
        static auto CompleteUpdatesAsync(Windows::Storage::IStorageFile const& file);
    };
    struct DownloadsFolder
    {
        DownloadsFolder() = delete;
        static auto CreateFileAsync(param::hstring const& desiredName);
        static auto CreateFolderAsync(param::hstring const& desiredName);
        static auto CreateFileAsync(param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& option);
        static auto CreateFolderAsync(param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& option);
        static auto CreateFileForUserAsync(Windows::System::User const& user, param::hstring const& desiredName);
        static auto CreateFolderForUserAsync(Windows::System::User const& user, param::hstring const& desiredName);
        static auto CreateFileForUserAsync(Windows::System::User const& user, param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& option);
        static auto CreateFolderForUserAsync(Windows::System::User const& user, param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& option);
    };
    struct FileIO
    {
        FileIO() = delete;
        static auto ReadTextAsync(Windows::Storage::IStorageFile const& file);
        static auto ReadTextAsync(Windows::Storage::IStorageFile const& file, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto WriteTextAsync(Windows::Storage::IStorageFile const& file, param::hstring const& contents);
        static auto WriteTextAsync(Windows::Storage::IStorageFile const& file, param::hstring const& contents, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto AppendTextAsync(Windows::Storage::IStorageFile const& file, param::hstring const& contents);
        static auto AppendTextAsync(Windows::Storage::IStorageFile const& file, param::hstring const& contents, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto ReadLinesAsync(Windows::Storage::IStorageFile const& file);
        static auto ReadLinesAsync(Windows::Storage::IStorageFile const& file, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto WriteLinesAsync(Windows::Storage::IStorageFile const& file, param::async_iterable<hstring> const& lines);
        static auto WriteLinesAsync(Windows::Storage::IStorageFile const& file, param::async_iterable<hstring> const& lines, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto AppendLinesAsync(Windows::Storage::IStorageFile const& file, param::async_iterable<hstring> const& lines);
        static auto AppendLinesAsync(Windows::Storage::IStorageFile const& file, param::async_iterable<hstring> const& lines, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto ReadBufferAsync(Windows::Storage::IStorageFile const& file);
        static auto WriteBufferAsync(Windows::Storage::IStorageFile const& file, Windows::Storage::Streams::IBuffer const& buffer);
        static auto WriteBytesAsync(Windows::Storage::IStorageFile const& file, array_view<uint8_t const> buffer);
    };
    struct KnownFolders
    {
        KnownFolders() = delete;
        [[nodiscard]] static auto CameraRoll();
        [[nodiscard]] static auto Playlists();
        [[nodiscard]] static auto SavedPictures();
        [[nodiscard]] static auto MusicLibrary();
        [[nodiscard]] static auto PicturesLibrary();
        [[nodiscard]] static auto VideosLibrary();
        [[nodiscard]] static auto DocumentsLibrary();
        [[nodiscard]] static auto HomeGroup();
        [[nodiscard]] static auto RemovableDevices();
        [[nodiscard]] static auto MediaServerDevices();
        [[nodiscard]] static auto Objects3D();
        [[nodiscard]] static auto AppCaptures();
        [[nodiscard]] static auto RecordedCalls();
        static auto GetFolderForUserAsync(Windows::System::User const& user, Windows::Storage::KnownFolderId const& folderId);
        static auto RequestAccessAsync(Windows::Storage::KnownFolderId const& folderId);
        static auto RequestAccessForUserAsync(Windows::System::User const& user, Windows::Storage::KnownFolderId const& folderId);
        static auto GetFolderAsync(Windows::Storage::KnownFolderId const& folderId);
    };
    struct PathIO
    {
        PathIO() = delete;
        static auto ReadTextAsync(param::hstring const& absolutePath);
        static auto ReadTextAsync(param::hstring const& absolutePath, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto WriteTextAsync(param::hstring const& absolutePath, param::hstring const& contents);
        static auto WriteTextAsync(param::hstring const& absolutePath, param::hstring const& contents, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto AppendTextAsync(param::hstring const& absolutePath, param::hstring const& contents);
        static auto AppendTextAsync(param::hstring const& absolutePath, param::hstring const& contents, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto ReadLinesAsync(param::hstring const& absolutePath);
        static auto ReadLinesAsync(param::hstring const& absolutePath, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto WriteLinesAsync(param::hstring const& absolutePath, param::async_iterable<hstring> const& lines);
        static auto WriteLinesAsync(param::hstring const& absolutePath, param::async_iterable<hstring> const& lines, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto AppendLinesAsync(param::hstring const& absolutePath, param::async_iterable<hstring> const& lines);
        static auto AppendLinesAsync(param::hstring const& absolutePath, param::async_iterable<hstring> const& lines, Windows::Storage::Streams::UnicodeEncoding const& encoding);
        static auto ReadBufferAsync(param::hstring const& absolutePath);
        static auto WriteBufferAsync(param::hstring const& absolutePath, Windows::Storage::Streams::IBuffer const& buffer);
        static auto WriteBytesAsync(param::hstring const& absolutePath, array_view<uint8_t const> buffer);
    };
    struct __declspec(empty_bases) SetVersionDeferral : Windows::Storage::ISetVersionDeferral
    {
        SetVersionDeferral(std::nullptr_t) noexcept {}
        SetVersionDeferral(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISetVersionDeferral(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) SetVersionRequest : Windows::Storage::ISetVersionRequest
    {
        SetVersionRequest(std::nullptr_t) noexcept {}
        SetVersionRequest(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISetVersionRequest(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageFile : Windows::Storage::IStorageFile,
        impl::require<StorageFile, Windows::Storage::IStorageItemProperties, Windows::Storage::IStorageItemProperties2, Windows::Storage::IStorageItem2, Windows::Storage::IStorageItemPropertiesWithProvider, Windows::Storage::IStorageFilePropertiesWithAvailability, Windows::Storage::IStorageFile2>
    {
        StorageFile(std::nullptr_t) noexcept {}
        StorageFile(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IStorageFile(ptr, take_ownership_from_abi) {}
        using Windows::Storage::IStorageFile::OpenAsync;
        using impl::consume_t<StorageFile, Windows::Storage::IStorageFile2>::OpenAsync;
        using Windows::Storage::IStorageFile::OpenTransactedWriteAsync;
        using impl::consume_t<StorageFile, Windows::Storage::IStorageFile2>::OpenTransactedWriteAsync;
        static auto GetFileFromPathAsync(param::hstring const& path);
        static auto GetFileFromApplicationUriAsync(Windows::Foundation::Uri const& uri);
        static auto CreateStreamedFileAsync(param::hstring const& displayNameWithExtension, Windows::Storage::StreamedFileDataRequestedHandler const& dataRequested, Windows::Storage::Streams::IRandomAccessStreamReference const& thumbnail);
        static auto ReplaceWithStreamedFileAsync(Windows::Storage::IStorageFile const& fileToReplace, Windows::Storage::StreamedFileDataRequestedHandler const& dataRequested, Windows::Storage::Streams::IRandomAccessStreamReference const& thumbnail);
        static auto CreateStreamedFileFromUriAsync(param::hstring const& displayNameWithExtension, Windows::Foundation::Uri const& uri, Windows::Storage::Streams::IRandomAccessStreamReference const& thumbnail);
        static auto ReplaceWithStreamedFileFromUriAsync(Windows::Storage::IStorageFile const& fileToReplace, Windows::Foundation::Uri const& uri, Windows::Storage::Streams::IRandomAccessStreamReference const& thumbnail);
        static auto GetFileFromPathForUserAsync(Windows::System::User const& user, param::hstring const& path);
    };
    struct __declspec(empty_bases) StorageFolder : Windows::Storage::IStorageFolder,
        impl::require<StorageFolder, Windows::Storage::Search::IStorageFolderQueryOperations, Windows::Storage::IStorageItemProperties, Windows::Storage::IStorageItemProperties2, Windows::Storage::IStorageItem2, Windows::Storage::IStorageFolder2, Windows::Storage::IStorageItemPropertiesWithProvider, Windows::Storage::IStorageFolder3>
    {
        StorageFolder(std::nullptr_t) noexcept {}
        StorageFolder(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IStorageFolder(ptr, take_ownership_from_abi) {}
        using Windows::Storage::IStorageFolder::GetFilesAsync;
        using impl::consume_t<StorageFolder, Windows::Storage::Search::IStorageFolderQueryOperations>::GetFilesAsync;
        using Windows::Storage::IStorageFolder::GetFoldersAsync;
        using impl::consume_t<StorageFolder, Windows::Storage::Search::IStorageFolderQueryOperations>::GetFoldersAsync;
        using Windows::Storage::IStorageFolder::GetItemsAsync;
        using impl::consume_t<StorageFolder, Windows::Storage::Search::IStorageFolderQueryOperations>::GetItemsAsync;
        static auto GetFolderFromPathAsync(param::hstring const& path);
        static auto GetFolderFromPathForUserAsync(Windows::System::User const& user, param::hstring const& path);
    };
    struct __declspec(empty_bases) StorageLibrary : Windows::Storage::IStorageLibrary,
        impl::require<StorageLibrary, Windows::Storage::IStorageLibrary2, Windows::Storage::IStorageLibrary3>
    {
        StorageLibrary(std::nullptr_t) noexcept {}
        StorageLibrary(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IStorageLibrary(ptr, take_ownership_from_abi) {}
        static auto GetLibraryAsync(Windows::Storage::KnownLibraryId const& libraryId);
        static auto GetLibraryForUserAsync(Windows::System::User const& user, Windows::Storage::KnownLibraryId const& libraryId);
    };
    struct __declspec(empty_bases) StorageLibraryChange : Windows::Storage::IStorageLibraryChange
    {
        StorageLibraryChange(std::nullptr_t) noexcept {}
        StorageLibraryChange(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IStorageLibraryChange(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageLibraryChangeReader : Windows::Storage::IStorageLibraryChangeReader
    {
        StorageLibraryChangeReader(std::nullptr_t) noexcept {}
        StorageLibraryChangeReader(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IStorageLibraryChangeReader(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageLibraryChangeTracker : Windows::Storage::IStorageLibraryChangeTracker
    {
        StorageLibraryChangeTracker(std::nullptr_t) noexcept {}
        StorageLibraryChangeTracker(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IStorageLibraryChangeTracker(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageProvider : Windows::Storage::IStorageProvider,
        impl::require<StorageProvider, Windows::Storage::IStorageProvider2>
    {
        StorageProvider(std::nullptr_t) noexcept {}
        StorageProvider(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IStorageProvider(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageStreamTransaction : Windows::Storage::IStorageStreamTransaction
    {
        StorageStreamTransaction(std::nullptr_t) noexcept {}
        StorageStreamTransaction(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IStorageStreamTransaction(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StreamedFileDataRequest : Windows::Storage::Streams::IOutputStream,
        impl::require<StreamedFileDataRequest, Windows::Storage::IStreamedFileDataRequest>
    {
        StreamedFileDataRequest(std::nullptr_t) noexcept {}
        StreamedFileDataRequest(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IOutputStream(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) SystemAudioProperties : Windows::Storage::ISystemAudioProperties
    {
        SystemAudioProperties(std::nullptr_t) noexcept {}
        SystemAudioProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISystemAudioProperties(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) SystemDataPaths : Windows::Storage::ISystemDataPaths
    {
        SystemDataPaths(std::nullptr_t) noexcept {}
        SystemDataPaths(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISystemDataPaths(ptr, take_ownership_from_abi) {}
        static auto GetDefault();
    };
    struct __declspec(empty_bases) SystemGPSProperties : Windows::Storage::ISystemGPSProperties
    {
        SystemGPSProperties(std::nullptr_t) noexcept {}
        SystemGPSProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISystemGPSProperties(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) SystemImageProperties : Windows::Storage::ISystemImageProperties
    {
        SystemImageProperties(std::nullptr_t) noexcept {}
        SystemImageProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISystemImageProperties(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) SystemMediaProperties : Windows::Storage::ISystemMediaProperties
    {
        SystemMediaProperties(std::nullptr_t) noexcept {}
        SystemMediaProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISystemMediaProperties(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) SystemMusicProperties : Windows::Storage::ISystemMusicProperties
    {
        SystemMusicProperties(std::nullptr_t) noexcept {}
        SystemMusicProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISystemMusicProperties(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) SystemPhotoProperties : Windows::Storage::ISystemPhotoProperties
    {
        SystemPhotoProperties(std::nullptr_t) noexcept {}
        SystemPhotoProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISystemPhotoProperties(ptr, take_ownership_from_abi) {}
    };
    struct SystemProperties
    {
        SystemProperties() = delete;
        [[nodiscard]] static auto Author();
        [[nodiscard]] static auto Comment();
        [[nodiscard]] static auto ItemNameDisplay();
        [[nodiscard]] static auto Keywords();
        [[nodiscard]] static auto Rating();
        [[nodiscard]] static auto Title();
        [[nodiscard]] static auto Audio();
        [[nodiscard]] static auto GPS();
        [[nodiscard]] static auto Media();
        [[nodiscard]] static auto Music();
        [[nodiscard]] static auto Photo();
        [[nodiscard]] static auto Video();
        [[nodiscard]] static auto Image();
    };
    struct __declspec(empty_bases) SystemVideoProperties : Windows::Storage::ISystemVideoProperties
    {
        SystemVideoProperties(std::nullptr_t) noexcept {}
        SystemVideoProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::ISystemVideoProperties(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) UserDataPaths : Windows::Storage::IUserDataPaths
    {
        UserDataPaths(std::nullptr_t) noexcept {}
        UserDataPaths(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::IUserDataPaths(ptr, take_ownership_from_abi) {}
        static auto GetForUser(Windows::System::User const& user);
        static auto GetDefault();
    };
}
#endif
