// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Storage_Search_1_H
#define WINRT_Windows_Storage_Search_1_H
#include "Windows.Storage.Search.0.h"
namespace winrt::Windows::Storage::Search
{
    struct __declspec(empty_bases) IContentIndexer :
        Windows::Foundation::IInspectable,
        impl::consume_t<IContentIndexer>
    {
        IContentIndexer(std::nullptr_t = nullptr) noexcept {}
        IContentIndexer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IContentIndexerQuery :
        Windows::Foundation::IInspectable,
        impl::consume_t<IContentIndexerQuery>
    {
        IContentIndexerQuery(std::nullptr_t = nullptr) noexcept {}
        IContentIndexerQuery(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IContentIndexerQueryOperations :
        Windows::Foundation::IInspectable,
        impl::consume_t<IContentIndexerQueryOperations>
    {
        IContentIndexerQueryOperations(std::nullptr_t = nullptr) noexcept {}
        IContentIndexerQueryOperations(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IContentIndexerStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IContentIndexerStatics>
    {
        IContentIndexerStatics(std::nullptr_t = nullptr) noexcept {}
        IContentIndexerStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IIndexableContent :
        Windows::Foundation::IInspectable,
        impl::consume_t<IIndexableContent>
    {
        IIndexableContent(std::nullptr_t = nullptr) noexcept {}
        IIndexableContent(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IQueryOptions :
        Windows::Foundation::IInspectable,
        impl::consume_t<IQueryOptions>
    {
        IQueryOptions(std::nullptr_t = nullptr) noexcept {}
        IQueryOptions(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IQueryOptionsFactory :
        Windows::Foundation::IInspectable,
        impl::consume_t<IQueryOptionsFactory>
    {
        IQueryOptionsFactory(std::nullptr_t = nullptr) noexcept {}
        IQueryOptionsFactory(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IQueryOptionsWithProviderFilter :
        Windows::Foundation::IInspectable,
        impl::consume_t<IQueryOptionsWithProviderFilter>
    {
        IQueryOptionsWithProviderFilter(std::nullptr_t = nullptr) noexcept {}
        IQueryOptionsWithProviderFilter(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFileQueryResult :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFileQueryResult>,
        impl::require<Windows::Storage::Search::IStorageFileQueryResult, Windows::Storage::Search::IStorageQueryResultBase>
    {
        IStorageFileQueryResult(std::nullptr_t = nullptr) noexcept {}
        IStorageFileQueryResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFileQueryResult2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFileQueryResult2>,
        impl::require<Windows::Storage::Search::IStorageFileQueryResult2, Windows::Storage::Search::IStorageQueryResultBase>
    {
        IStorageFileQueryResult2(std::nullptr_t = nullptr) noexcept {}
        IStorageFileQueryResult2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFolderQueryOperations :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFolderQueryOperations>
    {
        IStorageFolderQueryOperations(std::nullptr_t = nullptr) noexcept {}
        IStorageFolderQueryOperations(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageFolderQueryResult :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageFolderQueryResult>,
        impl::require<Windows::Storage::Search::IStorageFolderQueryResult, Windows::Storage::Search::IStorageQueryResultBase>
    {
        IStorageFolderQueryResult(std::nullptr_t = nullptr) noexcept {}
        IStorageFolderQueryResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageItemQueryResult :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageItemQueryResult>,
        impl::require<Windows::Storage::Search::IStorageItemQueryResult, Windows::Storage::Search::IStorageQueryResultBase>
    {
        IStorageItemQueryResult(std::nullptr_t = nullptr) noexcept {}
        IStorageItemQueryResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibraryChangeTrackerTriggerDetails :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibraryChangeTrackerTriggerDetails>
    {
        IStorageLibraryChangeTrackerTriggerDetails(std::nullptr_t = nullptr) noexcept {}
        IStorageLibraryChangeTrackerTriggerDetails(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageLibraryContentChangedTriggerDetails :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageLibraryContentChangedTriggerDetails>
    {
        IStorageLibraryContentChangedTriggerDetails(std::nullptr_t = nullptr) noexcept {}
        IStorageLibraryContentChangedTriggerDetails(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IStorageQueryResultBase :
        Windows::Foundation::IInspectable,
        impl::consume_t<IStorageQueryResultBase>
    {
        IStorageQueryResultBase(std::nullptr_t = nullptr) noexcept {}
        IStorageQueryResultBase(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IValueAndLanguage :
        Windows::Foundation::IInspectable,
        impl::consume_t<IValueAndLanguage>
    {
        IValueAndLanguage(std::nullptr_t = nullptr) noexcept {}
        IValueAndLanguage(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
}
#endif
