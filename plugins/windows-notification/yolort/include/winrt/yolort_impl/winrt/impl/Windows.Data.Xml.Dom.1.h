// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Data_Xml_Dom_1_H
#define WINRT_Windows_Data_Xml_Dom_1_H
#include "Windows.Foundation.Collections.0.h"
#include "Windows.Data.Xml.Dom.0.h"
namespace winrt::Windows::Data::Xml::Dom
{
    struct __declspec(empty_bases) IDtdEntity :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDtdEntity>,
        impl::require<Windows::Data::Xml::Dom::IDtdEntity, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IDtdEntity(std::nullptr_t = nullptr) noexcept {}
        IDtdEntity(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IDtdNotation :
        Windows::Foundation::IInspectable,
        impl::consume_t<IDtdNotation>,
        impl::require<Windows::Data::Xml::Dom::IDtdNotation, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IDtdNotation(std::nullptr_t = nullptr) noexcept {}
        IDtdNotation(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlAttribute :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlAttribute>,
        impl::require<Windows::Data::Xml::Dom::IXmlAttribute, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IXmlAttribute(std::nullptr_t = nullptr) noexcept {}
        IXmlAttribute(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlCDataSection :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlCDataSection>,
        impl::require<Windows::Data::Xml::Dom::IXmlCDataSection, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode, Windows::Data::Xml::Dom::IXmlCharacterData, Windows::Data::Xml::Dom::IXmlText>
    {
        IXmlCDataSection(std::nullptr_t = nullptr) noexcept {}
        IXmlCDataSection(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlCharacterData :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlCharacterData>,
        impl::require<Windows::Data::Xml::Dom::IXmlCharacterData, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IXmlCharacterData(std::nullptr_t = nullptr) noexcept {}
        IXmlCharacterData(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlComment :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlComment>,
        impl::require<Windows::Data::Xml::Dom::IXmlComment, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode, Windows::Data::Xml::Dom::IXmlCharacterData>
    {
        IXmlComment(std::nullptr_t = nullptr) noexcept {}
        IXmlComment(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlDocument :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlDocument>,
        impl::require<Windows::Data::Xml::Dom::IXmlDocument, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IXmlDocument(std::nullptr_t = nullptr) noexcept {}
        IXmlDocument(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlDocumentFragment :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlDocumentFragment>,
        impl::require<Windows::Data::Xml::Dom::IXmlDocumentFragment, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IXmlDocumentFragment(std::nullptr_t = nullptr) noexcept {}
        IXmlDocumentFragment(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlDocumentIO :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlDocumentIO>
    {
        IXmlDocumentIO(std::nullptr_t = nullptr) noexcept {}
        IXmlDocumentIO(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlDocumentIO2 :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlDocumentIO2>
    {
        IXmlDocumentIO2(std::nullptr_t = nullptr) noexcept {}
        IXmlDocumentIO2(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlDocumentStatics :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlDocumentStatics>
    {
        IXmlDocumentStatics(std::nullptr_t = nullptr) noexcept {}
        IXmlDocumentStatics(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlDocumentType :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlDocumentType>,
        impl::require<Windows::Data::Xml::Dom::IXmlDocumentType, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IXmlDocumentType(std::nullptr_t = nullptr) noexcept {}
        IXmlDocumentType(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlDomImplementation :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlDomImplementation>
    {
        IXmlDomImplementation(std::nullptr_t = nullptr) noexcept {}
        IXmlDomImplementation(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlElement :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlElement>,
        impl::require<Windows::Data::Xml::Dom::IXmlElement, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IXmlElement(std::nullptr_t = nullptr) noexcept {}
        IXmlElement(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlEntityReference :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlEntityReference>,
        impl::require<Windows::Data::Xml::Dom::IXmlEntityReference, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IXmlEntityReference(std::nullptr_t = nullptr) noexcept {}
        IXmlEntityReference(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlLoadSettings :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlLoadSettings>
    {
        IXmlLoadSettings(std::nullptr_t = nullptr) noexcept {}
        IXmlLoadSettings(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlNamedNodeMap :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlNamedNodeMap>,
        impl::require<Windows::Data::Xml::Dom::IXmlNamedNodeMap, Windows::Foundation::Collections::IIterable<Windows::Data::Xml::Dom::IXmlNode>, Windows::Foundation::Collections::IVectorView<Windows::Data::Xml::Dom::IXmlNode>>
    {
        IXmlNamedNodeMap(std::nullptr_t = nullptr) noexcept {}
        IXmlNamedNodeMap(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlNode :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlNode>,
        impl::require<Windows::Data::Xml::Dom::IXmlNode, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer>
    {
        IXmlNode(std::nullptr_t = nullptr) noexcept {}
        IXmlNode(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlNodeList :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlNodeList>,
        impl::require<Windows::Data::Xml::Dom::IXmlNodeList, Windows::Foundation::Collections::IIterable<Windows::Data::Xml::Dom::IXmlNode>, Windows::Foundation::Collections::IVectorView<Windows::Data::Xml::Dom::IXmlNode>>
    {
        IXmlNodeList(std::nullptr_t = nullptr) noexcept {}
        IXmlNodeList(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlNodeSelector :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlNodeSelector>
    {
        IXmlNodeSelector(std::nullptr_t = nullptr) noexcept {}
        IXmlNodeSelector(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlNodeSerializer :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlNodeSerializer>
    {
        IXmlNodeSerializer(std::nullptr_t = nullptr) noexcept {}
        IXmlNodeSerializer(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlProcessingInstruction :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlProcessingInstruction>,
        impl::require<Windows::Data::Xml::Dom::IXmlProcessingInstruction, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode>
    {
        IXmlProcessingInstruction(std::nullptr_t = nullptr) noexcept {}
        IXmlProcessingInstruction(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
    struct __declspec(empty_bases) IXmlText :
        Windows::Foundation::IInspectable,
        impl::consume_t<IXmlText>,
        impl::require<Windows::Data::Xml::Dom::IXmlText, Windows::Data::Xml::Dom::IXmlNodeSelector, Windows::Data::Xml::Dom::IXmlNodeSerializer, Windows::Data::Xml::Dom::IXmlNode, Windows::Data::Xml::Dom::IXmlCharacterData>
    {
        IXmlText(std::nullptr_t = nullptr) noexcept {}
        IXmlText(void* ptr, take_ownership_from_abi_t) noexcept : Windows::Foundation::IInspectable(ptr, take_ownership_from_abi) {}
    };
}
#endif
