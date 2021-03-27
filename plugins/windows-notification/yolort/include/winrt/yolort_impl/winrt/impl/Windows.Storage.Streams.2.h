// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Storage_Streams_2_H
#define WINRT_Windows_Storage_Streams_2_H
#include "Windows.Foundation.1.h"
#include "Windows.Storage.1.h"
#include "Windows.System.1.h"
#include "Windows.Storage.Streams.1.h"
namespace winrt::Windows::Storage::Streams
{
    struct __declspec(empty_bases) Buffer : Windows::Storage::Streams::IBuffer
    {
        Buffer(std::nullptr_t) noexcept {}
        Buffer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IBuffer(ptr, take_ownership_from_abi) {}
        Buffer(uint32_t capacity);
        static auto CreateCopyFromMemoryBuffer(Windows::Foundation::IMemoryBuffer const& input);
        static auto CreateMemoryBufferOverIBuffer(Windows::Storage::Streams::IBuffer const& input);
    };
    struct __declspec(empty_bases) DataReader : Windows::Storage::Streams::IDataReader,
        impl::require<DataReader, Windows::Foundation::IClosable>
    {
        DataReader(std::nullptr_t) noexcept {}
        DataReader(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IDataReader(ptr, take_ownership_from_abi) {}
        DataReader(Windows::Storage::Streams::IInputStream const& inputStream);
        static auto FromBuffer(Windows::Storage::Streams::IBuffer const& buffer);
    };
    struct __declspec(empty_bases) DataReaderLoadOperation : Windows::Foundation::IAsyncOperation<uint32_t>
    {
        DataReaderLoadOperation(std::nullptr_t) noexcept {}
        DataReaderLoadOperation(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IAsyncOperation<uint32_t>(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) DataWriter : Windows::Storage::Streams::IDataWriter,
        impl::require<DataWriter, Windows::Foundation::IClosable>
    {
        DataWriter(std::nullptr_t) noexcept {}
        DataWriter(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IDataWriter(ptr, take_ownership_from_abi) {}
        DataWriter();
        DataWriter(Windows::Storage::Streams::IOutputStream const& outputStream);
    };
    struct __declspec(empty_bases) DataWriterStoreOperation : Windows::Foundation::IAsyncOperation<uint32_t>
    {
        DataWriterStoreOperation(std::nullptr_t) noexcept {}
        DataWriterStoreOperation(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IAsyncOperation<uint32_t>(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) FileInputStream : Windows::Storage::Streams::IInputStream
    {
        FileInputStream(std::nullptr_t) noexcept {}
        FileInputStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IInputStream(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) FileOutputStream : Windows::Storage::Streams::IOutputStream
    {
        FileOutputStream(std::nullptr_t) noexcept {}
        FileOutputStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IOutputStream(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) FileRandomAccessStream : Windows::Storage::Streams::IRandomAccessStream
    {
        FileRandomAccessStream(std::nullptr_t) noexcept {}
        FileRandomAccessStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IRandomAccessStream(ptr, take_ownership_from_abi) {}
        static auto OpenAsync(param::hstring const& filePath, Windows::Storage::FileAccessMode const& accessMode);
        static auto OpenAsync(param::hstring const& filePath, Windows::Storage::FileAccessMode const& accessMode, Windows::Storage::StorageOpenOptions const& sharingOptions, Windows::Storage::Streams::FileOpenDisposition const& openDisposition);
        static auto OpenTransactedWriteAsync(param::hstring const& filePath);
        static auto OpenTransactedWriteAsync(param::hstring const& filePath, Windows::Storage::StorageOpenOptions const& openOptions, Windows::Storage::Streams::FileOpenDisposition const& openDisposition);
        static auto OpenForUserAsync(Windows::System::User const& user, param::hstring const& filePath, Windows::Storage::FileAccessMode const& accessMode);
        static auto OpenForUserAsync(Windows::System::User const& user, param::hstring const& filePath, Windows::Storage::FileAccessMode const& accessMode, Windows::Storage::StorageOpenOptions const& sharingOptions, Windows::Storage::Streams::FileOpenDisposition const& openDisposition);
        static auto OpenTransactedWriteForUserAsync(Windows::System::User const& user, param::hstring const& filePath);
        static auto OpenTransactedWriteForUserAsync(Windows::System::User const& user, param::hstring const& filePath, Windows::Storage::StorageOpenOptions const& openOptions, Windows::Storage::Streams::FileOpenDisposition const& openDisposition);
    };
    struct __declspec(empty_bases) InMemoryRandomAccessStream : Windows::Storage::Streams::IRandomAccessStream
    {
        InMemoryRandomAccessStream(std::nullptr_t) noexcept {}
        InMemoryRandomAccessStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IRandomAccessStream(ptr, take_ownership_from_abi) {}
        InMemoryRandomAccessStream();
    };
    struct __declspec(empty_bases) InputStreamOverStream : Windows::Storage::Streams::IInputStream
    {
        InputStreamOverStream(std::nullptr_t) noexcept {}
        InputStreamOverStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IInputStream(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) OutputStreamOverStream : Windows::Storage::Streams::IOutputStream
    {
        OutputStreamOverStream(std::nullptr_t) noexcept {}
        OutputStreamOverStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IOutputStream(ptr, take_ownership_from_abi) {}
    };
    struct RandomAccessStream
    {
        RandomAccessStream() = delete;
        static auto CopyAsync(Windows::Storage::Streams::IInputStream const& source, Windows::Storage::Streams::IOutputStream const& destination);
        static auto CopyAsync(Windows::Storage::Streams::IInputStream const& source, Windows::Storage::Streams::IOutputStream const& destination, uint64_t bytesToCopy);
        static auto CopyAndCloseAsync(Windows::Storage::Streams::IInputStream const& source, Windows::Storage::Streams::IOutputStream const& destination);
    };
    struct __declspec(empty_bases) RandomAccessStreamOverStream : Windows::Storage::Streams::IRandomAccessStream
    {
        RandomAccessStreamOverStream(std::nullptr_t) noexcept {}
        RandomAccessStreamOverStream(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IRandomAccessStream(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) RandomAccessStreamReference : Windows::Storage::Streams::IRandomAccessStreamReference
    {
        RandomAccessStreamReference(std::nullptr_t) noexcept {}
        RandomAccessStreamReference(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Storage::Streams::IRandomAccessStreamReference(ptr, take_ownership_from_abi) {}
        static auto CreateFromFile(Windows::Storage::IStorageFile const& file);
        static auto CreateFromUri(Windows::Foundation::Uri const& uri);
        static auto CreateFromStream(Windows::Storage::Streams::IRandomAccessStream const& stream);
    };
}
#endif
