// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Foundation_2_H
#define WINRT_Windows_Foundation_2_H
#include "Windows.Foundation.Collections.1.h"
#include "Windows.Foundation.1.h"
namespace winrt::Windows::Foundation
{
    struct AsyncActionCompletedHandler : Windows::Foundation::IUnknown
    {
        AsyncActionCompletedHandler(std::nullptr_t = nullptr) noexcept {}
        AsyncActionCompletedHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> AsyncActionCompletedHandler(L lambda);
        template <typename F> AsyncActionCompletedHandler(F* function);
        template <typename O, typename M> AsyncActionCompletedHandler(O* object, M method);
        template <typename O, typename M> AsyncActionCompletedHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> AsyncActionCompletedHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Foundation::IAsyncAction const& asyncInfo, Windows::Foundation::AsyncStatus const& asyncStatus) const;
    };
    template <typename TProgress>
    struct AsyncActionProgressHandler : Windows::Foundation::IUnknown
    {
        static_assert(impl::has_category_v<TProgress>, "TProgress must be WinRT type.");
        AsyncActionProgressHandler(std::nullptr_t = nullptr) noexcept {}
        AsyncActionProgressHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> AsyncActionProgressHandler(L lambda);
        template <typename F> AsyncActionProgressHandler(F* function);
        template <typename O, typename M> AsyncActionProgressHandler(O* object, M method);
        template <typename O, typename M> AsyncActionProgressHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> AsyncActionProgressHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Foundation::IAsyncActionWithProgress<TProgress> const& asyncInfo, impl::param_type<TProgress> const& progressInfo) const;
    };
    template <typename TProgress>
    struct AsyncActionWithProgressCompletedHandler : Windows::Foundation::IUnknown
    {
        static_assert(impl::has_category_v<TProgress>, "TProgress must be WinRT type.");
        AsyncActionWithProgressCompletedHandler(std::nullptr_t = nullptr) noexcept {}
        AsyncActionWithProgressCompletedHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> AsyncActionWithProgressCompletedHandler(L lambda);
        template <typename F> AsyncActionWithProgressCompletedHandler(F* function);
        template <typename O, typename M> AsyncActionWithProgressCompletedHandler(O* object, M method);
        template <typename O, typename M> AsyncActionWithProgressCompletedHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> AsyncActionWithProgressCompletedHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Foundation::IAsyncActionWithProgress<TProgress> const& asyncInfo, Windows::Foundation::AsyncStatus const& asyncStatus) const;
    };
    template <typename TResult>
    struct AsyncOperationCompletedHandler : Windows::Foundation::IUnknown
    {
        static_assert(impl::has_category_v<TResult>, "TResult must be WinRT type.");
        AsyncOperationCompletedHandler(std::nullptr_t = nullptr) noexcept {}
        AsyncOperationCompletedHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> AsyncOperationCompletedHandler(L lambda);
        template <typename F> AsyncOperationCompletedHandler(F* function);
        template <typename O, typename M> AsyncOperationCompletedHandler(O* object, M method);
        template <typename O, typename M> AsyncOperationCompletedHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> AsyncOperationCompletedHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Foundation::IAsyncOperation<TResult> const& asyncInfo, Windows::Foundation::AsyncStatus const& asyncStatus) const;
    };
    template <typename TResult, typename TProgress>
    struct AsyncOperationProgressHandler : Windows::Foundation::IUnknown
    {
        static_assert(impl::has_category_v<TResult>, "TResult must be WinRT type.");
        static_assert(impl::has_category_v<TProgress>, "TProgress must be WinRT type.");
        AsyncOperationProgressHandler(std::nullptr_t = nullptr) noexcept {}
        AsyncOperationProgressHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> AsyncOperationProgressHandler(L lambda);
        template <typename F> AsyncOperationProgressHandler(F* function);
        template <typename O, typename M> AsyncOperationProgressHandler(O* object, M method);
        template <typename O, typename M> AsyncOperationProgressHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> AsyncOperationProgressHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress> const& asyncInfo, impl::param_type<TProgress> const& progressInfo) const;
    };
    template <typename TResult, typename TProgress>
    struct AsyncOperationWithProgressCompletedHandler : Windows::Foundation::IUnknown
    {
        static_assert(impl::has_category_v<TResult>, "TResult must be WinRT type.");
        static_assert(impl::has_category_v<TProgress>, "TProgress must be WinRT type.");
        AsyncOperationWithProgressCompletedHandler(std::nullptr_t = nullptr) noexcept {}
        AsyncOperationWithProgressCompletedHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> AsyncOperationWithProgressCompletedHandler(L lambda);
        template <typename F> AsyncOperationWithProgressCompletedHandler(F* function);
        template <typename O, typename M> AsyncOperationWithProgressCompletedHandler(O* object, M method);
        template <typename O, typename M> AsyncOperationWithProgressCompletedHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> AsyncOperationWithProgressCompletedHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Foundation::IAsyncOperationWithProgress<TResult, TProgress> const& asyncInfo, Windows::Foundation::AsyncStatus const& asyncStatus) const;
    };
    struct DeferralCompletedHandler : Windows::Foundation::IUnknown
    {
        DeferralCompletedHandler(std::nullptr_t = nullptr) noexcept {}
        DeferralCompletedHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> DeferralCompletedHandler(L lambda);
        template <typename F> DeferralCompletedHandler(F* function);
        template <typename O, typename M> DeferralCompletedHandler(O* object, M method);
        template <typename O, typename M> DeferralCompletedHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> DeferralCompletedHandler(weak_ref<O>&& object, M method);
        auto operator()() const;
    };
    template <typename T>
    struct EventHandler : Windows::Foundation::IUnknown
    {
        static_assert(impl::has_category_v<T>, "T must be WinRT type.");
        EventHandler(std::nullptr_t = nullptr) noexcept {}
        EventHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> EventHandler(L lambda);
        template <typename F> EventHandler(F* function);
        template <typename O, typename M> EventHandler(O* object, M method);
        template <typename O, typename M> EventHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> EventHandler(weak_ref<O>&& object, M method);
        auto operator()(Windows::Foundation::IInspectable const& sender, impl::param_type<T> const& args) const;
    };
    template <typename TSender, typename TResult>
    struct TypedEventHandler : Windows::Foundation::IUnknown
    {
        static_assert(impl::has_category_v<TSender>, "TSender must be WinRT type.");
        static_assert(impl::has_category_v<TResult>, "TResult must be WinRT type.");
        TypedEventHandler(std::nullptr_t = nullptr) noexcept {}
        TypedEventHandler(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUnknown(ptr, take_ownership_from_abi) {}
        template <typename L> TypedEventHandler(L lambda);
        template <typename F> TypedEventHandler(F* function);
        template <typename O, typename M> TypedEventHandler(O* object, M method);
        template <typename O, typename M> TypedEventHandler(com_ptr<O>&& object, M method);
        template <typename O, typename M> TypedEventHandler(weak_ref<O>&& object, M method);
        auto operator()(impl::param_type<TSender> const& sender, impl::param_type<TResult> const& args) const;
    };
    struct __declspec(empty_bases) Deferral : Windows::Foundation::IDeferral
    {
        Deferral(std::nullptr_t) noexcept {}
        Deferral(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IDeferral(ptr, take_ownership_from_abi) {}
        Deferral(Windows::Foundation::DeferralCompletedHandler const& handler);
    };
    struct GuidHelper
    {
        GuidHelper() = delete;
        static auto CreateNewGuid();
        [[nodiscard]] static auto Empty();
        static auto Equals(winrt::guid const& target, winrt::guid const& value);
    };
    struct __declspec(empty_bases) MemoryBuffer : Windows::Foundation::IMemoryBuffer
    {
        MemoryBuffer(std::nullptr_t) noexcept {}
        MemoryBuffer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IMemoryBuffer(ptr, take_ownership_from_abi) {}
        MemoryBuffer(uint32_t capacity);
    };
    struct PropertyValue
    {
        PropertyValue() = delete;
        static auto CreateEmpty();
        static auto CreateUInt8(uint8_t value);
        static auto CreateInt16(int16_t value);
        static auto CreateUInt16(uint16_t value);
        static auto CreateInt32(int32_t value);
        static auto CreateUInt32(uint32_t value);
        static auto CreateInt64(int64_t value);
        static auto CreateUInt64(uint64_t value);
        static auto CreateSingle(float value);
        static auto CreateDouble(double value);
        static auto CreateChar16(char16_t value);
        static auto CreateBoolean(bool value);
        static auto CreateString(param::hstring const& value);
        static auto CreateInspectable(Windows::Foundation::IInspectable const& value);
        static auto CreateGuid(winrt::guid const& value);
        static auto CreateDateTime(Windows::Foundation::DateTime const& value);
        static auto CreateTimeSpan(Windows::Foundation::TimeSpan const& value);
        static auto CreatePoint(Windows::Foundation::Point const& value);
        static auto CreateSize(Windows::Foundation::Size const& value);
        static auto CreateRect(Windows::Foundation::Rect const& value);
        static auto CreateUInt8Array(array_view<uint8_t const> value);
        static auto CreateInt16Array(array_view<int16_t const> value);
        static auto CreateUInt16Array(array_view<uint16_t const> value);
        static auto CreateInt32Array(array_view<int32_t const> value);
        static auto CreateUInt32Array(array_view<uint32_t const> value);
        static auto CreateInt64Array(array_view<int64_t const> value);
        static auto CreateUInt64Array(array_view<uint64_t const> value);
        static auto CreateSingleArray(array_view<float const> value);
        static auto CreateDoubleArray(array_view<double const> value);
        static auto CreateChar16Array(array_view<char16_t const> value);
        static auto CreateBooleanArray(array_view<bool const> value);
        static auto CreateStringArray(array_view<hstring const> value);
        static auto CreateInspectableArray(array_view<Windows::Foundation::IInspectable const> value);
        static auto CreateGuidArray(array_view<winrt::guid const> value);
        static auto CreateDateTimeArray(array_view<Windows::Foundation::DateTime const> value);
        static auto CreateTimeSpanArray(array_view<Windows::Foundation::TimeSpan const> value);
        static auto CreatePointArray(array_view<Windows::Foundation::Point const> value);
        static auto CreateSizeArray(array_view<Windows::Foundation::Size const> value);
        static auto CreateRectArray(array_view<Windows::Foundation::Rect const> value);
    };
    struct __declspec(empty_bases) Uri : Windows::Foundation::IUriRuntimeClass,
        impl::require<Uri, Windows::Foundation::IUriRuntimeClassWithAbsoluteCanonicalUri, Windows::Foundation::IStringable>
    {
        Uri(std::nullptr_t) noexcept {}
        Uri(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IUriRuntimeClass(ptr, take_ownership_from_abi) {}
        Uri(param::hstring const& uri);
        Uri(param::hstring const& baseUri, param::hstring const& relativeUri);
        static auto UnescapeComponent(param::hstring const& toUnescape);
        static auto EscapeComponent(param::hstring const& toEscape);
    };
    struct __declspec(empty_bases) WwwFormUrlDecoder : Windows::Foundation::IWwwFormUrlDecoderRuntimeClass
    {
        WwwFormUrlDecoder(std::nullptr_t) noexcept {}
        WwwFormUrlDecoder(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IWwwFormUrlDecoderRuntimeClass(ptr, take_ownership_from_abi) {}
        WwwFormUrlDecoder(param::hstring const& query);
    };
    struct __declspec(empty_bases) WwwFormUrlDecoderEntry : Windows::Foundation::IWwwFormUrlDecoderEntry
    {
        WwwFormUrlDecoderEntry(std::nullptr_t) noexcept {}
        WwwFormUrlDecoderEntry(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IWwwFormUrlDecoderEntry(ptr, take_ownership_from_abi) {}
    };
}
#endif
