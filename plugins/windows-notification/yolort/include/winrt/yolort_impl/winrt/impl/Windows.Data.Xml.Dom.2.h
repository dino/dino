// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Data_Xml_Dom_2_H
#define WINRT_Windows_Data_Xml_Dom_2_H
#include "Windows.Foundation.1.h"
#include "Windows.Foundation.Collections.1.h"
#include "Windows.Storage.1.h"
#include "Windows.Data.Xml.Dom.1.h"
namespace winrt::Windows::Data::Xml::Dom
{
    struct __declspec(empty_bases) DtdEntity : Windows::Data::Xml::Dom::IDtdEntity
    {
        DtdEntity(std::nullptr_t) noexcept {}
        DtdEntity(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IDtdEntity(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) DtdNotation : Windows::Data::Xml::Dom::IDtdNotation
    {
        DtdNotation(std::nullptr_t) noexcept {}
        DtdNotation(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IDtdNotation(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlAttribute : Windows::Data::Xml::Dom::IXmlAttribute
    {
        XmlAttribute(std::nullptr_t) noexcept {}
        XmlAttribute(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlAttribute(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlCDataSection : Windows::Data::Xml::Dom::IXmlCDataSection
    {
        XmlCDataSection(std::nullptr_t) noexcept {}
        XmlCDataSection(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlCDataSection(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlComment : Windows::Data::Xml::Dom::IXmlComment
    {
        XmlComment(std::nullptr_t) noexcept {}
        XmlComment(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlComment(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlDocument : Windows::Data::Xml::Dom::IXmlDocument,
        impl::require<XmlDocument, Windows::Data::Xml::Dom::IXmlDocumentIO, Windows::Data::Xml::Dom::IXmlDocumentIO2>
    {
        XmlDocument(std::nullptr_t) noexcept {}
        XmlDocument(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlDocument(ptr, take_ownership_from_abi) {}
        XmlDocument();
        static auto LoadFromUriAsync(Windows::Foundation::Uri const& uri);
        static auto LoadFromUriAsync(Windows::Foundation::Uri const& uri, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings);
        static auto LoadFromFileAsync(Windows::Storage::IStorageFile const& file);
        static auto LoadFromFileAsync(Windows::Storage::IStorageFile const& file, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings);
    };
    struct __declspec(empty_bases) XmlDocumentFragment : Windows::Data::Xml::Dom::IXmlDocumentFragment
    {
        XmlDocumentFragment(std::nullptr_t) noexcept {}
        XmlDocumentFragment(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlDocumentFragment(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlDocumentType : Windows::Data::Xml::Dom::IXmlDocumentType
    {
        XmlDocumentType(std::nullptr_t) noexcept {}
        XmlDocumentType(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlDocumentType(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlDomImplementation : Windows::Data::Xml::Dom::IXmlDomImplementation
    {
        XmlDomImplementation(std::nullptr_t) noexcept {}
        XmlDomImplementation(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlDomImplementation(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlElement : Windows::Data::Xml::Dom::IXmlElement
    {
        XmlElement(std::nullptr_t) noexcept {}
        XmlElement(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlElement(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlEntityReference : Windows::Data::Xml::Dom::IXmlEntityReference
    {
        XmlEntityReference(std::nullptr_t) noexcept {}
        XmlEntityReference(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlEntityReference(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlLoadSettings : Windows::Data::Xml::Dom::IXmlLoadSettings
    {
        XmlLoadSettings(std::nullptr_t) noexcept {}
        XmlLoadSettings(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlLoadSettings(ptr, take_ownership_from_abi) {}
        XmlLoadSettings();
    };
    struct __declspec(empty_bases) XmlNamedNodeMap : Windows::Data::Xml::Dom::IXmlNamedNodeMap
    {
        XmlNamedNodeMap(std::nullptr_t) noexcept {}
        XmlNamedNodeMap(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlNamedNodeMap(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlNodeList : Windows::Data::Xml::Dom::IXmlNodeList
    {
        XmlNodeList(std::nullptr_t) noexcept {}
        XmlNodeList(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlNodeList(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlProcessingInstruction : Windows::Data::Xml::Dom::IXmlProcessingInstruction
    {
        XmlProcessingInstruction(std::nullptr_t) noexcept {}
        XmlProcessingInstruction(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlProcessingInstruction(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) XmlText : Windows::Data::Xml::Dom::IXmlText
    {
        XmlText(std::nullptr_t) noexcept {}
        XmlText(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Data::Xml::Dom::IXmlText(ptr, take_ownership_from_abi) {}
    };
}
#endif
