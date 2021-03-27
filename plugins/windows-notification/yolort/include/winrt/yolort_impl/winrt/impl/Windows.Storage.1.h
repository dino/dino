// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Storage_1_H
#define WINRT_Windows_Storage_1_H
#include "Windows.Foundation.0.h"
#include "Windows.Storage.Streams.0.h"
#include "Windows.Storage.0.h"
namespace winrt::Windows::Storage
{
    struct __declspec(empty_bases) IAppDataPaths :
        Windows::Foundation::IInspectable,
        impl::consume_t<IAppDataPaths>
    {
        IAppDataPaths(std::nullptr_t = nullptr) noexcept {}
        IAppDataPaths(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IAppDataPathsStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IAppDataPathsStatics>
    {
        IAppDataPathsStatics(std::nullptr_t = nullptr) noexcept {}
        IAppDataPathsStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IApplicationData :
        Windows::Foundation::IInspectable,
        impl::consume_t<IApplicationData>
    {
        IApplicationData(std::nullptr_t = nullptr) noexcept {}
        IApplicationData(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IApplicationData2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IApplicationData2>
    {
        IApplicationData2(std::nullptr_t = nullptr) noexcept {}
        IApplicationData2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IApplicationData3 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IApplicationData3>
    {
        IApplicationData3(std::nullptr_t = nullptr) noexcept {}
        IApplicationData3(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IApplicationDataContainer :
        Windows::Foundation::IInspectable,
        impl::consume_t<IApplicationDataContainer>
    {
        IApplicationDataContainer(std::nullptr_t = nullptr) noexcept {}
        IApplicationDataContainer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IApplicationDataStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IApplicationDataStatics>
    {
        IApplicationDataStatics(std::nullptr_t = nullptr) noexcept {}
        IApplicationDataStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IApplicationDataStatics2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IApplicationDataStatics2>
    {
        IApplicationDataStatics2(std::nullptr_t = nullptr) noexcept {}
        IApplicationDataStatics2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ICachedFileManagerStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<ICachedFileManagerStatics>
    {
        ICachedFileManagerStatics(std::nullptr_t = nullptr) noexcept {}
        ICachedFileManagerStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDownloadsFolderStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDownloadsFolderStatics>
    {
        IDownloadsFolderStatics(std::nullptr_t = nullptr) noexcept {}
        IDownloadsFolderStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDownloadsFolderStatics2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDownloadsFolderStatics2>
    {
        IDownloadsFolderStatics2(std::nullptr_t = nullptr) noexcept {}
        IDownloadsFolderStatics2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IFileIOStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IFileIOStatics>
    {
        IFileIOStatics(std::nullptr_t = nullptr) noexcept {}
        IFileIOStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IKnownFoldersCameraRollStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IKnownFoldersCameraRollStatics>
    {
        IKnownFoldersCameraRollStatics(std::nullptr_t = nullptr) noexcept {}
        IKnownFoldersCameraRollStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IKnownFoldersPlaylistsStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IKnownFoldersPlaylistsStatics>
    {
        IKnownFoldersPlaylistsStatics(std::nullptr_t = nullptr) noexcept {}
        IKnownFoldersPlaylistsStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IKnownFoldersSavedPicturesStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IKnownFoldersSavedPicturesStatics>
    {
        IKnownFoldersSavedPicturesStatics(std::nullptr_t = nullptr) noexcept {}
        IKnownFoldersSavedPicturesStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IKnownFoldersStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IKnownFoldersStatics>
    {
        IKnownFoldersStatics(std::nullptr_t = nullptr) noexcept {}
        IKnownFoldersStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IKnownFoldersStatics2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IKnownFoldersStatics2>
    {
        IKnownFoldersStatics2(std::nullptr_t = nullptr) noexcept {}
        IKnownFoldersStatics2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IKnownFoldersStatics3 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IKnownFoldersStatics3>
    {
        IKnownFoldersStatics3(std::nullptr_t = nullptr) noexcept {}
        IKnownFoldersStatics3(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IKnownFoldersStatics4 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IKnownFoldersStatics4>
    {
        IKnownFoldersStatics4(std::nullptr_t = nullptr) noexcept {}
        IKnownFoldersStatics4(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IPathIOStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IPathIOStatics>
    {
        IPathIOStatics(std::nullptr_t = nullptr) noexcept {}
        IPathIOStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISetVersionDeferral :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISetVersionDeferral>
    {
        ISetVersionDeferral(std::nullptr_t = nullptr) noexcept {}
        ISetVersionDeferral(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISetVersionRequest :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISetVersionRequest>
    {
        ISetVersionRequest(std::nullptr_t = nullptr) noexcept {}
        ISetVersionRequest(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFile :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFile>,
        impl::require<Windows::Storage::IStorageFile, Windows::Storage::IStorageItem, Windows::Storage::Streams::IRandomAccessStreamReference, Windows::Storage::Streams::IInputStreamReference>
    {
        IStorageFile(std::nullptr_t = nullptr) noexcept {}
        IStorageFile(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFile2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFile2>
    {
        IStorageFile2(std::nullptr_t = nullptr) noexcept {}
        IStorageFile2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFilePropertiesWithAvailability :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFilePropertiesWithAvailability>
    {
        IStorageFilePropertiesWithAvailability(std::nullptr_t = nullptr) noexcept {}
        IStorageFilePropertiesWithAvailability(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFileStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFileStatics>
    {
        IStorageFileStatics(std::nullptr_t = nullptr) noexcept {}
        IStorageFileStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFileStatics2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFileStatics2>
    {
        IStorageFileStatics2(std::nullptr_t = nullptr) noexcept {}
        IStorageFileStatics2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFolder :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFolder>,
        impl::require<Windows::Storage::IStorageFolder, Windows::Storage::IStorageItem>
    {
        IStorageFolder(std::nullptr_t = nullptr) noexcept {}
        IStorageFolder(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFolder2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFolder2>
    {
        IStorageFolder2(std::nullptr_t = nullptr) noexcept {}
        IStorageFolder2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFolder3 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFolder3>
    {
        IStorageFolder3(std::nullptr_t = nullptr) noexcept {}
        IStorageFolder3(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFolderStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFolderStatics>
    {
        IStorageFolderStatics(std::nullptr_t = nullptr) noexcept {}
        IStorageFolderStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFolderStatics2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFolderStatics2>
    {
        IStorageFolderStatics2(std::nullptr_t = nullptr) noexcept {}
        IStorageFolderStatics2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageItem :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageItem>
    {
        IStorageItem(std::nullptr_t = nullptr) noexcept {}
        IStorageItem(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageItem2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageItem2>,
        impl::require<Windows::Storage::IStorageItem2, Windows::Storage::IStorageItem>
    {
        IStorageItem2(std::nullptr_t = nullptr) noexcept {}
        IStorageItem2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageItemProperties :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageItemProperties>
    {
        IStorageItemProperties(std::nullptr_t = nullptr) noexcept {}
        IStorageItemProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageItemProperties2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageItemProperties2>,
        impl::require<Windows::Storage::IStorageItemProperties2, Windows::Storage::IStorageItemProperties>
    {
        IStorageItemProperties2(std::nullptr_t = nullptr) noexcept {}
        IStorageItemProperties2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageItemPropertiesWithProvider :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageItemPropertiesWithProvider>,
        impl::require<Windows::Storage::IStorageItemPropertiesWithProvider, Windows::Storage::IStorageItemProperties>
    {
        IStorageItemPropertiesWithProvider(std::nullptr_t = nullptr) noexcept {}
        IStorageItemPropertiesWithProvider(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibrary :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibrary>
    {
        IStorageLibrary(std::nullptr_t = nullptr) noexcept {}
        IStorageLibrary(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibrary2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibrary2>
    {
        IStorageLibrary2(std::nullptr_t = nullptr) noexcept {}
        IStorageLibrary2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibrary3 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibrary3>
    {
        IStorageLibrary3(std::nullptr_t = nullptr) noexcept {}
        IStorageLibrary3(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibraryChange :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibraryChange>
    {
        IStorageLibraryChange(std::nullptr_t = nullptr) noexcept {}
        IStorageLibraryChange(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibraryChangeReader :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibraryChangeReader>
    {
        IStorageLibraryChangeReader(std::nullptr_t = nullptr) noexcept {}
        IStorageLibraryChangeReader(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibraryChangeTracker :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibraryChangeTracker>
    {
        IStorageLibraryChangeTracker(std::nullptr_t = nullptr) noexcept {}
        IStorageLibraryChangeTracker(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibraryStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibraryStatics>
    {
        IStorageLibraryStatics(std::nullptr_t = nullptr) noexcept {}
        IStorageLibraryStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibraryStatics2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibraryStatics2>
    {
        IStorageLibraryStatics2(std::nullptr_t = nullptr) noexcept {}
        IStorageLibraryStatics2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageProvider :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageProvider>
    {
        IStorageProvider(std::nullptr_t = nullptr) noexcept {}
        IStorageProvider(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageProvider2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageProvider2>,
        impl::require<Windows::Storage::IStorageProvider2, Windows::Storage::IStorageProvider>
    {
        IStorageProvider2(std::nullptr_t = nullptr) noexcept {}
        IStorageProvider2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageStreamTransaction :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageStreamTransaction>,
        impl::require<Windows::Storage::IStorageStreamTransaction, Windows::Foundation::IClosable>
    {
        IStorageStreamTransaction(std::nullptr_t = nullptr) noexcept {}
        IStorageStreamTransaction(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStreamedFileDataRequest :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStreamedFileDataRequest>
    {
        IStreamedFileDataRequest(std::nullptr_t = nullptr) noexcept {}
        IStreamedFileDataRequest(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemAudioProperties :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemAudioProperties>
    {
        ISystemAudioProperties(std::nullptr_t = nullptr) noexcept {}
        ISystemAudioProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemDataPaths :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemDataPaths>
    {
        ISystemDataPaths(std::nullptr_t = nullptr) noexcept {}
        ISystemDataPaths(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemDataPathsStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemDataPathsStatics>
    {
        ISystemDataPathsStatics(std::nullptr_t = nullptr) noexcept {}
        ISystemDataPathsStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemGPSProperties :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemGPSProperties>
    {
        ISystemGPSProperties(std::nullptr_t = nullptr) noexcept {}
        ISystemGPSProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemImageProperties :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemImageProperties>
    {
        ISystemImageProperties(std::nullptr_t = nullptr) noexcept {}
        ISystemImageProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemMediaProperties :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemMediaProperties>
    {
        ISystemMediaProperties(std::nullptr_t = nullptr) noexcept {}
        ISystemMediaProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemMusicProperties :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemMusicProperties>
    {
        ISystemMusicProperties(std::nullptr_t = nullptr) noexcept {}
        ISystemMusicProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemPhotoProperties :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemPhotoProperties>
    {
        ISystemPhotoProperties(std::nullptr_t = nullptr) noexcept {}
        ISystemPhotoProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemProperties :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemProperties>
    {
        ISystemProperties(std::nullptr_t = nullptr) noexcept {}
        ISystemProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ISystemVideoProperties :
        Windows::Foundation::IInspectable,
        impl::consume_t<ISystemVideoProperties>
    {
        ISystemVideoProperties(std::nullptr_t = nullptr) noexcept {}
        ISystemVideoProperties(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IUserDataPaths :
        Windows::Foundation::IInspectable,
        impl::consume_t<IUserDataPaths>
    {
        IUserDataPaths(std::nullptr_t = nullptr) noexcept {}
        IUserDataPaths(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IUserDataPathsStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IUserDataPathsStatics>
    {
        IUserDataPathsStatics(std::nullptr_t = nullptr) noexcept {}
        IUserDataPathsStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
}
#endif
