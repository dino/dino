// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Storage_Streams_0_H
#define WINRT_Windows_Storage_Streams_0_H
namespace winrt::Windows::Foundation
{
    template <typename TResult> struct IAsyncOperation;
    struct IMemoryBuffer;
    struct MemoryBuffer;
    struct Uri;
}
namespace winrt::Windows::Storage
{
    enum class FileAccessMode : int32_t;
    struct IStorageFile;
    enum class StorageOpenOptions : uint32_t;
}
namespace winrt::Windows::System
{
    struct User;
}
namespace winrt::Windows::Storage::Streams
{
    enum class ByteOrder : int32_t
    {
        LittleEndian = 0,
        BigEndian = 1,
    };
    enum class FileOpenDisposition : int32_t
    {
        OpenExisting = 0,
        OpenAlways = 1,
        CreateNew = 2,
        CreateAlways = 3,
        TruncateExisting = 4,
    };
    enum class InputStreamOptions : uint32_t
    {
        None = 0,
        Partial = 0x1,
        ReadAhead = 0x2,
    };
    enum class UnicodeEncoding : int32_t
    {
        Utf8 = 0,
        Utf16LE = 1,
        Utf16BE = 2,
    };
    struct IBuffer;
    struct IBufferFactory;
    struct IBufferStatics;
    struct IContentTypeProvider;
    struct IDataReader;
    struct IDataReaderFactory;
    struct IDataReaderStatics;
    struct IDataWriter;
    struct IDataWriterFactory;
    struct IFileRandomAccessStreamStatics;
    struct IInputStream;
    struct IInputStreamReference;
    struct IOutputStream;
    struct IRandomAccessStream;
    struct IRandomAccessStreamReference;
    struct IRandomAccessStreamReferenceStatics;
    struct IRandomAccessStreamStatics;
    struct IRandomAccessStreamWithContentType;
    struct Buffer;
    struct DataReader;
    struct DataReaderLoadOperation;
    struct DataWriter;
    struct DataWriterStoreOperation;
    struct FileInputStream;
    struct FileOutputStream;
    struct FileRandomAccessStream;
    struct InMemoryRandomAccessStream;
    struct InputStreamOverStream;
    struct OutputStreamOverStream;
    struct RandomAccessStream;
    struct RandomAccessStreamOverStream;
    struct RandomAccessStreamReference;
}
namespace winrt::impl
{
    template <> struct category<Windows::Storage::Streams::IBuffer>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IBufferFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IBufferStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IContentTypeProvider>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IDataReader>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IDataReaderFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IDataReaderStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IDataWriter>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IDataWriterFactory>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IFileRandomAccessStreamStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IInputStream>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IInputStreamReference>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IOutputStream>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IRandomAccessStream>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IRandomAccessStreamReference>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IRandomAccessStreamReferenceStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IRandomAccessStreamStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::IRandomAccessStreamWithContentType>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Storage::Streams::Buffer>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::DataReader>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::DataReaderLoadOperation>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::DataWriter>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::DataWriterStoreOperation>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::FileInputStream>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::FileOutputStream>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::FileRandomAccessStream>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::InMemoryRandomAccessStream>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::InputStreamOverStream>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::OutputStreamOverStream>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::RandomAccessStream>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::RandomAccessStreamOverStream>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::RandomAccessStreamReference>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Storage::Streams::ByteOrder>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::Streams::FileOpenDisposition>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::Streams::InputStreamOptions>
    {
        using type = enum_category;
    };
    template <> struct category<Windows::Storage::Streams::UnicodeEncoding>
    {
        using type = enum_category;
    };
    template <> struct name<Windows::Storage::Streams::IBuffer>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IBuffer" };
    };
    template <> struct name<Windows::Storage::Streams::IBufferFactory>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IBufferFactory" };
    };
    template <> struct name<Windows::Storage::Streams::IBufferStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IBufferStatics" };
    };
    template <> struct name<Windows::Storage::Streams::IContentTypeProvider>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IContentTypeProvider" };
    };
    template <> struct name<Windows::Storage::Streams::IDataReader>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IDataReader" };
    };
    template <> struct name<Windows::Storage::Streams::IDataReaderFactory>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IDataReaderFactory" };
    };
    template <> struct name<Windows::Storage::Streams::IDataReaderStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IDataReaderStatics" };
    };
    template <> struct name<Windows::Storage::Streams::IDataWriter>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IDataWriter" };
    };
    template <> struct name<Windows::Storage::Streams::IDataWriterFactory>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IDataWriterFactory" };
    };
    template <> struct name<Windows::Storage::Streams::IFileRandomAccessStreamStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IFileRandomAccessStreamStatics" };
    };
    template <> struct name<Windows::Storage::Streams::IInputStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IInputStream" };
    };
    template <> struct name<Windows::Storage::Streams::IInputStreamReference>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IInputStreamReference" };
    };
    template <> struct name<Windows::Storage::Streams::IOutputStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IOutputStream" };
    };
    template <> struct name<Windows::Storage::Streams::IRandomAccessStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IRandomAccessStream" };
    };
    template <> struct name<Windows::Storage::Streams::IRandomAccessStreamReference>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IRandomAccessStreamReference" };
    };
    template <> struct name<Windows::Storage::Streams::IRandomAccessStreamReferenceStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IRandomAccessStreamReferenceStatics" };
    };
    template <> struct name<Windows::Storage::Streams::IRandomAccessStreamStatics>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IRandomAccessStreamStatics" };
    };
    template <> struct name<Windows::Storage::Streams::IRandomAccessStreamWithContentType>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.IRandomAccessStreamWithContentType" };
    };
    template <> struct name<Windows::Storage::Streams::Buffer>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.Buffer" };
    };
    template <> struct name<Windows::Storage::Streams::DataReader>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.DataReader" };
    };
    template <> struct name<Windows::Storage::Streams::DataReaderLoadOperation>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.DataReaderLoadOperation" };
    };
    template <> struct name<Windows::Storage::Streams::DataWriter>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.DataWriter" };
    };
    template <> struct name<Windows::Storage::Streams::DataWriterStoreOperation>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.DataWriterStoreOperation" };
    };
    template <> struct name<Windows::Storage::Streams::FileInputStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.FileInputStream" };
    };
    template <> struct name<Windows::Storage::Streams::FileOutputStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.FileOutputStream" };
    };
    template <> struct name<Windows::Storage::Streams::FileRandomAccessStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.FileRandomAccessStream" };
    };
    template <> struct name<Windows::Storage::Streams::InMemoryRandomAccessStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.InMemoryRandomAccessStream" };
    };
    template <> struct name<Windows::Storage::Streams::InputStreamOverStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.InputStreamOverStream" };
    };
    template <> struct name<Windows::Storage::Streams::OutputStreamOverStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.OutputStreamOverStream" };
    };
    template <> struct name<Windows::Storage::Streams::RandomAccessStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.RandomAccessStream" };
    };
    template <> struct name<Windows::Storage::Streams::RandomAccessStreamOverStream>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.RandomAccessStreamOverStream" };
    };
    template <> struct name<Windows::Storage::Streams::RandomAccessStreamReference>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.RandomAccessStreamReference" };
    };
    template <> struct name<Windows::Storage::Streams::ByteOrder>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.ByteOrder" };
    };
    template <> struct name<Windows::Storage::Streams::FileOpenDisposition>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.FileOpenDisposition" };
    };
    template <> struct name<Windows::Storage::Streams::InputStreamOptions>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.InputStreamOptions" };
    };
    template <> struct name<Windows::Storage::Streams::UnicodeEncoding>
    {
        static constexpr auto & value{ L"Windows.Storage.Streams.UnicodeEncoding" };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IBuffer>
    {
        static constexpr guid value{ 0x905A0FE0,0xBC53,0x11DF,{ 0x8C,0x49,0x00,0x1E,0x4F,0xC6,0x86,0xDA } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IBufferFactory>
    {
        static constexpr guid value{ 0x71AF914D,0xC10F,0x484B,{ 0xBC,0x50,0x14,0xBC,0x62,0x3B,0x3A,0x27 } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IBufferStatics>
    {
        static constexpr guid value{ 0xE901E65B,0xD716,0x475A,{ 0xA9,0x0A,0xAF,0x72,0x29,0xB1,0xE7,0x41 } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IContentTypeProvider>
    {
        static constexpr guid value{ 0x97D098A5,0x3B99,0x4DE9,{ 0x88,0xA5,0xE1,0x1D,0x2F,0x50,0xC7,0x95 } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IDataReader>
    {
        static constexpr guid value{ 0xE2B50029,0xB4C1,0x4314,{ 0xA4,0xB8,0xFB,0x81,0x3A,0x2F,0x27,0x5E } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IDataReaderFactory>
    {
        static constexpr guid value{ 0xD7527847,0x57DA,0x4E15,{ 0x91,0x4C,0x06,0x80,0x66,0x99,0xA0,0x98 } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IDataReaderStatics>
    {
        static constexpr guid value{ 0x11FCBFC8,0xF93A,0x471B,{ 0xB1,0x21,0xF3,0x79,0xE3,0x49,0x31,0x3C } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IDataWriter>
    {
        static constexpr guid value{ 0x64B89265,0xD341,0x4922,{ 0xB3,0x8A,0xDD,0x4A,0xF8,0x80,0x8C,0x4E } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IDataWriterFactory>
    {
        static constexpr guid value{ 0x338C67C2,0x8B84,0x4C2B,{ 0x9C,0x50,0x7B,0x87,0x67,0x84,0x7A,0x1F } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IFileRandomAccessStreamStatics>
    {
        static constexpr guid value{ 0x73550107,0x3B57,0x4B5D,{ 0x83,0x45,0x55,0x4D,0x2F,0xC6,0x21,0xF0 } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IInputStream>
    {
        static constexpr guid value{ 0x905A0FE2,0xBC53,0x11DF,{ 0x8C,0x49,0x00,0x1E,0x4F,0xC6,0x86,0xDA } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IInputStreamReference>
    {
        static constexpr guid value{ 0x43929D18,0x5EC9,0x4B5A,{ 0x91,0x9C,0x42,0x05,0xB0,0xC8,0x04,0xB6 } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IOutputStream>
    {
        static constexpr guid value{ 0x905A0FE6,0xBC53,0x11DF,{ 0x8C,0x49,0x00,0x1E,0x4F,0xC6,0x86,0xDA } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IRandomAccessStream>
    {
        static constexpr guid value{ 0x905A0FE1,0xBC53,0x11DF,{ 0x8C,0x49,0x00,0x1E,0x4F,0xC6,0x86,0xDA } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IRandomAccessStreamReference>
    {
        static constexpr guid value{ 0x33EE3134,0x1DD6,0x4E3A,{ 0x80,0x67,0xD1,0xC1,0x62,0xE8,0x64,0x2B } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IRandomAccessStreamReferenceStatics>
    {
        static constexpr guid value{ 0x857309DC,0x3FBF,0x4E7D,{ 0x98,0x6F,0xEF,0x3B,0x1A,0x07,0xA9,0x64 } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IRandomAccessStreamStatics>
    {
        static constexpr guid value{ 0x524CEDCF,0x6E29,0x4CE5,{ 0x95,0x73,0x6B,0x75,0x3D,0xB6,0x6C,0x3A } };
    };
    template <> struct guid_storage<Windows::Storage::Streams::IRandomAccessStreamWithContentType>
    {
        static constexpr guid value{ 0xCC254827,0x4B3D,0x438F,{ 0x92,0x32,0x10,0xC7,0x6B,0xC7,0xE0,0x38 } };
    };
    template <> struct default_interface<Windows::Storage::Streams::Buffer>
    {
        using type = Windows::Storage::Streams::IBuffer;
    };
    template <> struct default_interface<Windows::Storage::Streams::DataReader>
    {
        using type = Windows::Storage::Streams::IDataReader;
    };
    template <> struct default_interface<Windows::Storage::Streams::DataReaderLoadOperation>
    {
        using type = Windows::Foundation::IAsyncOperation<uint32_t>;
    };
    template <> struct default_interface<Windows::Storage::Streams::DataWriter>
    {
        using type = Windows::Storage::Streams::IDataWriter;
    };
    template <> struct default_interface<Windows::Storage::Streams::DataWriterStoreOperation>
    {
        using type = Windows::Foundation::IAsyncOperation<uint32_t>;
    };
    template <> struct default_interface<Windows::Storage::Streams::FileInputStream>
    {
        using type = Windows::Storage::Streams::IInputStream;
    };
    template <> struct default_interface<Windows::Storage::Streams::FileOutputStream>
    {
        using type = Windows::Storage::Streams::IOutputStream;
    };
    template <> struct default_interface<Windows::Storage::Streams::FileRandomAccessStream>
    {
        using type = Windows::Storage::Streams::IRandomAccessStream;
    };
    template <> struct default_interface<Windows::Storage::Streams::InMemoryRandomAccessStream>
    {
        using type = Windows::Storage::Streams::IRandomAccessStream;
    };
    template <> struct default_interface<Windows::Storage::Streams::InputStreamOverStream>
    {
        using type = Windows::Storage::Streams::IInputStream;
    };
    template <> struct default_interface<Windows::Storage::Streams::OutputStreamOverStream>
    {
        using type = Windows::Storage::Streams::IOutputStream;
    };
    template <> struct default_interface<Windows::Storage::Streams::RandomAccessStreamOverStream>
    {
        using type = Windows::Storage::Streams::IRandomAccessStream;
    };
    template <> struct default_interface<Windows::Storage::Streams::RandomAccessStreamReference>
    {
        using type = Windows::Storage::Streams::IRandomAccessStreamReference;
    };
    template <> struct abi<Windows::Storage::Streams::IBuffer>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Capacity(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall get_Length(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall put_Length(uint32_t) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IBufferFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall Create(uint32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IBufferStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateCopyFromMemoryBuffer(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateMemoryBufferOverIBuffer(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IContentTypeProvider>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_ContentType(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IDataReader>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_UnconsumedBufferLength(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall get_UnicodeEncoding(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_UnicodeEncoding(int32_t) noexcept = 0;
            virtual int32_t __stdcall get_ByteOrder(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_ByteOrder(int32_t) noexcept = 0;
            virtual int32_t __stdcall get_InputStreamOptions(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall put_InputStreamOptions(uint32_t) noexcept = 0;
            virtual int32_t __stdcall ReadByte(uint8_t*) noexcept = 0;
            virtual int32_t __stdcall ReadBytes(uint32_t, uint8_t*) noexcept = 0;
            virtual int32_t __stdcall ReadBuffer(uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall ReadBoolean(bool*) noexcept = 0;
            virtual int32_t __stdcall ReadGuid(winrt::guid*) noexcept = 0;
            virtual int32_t __stdcall ReadInt16(int16_t*) noexcept = 0;
            virtual int32_t __stdcall ReadInt32(int32_t*) noexcept = 0;
            virtual int32_t __stdcall ReadInt64(int64_t*) noexcept = 0;
            virtual int32_t __stdcall ReadUInt16(uint16_t*) noexcept = 0;
            virtual int32_t __stdcall ReadUInt32(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall ReadUInt64(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall ReadSingle(float*) noexcept = 0;
            virtual int32_t __stdcall ReadDouble(double*) noexcept = 0;
            virtual int32_t __stdcall ReadString(uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall ReadDateTime(int64_t*) noexcept = 0;
            virtual int32_t __stdcall ReadTimeSpan(int64_t*) noexcept = 0;
            virtual int32_t __stdcall LoadAsync(uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall DetachBuffer(void**) noexcept = 0;
            virtual int32_t __stdcall DetachStream(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IDataReaderFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateDataReader(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IDataReaderStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall FromBuffer(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IDataWriter>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_UnstoredBufferLength(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall get_UnicodeEncoding(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_UnicodeEncoding(int32_t) noexcept = 0;
            virtual int32_t __stdcall get_ByteOrder(int32_t*) noexcept = 0;
            virtual int32_t __stdcall put_ByteOrder(int32_t) noexcept = 0;
            virtual int32_t __stdcall WriteByte(uint8_t) noexcept = 0;
            virtual int32_t __stdcall WriteBytes(uint32_t, uint8_t*) noexcept = 0;
            virtual int32_t __stdcall WriteBuffer(void*) noexcept = 0;
            virtual int32_t __stdcall WriteBufferRange(void*, uint32_t, uint32_t) noexcept = 0;
            virtual int32_t __stdcall WriteBoolean(bool) noexcept = 0;
            virtual int32_t __stdcall WriteGuid(winrt::guid) noexcept = 0;
            virtual int32_t __stdcall WriteInt16(int16_t) noexcept = 0;
            virtual int32_t __stdcall WriteInt32(int32_t) noexcept = 0;
            virtual int32_t __stdcall WriteInt64(int64_t) noexcept = 0;
            virtual int32_t __stdcall WriteUInt16(uint16_t) noexcept = 0;
            virtual int32_t __stdcall WriteUInt32(uint32_t) noexcept = 0;
            virtual int32_t __stdcall WriteUInt64(uint64_t) noexcept = 0;
            virtual int32_t __stdcall WriteSingle(float) noexcept = 0;
            virtual int32_t __stdcall WriteDouble(double) noexcept = 0;
            virtual int32_t __stdcall WriteDateTime(int64_t) noexcept = 0;
            virtual int32_t __stdcall WriteTimeSpan(int64_t) noexcept = 0;
            virtual int32_t __stdcall WriteString(void*, uint32_t*) noexcept = 0;
            virtual int32_t __stdcall MeasureString(void*, uint32_t*) noexcept = 0;
            virtual int32_t __stdcall StoreAsync(void**) noexcept = 0;
            virtual int32_t __stdcall FlushAsync(void**) noexcept = 0;
            virtual int32_t __stdcall DetachBuffer(void**) noexcept = 0;
            virtual int32_t __stdcall DetachStream(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IDataWriterFactory>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateDataWriter(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IFileRandomAccessStreamStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall OpenAsync(void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall OpenWithOptionsAsync(void*, int32_t, uint32_t, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall OpenTransactedWriteAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall OpenTransactedWriteWithOptionsAsync(void*, uint32_t, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall OpenForUserAsync(void*, void*, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall OpenForUserWithOptionsAsync(void*, void*, int32_t, uint32_t, int32_t, void**) noexcept = 0;
            virtual int32_t __stdcall OpenTransactedWriteForUserAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall OpenTransactedWriteForUserWithOptionsAsync(void*, void*, uint32_t, int32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IInputStream>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall ReadAsync(void*, uint32_t, uint32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IInputStreamReference>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall OpenSequentialReadAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IOutputStream>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall WriteAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall FlushAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IRandomAccessStream>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Size(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall put_Size(uint64_t) noexcept = 0;
            virtual int32_t __stdcall GetInputStreamAt(uint64_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetOutputStreamAt(uint64_t, void**) noexcept = 0;
            virtual int32_t __stdcall get_Position(uint64_t*) noexcept = 0;
            virtual int32_t __stdcall Seek(uint64_t) noexcept = 0;
            virtual int32_t __stdcall CloneStream(void**) noexcept = 0;
            virtual int32_t __stdcall get_CanRead(bool*) noexcept = 0;
            virtual int32_t __stdcall get_CanWrite(bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IRandomAccessStreamReference>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall OpenReadAsync(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IRandomAccessStreamReferenceStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CreateFromFile(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFromUri(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateFromStream(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IRandomAccessStreamStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall CopyAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall CopySizeAsync(void*, void*, uint64_t, void**) noexcept = 0;
            virtual int32_t __stdcall CopyAndCloseAsync(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Storage::Streams::IRandomAccessStreamWithContentType>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
        };
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IBuffer
    {
        [[nodiscard]] auto Capacity() const;
        [[nodiscard]] auto Length() const;
        auto Length(uint32_t value) const;

        auto data() const
        {
            uint8_t* data{};
            static_cast<D const&>(*this).template as<IBufferByteAccess>()->Buffer(&data);
            return data;
        }
    };
    template <> struct consume<Windows::Storage::Streams::IBuffer>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IBuffer<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IBufferFactory
    {
        auto Create(uint32_t capacity) const;
    };
    template <> struct consume<Windows::Storage::Streams::IBufferFactory>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IBufferFactory<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IBufferStatics
    {
        auto CreateCopyFromMemoryBuffer(Windows::Foundation::IMemoryBuffer const& input) const;
        auto CreateMemoryBufferOverIBuffer(Windows::Storage::Streams::IBuffer const& input) const;
    };
    template <> struct consume<Windows::Storage::Streams::IBufferStatics>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IBufferStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IContentTypeProvider
    {
        [[nodiscard]] auto ContentType() const;
    };
    template <> struct consume<Windows::Storage::Streams::IContentTypeProvider>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IContentTypeProvider<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IDataReader
    {
        [[nodiscard]] auto UnconsumedBufferLength() const;
        [[nodiscard]] auto UnicodeEncoding() const;
        auto UnicodeEncoding(Windows::Storage::Streams::UnicodeEncoding const& value) const;
        [[nodiscard]] auto ByteOrder() const;
        auto ByteOrder(Windows::Storage::Streams::ByteOrder const& value) const;
        [[nodiscard]] auto InputStreamOptions() const;
        auto InputStreamOptions(Windows::Storage::Streams::InputStreamOptions const& value) const;
        auto ReadByte() const;
        auto ReadBytes(array_view<uint8_t> value) const;
        auto ReadBuffer(uint32_t length) const;
        auto ReadBoolean() const;
        auto ReadGuid() const;
        auto ReadInt16() const;
        auto ReadInt32() const;
        auto ReadInt64() const;
        auto ReadUInt16() const;
        auto ReadUInt32() const;
        auto ReadUInt64() const;
        auto ReadSingle() const;
        auto ReadDouble() const;
        auto ReadString(uint32_t codeUnitCount) const;
        auto ReadDateTime() const;
        auto ReadTimeSpan() const;
        auto LoadAsync(uint32_t count) const;
        auto DetachBuffer() const;
        auto DetachStream() const;
    };
    template <> struct consume<Windows::Storage::Streams::IDataReader>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IDataReader<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IDataReaderFactory
    {
        auto CreateDataReader(Windows::Storage::Streams::IInputStream const& inputStream) const;
    };
    template <> struct consume<Windows::Storage::Streams::IDataReaderFactory>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IDataReaderFactory<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IDataReaderStatics
    {
        auto FromBuffer(Windows::Storage::Streams::IBuffer const& buffer) const;
    };
    template <> struct consume<Windows::Storage::Streams::IDataReaderStatics>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IDataReaderStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IDataWriter
    {
        [[nodiscard]] auto UnstoredBufferLength() const;
        [[nodiscard]] auto UnicodeEncoding() const;
        auto UnicodeEncoding(Windows::Storage::Streams::UnicodeEncoding const& value) const;
        [[nodiscard]] auto ByteOrder() const;
        auto ByteOrder(Windows::Storage::Streams::ByteOrder const& value) const;
        auto WriteByte(uint8_t value) const;
        auto WriteBytes(array_view<uint8_t const> value) const;
        auto WriteBuffer(Windows::Storage::Streams::IBuffer const& buffer) const;
        auto WriteBuffer(Windows::Storage::Streams::IBuffer const& buffer, uint32_t start, uint32_t count) const;
        auto WriteBoolean(bool value) const;
        auto WriteGuid(winrt::guid const& value) const;
        auto WriteInt16(int16_t value) const;
        auto WriteInt32(int32_t value) const;
        auto WriteInt64(int64_t value) const;
        auto WriteUInt16(uint16_t value) const;
        auto WriteUInt32(uint32_t value) const;
        auto WriteUInt64(uint64_t value) const;
        auto WriteSingle(float value) const;
        auto WriteDouble(double value) const;
        auto WriteDateTime(Windows::Foundation::DateTime const& value) const;
        auto WriteTimeSpan(Windows::Foundation::TimeSpan const& value) const;
        auto WriteString(param::hstring const& value) const;
        auto MeasureString(param::hstring const& value) const;
        auto StoreAsync() const;
        auto FlushAsync() const;
        auto DetachBuffer() const;
        auto DetachStream() const;
    };
    template <> struct consume<Windows::Storage::Streams::IDataWriter>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IDataWriter<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IDataWriterFactory
    {
        auto CreateDataWriter(Windows::Storage::Streams::IOutputStream const& outputStream) const;
    };
    template <> struct consume<Windows::Storage::Streams::IDataWriterFactory>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IDataWriterFactory<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IFileRandomAccessStreamStatics
    {
        auto OpenAsync(param::hstring const& filePath, Windows::Storage::FileAccessMode const& accessMode) const;
        auto OpenAsync(param::hstring const& filePath, Windows::Storage::FileAccessMode const& accessMode, Windows::Storage::StorageOpenOptions const& sharingOptions, Windows::Storage::Streams::FileOpenDisposition const& openDisposition) const;
        auto OpenTransactedWriteAsync(param::hstring const& filePath) const;
        auto OpenTransactedWriteAsync(param::hstring const& filePath, Windows::Storage::StorageOpenOptions const& openOptions, Windows::Storage::Streams::FileOpenDisposition const& openDisposition) const;
        auto OpenForUserAsync(Windows::System::User const& user, param::hstring const& filePath, Windows::Storage::FileAccessMode const& accessMode) const;
        auto OpenForUserAsync(Windows::System::User const& user, param::hstring const& filePath, Windows::Storage::FileAccessMode const& accessMode, Windows::Storage::StorageOpenOptions const& sharingOptions, Windows::Storage::Streams::FileOpenDisposition const& openDisposition) const;
        auto OpenTransactedWriteForUserAsync(Windows::System::User const& user, param::hstring const& filePath) const;
        auto OpenTransactedWriteForUserAsync(Windows::System::User const& user, param::hstring const& filePath, Windows::Storage::StorageOpenOptions const& openOptions, Windows::Storage::Streams::FileOpenDisposition const& openDisposition) const;
    };
    template <> struct consume<Windows::Storage::Streams::IFileRandomAccessStreamStatics>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IFileRandomAccessStreamStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IInputStream
    {
        auto ReadAsync(Windows::Storage::Streams::IBuffer const& buffer, uint32_t count, Windows::Storage::Streams::InputStreamOptions const& options) const;
    };
    template <> struct consume<Windows::Storage::Streams::IInputStream>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IInputStream<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IInputStreamReference
    {
        auto OpenSequentialReadAsync() const;
    };
    template <> struct consume<Windows::Storage::Streams::IInputStreamReference>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IInputStreamReference<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IOutputStream
    {
        auto WriteAsync(Windows::Storage::Streams::IBuffer const& buffer) const;
        auto FlushAsync() const;
    };
    template <> struct consume<Windows::Storage::Streams::IOutputStream>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IOutputStream<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IRandomAccessStream
    {
        [[nodiscard]] auto Size() const;
        auto Size(uint64_t value) const;
        auto GetInputStreamAt(uint64_t position) const;
        auto GetOutputStreamAt(uint64_t position) const;
        [[nodiscard]] auto Position() const;
        auto Seek(uint64_t position) const;
        auto CloneStream() const;
        [[nodiscard]] auto CanRead() const;
        [[nodiscard]] auto CanWrite() const;
    };
    template <> struct consume<Windows::Storage::Streams::IRandomAccessStream>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IRandomAccessStream<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IRandomAccessStreamReference
    {
        auto OpenReadAsync() const;
    };
    template <> struct consume<Windows::Storage::Streams::IRandomAccessStreamReference>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IRandomAccessStreamReference<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IRandomAccessStreamReferenceStatics
    {
        auto CreateFromFile(Windows::Storage::IStorageFile const& file) const;
        auto CreateFromUri(Windows::Foundation::Uri const& uri) const;
        auto CreateFromStream(Windows::Storage::Streams::IRandomAccessStream const& stream) const;
    };
    template <> struct consume<Windows::Storage::Streams::IRandomAccessStreamReferenceStatics>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IRandomAccessStreamReferenceStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IRandomAccessStreamStatics
    {
        auto CopyAsync(Windows::Storage::Streams::IInputStream const& source, Windows::Storage::Streams::IOutputStream const& destination) const;
        auto CopyAsync(Windows::Storage::Streams::IInputStream const& source, Windows::Storage::Streams::IOutputStream const& destination, uint64_t bytesToCopy) const;
        auto CopyAndCloseAsync(Windows::Storage::Streams::IInputStream const& source, Windows::Storage::Streams::IOutputStream const& destination) const;
    };
    template <> struct consume<Windows::Storage::Streams::IRandomAccessStreamStatics>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IRandomAccessStreamStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Storage_Streams_IRandomAccessStreamWithContentType
    {
    };
    template <> struct consume<Windows::Storage::Streams::IRandomAccessStreamWithContentType>
    {
        template <typename D> using type = consume_Windows_Storage_Streams_IRandomAccessStreamWithContentType<D>;
    };
}
#endif
