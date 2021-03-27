// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Storage_Search_2_H
#define WINRT_Windows_Storage_Search_2_H
#include "Windows.Foundation.Collections.1.h"
#include "Windows.Storage.Search.1.h"
namespace winrt::Windows::Storage::Search
{
    struct SortEntry
    {
        hstring PropertyName;
        bool AscendingOrder;
    };
    inline bool operator==(SortEntry const& left, SortEntry const& right) noexcept
    {
        return left.PropertyName == right.PropertyName && left.AscendingOrder == right.AscendingOrder;
    }
    inline bool operator!=(SortEntry const& left, SortEntry const& right) noexcept
    {
        return !(left == right);
    }
    struct __declspec(empty_bases) ContentIndexer : Windows::Storage::Search::IContentIndexer,
        impl::require<ContentIndexer, Windows::Storage::Search::IContentIndexerQueryOperations>
    {
        ContentIndexer(std::nullptr_t) noexcept {}
        ContentIndexer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IContentIndexer(ptr, take_ownership_from_abi) {}
        static auto GetIndexer(param::hstring const& indexName);
        static auto GetIndexer();
    };
    struct __declspec(empty_bases) ContentIndexerQuery : Windows::Storage::Search::IContentIndexerQuery
    {
        ContentIndexerQuery(std::nullptr_t) noexcept {}
        ContentIndexerQuery(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IContentIndexerQuery(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IndexableContent : Windows::Storage::Search::IIndexableContent
    {
        IndexableContent(std::nullptr_t) noexcept {}
        IndexableContent(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IIndexableContent(ptr, take_ownership_from_abi) {}
        IndexableContent();
    };
    struct __declspec(empty_bases) QueryOptions : Windows::Storage::Search::IQueryOptions,
        impl::require<QueryOptions, Windows::Storage::Search::IQueryOptionsWithProviderFilter>
    {
        QueryOptions(std::nullptr_t) noexcept {}
        QueryOptions(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IQueryOptions(ptr, take_ownership_from_abi) {}
        QueryOptions();
        QueryOptions(Windows::Storage::Search::CommonFileQuery const& query, param::iterable<hstring> const& fileTypeFilter);
        QueryOptions(Windows::Storage::Search::CommonFolderQuery const& query);
    };
    struct __declspec(empty_bases) SortEntryVector : Windows::Foundation::Collections::IVector<Windows::Storage::Search::SortEntry>
    {
        SortEntryVector(std::nullptr_t) noexcept {}
        SortEntryVector(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::Collections::IVector<Windows::Storage::Search::SortEntry>(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageFileQueryResult : Windows::Storage::Search::IStorageFileQueryResult,
        impl::require<StorageFileQueryResult, Windows::Storage::Search::IStorageFileQueryResult2>
    {
        StorageFileQueryResult(std::nullptr_t) noexcept {}
        StorageFileQueryResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IStorageFileQueryResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageFolderQueryResult : Windows::Storage::Search::IStorageFolderQueryResult
    {
        StorageFolderQueryResult(std::nullptr_t) noexcept {}
        StorageFolderQueryResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IStorageFolderQueryResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageItemQueryResult : Windows::Storage::Search::IStorageItemQueryResult
    {
        StorageItemQueryResult(std::nullptr_t) noexcept {}
        StorageItemQueryResult(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IStorageItemQueryResult(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageLibraryChangeTrackerTriggerDetails : Windows::Storage::Search::IStorageLibraryChangeTrackerTriggerDetails
    {
        StorageLibraryChangeTrackerTriggerDetails(std::nullptr_t) noexcept {}
        StorageLibraryChangeTrackerTriggerDetails(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IStorageLibraryChangeTrackerTriggerDetails(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) StorageLibraryContentChangedTriggerDetails : Windows::Storage::Search::IStorageLibraryContentChangedTriggerDetails
    {
        StorageLibraryContentChangedTriggerDetails(std::nullptr_t) noexcept {}
        StorageLibraryContentChangedTriggerDetails(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IStorageLibraryContentChangedTriggerDetails(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) ValueAndLanguage : Windows::Storage::Search::IValueAndLanguage
    {
        ValueAndLanguage(std::nullptr_t) noexcept {}
        ValueAndLanguage(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Search::IValueAndLanguage(ptr, take_ownership_from_abi) {}
        ValueAndLanguage();
    };
}
#endif
