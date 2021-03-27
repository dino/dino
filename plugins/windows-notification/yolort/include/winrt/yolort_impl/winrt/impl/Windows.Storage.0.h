// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Storage_0_H
#define WINRT_Windows_Storage_0_H
namespace winrt::Windows::Foundation
{
    struct EventRegistrationToken;
    struct IAsyncAction;
    template <typename TSender, typename TResult> struct TypedEventHandler;
    struct Uri;
}
namespace winrt::Windows::Foundation::Collections
{
    template <typename T> struct IIterable;
    struct IPropertySet;
}
namespace winrt::Windows::Storage::FileProperties
{
    struct StorageItemContentProperties;
    enum class ThumbnailMode : int32_t;
    enum class ThumbnailOptions : uint32_t;
}
namespace winrt::Windows::Storage::Streams
{
    struct IBuffer;
    struct IOutputStream;
    struct IRandomAccessStream;
    struct IRandomAccessStreamReference;
    enum class UnicodeEncoding : int32_t;
}
namespace winrt::Windows::System
{
    struct User;
}
namespace winrt::Windows::Storage
{
    enum class ApplicationDataCreateDisposition : int32_t
    {
        Always = 0,
        Existing = 1,
    };
    enum class ApplicationDataLocality : int32_t
    {
        Local = 0,
        Roaming = 1,
        Temporary = 2,
        LocalCache = 3,
    };
    enum class CreationCollisionOption : int32_t
    {
        GenerateUniqueName = 0,
        ReplaceExisting = 1,
        FailIfExists = 2,
        OpenIfExists = 3,
    };
    enum class FileAccessMode : int32_t
    {
        Read = 0,
        ReadWrite = 1,
    };
    enum class FileAttributes : uint32_t
    {
        Normal = 0,
        ReadOnly = 0x1,
        Directory = 0x10,
        Archive = 0x20,
        Temporary = 0x100,
        LocallyIncomplete = 0x200,
    };
    enum class KnownFolderId : int32_t
    {
        AppCaptures = 0,
        CameraRoll = 1,
        DocumentsLibrary = 2,
        HomeGroup = 3,
        MediaServerDevices = 4,
        MusicLibrary = 5,
        Objects3D = 6,
        PicturesLibrary = 7,
        Playlists = 8,
        RecordedCalls = 9,
        RemovableDevices = 10,
        SavedPictures = 11,
        Screenshots = 12,
        VideosLibrary = 13,
        AllAppMods = 14,
        CurrentAppMods = 15,
    };
    enum class KnownFoldersAccessStatus : int32_t
    {
        DeniedBySystem = 0,
        NotDeclaredByApp = 1,
        DeniedByUser = 2,
        UserPromptRequired = 3,
        Allowed = 4,
    };
    enum class KnownLibraryId : int32_t
    {
        Music = 0,
        Pictures = 1,
        Videos = 2,
        Documents = 3,
    };
    enum class NameCollisionOption : int32_t
    {
        GenerateUniqueName = 0,
        ReplaceExisting = 1,
        FailIfExists = 2,
    };
    enum class StorageDeleteOption : int32_t
    {
        Default = 0,
        PermanentDelete = 1,
    };
    enum class StorageItemTypes : uint32_t
    {
        None = 0,
        File = 0x1,
        Folder = 0x2,
    };
    enum class StorageLibraryChangeType : int32_t
    {
        Created = 0,
        Deleted = 1,
        MovedOrRenamed = 2,
        ContentsChanged = 3,
        MovedOutOfLibrary = 4,
        MovedIntoLibrary = 5,
        ContentsReplaced = 6,
        IndexingStatusChanged = 7,
        EncryptionChanged = 8,
        ChangeTrackingLost = 9,
    };
    enum class StorageOpenOptions : uint32_t
    {
        None = 0,
        AllowOnlyReaders = 0x1,
        AllowReadersAndWriters = 0x2,
    };
    enum class StreamedFileFailureMode : int32_t
    {
        Failed = 0,
        CurrentlyUnavailable = 1,
        Incomplete = 2,
    };
    struct IAppDataPaths;
    struct IAppDataPathsStatics;
    struct IApplicationData;
    struct IApplicationData2;
    struct IApplicationData3;
    struct IApplicationDataContainer;
    struct IApplicationDataStatics;
    struct IApplicationDataStatics2;
    struct ICachedFileManagerStatics;
    struct IDownloadsFolderStatics;
    struct IDownloadsFolderStatics2;
    struct IFileIOStatics;
    struct IKnownFoldersCameraRollStatics;
    struct IKnownFoldersPlaylistsStatics;
    struct IKnownFoldersSavedPicturesStatics;
    struct IKnownFoldersStatics;
    struct IKnownFoldersStatics2;
    struct IKnownFoldersStatics3;
    struct IKnownFoldersStatics4;
    struct IPathIOStatics;
    struct ISetVersionDeferral;
    struct ISetVersionRequest;
    struct IStorageFile;
    struct IStorageFile2;
    struct IStorageFilePropertiesWithAvailability;
    struct IStorageFileStatics;
    struct IStorageFileStatics2;
    struct IStorageFolder;
    struct IStorageFolder2;
    struct IStorageFolder3;
    struct IStorageFolderStatics;
    struct IStorageFolderStatics2;
    struct IStorageItem;
    struct IStorageItem2;
    struct IStorageItemProperties;
    struct IStorageItemProperties2;
    struct IStorageItemPropertiesWithProvider;
    struct IStorageLibrary;
    struct IStorageLibrary2;
    struct IStorageLibrary3;
    struct IStorageLibraryChange;
    struct IStorageLibraryChangeReader;
    struct IStorageLibraryChangeTracker;
    struct IStorageLibraryStatics;
    struct IStorageLibraryStatics2;
    struct IStorageProvider;
    struct IStorageProvider2;
    struct IStorageStreamTransaction;
    struct IStreamedFileDataRequest;
    struct ISystemAudioProperties;
    struct ISystemDataPaths;
    struct ISystemDataPathsStatics;
    struct ISystemGPSProperties;
    struct ISystemImageProperties;
    struct ISystemMediaProperties;
    struct ISystemMusicProperties;
    struct ISystemPhotoProperties;
    struct ISystemProperties;
    struct ISystemVideoProperties;
    struct IUserDataPaths;
    struct IUserDataPathsStatics;
    struct AppDataPaths;
    struct ApplicationData;
    struct ApplicationDataCompositeValue;
    struct ApplicationDataContainer;
    struct ApplicationDataContainerSettings;
    struct CachedFileManager;
    struct DownloadsFolder;
    struct FileIO;
    struct KnownFolders;
    struct PathIO;
    struct SetVersionDeferral;
    struct SetVersionRequest;
    struct StorageFile;
    struct StorageFolder;
    struct StorageLibrary;
    struct StorageLibraryChange;
    struct StorageLibraryChangeReader;
    struct StorageLibraryChangeTracker;
    struct StorageProvider;
    struct StorageStreamTransaction;
    struct StreamedFileDataRequest;
    struct SystemAudioProperties;
    struct SystemDataPaths;
    struct SystemGPSProperties;
    struct SystemImageProperties;
    struct SystemMediaProperties;
    struct SystemMusicProperties;
    struct SystemPhotoProperties;
    struct SystemProperties;
    struct SystemVideoProperties;
    struct UserDataPaths;
    struct ApplicationDataSetVersionHandler;
    struct StreamedFileDataRequestedHandler;
}
namespace winrt::impl
{
    template <> struct category<Windows::Storage::IAppDataPaths>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IAppDataPathsStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IApplicationData>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IApplicationData2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IApplicationData3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IApplicationDataContainer>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IApplicationDataStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IApplicationDataStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ICachedFileManagerStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IDownloadsFolderStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IDownloadsFolderStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IFileIOStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IKnownFoldersCameraRollStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IKnownFoldersPlaylistsStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IKnownFoldersSavedPicturesStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IKnownFoldersStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IKnownFoldersStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IKnownFoldersStatics3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IKnownFoldersStatics4>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IPathIOStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISetVersionDeferral>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISetVersionRequest>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFile>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFile2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFilePropertiesWithAvailability>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFileStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFileStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFolder>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFolder2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFolder3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFolderStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageFolderStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageItem>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageItem2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageItemProperties>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageItemProperties2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageItemPropertiesWithProvider>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageLibrary>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageLibrary2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageLibrary3>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageLibraryChange>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageLibraryChangeReader>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageLibraryChangeTracker>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageLibraryStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageLibraryStatics2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageProvider>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageProvider2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStorageStreamTransaction>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IStreamedFileDataRequest>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemAudioProperties>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemDataPaths>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemDataPathsStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemGPSProperties>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemImageProperties>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemMediaProperties>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemMusicProperties>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemPhotoProperties>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemProperties>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::ISystemVideoProperties>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IUserDataPaths>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::IUserDataPathsStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::AppDataPaths>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::ApplicationData>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::ApplicationDataCompositeValue>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::ApplicationDataContainer>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::ApplicationDataContainerSettings>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::CachedFileManager>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::DownloadsFolder>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::FileIO>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::KnownFolders>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::PathIO>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SetVersionDeferral>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SetVersionRequest>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::StorageFile>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::StorageFolder>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::StorageLibrary>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::StorageLibraryChange>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::StorageLibraryChangeReader>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::StorageLibraryChangeTracker>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::StorageProvider>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::StorageStreamTransaction>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::StreamedFileDataRequest>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SystemAudioProperties>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SystemDataPaths>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SystemGPSProperties>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SystemImageProperties>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SystemMediaProperties>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SystemMusicProperties>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SystemPhotoProperties>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SystemProperties>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::SystemVideoProperties>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::UserDataPaths>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::ApplicationDataCreateDisposition>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::ApplicationDataLocality>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::CreationCollisionOption>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::FileAccessMode>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::FileAttributes>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::KnownFolderId>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::KnownFoldersAccessStatus>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::KnownLibraryId>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::NameCollisionOption>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::StorageDeleteOption>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::StorageItemTypes>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::StorageLibraryChangeType>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::StorageOpenOptions>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::StreamedFileFailureMode>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::ApplicationDataSetVersionHandler>
    {
        using type = delegate_category;
    };
    template <> struct category<Windows::Storage::StreamedFileDataRequestedHandler>
    {
        using type = delegate_category;
    };
    template <> struct name<Windows::Storage::IAppDataPaths>
    {
        static constexpr auto & value{ L"Windows.Storage.IAppDataPaths" };
    };
    template <> struct name<Windows::Storage::IAppDataPathsStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IAppDataPathsStatics" };
    };
    template <> struct name<Windows::Storage::IApplicationData>
    {
        static constexpr auto & value{ L"Windows.Storage.IApplicationData" };
    };
    template <> struct name<Windows::Storage::IApplicationData2>
    {
        static constexpr auto & value{ L"Windows.Storage.IApplicationData2" };
    };
    template <> struct name<Windows::Storage::IApplicationData3>
    {
        static constexpr auto & value{ L"Windows.Storage.IApplicationData3" };
    };
    template <> struct name<Windows::Storage::IApplicationDataContainer>
    {
        static constexpr auto & value{ L"Windows.Storage.IApplicationDataContainer" };
    };
    template <> struct name<Windows::Storage::IApplicationDataStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IApplicationDataStatics" };
    };
    template <> struct name<Windows::Storage::IApplicationDataStatics2>
    {
        static constexpr auto & value{ L"Windows.Storage.IApplicationDataStatics2" };
    };
    template <> struct name<Windows::Storage::ICachedFileManagerStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.ICachedFileManagerStatics" };
    };
    template <> struct name<Windows::Storage::IDownloadsFolderStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IDownloadsFolderStatics" };
    };
    template <> struct name<Windows::Storage::IDownloadsFolderStatics2>
    {
        static constexpr auto & value{ L"Windows.Storage.IDownloadsFolderStatics2" };
    };
    template <> struct name<Windows::Storage::IFileIOStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IFileIOStatics" };
    };
    template <> struct name<Windows::Storage::IKnownFoldersCameraRollStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IKnownFoldersCameraRollStatics" };
    };
    template <> struct name<Windows::Storage::IKnownFoldersPlaylistsStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IKnownFoldersPlaylistsStatics" };
    };
    template <> struct name<Windows::Storage::IKnownFoldersSavedPicturesStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IKnownFoldersSavedPicturesStatics" };
    };
    template <> struct name<Windows::Storage::IKnownFoldersStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IKnownFoldersStatics" };
    };
    template <> struct name<Windows::Storage::IKnownFoldersStatics2>
    {
        static constexpr auto & value{ L"Windows.Storage.IKnownFoldersStatics2" };
    };
    template <> struct name<Windows::Storage::IKnownFoldersStatics3>
    {
        static constexpr auto & value{ L"Windows.Storage.IKnownFoldersStatics3" };
    };
    template <> struct name<Windows::Storage::IKnownFoldersStatics4>
    {
        static constexpr auto & value{ L"Windows.Storage.IKnownFoldersStatics4" };
    };
    template <> struct name<Windows::Storage::IPathIOStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IPathIOStatics" };
    };
    template <> struct name<Windows::Storage::ISetVersionDeferral>
    {
        static constexpr auto & value{ L"Windows.Storage.ISetVersionDeferral" };
    };
    template <> struct name<Windows::Storage::ISetVersionRequest>
    {
        static constexpr auto & value{ L"Windows.Storage.ISetVersionRequest" };
    };
    template <> struct name<Windows::Storage::IStorageFile>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFile" };
    };
    template <> struct name<Windows::Storage::IStorageFile2>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFile2" };
    };
    template <> struct name<Windows::Storage::IStorageFilePropertiesWithAvailability>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFilePropertiesWithAvailability" };
    };
    template <> struct name<Windows::Storage::IStorageFileStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFileStatics" };
    };
    template <> struct name<Windows::Storage::IStorageFileStatics2>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFileStatics2" };
    };
    template <> struct name<Windows::Storage::IStorageFolder>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFolder" };
    };
    template <> struct name<Windows::Storage::IStorageFolder2>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFolder2" };
    };
    template <> struct name<Windows::Storage::IStorageFolder3>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFolder3" };
    };
    template <> struct name<Windows::Storage::IStorageFolderStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFolderStatics" };
    };
    template <> struct name<Windows::Storage::IStorageFolderStatics2>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageFolderStatics2" };
    };
    template <> struct name<Windows::Storage::IStorageItem>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageItem" };
    };
    template <> struct name<Windows::Storage::IStorageItem2>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageItem2" };
    };
    template <> struct name<Windows::Storage::IStorageItemProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageItemProperties" };
    };
    template <> struct name<Windows::Storage::IStorageItemProperties2>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageItemProperties2" };
    };
    template <> struct name<Windows::Storage::IStorageItemPropertiesWithProvider>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageItemPropertiesWithProvider" };
    };
    template <> struct name<Windows::Storage::IStorageLibrary>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageLibrary" };
    };
    template <> struct name<Windows::Storage::IStorageLibrary2>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageLibrary2" };
    };
    template <> struct name<Windows::Storage::IStorageLibrary3>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageLibrary3" };
    };
    template <> struct name<Windows::Storage::IStorageLibraryChange>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageLibraryChange" };
    };
    template <> struct name<Windows::Storage::IStorageLibraryChangeReader>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageLibraryChangeReader" };
    };
    template <> struct name<Windows::Storage::IStorageLibraryChangeTracker>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageLibraryChangeTracker" };
    };
    template <> struct name<Windows::Storage::IStorageLibraryStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageLibraryStatics" };
    };
    template <> struct name<Windows::Storage::IStorageLibraryStatics2>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageLibraryStatics2" };
    };
    template <> struct name<Windows::Storage::IStorageProvider>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageProvider" };
    };
    template <> struct name<Windows::Storage::IStorageProvider2>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageProvider2" };
    };
    template <> struct name<Windows::Storage::IStorageStreamTransaction>
    {
        static constexpr auto & value{ L"Windows.Storage.IStorageStreamTransaction" };
    };
    template <> struct name<Windows::Storage::IStreamedFileDataRequest>
    {
        static constexpr auto & value{ L"Windows.Storage.IStreamedFileDataRequest" };
    };
    template <> struct name<Windows::Storage::ISystemAudioProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemAudioProperties" };
    };
    template <> struct name<Windows::Storage::ISystemDataPaths>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemDataPaths" };
    };
    template <> struct name<Windows::Storage::ISystemDataPathsStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemDataPathsStatics" };
    };
    template <> struct name<Windows::Storage::ISystemGPSProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemGPSProperties" };
    };
    template <> struct name<Windows::Storage::ISystemImageProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemImageProperties" };
    };
    template <> struct name<Windows::Storage::ISystemMediaProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemMediaProperties" };
    };
    template <> struct name<Windows::Storage::ISystemMusicProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemMusicProperties" };
    };
    template <> struct name<Windows::Storage::ISystemPhotoProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemPhotoProperties" };
    };
    template <> struct name<Windows::Storage::ISystemProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemProperties" };
    };
    template <> struct name<Windows::Storage::ISystemVideoProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.ISystemVideoProperties" };
    };
    template <> struct name<Windows::Storage::IUserDataPaths>
    {
        static constexpr auto & value{ L"Windows.Storage.IUserDataPaths" };
    };
    template <> struct name<Windows::Storage::IUserDataPathsStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.IUserDataPathsStatics" };
    };
    template <> struct name<Windows::Storage::AppDataPaths>
    {
        static constexpr auto & value{ L"Windows.Storage.AppDataPaths" };
    };
    template <> struct name<Windows::Storage::ApplicationData>
    {
        static constexpr auto & value{ L"Windows.Storage.ApplicationData" };
    };
    template <> struct name<Windows::Storage::ApplicationDataCompositeValue>
    {
        static constexpr auto & value{ L"Windows.Storage.ApplicationDataCompositeValue" };
    };
    template <> struct name<Windows::Storage::ApplicationDataContainer>
    {
        static constexpr auto & value{ L"Windows.Storage.ApplicationDataContainer" };
    };
    template <> struct name<Windows::Storage::ApplicationDataContainerSettings>
    {
        static constexpr auto & value{ L"Windows.Storage.ApplicationDataContainerSettings" };
    };
    template <> struct name<Windows::Storage::CachedFileManager>
    {
        static constexpr auto & value{ L"Windows.Storage.CachedFileManager" };
    };
    template <> struct name<Windows::Storage::DownloadsFolder>
    {
        static constexpr auto & value{ L"Windows.Storage.DownloadsFolder" };
    };
    template <> struct name<Windows::Storage::FileIO>
    {
        static constexpr auto & value{ L"Windows.Storage.FileIO" };
    };
    template <> struct name<Windows::Storage::KnownFolders>
    {
        static constexpr auto & value{ L"Windows.Storage.KnownFolders" };
    };
    template <> struct name<Windows::Storage::PathIO>
    {
        static constexpr auto & value{ L"Windows.Storage.PathIO" };
    };
    template <> struct name<Windows::Storage::SetVersionDeferral>
    {
        static constexpr auto & value{ L"Windows.Storage.SetVersionDeferral" };
    };
    template <> struct name<Windows::Storage::SetVersionRequest>
    {
        static constexpr auto & value{ L"Windows.Storage.SetVersionRequest" };
    };
    template <> struct name<Windows::Storage::StorageFile>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageFile" };
    };
    template <> struct name<Windows::Storage::StorageFolder>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageFolder" };
    };
    template <> struct name<Windows::Storage::StorageLibrary>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageLibrary" };
    };
    template <> struct name<Windows::Storage::StorageLibraryChange>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageLibraryChange" };
    };
    template <> struct name<Windows::Storage::StorageLibraryChangeReader>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageLibraryChangeReader" };
    };
    template <> struct name<Windows::Storage::StorageLibraryChangeTracker>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageLibraryChangeTracker" };
    };
    template <> struct name<Windows::Storage::StorageProvider>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageProvider" };
    };
    template <> struct name<Windows::Storage::StorageStreamTransaction>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageStreamTransaction" };
    };
    template <> struct name<Windows::Storage::StreamedFileDataRequest>
    {
        static constexpr auto & value{ L"Windows.Storage.StreamedFileDataRequest" };
    };
    template <> struct name<Windows::Storage::SystemAudioProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.SystemAudioProperties" };
    };
    template <> struct name<Windows::Storage::SystemDataPaths>
    {
        static constexpr auto & value{ L"Windows.Storage.SystemDataPaths" };
    };
    template <> struct name<Windows::Storage::SystemGPSProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.SystemGPSProperties" };
    };
    template <> struct name<Windows::Storage::SystemImageProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.SystemImageProperties" };
    };
    template <> struct name<Windows::Storage::SystemMediaProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.SystemMediaProperties" };
    };
    template <> struct name<Windows::Storage::SystemMusicProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.SystemMusicProperties" };
    };
    template <> struct name<Windows::Storage::SystemPhotoProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.SystemPhotoProperties" };
    };
    template <> struct name<Windows::Storage::SystemProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.SystemProperties" };
    };
    template <> struct name<Windows::Storage::SystemVideoProperties>
    {
        static constexpr auto & value{ L"Windows.Storage.SystemVideoProperties" };
    };
    template <> struct name<Windows::Storage::UserDataPaths>
    {
        static constexpr auto & value{ L"Windows.Storage.UserDataPaths" };
    };
    template <> struct name<Windows::Storage::ApplicationDataCreateDisposition>
    {
        static constexpr auto & value{ L"Windows.Storage.ApplicationDataCreateDisposition" };
    };
    template <> struct name<Windows::Storage::ApplicationDataLocality>
    {
        static constexpr auto & value{ L"Windows.Storage.ApplicationDataLocality" };
    };
    template <> struct name<Windows::Storage::CreationCollisionOption>
    {
        static constexpr auto & value{ L"Windows.Storage.CreationCollisionOption" };
    };
    template <> struct name<Windows::Storage::FileAccessMode>
    {
        static constexpr auto & value{ L"Windows.Storage.FileAccessMode" };
    };
    template <> struct name<Windows::Storage::FileAttributes>
    {
        static constexpr auto & value{ L"Windows.Storage.FileAttributes" };
    };
    template <> struct name<Windows::Storage::KnownFolderId>
    {
        static constexpr auto & value{ L"Windows.Storage.KnownFolderId" };
    };
    template <> struct name<Windows::Storage::KnownFoldersAccessStatus>
    {
        static constexpr auto & value{ L"Windows.Storage.KnownFoldersAccessStatus" };
    };
    template <> struct name<Windows::Storage::KnownLibraryId>
    {
        static constexpr auto & value{ L"Windows.Storage.KnownLibraryId" };
    };
    template <> struct name<Windows::Storage::NameCollisionOption>
    {
        static constexpr auto & value{ L"Windows.Storage.NameCollisionOption" };
    };
    template <> struct name<Windows::Storage::StorageDeleteOption>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageDeleteOption" };
    };
    template <> struct name<Windows::Storage::StorageItemTypes>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageItemTypes" };
    };
    template <> struct name<Windows::Storage::StorageLibraryChangeType>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageLibraryChangeType" };
    };
    template <> struct name<Windows::Storage::StorageOpenOptions>
    {
        static constexpr auto & value{ L"Windows.Storage.StorageOpenOptions" };
    };
    template <> struct name<Windows::Storage::StreamedFileFailureMode>
    {
        static constexpr auto & value{ L"Windows.Storage.StreamedFileFailureMode" };
    };
    template <> struct name<Windows::Storage::ApplicationDataSetVersionHandler>
    {
        static constexpr auto & value{ L"Windows.Storage.ApplicationDataSetVersionHandler" };
    };
    template <> struct name<Windows::Storage::StreamedFileDataRequestedHandler>
    {
        static constexpr auto & value{ L"Windows.Storage.StreamedFileDataRequestedHandler" };
    };
    template <> struct guid_storage<Windows::Storage::IAppDataPaths>
    {
        static constexpr guid value{ 0x7301D60A,0x79A2,0x48C9,{ 0x9E,0xC0,0x3F,0xDA,0x09,0x2F,0x79,0xE1 } };
    };
    template <> struct guid_storage<Windows::Storage::IAppDataPathsStatics>
    {
        static constexpr guid value{ 0xD8EB2AFE,0xA9D9,0x4B14,{ 0xB9,0x99,0xE3,0x92,0x13,0x79,0xD9,0x03 } };
    };
    template <> struct guid_storage<Windows::Storage::IApplicationData>
    {
        static constexpr guid value{ 0xC3DA6FB7,0xB744,0x4B45,{ 0xB0,0xB8,0x22,0x3A,0x09,0x38,0xD0,0xDC } };
    };
    template <> struct guid_storage<Windows::Storage::IApplicationData2>
    {
        static constexpr guid value{ 0x9E65CD69,0x0BA3,0x4E32,{ 0xBE,0x29,0xB0,0x2D,0xE6,0x60,0x76,0x38 } };
    };
    template <> struct guid_storage<Windows::Storage::IApplicationData3>
    {
        static constexpr guid value{ 0xDC222CF4,0x2772,0x4C1D,{ 0xAA,0x2C,0xC9,0xF7,0x43,0xAD,0xE8,0xD1 } };
    };
    template <> struct guid_storage<Windows::Storage::IApplicationDataContainer>
    {
        static constexpr guid value{ 0xC5AEFD1E,0xF467,0x40BA,{ 0x85,0x66,0xAB,0x64,0x0A,0x44,0x1E,0x1D } };
    };
    template <> struct guid_storage<Windows::Storage::IApplicationDataStatics>
    {
        static constexpr guid value{ 0x5612147B,0xE843,0x45E3,{ 0x94,0xD8,0x06,0x16,0x9E,0x3C,0x8E,0x17 } };
    };
    template <> struct guid_storage<Windows::Storage::IApplicationDataStatics2>
    {
        static constexpr guid value{ 0xCD606211,0xCF49,0x40A4,{ 0xA4,0x7C,0xC7,0xF0,0xDB,0xBA,0x81,0x07 } };
    };
    template <> struct guid_storage<Windows::Storage::ICachedFileManagerStatics>
    {
        static constexpr guid value{ 0x8FFC224A,0xE782,0x495D,{ 0xB6,0x14,0x65,0x4C,0x4F,0x0B,0x23,0x70 } };
    };
    template <> struct guid_storage<Windows::Storage::IDownloadsFolderStatics>
    {
        static constexpr guid value{ 0x27862ED0,0x404E,0x47DF,{ 0xA1,0xE2,0xE3,0x73,0x08,0xBE,0x7B,0x37 } };
    };
    template <> struct guid_storage<Windows::Storage::IDownloadsFolderStatics2>
    {
        static constexpr guid value{ 0xE93045BD,0x8EF8,0x4F8E,{ 0x8D,0x15,0xAC,0x0E,0x26,0x5F,0x39,0x0D } };
    };
    template <> struct guid_storage<Windows::Storage::IFileIOStatics>
    {
        static constexpr guid value{ 0x887411EB,0x7F54,0x4732,{ 0xA5,0xF0,0x5E,0x43,0xE3,0xB8,0xC2,0xF5 } };
    };
    template <> struct guid_storage<Windows::Storage::IKnownFoldersCameraRollStatics>
    {
        static constexpr guid value{ 0x5D115E66,0x27E8,0x492F,{ 0xB8,0xE5,0x2F,0x90,0x89,0x6C,0xD4,0xCD } };
    };
    template <> struct guid_storage<Windows::Storage::IKnownFoldersPlaylistsStatics>
    {
        static constexpr guid value{ 0xDAD5ECD6,0x306F,0x4D6A,{ 0xB4,0x96,0x46,0xBA,0x8E,0xB1,0x06,0xCE } };
    };
    template <> struct guid_storage<Windows::Storage::IKnownFoldersSavedPicturesStatics>
    {
        static constexpr guid value{ 0x055C93EA,0x253D,0x467C,{ 0xB6,0xCA,0xA9,0x7D,0xA1,0xE9,0xA1,0x8D } };
    };
    template <> struct guid_storage<Windows::Storage::IKnownFoldersStatics>
    {
        static constexpr guid value{ 0x5A2A7520,0x4802,0x452D,{ 0x9A,0xD9,0x43,0x51,0xAD,0xA7,0xEC,0x35 } };
    };
    template <> struct guid_storage<Windows::Storage::IKnownFoldersStatics2>
    {
        static constexpr guid value{ 0x194BD0CD,0xCF6E,0x4D07,{ 0x9D,0x53,0xE9,0x16,0x3A,0x25,0x36,0xE9 } };
    };
    template <> struct guid_storage<Windows::Storage::IKnownFoldersStatics3>
    {
        static constexpr guid value{ 0xC5194341,0x9742,0x4ED5,{ 0x82,0x3D,0xFC,0x14,0x01,0x14,0x87,0x64 } };
    };
    template <> struct guid_storage<Windows::Storage::IKnownFoldersStatics4>
    {
        static constexpr guid value{ 0x1722E6BF,0x9FF9,0x4B21,{ 0xBE,0xD5,0x90,0xEC,0xB1,0x3A,0x19,0x2E } };
    };
    template <> struct guid_storage<Windows::Storage::IPathIOStatics>
    {
        static constexpr guid value{ 0x0F2F3758,0x8EC7,0x4381,{ 0x92,0x2B,0x8F,0x6C,0x07,0xD2,0x88,0xF3 } };
    };
    template <> struct guid_storage<Windows::Storage::ISetVersionDeferral>
    {
        static constexpr guid value{ 0x033508A2,0x781A,0x437A,{ 0xB0,0x78,0x3F,0x32,0xBA,0xDC,0xFE,0x47 } };
    };
    template <> struct guid_storage<Windows::Storage::ISetVersionRequest>
    {
        static constexpr guid value{ 0xB9C76B9B,0x1056,0x4E69,{ 0x83,0x30,0x16,0x26,0x19,0x95,0x6F,0x9B } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFile>
    {
        static constexpr guid value{ 0xFA3F6186,0x4214,0x428C,{ 0xA6,0x4C,0x14,0xC9,0xAC,0x73,0x15,0xEA } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFile2>
    {
        static constexpr guid value{ 0x954E4BCF,0x0A77,0x42FB,{ 0xB7,0x77,0xC2,0xED,0x58,0xA5,0x2E,0x44 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFilePropertiesWithAvailability>
    {
        static constexpr guid value{ 0xAFCBBE9B,0x582B,0x4133,{ 0x96,0x48,0xE4,0x4C,0xA4,0x6E,0xE4,0x91 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFileStatics>
    {
        static constexpr guid value{ 0x5984C710,0xDAF2,0x43C8,{ 0x8B,0xB4,0xA4,0xD3,0xEA,0xCF,0xD0,0x3F } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFileStatics2>
    {
        static constexpr guid value{ 0x5C76A781,0x212E,0x4AF9,{ 0x8F,0x04,0x74,0x0C,0xAE,0x10,0x89,0x74 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFolder>
    {
        static constexpr guid value{ 0x72D1CB78,0xB3EF,0x4F75,{ 0xA8,0x0B,0x6F,0xD9,0xDA,0xE2,0x94,0x4B } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFolder2>
    {
        static constexpr guid value{ 0xE827E8B9,0x08D9,0x4A8E,{ 0xA0,0xAC,0xFE,0x5E,0xD3,0xCB,0xBB,0xD3 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFolder3>
    {
        static constexpr guid value{ 0x9F617899,0xBDE1,0x4124,{ 0xAE,0xB3,0xB0,0x6A,0xD9,0x6F,0x98,0xD4 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFolderStatics>
    {
        static constexpr guid value{ 0x08F327FF,0x85D5,0x48B9,{ 0xAE,0xE9,0x28,0x51,0x1E,0x33,0x9F,0x9F } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageFolderStatics2>
    {
        static constexpr guid value{ 0xB4656DC3,0x71D2,0x467D,{ 0x8B,0x29,0x37,0x1F,0x0F,0x62,0xBF,0x6F } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageItem>
    {
        static constexpr guid value{ 0x4207A996,0xCA2F,0x42F7,{ 0xBD,0xE8,0x8B,0x10,0x45,0x7A,0x7F,0x30 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageItem2>
    {
        static constexpr guid value{ 0x53F926D2,0x083C,0x4283,{ 0xB4,0x5B,0x81,0xC0,0x07,0x23,0x7E,0x44 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageItemProperties>
    {
        static constexpr guid value{ 0x86664478,0x8029,0x46FE,{ 0xA7,0x89,0x1C,0x2F,0x3E,0x2F,0xFB,0x5C } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageItemProperties2>
    {
        static constexpr guid value{ 0x8E86A951,0x04B9,0x4BD2,{ 0x92,0x9D,0xFE,0xF3,0xF7,0x16,0x21,0xD0 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageItemPropertiesWithProvider>
    {
        static constexpr guid value{ 0x861BF39B,0x6368,0x4DEE,{ 0xB4,0x0E,0x74,0x68,0x4A,0x5C,0xE7,0x14 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageLibrary>
    {
        static constexpr guid value{ 0x1EDD7103,0x0E5E,0x4D6C,{ 0xB5,0xE8,0x93,0x18,0x98,0x3D,0x6A,0x03 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageLibrary2>
    {
        static constexpr guid value{ 0x5B0CE348,0xFCB3,0x4031,{ 0xAF,0xB0,0xA6,0x8D,0x7B,0xD4,0x45,0x34 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageLibrary3>
    {
        static constexpr guid value{ 0x8A281291,0x2154,0x4201,{ 0x81,0x13,0xD2,0xC0,0x5C,0xE1,0xAD,0x23 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageLibraryChange>
    {
        static constexpr guid value{ 0x00980B23,0x2BE2,0x4909,{ 0xAA,0x48,0x15,0x9F,0x52,0x03,0xA5,0x1E } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageLibraryChangeReader>
    {
        static constexpr guid value{ 0xF205BC83,0xFCA2,0x41F9,{ 0x89,0x54,0xEE,0x2E,0x99,0x1E,0xB9,0x6F } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageLibraryChangeTracker>
    {
        static constexpr guid value{ 0x9E157316,0x6073,0x44F6,{ 0x96,0x81,0x74,0x92,0xD1,0x28,0x6C,0x90 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageLibraryStatics>
    {
        static constexpr guid value{ 0x4208A6DB,0x684A,0x49C6,{ 0x9E,0x59,0x90,0x12,0x1E,0xE0,0x50,0xD6 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageLibraryStatics2>
    {
        static constexpr guid value{ 0xFFB08DDC,0xFA75,0x4695,{ 0xB9,0xD1,0x7F,0x81,0xF9,0x78,0x32,0xE3 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageProvider>
    {
        static constexpr guid value{ 0xE705EED4,0xD478,0x47D6,{ 0xBA,0x46,0x1A,0x8E,0xBE,0x11,0x4A,0x20 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageProvider2>
    {
        static constexpr guid value{ 0x010D1917,0x3404,0x414B,{ 0x9F,0xD7,0xCD,0x44,0x47,0x2E,0xAA,0x39 } };
    };
    template <> struct guid_storage<Windows::Storage::IStorageStreamTransaction>
    {
        static constexpr guid value{ 0xF67CF363,0xA53D,0x4D94,{ 0xAE,0x2C,0x67,0x23,0x2D,0x93,0xAC,0xDD } };
    };
    template <> struct guid_storage<Windows::Storage::IStreamedFileDataRequest>
    {
        static constexpr guid value{ 0x1673FCCE,0xDABD,0x4D50,{ 0xBE,0xEE,0x18,0x0B,0x8A,0x81,0x91,0xB6 } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemAudioProperties>
    {
        static constexpr guid value{ 0x3F8F38B7,0x308C,0x47E1,{ 0x92,0x4D,0x86,0x45,0x34,0x8E,0x5D,0xB7 } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemDataPaths>
    {
        static constexpr guid value{ 0xE32ABF70,0xD8FA,0x45EC,{ 0xA9,0x42,0xD2,0xE2,0x6F,0xB6,0x0B,0xA5 } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemDataPathsStatics>
    {
        static constexpr guid value{ 0xE0F96FD0,0x9920,0x4BCA,{ 0xB3,0x79,0xF9,0x6F,0xDF,0x7C,0xAA,0xD8 } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemGPSProperties>
    {
        static constexpr guid value{ 0xC0F46EB4,0xC174,0x481A,{ 0xBC,0x25,0x92,0x19,0x86,0xF6,0xA6,0xF3 } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemImageProperties>
    {
        static constexpr guid value{ 0x011B2E30,0x8B39,0x4308,{ 0xBE,0xA1,0xE8,0xAA,0x61,0xE4,0x78,0x26 } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemMediaProperties>
    {
        static constexpr guid value{ 0xA42B3316,0x8415,0x40DC,{ 0x8C,0x44,0x98,0x36,0x1D,0x23,0x54,0x30 } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemMusicProperties>
    {
        static constexpr guid value{ 0xB47988D5,0x67AF,0x4BC3,{ 0x8D,0x39,0x5B,0x89,0x02,0x20,0x26,0xA1 } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemPhotoProperties>
    {
        static constexpr guid value{ 0x4734FC3D,0xAB21,0x4424,{ 0xB7,0x35,0xF4,0x35,0x3A,0x56,0xC8,0xFC } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemProperties>
    {
        static constexpr guid value{ 0x917A71C1,0x85F3,0x4DD1,{ 0xB0,0x01,0xA5,0x0B,0xFD,0x21,0xC8,0xD2 } };
    };
    template <> struct guid_storage<Windows::Storage::ISystemVideoProperties>
    {
        static constexpr guid value{ 0x2040F715,0x67F8,0x4322,{ 0x9B,0x80,0x4F,0xA9,0xFE,0xFB,0x83,0xE8 } };
    };
    template <> struct guid_storage<Windows::Storage::IUserDataPaths>
    {
        static constexpr guid value{ 0xF9C53912,0xABC4,0x46FF,{ 0x8A,0x2B,0xDC,0x9D,0x7F,0xA6,0xE5,0x2F } };
    };
    template <> struct guid_storage<Windows::Storage::IUserDataPathsStatics>
    {
        static constexpr guid value{ 0x01B29DEF,0xE062,0x48A1,{ 0x8B,0x0C,0xF2,0xC7,0xA9,0xCA,0x56,0xC0 } };
    };
    template <> struct guid_storage<Windows::Storage::ApplicationDataSetVersionHandler>
    {
        static constexpr guid value{ 0xA05791E6,0xCC9F,0x4687,{ 0xAC,0xAB,0xA3,0x64,0xFD,0x78,0x54,0x63 } };
    };
    template <> struct guid_storage<Windows::Storage::StreamedFileDataRequestedHandler>
    {
        static constexpr guid value{ 0xFEF6A824,0x2FE1,0x4D07,{ 0xA3,0x5B,0xB7,0x7C,0x50,0xB5,0xF4,0xCC } };
    };
    template <> struct default_interface<Windows::Storage::AppDataPaths>
    {
        using type = Windows::Storage::IAppDataPaths;
    };
    template <> struct default_interface<Windows::Storage::ApplicationData>
    {
        using type = Windows::Storage::IApplicationData;
    };
    template <> struct default_interface<Windows::Storage::ApplicationDataCompositeValue>
    {
        using type = Windows::Foundation::Collections::IPropertySet;
    };
    template <> struct default_interface<Windows::Storage::ApplicationDataContainer>
    {
        using type = Windows::Storage::IApplicationDataContainer;
    };
    template <> struct default_interface<Windows::Storage::ApplicationDataContainerSettings>
    {
        using type = Windows::Foundation::Collections::IPropertySet;
    };
    template <> struct default_interface<Windows::Storage::SetVersionDeferral>
    {
        using type = Windows::Storage::ISetVersionDeferral;
    };
    template <> struct default_interface<Windows::Storage::SetVersionRequest>
    {
        using type = Windows::Storage::ISetVersionRequest;
    };
    template <> struct default_interface<Windows::Storage::StorageFile>
    {
        using type = Windows::Storage::IStorageFile;
    };
    template <> struct default_interface<Windows::Storage::StorageFolder>
    {
        using type = Windows::Storage::IStorageFolder;
    };
    template <> struct default_interface<Windows::Storage::StorageLibrary>
    {
        using type = Windows::Storage::IStorageLibrary;
    };
    template <> struct default_interface<Windows::Storage::StorageLibraryChange>
    {
        using type = Windows::Storage::IStorageLibraryChange;
    };
    template <> struct default_interface<Windows::Storage::StorageLibraryChangeReader>
    {
        using type = Windows::Storage::IStorageLibraryChangeReader;
    };
    template <> struct default_interface<Windows::Storage::StorageLibraryChangeTracker>
    {
        using type = Windows::Storage::IStorageLibraryChangeTracker;
    };
    template <> struct default_interface<Windows::Storage::StorageProvider>
    {
        using type = Windows::Storage::IStorageProvider;
    };
    template <> struct default_interface<Windows::Storage::StorageStreamTransaction>
    {
        using type = Windows::Storage::IStorageStreamTransaction;
    };
    template <> struct default_interface<Windows::Storage::StreamedFileDataRequest>
    {
        using type = Windows::Storage::Streams::IOutputStream;
    };
    template <> struct default_interface<Windows::Storage::SystemAudioProperties>
    {
        using type = Windows::Storage::ISystemAudioProperties;
    };
    template <> struct default_interface<Windows::Storage::SystemDataPaths>
    {
        using type = Windows::Storage::ISystemDataPaths;
    };
    template <> struct default_interface<Windows::Storage::SystemGPSProperties>
    {
        using type = Windows::Storage::ISystemGPSProperties;
    };
    template <> struct default_interface<Windows::Storage::SystemImageProperties>
    {
        using type = Windows::Storage::ISystemImageProperties;
    };
    template <> struct default_interface<Windows::Storage::SystemMediaProperties>
    {
        using type = Windows::Storage::ISystemMediaProperties;
    };
    template <> struct default_interface<Windows::Storage::SystemMusicProperties>
    {
        using type = Windows::Storage::ISystemMusicProperties;
    };
    template <> struct default_interface<Windows::Storage::SystemPhotoProperties>
    {
        using type = Windows::Storage::ISystemPhotoProperties;
    };
    template <> struct default_interface<Windows::Storage::SystemVideoProperties>
    {
        using type = Windows::Storage::ISystemVideoProperties;
    };
    template <> struct default_interface<Windows::Storage::UserDataPaths>
    {
        using type = Windows::Storage::IUserDataPaths;
    };
    template <> struct abi<Windows::Storage::IAppDataPaths>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Cookies(void**) noexcept = 0;
            virtual int32_t __stdcall get_Desktop(void**) noexcept = 0;
            virtual int32_t __stdcall get_Documents(void**) noexcept = 0;
            virtual int32_t __stdcall get_Favorites(void**) noexcept = 0;
            virtual int32_t __stdcall get_History(void**) noexcept = 0;
            virtual int32_t __stdcall get_InternetCache(void**) noexcept = 0;
            virtual int32_t __stdcall get_LocalAppData(void**) noexcept = 0;
            virtual int32_t __stdcall get_ProgramData(void**) noexcept = 0;
            virtual int32_t __stdcall get_RoamingAppData(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IAppDataPathsStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetForUser(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetDefault(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IApplicationData>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Version(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall SetVersionAsync(uint32_t, void*, void**) noexcept = 0;
            virtual int32_t __stdcall ClearAllAsync(void**) noexcept = 0;
            virtual int32_t __stdcall ClearAsync(int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall get_LocalSettings(void**) noexcept = 0;
            virtual int32_t __stdcall get_RoamingSettings(void**) noexcept = 0;
            virtual int32_t __stdcall get_LocalFolder(void**) noexcept = 0;
            virtual int32_t __stdcall get_RoamingFolder(void**) noexcept = 0;
            virtual int32_t __stdcall get_TemporaryFolder(void**) noexcept = 0;
            virtual int32_t __stdcall add_DataChanged(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_DataChanged(winrt::event_token) noexcept = 0;
            virtual int32_t __stdcall SignalDataChanged() noexcept = 0;
            virtual int32_t __stdcall get_RoamingStorageQuota(uint64_t*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IApplicationData2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_LocalCacheFolder(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IApplicationData3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetPublisherCacheFolder(void*, void**) noexcept = 0;
            virtual int32_t __stdcall ClearPublisherCacheFolderAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall get_SharedLocalFolder(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IApplicationDataContainer>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Name(void**) noexcept = 0;
            virtual int32_t __stdcall get_Locality(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Values(void**) noexcept = 0;
            virtual int32_t __stdcall get_Containers(void**) noexcept = 0;
            virtual int32_t __stdcall CreateContainer(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall DeleteContainer(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IApplicationDataStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Current(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IApplicationDataStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetForUserAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ICachedFileManagerStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall DeferUpdates(void*) noexcept = 0;
            virtual int32_t __stdcall CompleteUpdatesAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IDownloadsFolderStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateFileAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFolderAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFileWithCollisionOptionAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFolderWithCollisionOptionAsync(void*, int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IDownloadsFolderStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateFileForUserAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFolderForUserAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFileForUserWithCollisionOptionAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFolderForUserWithCollisionOptionAsync(void*, void*, int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IFileIOStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall ReadTextAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall ReadTextWithEncodingAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall WriteTextAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall WriteTextWithEncodingAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall AppendTextAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall AppendTextWithEncodingAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall ReadLinesAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall ReadLinesWithEncodingAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall WriteLinesAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall WriteLinesWithEncodingAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall AppendLinesAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall AppendLinesWithEncodingAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall ReadBufferAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall WriteBufferAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall WriteBytesAsync(void*, uint32_t, uint8_t*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IKnownFoldersCameraRollStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_CameraRoll(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IKnownFoldersPlaylistsStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Playlists(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IKnownFoldersSavedPicturesStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_SavedPictures(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IKnownFoldersStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_MusicLibrary(void**) noexcept = 0;
            virtual int32_t __stdcall get_PicturesLibrary(void**) noexcept = 0;
            virtual int32_t __stdcall get_VideosLibrary(void**) noexcept = 0;
            virtual int32_t __stdcall get_DocumentsLibrary(void**) noexcept = 0;
            virtual int32_t __stdcall get_HomeGroup(void**) noexcept = 0;
            virtual int32_t __stdcall get_RemovableDevices(void**) noexcept = 0;
            virtual int32_t __stdcall get_MediaServerDevices(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IKnownFoldersStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Objects3D(void**) noexcept = 0;
            virtual int32_t __stdcall get_AppCaptures(void**) noexcept = 0;
            virtual int32_t __stdcall get_RecordedCalls(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IKnownFoldersStatics3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetFolderForUserAsync(void*, int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IKnownFoldersStatics4>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall RequestAccessAsync(int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall RequestAccessForUserAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetFolderAsync(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IPathIOStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall ReadTextAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall ReadTextWithEncodingAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall WriteTextAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall WriteTextWithEncodingAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall AppendTextAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall AppendTextWithEncodingAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall ReadLinesAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall ReadLinesWithEncodingAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall WriteLinesAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall WriteLinesWithEncodingAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall AppendLinesAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall AppendLinesWithEncodingAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall ReadBufferAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall WriteBufferAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall WriteBytesAsync(void*, uint32_t, uint8_t*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISetVersionDeferral>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Complete() noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISetVersionRequest>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_CurrentVersion(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall get_DesiredVersion(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall GetDeferral(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFile>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_FileType(void**) noexcept = 0;
            virtual int32_t __stdcall get_ContentType(void**) noexcept = 0;
            virtual int32_t __stdcall OpenAsync(int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall OpenTransactedWriteAsync(void**) noexcept = 0;
            virtual int32_t __stdcall CopyOverloadDefaultNameAndOptions(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CopyOverloadDefaultOptions(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall CopyOverload(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall CopyAndReplaceAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall MoveOverloadDefaultNameAndOptions(void*, void**) noexcept = 0;
            virtual int32_t __stdcall MoveOverloadDefaultOptions(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall MoveOverload(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall MoveAndReplaceAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFile2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall OpenWithOptionsAsync(int32_t, uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall OpenTransactedWriteWithOptionsAsync(uint32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFilePropertiesWithAvailability>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_IsAvailable(bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFileStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetFileFromPathAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetFileFromApplicationUriAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateStreamedFileAsync(void*, void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall ReplaceWithStreamedFileAsync(void*, void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateStreamedFileFromUriAsync(void*, void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall ReplaceWithStreamedFileFromUriAsync(void*, void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFileStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetFileFromPathForUserAsync(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFolder>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateFileAsyncOverloadDefaultOptions(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFileAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFolderAsyncOverloadDefaultOptions(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFolderAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetFileAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetFolderAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetItemAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetFilesAsyncOverloadDefaultOptionsStartAndCount(void**) noexcept = 0;
            virtual int32_t __stdcall GetFoldersAsyncOverloadDefaultOptionsStartAndCount(void**) noexcept = 0;
            virtual int32_t __stdcall GetItemsAsyncOverloadDefaultStartAndCount(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFolder2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall TryGetItemAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFolder3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall TryGetChangeTracker(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFolderStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetFolderFromPathAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageFolderStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetFolderFromPathForUserAsync(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageItem>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall RenameAsyncOverloadDefaultOptions(void*, void**) noexcept = 0;
            virtual int32_t __stdcall RenameAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall DeleteAsyncOverloadDefaultOptions(void**) noexcept = 0;
            virtual int32_t __stdcall DeleteAsync(int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetBasicPropertiesAsync(void**) noexcept = 0;
            virtual int32_t __stdcall get_Name(void**) noexcept = 0;
            virtual int32_t __stdcall get_Path(void**) noexcept = 0;
            virtual int32_t __stdcall get_Attributes(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall get_DateCreated(int64_t*) noexcept = 0;
            virtual int32_t __stdcall IsOfType(uint32_t, bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageItem2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetParentAsync(void**) noexcept = 0;
            virtual int32_t __stdcall IsEqual(void*, bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageItemProperties>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetThumbnailAsyncOverloadDefaultSizeDefaultOptions(int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetThumbnailAsyncOverloadDefaultOptions(int32_t, uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetThumbnailAsync(int32_t, uint32_t, uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall get_DisplayName(void**) noexcept = 0;
            virtual int32_t __stdcall get_DisplayType(void**) noexcept = 0;
            virtual int32_t __stdcall get_FolderRelativeId(void**) noexcept = 0;
            virtual int32_t __stdcall get_Properties(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageItemProperties2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetScaledImageAsThumbnailAsyncOverloadDefaultSizeDefaultOptions(int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetScaledImageAsThumbnailAsyncOverloadDefaultOptions(int32_t, uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetScaledImageAsThumbnailAsync(int32_t, uint32_t, uint32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageItemPropertiesWithProvider>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Provider(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageLibrary>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall RequestAddFolderAsync(void**) noexcept = 0;
            virtual int32_t __stdcall RequestRemoveFolderAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall get_Folders(void**) noexcept = 0;
            virtual int32_t __stdcall get_SaveFolder(void**) noexcept = 0;
            virtual int32_t __stdcall add_DefinitionChanged(void*, winrt::event_token*) noexcept = 0;
            virtual int32_t __stdcall remove_DefinitionChanged(winrt::event_token) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageLibrary2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ChangeTracker(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageLibrary3>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall AreFolderSuggestionsAvailableAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageLibraryChange>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ChangeType(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Path(void**) noexcept = 0;
            virtual int32_t __stdcall get_PreviousPath(void**) noexcept = 0;
            virtual int32_t __stdcall IsOfType(uint32_t, bool*) noexcept = 0;
            virtual int32_t __stdcall GetStorageItemAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageLibraryChangeReader>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall ReadBatchAsync(void**) noexcept = 0;
            virtual int32_t __stdcall AcceptChangesAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageLibraryChangeTracker>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetChangeReader(void**) noexcept = 0;
            virtual int32_t __stdcall Enable() noexcept = 0;
            virtual int32_t __stdcall Reset() noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageLibraryStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetLibraryAsync(int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageLibraryStatics2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetLibraryForUserAsync(void*, int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageProvider>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Id(void**) noexcept = 0;
            virtual int32_t __stdcall get_DisplayName(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageProvider2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall IsPropertySupportedForPartialFileAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStorageStreamTransaction>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Stream(void**) noexcept = 0;
            virtual int32_t __stdcall CommitAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IStreamedFileDataRequest>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall FailAndClose(int32_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemAudioProperties>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_EncodingBitrate(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemDataPaths>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Fonts(void**) noexcept = 0;
            virtual int32_t __stdcall get_ProgramData(void**) noexcept = 0;
            virtual int32_t __stdcall get_Public(void**) noexcept = 0;
            virtual int32_t __stdcall get_PublicDesktop(void**) noexcept = 0;
            virtual int32_t __stdcall get_PublicDocuments(void**) noexcept = 0;
            virtual int32_t __stdcall get_PublicDownloads(void**) noexcept = 0;
            virtual int32_t __stdcall get_PublicMusic(void**) noexcept = 0;
            virtual int32_t __stdcall get_PublicPictures(void**) noexcept = 0;
            virtual int32_t __stdcall get_PublicVideos(void**) noexcept = 0;
            virtual int32_t __stdcall get_System(void**) noexcept = 0;
            virtual int32_t __stdcall get_SystemHost(void**) noexcept = 0;
            virtual int32_t __stdcall get_SystemX86(void**) noexcept = 0;
            virtual int32_t __stdcall get_SystemX64(void**) noexcept = 0;
            virtual int32_t __stdcall get_SystemArm(void**) noexcept = 0;
            virtual int32_t __stdcall get_UserProfiles(void**) noexcept = 0;
            virtual int32_t __stdcall get_Windows(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemDataPathsStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetDefault(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemGPSProperties>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_LatitudeDecimal(void**) noexcept = 0;
            virtual int32_t __stdcall get_LongitudeDecimal(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemImageProperties>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_HorizontalSize(void**) noexcept = 0;
            virtual int32_t __stdcall get_VerticalSize(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemMediaProperties>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Duration(void**) noexcept = 0;
            virtual int32_t __stdcall get_Producer(void**) noexcept = 0;
            virtual int32_t __stdcall get_Publisher(void**) noexcept = 0;
            virtual int32_t __stdcall get_SubTitle(void**) noexcept = 0;
            virtual int32_t __stdcall get_Writer(void**) noexcept = 0;
            virtual int32_t __stdcall get_Year(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemMusicProperties>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_AlbumArtist(void**) noexcept = 0;
            virtual int32_t __stdcall get_AlbumTitle(void**) noexcept = 0;
            virtual int32_t __stdcall get_Artist(void**) noexcept = 0;
            virtual int32_t __stdcall get_Composer(void**) noexcept = 0;
            virtual int32_t __stdcall get_Conductor(void**) noexcept = 0;
            virtual int32_t __stdcall get_DisplayArtist(void**) noexcept = 0;
            virtual int32_t __stdcall get_Genre(void**) noexcept = 0;
            virtual int32_t __stdcall get_TrackNumber(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemPhotoProperties>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_CameraManufacturer(void**) noexcept = 0;
            virtual int32_t __stdcall get_CameraModel(void**) noexcept = 0;
            virtual int32_t __stdcall get_DateTaken(void**) noexcept = 0;
            virtual int32_t __stdcall get_Orientation(void**) noexcept = 0;
            virtual int32_t __stdcall get_PeopleNames(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemProperties>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Author(void**) noexcept = 0;
            virtual int32_t __stdcall get_Comment(void**) noexcept = 0;
            virtual int32_t __stdcall get_ItemNameDisplay(void**) noexcept = 0;
            virtual int32_t __stdcall get_Keywords(void**) noexcept = 0;
            virtual int32_t __stdcall get_Rating(void**) noexcept = 0;
            virtual int32_t __stdcall get_Title(void**) noexcept = 0;
            virtual int32_t __stdcall get_Audio(void**) noexcept = 0;
            virtual int32_t __stdcall get_GPS(void**) noexcept = 0;
            virtual int32_t __stdcall get_Media(void**) noexcept = 0;
            virtual int32_t __stdcall get_Music(void**) noexcept = 0;
            virtual int32_t __stdcall get_Photo(void**) noexcept = 0;
            virtual int32_t __stdcall get_Video(void**) noexcept = 0;
            virtual int32_t __stdcall get_Image(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ISystemVideoProperties>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Director(void**) noexcept = 0;
            virtual int32_t __stdcall get_FrameHeight(void**) noexcept = 0;
            virtual int32_t __stdcall get_FrameWidth(void**) noexcept = 0;
            virtual int32_t __stdcall get_Orientation(void**) noexcept = 0;
            virtual int32_t __stdcall get_TotalBitrate(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IUserDataPaths>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_CameraRoll(void**) noexcept = 0;
            virtual int32_t __stdcall get_Cookies(void**) noexcept = 0;
            virtual int32_t __stdcall get_Desktop(void**) noexcept = 0;
            virtual int32_t __stdcall get_Documents(void**) noexcept = 0;
            virtual int32_t __stdcall get_Downloads(void**) noexcept = 0;
            virtual int32_t __stdcall get_Favorites(void**) noexcept = 0;
            virtual int32_t __stdcall get_History(void**) noexcept = 0;
            virtual int32_t __stdcall get_InternetCache(void**) noexcept = 0;
            virtual int32_t __stdcall get_LocalAppData(void**) noexcept = 0;
            virtual int32_t __stdcall get_LocalAppDataLow(void**) noexcept = 0;
            virtual int32_t __stdcall get_Music(void**) noexcept = 0;
            virtual int32_t __stdcall get_Pictures(void**) noexcept = 0;
            virtual int32_t __stdcall get_Profile(void**) noexcept = 0;
            virtual int32_t __stdcall get_Recent(void**) noexcept = 0;
            virtual int32_t __stdcall get_RoamingAppData(void**) noexcept = 0;
            virtual int32_t __stdcall get_SavedPictures(void**) noexcept = 0;
            virtual int32_t __stdcall get_Screenshots(void**) noexcept = 0;
            virtual int32_t __stdcall get_Templates(void**) noexcept = 0;
            virtual int32_t __stdcall get_Videos(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::IUserDataPathsStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetForUser(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetDefault(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::ApplicationDataSetVersionHandler>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::StreamedFileDataRequestedHandler>
    {
        struct __declspec(novtable) type : unknown_abi
        {
            virtual int32_t __stdcall Invoke(void*) noexcept = 0;
        };
    };
    template <typename D>
    struct consume_Windows_Storage_IAppDataPaths
    {
        [[nodiscard]] auto Cookies() const;
        [[nodiscard]] auto Desktop() const;
        [[nodiscard]] auto Documents() const;
        [[nodiscard]] auto Favorites() const;
        [[nodiscard]] auto History() const;
        [[nodiscard]] auto InternetCache() const;
        [[nodiscard]] auto LocalAppData() const;
        [[nodiscard]] auto ProgramData() const;
        [[nodiscard]] auto RoamingAppData() const;
    };
    template <> struct consume<Windows::Storage::IAppDataPaths>
    {
        template <typename D> using type = consume_Windows_Storage_IAppDataPaths<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IAppDataPathsStatics
    {
        auto GetForUser(Windows::System::User const& user) const;
        auto GetDefault() const;
    };
    template <> struct consume<Windows::Storage::IAppDataPathsStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IAppDataPathsStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IApplicationData
    {
        [[nodiscard]] auto Version() const;
        auto SetVersionAsync(uint32_t desiredVersion, Windows::Storage::ApplicationDataSetVersionHandler const& handler) const;
        auto ClearAsync() const;
        auto ClearAsync(Windows::Storage::ApplicationDataLocality const& locality) const;
        [[nodiscard]] auto LocalSettings() const;
        [[nodiscard]] auto RoamingSettings() const;
        [[nodiscard]] auto LocalFolder() const;
        [[nodiscard]] auto RoamingFolder() const;
        [[nodiscard]] auto TemporaryFolder() const;
        auto DataChanged(Windows::Foundation::TypedEventHandler<Windows::Storage::ApplicationData, Windows::Foundation::IInspectable> const& handler) const;
        using DataChanged_revoker = impl::event_revoker<Windows::Storage::IApplicationData, &impl::abi_t<Windows::Storage::IApplicationData>::remove_DataChanged>;
        DataChanged_revoker DataChanged(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::Storage::ApplicationData, Windows::Foundation::IInspectable> const& handler) const;
        auto DataChanged(winrt::event_token const& token) const noexcept;
        auto SignalDataChanged() const;
        [[nodiscard]] auto RoamingStorageQuota() const;
    };
    template <> struct consume<Windows::Storage::IApplicationData>
    {
        template <typename D> using type = consume_Windows_Storage_IApplicationData<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IApplicationData2
    {
        [[nodiscard]] auto LocalCacheFolder() const;
    };
    template <> struct consume<Windows::Storage::IApplicationData2>
    {
        template <typename D> using type = consume_Windows_Storage_IApplicationData2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IApplicationData3
    {
        auto GetPublisherCacheFolder(param::hstring const& folderName) const;
        auto ClearPublisherCacheFolderAsync(param::hstring const& folderName) const;
        [[nodiscard]] auto SharedLocalFolder() const;
    };
    template <> struct consume<Windows::Storage::IApplicationData3>
    {
        template <typename D> using type = consume_Windows_Storage_IApplicationData3<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IApplicationDataContainer
    {
        [[nodiscard]] auto Name() const;
        [[nodiscard]] auto Locality() const;
        [[nodiscard]] auto Values() const;
        [[nodiscard]] auto Containers() const;
        auto CreateContainer(param::hstring const& name, Windows::Storage::ApplicationDataCreateDisposition const& disposition) const;
        auto DeleteContainer(param::hstring const& name) const;
    };
    template <> struct consume<Windows::Storage::IApplicationDataContainer>
    {
        template <typename D> using type = consume_Windows_Storage_IApplicationDataContainer<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IApplicationDataStatics
    {
        [[nodiscard]] auto Current() const;
    };
    template <> struct consume<Windows::Storage::IApplicationDataStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IApplicationDataStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IApplicationDataStatics2
    {
        auto GetForUserAsync(Windows::System::User const& user) const;
    };
    template <> struct consume<Windows::Storage::IApplicationDataStatics2>
    {
        template <typename D> using type = consume_Windows_Storage_IApplicationDataStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ICachedFileManagerStatics
    {
        auto DeferUpdates(Windows::Storage::IStorageFile const& file) const;
        auto CompleteUpdatesAsync(Windows::Storage::IStorageFile const& file) const;
    };
    template <> struct consume<Windows::Storage::ICachedFileManagerStatics>
    {
        template <typename D> using type = consume_Windows_Storage_ICachedFileManagerStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IDownloadsFolderStatics
    {
        auto CreateFileAsync(param::hstring const& desiredName) const;
        auto CreateFolderAsync(param::hstring const& desiredName) const;
        auto CreateFileAsync(param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& option) const;
        auto CreateFolderAsync(param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& option) const;
    };
    template <> struct consume<Windows::Storage::IDownloadsFolderStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IDownloadsFolderStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IDownloadsFolderStatics2
    {
        auto CreateFileForUserAsync(Windows::System::User const& user, param::hstring const& desiredName) const;
        auto CreateFolderForUserAsync(Windows::System::User const& user, param::hstring const& desiredName) const;
        auto CreateFileForUserAsync(Windows::System::User const& user, param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& option) const;
        auto CreateFolderForUserAsync(Windows::System::User const& user, param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& option) const;
    };
    template <> struct consume<Windows::Storage::IDownloadsFolderStatics2>
    {
        template <typename D> using type = consume_Windows_Storage_IDownloadsFolderStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IFileIOStatics
    {
        auto ReadTextAsync(Windows::Storage::IStorageFile const& file) const;
        auto ReadTextAsync(Windows::Storage::IStorageFile const& file, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto WriteTextAsync(Windows::Storage::IStorageFile const& file, param::hstring const& contents) const;
        auto WriteTextAsync(Windows::Storage::IStorageFile const& file, param::hstring const& contents, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto AppendTextAsync(Windows::Storage::IStorageFile const& file, param::hstring const& contents) const;
        auto AppendTextAsync(Windows::Storage::IStorageFile const& file, param::hstring const& contents, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto ReadLinesAsync(Windows::Storage::IStorageFile const& file) const;
        auto ReadLinesAsync(Windows::Storage::IStorageFile const& file, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto WriteLinesAsync(Windows::Storage::IStorageFile const& file, param::async_iterable<hstring> const& lines) const;
        auto WriteLinesAsync(Windows::Storage::IStorageFile const& file, param::async_iterable<hstring> const& lines, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto AppendLinesAsync(Windows::Storage::IStorageFile const& file, param::async_iterable<hstring> const& lines) const;
        auto AppendLinesAsync(Windows::Storage::IStorageFile const& file, param::async_iterable<hstring> const& lines, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto ReadBufferAsync(Windows::Storage::IStorageFile const& file) const;
        auto WriteBufferAsync(Windows::Storage::IStorageFile const& file, Windows::Storage::Streams::IBuffer const& buffer) const;
        auto WriteBytesAsync(Windows::Storage::IStorageFile const& file, array_view<uint8_t const> buffer) const;
    };
    template <> struct consume<Windows::Storage::IFileIOStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IFileIOStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IKnownFoldersCameraRollStatics
    {
        [[nodiscard]] auto CameraRoll() const;
    };
    template <> struct consume<Windows::Storage::IKnownFoldersCameraRollStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IKnownFoldersCameraRollStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IKnownFoldersPlaylistsStatics
    {
        [[nodiscard]] auto Playlists() const;
    };
    template <> struct consume<Windows::Storage::IKnownFoldersPlaylistsStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IKnownFoldersPlaylistsStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IKnownFoldersSavedPicturesStatics
    {
        [[nodiscard]] auto SavedPictures() const;
    };
    template <> struct consume<Windows::Storage::IKnownFoldersSavedPicturesStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IKnownFoldersSavedPicturesStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IKnownFoldersStatics
    {
        [[nodiscard]] auto MusicLibrary() const;
        [[nodiscard]] auto PicturesLibrary() const;
        [[nodiscard]] auto VideosLibrary() const;
        [[nodiscard]] auto DocumentsLibrary() const;
        [[nodiscard]] auto HomeGroup() const;
        [[nodiscard]] auto RemovableDevices() const;
        [[nodiscard]] auto MediaServerDevices() const;
    };
    template <> struct consume<Windows::Storage::IKnownFoldersStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IKnownFoldersStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IKnownFoldersStatics2
    {
        [[nodiscard]] auto Objects3D() const;
        [[nodiscard]] auto AppCaptures() const;
        [[nodiscard]] auto RecordedCalls() const;
    };
    template <> struct consume<Windows::Storage::IKnownFoldersStatics2>
    {
        template <typename D> using type = consume_Windows_Storage_IKnownFoldersStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IKnownFoldersStatics3
    {
        auto GetFolderForUserAsync(Windows::System::User const& user, Windows::Storage::KnownFolderId const& folderId) const;
    };
    template <> struct consume<Windows::Storage::IKnownFoldersStatics3>
    {
        template <typename D> using type = consume_Windows_Storage_IKnownFoldersStatics3<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IKnownFoldersStatics4
    {
        auto RequestAccessAsync(Windows::Storage::KnownFolderId const& folderId) const;
        auto RequestAccessForUserAsync(Windows::System::User const& user, Windows::Storage::KnownFolderId const& folderId) const;
        auto GetFolderAsync(Windows::Storage::KnownFolderId const& folderId) const;
    };
    template <> struct consume<Windows::Storage::IKnownFoldersStatics4>
    {
        template <typename D> using type = consume_Windows_Storage_IKnownFoldersStatics4<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IPathIOStatics
    {
        auto ReadTextAsync(param::hstring const& absolutePath) const;
        auto ReadTextAsync(param::hstring const& absolutePath, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto WriteTextAsync(param::hstring const& absolutePath, param::hstring const& contents) const;
        auto WriteTextAsync(param::hstring const& absolutePath, param::hstring const& contents, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto AppendTextAsync(param::hstring const& absolutePath, param::hstring const& contents) const;
        auto AppendTextAsync(param::hstring const& absolutePath, param::hstring const& contents, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto ReadLinesAsync(param::hstring const& absolutePath) const;
        auto ReadLinesAsync(param::hstring const& absolutePath, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto WriteLinesAsync(param::hstring const& absolutePath, param::async_iterable<hstring> const& lines) const;
        auto WriteLinesAsync(param::hstring const& absolutePath, param::async_iterable<hstring> const& lines, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto AppendLinesAsync(param::hstring const& absolutePath, param::async_iterable<hstring> const& lines) const;
        auto AppendLinesAsync(param::hstring const& absolutePath, param::async_iterable<hstring> const& lines, Windows::Storage::Streams::UnicodeEncoding const& encoding) const;
        auto ReadBufferAsync(param::hstring const& absolutePath) const;
        auto WriteBufferAsync(param::hstring const& absolutePath, Windows::Storage::Streams::IBuffer const& buffer) const;
        auto WriteBytesAsync(param::hstring const& absolutePath, array_view<uint8_t const> buffer) const;
    };
    template <> struct consume<Windows::Storage::IPathIOStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IPathIOStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISetVersionDeferral
    {
        auto Complete() const;
    };
    template <> struct consume<Windows::Storage::ISetVersionDeferral>
    {
        template <typename D> using type = consume_Windows_Storage_ISetVersionDeferral<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISetVersionRequest
    {
        [[nodiscard]] auto CurrentVersion() const;
        [[nodiscard]] auto DesiredVersion() const;
        auto GetDeferral() const;
    };
    template <> struct consume<Windows::Storage::ISetVersionRequest>
    {
        template <typename D> using type = consume_Windows_Storage_ISetVersionRequest<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFile
    {
        [[nodiscard]] auto FileType() const;
        [[nodiscard]] auto ContentType() const;
        auto OpenAsync(Windows::Storage::FileAccessMode const& accessMode) const;
        auto OpenTransactedWriteAsync() const;
        auto CopyAsync(Windows::Storage::IStorageFolder const& destinationFolder) const;
        auto CopyAsync(Windows::Storage::IStorageFolder const& destinationFolder, param::hstring const& desiredNewName) const;
        auto CopyAsync(Windows::Storage::IStorageFolder const& destinationFolder, param::hstring const& desiredNewName, Windows::Storage::NameCollisionOption const& option) const;
        auto CopyAndReplaceAsync(Windows::Storage::IStorageFile const& fileToReplace) const;
        auto MoveAsync(Windows::Storage::IStorageFolder const& destinationFolder) const;
        auto MoveAsync(Windows::Storage::IStorageFolder const& destinationFolder, param::hstring const& desiredNewName) const;
        auto MoveAsync(Windows::Storage::IStorageFolder const& destinationFolder, param::hstring const& desiredNewName, Windows::Storage::NameCollisionOption const& option) const;
        auto MoveAndReplaceAsync(Windows::Storage::IStorageFile const& fileToReplace) const;
    };
    template <> struct consume<Windows::Storage::IStorageFile>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFile<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFile2
    {
        auto OpenAsync(Windows::Storage::FileAccessMode const& accessMode, Windows::Storage::StorageOpenOptions const& options) const;
        auto OpenTransactedWriteAsync(Windows::Storage::StorageOpenOptions const& options) const;
    };
    template <> struct consume<Windows::Storage::IStorageFile2>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFile2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFilePropertiesWithAvailability
    {
        [[nodiscard]] auto IsAvailable() const;
    };
    template <> struct consume<Windows::Storage::IStorageFilePropertiesWithAvailability>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFilePropertiesWithAvailability<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFileStatics
    {
        auto GetFileFromPathAsync(param::hstring const& path) const;
        auto GetFileFromApplicationUriAsync(Windows::Foundation::Uri const& uri) const;
        auto CreateStreamedFileAsync(param::hstring const& displayNameWithExtension, Windows::Storage::StreamedFileDataRequestedHandler const& dataRequested, Windows::Storage::Streams::IRandomAccessStreamReference const& thumbnail) const;
        auto ReplaceWithStreamedFileAsync(Windows::Storage::IStorageFile const& fileToReplace, Windows::Storage::StreamedFileDataRequestedHandler const& dataRequested, Windows::Storage::Streams::IRandomAccessStreamReference const& thumbnail) const;
        auto CreateStreamedFileFromUriAsync(param::hstring const& displayNameWithExtension, Windows::Foundation::Uri const& uri, Windows::Storage::Streams::IRandomAccessStreamReference const& thumbnail) const;
        auto ReplaceWithStreamedFileFromUriAsync(Windows::Storage::IStorageFile const& fileToReplace, Windows::Foundation::Uri const& uri, Windows::Storage::Streams::IRandomAccessStreamReference const& thumbnail) const;
    };
    template <> struct consume<Windows::Storage::IStorageFileStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFileStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFileStatics2
    {
        auto GetFileFromPathForUserAsync(Windows::System::User const& user, param::hstring const& path) const;
    };
    template <> struct consume<Windows::Storage::IStorageFileStatics2>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFileStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFolder
    {
        auto CreateFileAsync(param::hstring const& desiredName) const;
        auto CreateFileAsync(param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& options) const;
        auto CreateFolderAsync(param::hstring const& desiredName) const;
        auto CreateFolderAsync(param::hstring const& desiredName, Windows::Storage::CreationCollisionOption const& options) const;
        auto GetFileAsync(param::hstring const& name) const;
        auto GetFolderAsync(param::hstring const& name) const;
        auto GetItemAsync(param::hstring const& name) const;
        auto GetFilesAsync() const;
        auto GetFoldersAsync() const;
        auto GetItemsAsync() const;
    };
    template <> struct consume<Windows::Storage::IStorageFolder>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFolder<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFolder2
    {
        auto TryGetItemAsync(param::hstring const& name) const;
    };
    template <> struct consume<Windows::Storage::IStorageFolder2>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFolder2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFolder3
    {
        auto TryGetChangeTracker() const;
    };
    template <> struct consume<Windows::Storage::IStorageFolder3>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFolder3<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFolderStatics
    {
        auto GetFolderFromPathAsync(param::hstring const& path) const;
    };
    template <> struct consume<Windows::Storage::IStorageFolderStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFolderStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageFolderStatics2
    {
        auto GetFolderFromPathForUserAsync(Windows::System::User const& user, param::hstring const& path) const;
    };
    template <> struct consume<Windows::Storage::IStorageFolderStatics2>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageFolderStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageItem
    {
        auto RenameAsync(param::hstring const& desiredName) const;
        auto RenameAsync(param::hstring const& desiredName, Windows::Storage::NameCollisionOption const& option) const;
        auto DeleteAsync() const;
        auto DeleteAsync(Windows::Storage::StorageDeleteOption const& option) const;
        auto GetBasicPropertiesAsync() const;
        [[nodiscard]] auto Name() const;
        [[nodiscard]] auto Path() const;
        [[nodiscard]] auto Attributes() const;
        [[nodiscard]] auto DateCreated() const;
        auto IsOfType(Windows::Storage::StorageItemTypes const& type) const;
    };
    template <> struct consume<Windows::Storage::IStorageItem>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageItem<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageItem2
    {
        auto GetParentAsync() const;
        auto IsEqual(Windows::Storage::IStorageItem const& item) const;
    };
    template <> struct consume<Windows::Storage::IStorageItem2>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageItem2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageItemProperties
    {
        auto GetThumbnailAsync(Windows::Storage::FileProperties::ThumbnailMode const& mode) const;
        auto GetThumbnailAsync(Windows::Storage::FileProperties::ThumbnailMode const& mode, uint32_t requestedSize) const;
        auto GetThumbnailAsync(Windows::Storage::FileProperties::ThumbnailMode const& mode, uint32_t requestedSize, Windows::Storage::FileProperties::ThumbnailOptions const& options) const;
        [[nodiscard]] auto DisplayName() const;
        [[nodiscard]] auto DisplayType() const;
        [[nodiscard]] auto FolderRelativeId() const;
        [[nodiscard]] auto Properties() const;
    };
    template <> struct consume<Windows::Storage::IStorageItemProperties>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageItemProperties<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageItemProperties2
    {
        auto GetScaledImageAsThumbnailAsync(Windows::Storage::FileProperties::ThumbnailMode const& mode) const;
        auto GetScaledImageAsThumbnailAsync(Windows::Storage::FileProperties::ThumbnailMode const& mode, uint32_t requestedSize) const;
        auto GetScaledImageAsThumbnailAsync(Windows::Storage::FileProperties::ThumbnailMode const& mode, uint32_t requestedSize, Windows::Storage::FileProperties::ThumbnailOptions const& options) const;
    };
    template <> struct consume<Windows::Storage::IStorageItemProperties2>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageItemProperties2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageItemPropertiesWithProvider
    {
        [[nodiscard]] auto Provider() const;
    };
    template <> struct consume<Windows::Storage::IStorageItemPropertiesWithProvider>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageItemPropertiesWithProvider<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageLibrary
    {
        auto RequestAddFolderAsync() const;
        auto RequestRemoveFolderAsync(Windows::Storage::StorageFolder const& folder) const;
        [[nodiscard]] auto Folders() const;
        [[nodiscard]] auto SaveFolder() const;
        auto DefinitionChanged(Windows::Foundation::TypedEventHandler<Windows::Storage::StorageLibrary, Windows::Foundation::IInspectable> const& handler) const;
        using DefinitionChanged_revoker = impl::event_revoker<Windows::Storage::IStorageLibrary, &impl::abi_t<Windows::Storage::IStorageLibrary>::remove_DefinitionChanged>;
        DefinitionChanged_revoker DefinitionChanged(auto_revoke_t, Windows::Foundation::TypedEventHandler<Windows::Storage::StorageLibrary, Windows::Foundation::IInspectable> const& handler) const;
        auto DefinitionChanged(winrt::event_token const& eventCookie) const noexcept;
    };
    template <> struct consume<Windows::Storage::IStorageLibrary>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageLibrary<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageLibrary2
    {
        [[nodiscard]] auto ChangeTracker() const;
    };
    template <> struct consume<Windows::Storage::IStorageLibrary2>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageLibrary2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageLibrary3
    {
        auto AreFolderSuggestionsAvailableAsync() const;
    };
    template <> struct consume<Windows::Storage::IStorageLibrary3>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageLibrary3<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageLibraryChange
    {
        [[nodiscard]] auto ChangeType() const;
        [[nodiscard]] auto Path() const;
        [[nodiscard]] auto PreviousPath() const;
        auto IsOfType(Windows::Storage::StorageItemTypes const& type) const;
        auto GetStorageItemAsync() const;
    };
    template <> struct consume<Windows::Storage::IStorageLibraryChange>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageLibraryChange<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageLibraryChangeReader
    {
        auto ReadBatchAsync() const;
        auto AcceptChangesAsync() const;
    };
    template <> struct consume<Windows::Storage::IStorageLibraryChangeReader>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageLibraryChangeReader<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageLibraryChangeTracker
    {
        auto GetChangeReader() const;
        auto Enable() const;
        auto Reset() const;
    };
    template <> struct consume<Windows::Storage::IStorageLibraryChangeTracker>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageLibraryChangeTracker<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageLibraryStatics
    {
        auto GetLibraryAsync(Windows::Storage::KnownLibraryId const& libraryId) const;
    };
    template <> struct consume<Windows::Storage::IStorageLibraryStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageLibraryStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageLibraryStatics2
    {
        auto GetLibraryForUserAsync(Windows::System::User const& user, Windows::Storage::KnownLibraryId const& libraryId) const;
    };
    template <> struct consume<Windows::Storage::IStorageLibraryStatics2>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageLibraryStatics2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageProvider
    {
        [[nodiscard]] auto Id() const;
        [[nodiscard]] auto DisplayName() const;
    };
    template <> struct consume<Windows::Storage::IStorageProvider>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageProvider<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageProvider2
    {
        auto IsPropertySupportedForPartialFileAsync(param::hstring const& propertyCanonicalName) const;
    };
    template <> struct consume<Windows::Storage::IStorageProvider2>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageProvider2<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStorageStreamTransaction
    {
        [[nodiscard]] auto Stream() const;
        auto CommitAsync() const;
    };
    template <> struct consume<Windows::Storage::IStorageStreamTransaction>
    {
        template <typename D> using type = consume_Windows_Storage_IStorageStreamTransaction<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IStreamedFileDataRequest
    {
        auto FailAndClose(Windows::Storage::StreamedFileFailureMode const& failureMode) const;
    };
    template <> struct consume<Windows::Storage::IStreamedFileDataRequest>
    {
        template <typename D> using type = consume_Windows_Storage_IStreamedFileDataRequest<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemAudioProperties
    {
        [[nodiscard]] auto EncodingBitrate() const;
    };
    template <> struct consume<Windows::Storage::ISystemAudioProperties>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemAudioProperties<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemDataPaths
    {
        [[nodiscard]] auto Fonts() const;
        [[nodiscard]] auto ProgramData() const;
        [[nodiscard]] auto Public() const;
        [[nodiscard]] auto PublicDesktop() const;
        [[nodiscard]] auto PublicDocuments() const;
        [[nodiscard]] auto PublicDownloads() const;
        [[nodiscard]] auto PublicMusic() const;
        [[nodiscard]] auto PublicPictures() const;
        [[nodiscard]] auto PublicVideos() const;
        [[nodiscard]] auto System() const;
        [[nodiscard]] auto SystemHost() const;
        [[nodiscard]] auto SystemX86() const;
        [[nodiscard]] auto SystemX64() const;
        [[nodiscard]] auto SystemArm() const;
        [[nodiscard]] auto UserProfiles() const;
        [[nodiscard]] auto Windows() const;
    };
    template <> struct consume<Windows::Storage::ISystemDataPaths>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemDataPaths<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemDataPathsStatics
    {
        auto GetDefault() const;
    };
    template <> struct consume<Windows::Storage::ISystemDataPathsStatics>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemDataPathsStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemGPSProperties
    {
        [[nodiscard]] auto LatitudeDecimal() const;
        [[nodiscard]] auto LongitudeDecimal() const;
    };
    template <> struct consume<Windows::Storage::ISystemGPSProperties>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemGPSProperties<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemImageProperties
    {
        [[nodiscard]] auto HorizontalSize() const;
        [[nodiscard]] auto VerticalSize() const;
    };
    template <> struct consume<Windows::Storage::ISystemImageProperties>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemImageProperties<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemMediaProperties
    {
        [[nodiscard]] auto Duration() const;
        [[nodiscard]] auto Producer() const;
        [[nodiscard]] auto Publisher() const;
        [[nodiscard]] auto SubTitle() const;
        [[nodiscard]] auto Writer() const;
        [[nodiscard]] auto Year() const;
    };
    template <> struct consume<Windows::Storage::ISystemMediaProperties>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemMediaProperties<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemMusicProperties
    {
        [[nodiscard]] auto AlbumArtist() const;
        [[nodiscard]] auto AlbumTitle() const;
        [[nodiscard]] auto Artist() const;
        [[nodiscard]] auto Composer() const;
        [[nodiscard]] auto Conductor() const;
        [[nodiscard]] auto DisplayArtist() const;
        [[nodiscard]] auto Genre() const;
        [[nodiscard]] auto TrackNumber() const;
    };
    template <> struct consume<Windows::Storage::ISystemMusicProperties>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemMusicProperties<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemPhotoProperties
    {
        [[nodiscard]] auto CameraManufacturer() const;
        [[nodiscard]] auto CameraModel() const;
        [[nodiscard]] auto DateTaken() const;
        [[nodiscard]] auto Orientation() const;
        [[nodiscard]] auto PeopleNames() const;
    };
    template <> struct consume<Windows::Storage::ISystemPhotoProperties>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemPhotoProperties<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemProperties
    {
        [[nodiscard]] auto Author() const;
        [[nodiscard]] auto Comment() const;
        [[nodiscard]] auto ItemNameDisplay() const;
        [[nodiscard]] auto Keywords() const;
        [[nodiscard]] auto Rating() const;
        [[nodiscard]] auto Title() const;
        [[nodiscard]] auto Audio() const;
        [[nodiscard]] auto GPS() const;
        [[nodiscard]] auto Media() const;
        [[nodiscard]] auto Music() const;
        [[nodiscard]] auto Photo() const;
        [[nodiscard]] auto Video() const;
        [[nodiscard]] auto Image() const;
    };
    template <> struct consume<Windows::Storage::ISystemProperties>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemProperties<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_ISystemVideoProperties
    {
        [[nodiscard]] auto Director() const;
        [[nodiscard]] auto FrameHeight() const;
        [[nodiscard]] auto FrameWidth() const;
        [[nodiscard]] auto Orientation() const;
        [[nodiscard]] auto TotalBitrate() const;
    };
    template <> struct consume<Windows::Storage::ISystemVideoProperties>
    {
        template <typename D> using type = consume_Windows_Storage_ISystemVideoProperties<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IUserDataPaths
    {
        [[nodiscard]] auto CameraRoll() const;
        [[nodiscard]] auto Cookies() const;
        [[nodiscard]] auto Desktop() const;
        [[nodiscard]] auto Documents() const;
        [[nodiscard]] auto Downloads() const;
        [[nodiscard]] auto Favorites() const;
        [[nodiscard]] auto History() const;
        [[nodiscard]] auto InternetCache() const;
        [[nodiscard]] auto LocalAppData() const;
        [[nodiscard]] auto LocalAppDataLow() const;
        [[nodiscard]] auto Music() const;
        [[nodiscard]] auto Pictures() const;
        [[nodiscard]] auto Profile() const;
        [[nodiscard]] auto Recent() const;
        [[nodiscard]] auto RoamingAppData() const;
        [[nodiscard]] auto SavedPictures() const;
        [[nodiscard]] auto Screenshots() const;
        [[nodiscard]] auto Templates() const;
        [[nodiscard]] auto Videos() const;
    };
    template <> struct consume<Windows::Storage::IUserDataPaths>
    {
        template <typename D> using type = consume_Windows_Storage_IUserDataPaths<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_IUserDataPathsStatics
    {
        auto GetForUser(Windows::System::User const& user) const;
        auto GetDefault() const;
    };
    template <> struct consume<Windows::Storage::IUserDataPathsStatics>
    {
        template <typename D> using type = consume_Windows_Storage_IUserDataPathsStatics<D>;
    };
}
#endif
