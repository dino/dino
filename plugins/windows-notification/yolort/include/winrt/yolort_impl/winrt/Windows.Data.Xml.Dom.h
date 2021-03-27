// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Data_Xml_Dom_H
#define WINRT_Windows_Data_Xml_Dom_H
#include "base.h"
static_assert(winrt::check_version(CPPWINRT_VERSION, "2.0.190620.2"), "Mismatched C++/WinRT headers.");
#include "impl/Windows.Foundation.2.h"
#include "impl/Windows.Foundation.Collections.2.h"
#include "impl/Windows.Storage.2.h"
#include "impl/Windows.Storage.Streams.2.h"
#include "impl/Windows.Data.Xml.Dom.2.h"
namespace winrt::impl
{
    template <typename D> auto consume_Windows_Data_Xml_Dom_IDtdEntity<D>::PublicId() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IDtdEntity)->get_PublicId(&value));
        return Windows::Foundation::IInspectable{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IDtdEntity<D>::SystemId() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IDtdEntity)->get_SystemId(&value));
        return Windows::Foundation::IInspectable{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IDtdEntity<D>::NotationName() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IDtdEntity)->get_NotationName(&value));
        return Windows::Foundation::IInspectable{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IDtdNotation<D>::PublicId() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IDtdNotation)->get_PublicId(&value));
        return Windows::Foundation::IInspectable{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IDtdNotation<D>::SystemId() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IDtdNotation)->get_SystemId(&value));
        return Windows::Foundation::IInspectable{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlAttribute<D>::Name() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlAttribute)->get_Name(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlAttribute<D>::Specified() const
    {
        bool value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlAttribute)->get_Specified(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlAttribute<D>::Value() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlAttribute)->get_Value(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlAttribute<D>::Value(param::hstring const& value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlAttribute)->put_Value(*(void**)(&value)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlCharacterData<D>::Data() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlCharacterData)->get_Data(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlCharacterData<D>::Data(param::hstring const& value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlCharacterData)->put_Data(*(void**)(&value)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlCharacterData<D>::Length() const
    {
        uint32_t value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlCharacterData)->get_Length(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlCharacterData<D>::SubstringData(uint32_t offset, uint32_t count) const
    {
        void* data{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlCharacterData)->SubstringData(offset, count, &data));
        return hstring{ data, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlCharacterData<D>::AppendData(param::hstring const& data) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlCharacterData)->AppendData(*(void**)(&data)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlCharacterData<D>::InsertData(uint32_t offset, param::hstring const& data) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlCharacterData)->InsertData(offset, *(void**)(&data)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlCharacterData<D>::DeleteData(uint32_t offset, uint32_t count) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlCharacterData)->DeleteData(offset, count));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlCharacterData<D>::ReplaceData(uint32_t offset, uint32_t count, param::hstring const& data) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlCharacterData)->ReplaceData(offset, count, *(void**)(&data)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::Doctype() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->get_Doctype(&value));
        return Windows::Data::Xml::Dom::XmlDocumentType{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::Implementation() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->get_Implementation(&value));
        return Windows::Data::Xml::Dom::XmlDomImplementation{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::DocumentElement() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->get_DocumentElement(&value));
        return Windows::Data::Xml::Dom::XmlElement{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateElement(param::hstring const& tagName) const
    {
        void* newElement{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateElement(*(void**)(&tagName), &newElement));
        return Windows::Data::Xml::Dom::XmlElement{ newElement, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateDocumentFragment() const
    {
        void* newDocumentFragment{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateDocumentFragment(&newDocumentFragment));
        return Windows::Data::Xml::Dom::XmlDocumentFragment{ newDocumentFragment, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateTextNode(param::hstring const& data) const
    {
        void* newTextNode{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateTextNode(*(void**)(&data), &newTextNode));
        return Windows::Data::Xml::Dom::XmlText{ newTextNode, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateComment(param::hstring const& data) const
    {
        void* newComment{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateComment(*(void**)(&data), &newComment));
        return Windows::Data::Xml::Dom::XmlComment{ newComment, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateProcessingInstruction(param::hstring const& target, param::hstring const& data) const
    {
        void* newProcessingInstruction{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateProcessingInstruction(*(void**)(&target), *(void**)(&data), &newProcessingInstruction));
        return Windows::Data::Xml::Dom::XmlProcessingInstruction{ newProcessingInstruction, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateAttribute(param::hstring const& name) const
    {
        void* newAttribute{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateAttribute(*(void**)(&name), &newAttribute));
        return Windows::Data::Xml::Dom::XmlAttribute{ newAttribute, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateEntityReference(param::hstring const& name) const
    {
        void* newEntityReference{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateEntityReference(*(void**)(&name), &newEntityReference));
        return Windows::Data::Xml::Dom::XmlEntityReference{ newEntityReference, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::GetElementsByTagName(param::hstring const& tagName) const
    {
        void* elements{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->GetElementsByTagName(*(void**)(&tagName), &elements));
        return Windows::Data::Xml::Dom::XmlNodeList{ elements, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateCDataSection(param::hstring const& data) const
    {
        void* newCDataSection{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateCDataSection(*(void**)(&data), &newCDataSection));
        return Windows::Data::Xml::Dom::XmlCDataSection{ newCDataSection, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::DocumentUri() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->get_DocumentUri(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateAttributeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& qualifiedName) const
    {
        void* newAttribute{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateAttributeNS(*(void**)(&namespaceUri), *(void**)(&qualifiedName), &newAttribute));
        return Windows::Data::Xml::Dom::XmlAttribute{ newAttribute, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::CreateElementNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& qualifiedName) const
    {
        void* newElement{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->CreateElementNS(*(void**)(&namespaceUri), *(void**)(&qualifiedName), &newElement));
        return Windows::Data::Xml::Dom::XmlElement{ newElement, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::GetElementById(param::hstring const& elementId) const
    {
        void* element{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->GetElementById(*(void**)(&elementId), &element));
        return Windows::Data::Xml::Dom::XmlElement{ element, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocument<D>::ImportNode(Windows::Data::Xml::Dom::IXmlNode const& node, bool deep) const
    {
        void* newNode{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocument)->ImportNode(*(void**)(&node), deep, &newNode));
        return Windows::Data::Xml::Dom::IXmlNode{ newNode, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentIO<D>::LoadXml(param::hstring const& xml) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentIO)->LoadXml(*(void**)(&xml)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentIO<D>::LoadXml(param::hstring const& xml, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentIO)->LoadXmlWithSettings(*(void**)(&xml), *(void**)(&loadSettings)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentIO<D>::SaveToFileAsync(Windows::Storage::IStorageFile const& file) const
    {
        void* asyncInfo{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentIO)->SaveToFileAsync(*(void**)(&file), &asyncInfo));
        return Windows::Foundation::IAsyncAction{ asyncInfo, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentIO2<D>::LoadXmlFromBuffer(Windows::Storage::Streams::IBuffer const& buffer) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentIO2)->LoadXmlFromBuffer(*(void**)(&buffer)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentIO2<D>::LoadXmlFromBuffer(Windows::Storage::Streams::IBuffer const& buffer, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentIO2)->LoadXmlFromBufferWithSettings(*(void**)(&buffer), *(void**)(&loadSettings)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentStatics<D>::LoadFromUriAsync(Windows::Foundation::Uri const& uri) const
    {
        void* asyncInfo{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentStatics)->LoadFromUriAsync(*(void**)(&uri), &asyncInfo));
        return Windows::Foundation::IAsyncOperation<Windows::Data::Xml::Dom::XmlDocument>{ asyncInfo, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentStatics<D>::LoadFromUriAsync(Windows::Foundation::Uri const& uri, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings) const
    {
        void* asyncInfo{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentStatics)->LoadFromUriWithSettingsAsync(*(void**)(&uri), *(void**)(&loadSettings), &asyncInfo));
        return Windows::Foundation::IAsyncOperation<Windows::Data::Xml::Dom::XmlDocument>{ asyncInfo, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentStatics<D>::LoadFromFileAsync(Windows::Storage::IStorageFile const& file) const
    {
        void* asyncInfo{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentStatics)->LoadFromFileAsync(*(void**)(&file), &asyncInfo));
        return Windows::Foundation::IAsyncOperation<Windows::Data::Xml::Dom::XmlDocument>{ asyncInfo, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentStatics<D>::LoadFromFileAsync(Windows::Storage::IStorageFile const& file, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings) const
    {
        void* asyncInfo{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentStatics)->LoadFromFileWithSettingsAsync(*(void**)(&file), *(void**)(&loadSettings), &asyncInfo));
        return Windows::Foundation::IAsyncOperation<Windows::Data::Xml::Dom::XmlDocument>{ asyncInfo, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentType<D>::Name() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentType)->get_Name(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentType<D>::Entities() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentType)->get_Entities(&value));
        return Windows::Data::Xml::Dom::XmlNamedNodeMap{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDocumentType<D>::Notations() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDocumentType)->get_Notations(&value));
        return Windows::Data::Xml::Dom::XmlNamedNodeMap{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlDomImplementation<D>::HasFeature(param::hstring const& feature, Windows::Foundation::IInspectable const& version) const
    {
        bool featureSupported;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlDomImplementation)->HasFeature(*(void**)(&feature), *(void**)(&version), &featureSupported));
        return featureSupported;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::TagName() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->get_TagName(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::GetAttribute(param::hstring const& attributeName) const
    {
        void* attributeValue{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->GetAttribute(*(void**)(&attributeName), &attributeValue));
        return hstring{ attributeValue, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::SetAttribute(param::hstring const& attributeName, param::hstring const& attributeValue) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->SetAttribute(*(void**)(&attributeName), *(void**)(&attributeValue)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::RemoveAttribute(param::hstring const& attributeName) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->RemoveAttribute(*(void**)(&attributeName)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::GetAttributeNode(param::hstring const& attributeName) const
    {
        void* attributeNode{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->GetAttributeNode(*(void**)(&attributeName), &attributeNode));
        return Windows::Data::Xml::Dom::XmlAttribute{ attributeNode, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::SetAttributeNode(Windows::Data::Xml::Dom::XmlAttribute const& newAttribute) const
    {
        void* previousAttribute{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->SetAttributeNode(*(void**)(&newAttribute), &previousAttribute));
        return Windows::Data::Xml::Dom::XmlAttribute{ previousAttribute, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::RemoveAttributeNode(Windows::Data::Xml::Dom::XmlAttribute const& attributeNode) const
    {
        void* removedAttribute{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->RemoveAttributeNode(*(void**)(&attributeNode), &removedAttribute));
        return Windows::Data::Xml::Dom::XmlAttribute{ removedAttribute, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::GetElementsByTagName(param::hstring const& tagName) const
    {
        void* elements{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->GetElementsByTagName(*(void**)(&tagName), &elements));
        return Windows::Data::Xml::Dom::XmlNodeList{ elements, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::SetAttributeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& qualifiedName, param::hstring const& value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->SetAttributeNS(*(void**)(&namespaceUri), *(void**)(&qualifiedName), *(void**)(&value)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::GetAttributeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& localName) const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->GetAttributeNS(*(void**)(&namespaceUri), *(void**)(&localName), &value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::RemoveAttributeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& localName) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->RemoveAttributeNS(*(void**)(&namespaceUri), *(void**)(&localName)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::SetAttributeNodeNS(Windows::Data::Xml::Dom::XmlAttribute const& newAttribute) const
    {
        void* previousAttribute{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->SetAttributeNodeNS(*(void**)(&newAttribute), &previousAttribute));
        return Windows::Data::Xml::Dom::XmlAttribute{ previousAttribute, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlElement<D>::GetAttributeNodeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& localName) const
    {
        void* previousAttribute{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlElement)->GetAttributeNodeNS(*(void**)(&namespaceUri), *(void**)(&localName), &previousAttribute));
        return Windows::Data::Xml::Dom::XmlAttribute{ previousAttribute, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::MaxElementDepth() const
    {
        uint32_t value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->get_MaxElementDepth(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::MaxElementDepth(uint32_t value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->put_MaxElementDepth(value));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::ProhibitDtd() const
    {
        bool value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->get_ProhibitDtd(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::ProhibitDtd(bool value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->put_ProhibitDtd(value));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::ResolveExternals() const
    {
        bool value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->get_ResolveExternals(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::ResolveExternals(bool value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->put_ResolveExternals(value));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::ValidateOnParse() const
    {
        bool value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->get_ValidateOnParse(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::ValidateOnParse(bool value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->put_ValidateOnParse(value));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::ElementContentWhiteSpace() const
    {
        bool value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->get_ElementContentWhiteSpace(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>::ElementContentWhiteSpace(bool value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlLoadSettings)->put_ElementContentWhiteSpace(value));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap<D>::Length() const
    {
        uint32_t value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNamedNodeMap)->get_Length(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap<D>::Item(uint32_t index) const
    {
        void* node{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNamedNodeMap)->Item(index, &node));
        return Windows::Data::Xml::Dom::IXmlNode{ node, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap<D>::GetNamedItem(param::hstring const& name) const
    {
        void* node{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNamedNodeMap)->GetNamedItem(*(void**)(&name), &node));
        return Windows::Data::Xml::Dom::IXmlNode{ node, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap<D>::SetNamedItem(Windows::Data::Xml::Dom::IXmlNode const& node) const
    {
        void* previousNode{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNamedNodeMap)->SetNamedItem(*(void**)(&node), &previousNode));
        return Windows::Data::Xml::Dom::IXmlNode{ previousNode, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap<D>::RemoveNamedItem(param::hstring const& name) const
    {
        void* previousNode{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNamedNodeMap)->RemoveNamedItem(*(void**)(&name), &previousNode));
        return Windows::Data::Xml::Dom::IXmlNode{ previousNode, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap<D>::GetNamedItemNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& name) const
    {
        void* node{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNamedNodeMap)->GetNamedItemNS(*(void**)(&namespaceUri), *(void**)(&name), &node));
        return Windows::Data::Xml::Dom::IXmlNode{ node, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap<D>::RemoveNamedItemNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& name) const
    {
        void* previousNode{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNamedNodeMap)->RemoveNamedItemNS(*(void**)(&namespaceUri), *(void**)(&name), &previousNode));
        return Windows::Data::Xml::Dom::IXmlNode{ previousNode, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap<D>::SetNamedItemNS(Windows::Data::Xml::Dom::IXmlNode const& node) const
    {
        void* previousNode{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNamedNodeMap)->SetNamedItemNS(*(void**)(&node), &previousNode));
        return Windows::Data::Xml::Dom::IXmlNode{ previousNode, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::NodeValue() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_NodeValue(&value));
        return Windows::Foundation::IInspectable{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::NodeValue(Windows::Foundation::IInspectable const& value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->put_NodeValue(*(void**)(&value)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::NodeType() const
    {
        Windows::Data::Xml::Dom::NodeType value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_NodeType(put_abi(value)));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::NodeName() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_NodeName(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::ParentNode() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_ParentNode(&value));
        return Windows::Data::Xml::Dom::IXmlNode{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::ChildNodes() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_ChildNodes(&value));
        return Windows::Data::Xml::Dom::XmlNodeList{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::FirstChild() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_FirstChild(&value));
        return Windows::Data::Xml::Dom::IXmlNode{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::LastChild() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_LastChild(&value));
        return Windows::Data::Xml::Dom::IXmlNode{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::PreviousSibling() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_PreviousSibling(&value));
        return Windows::Data::Xml::Dom::IXmlNode{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::NextSibling() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_NextSibling(&value));
        return Windows::Data::Xml::Dom::IXmlNode{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::Attributes() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_Attributes(&value));
        return Windows::Data::Xml::Dom::XmlNamedNodeMap{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::HasChildNodes() const
    {
        bool value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->HasChildNodes(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::OwnerDocument() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_OwnerDocument(&value));
        return Windows::Data::Xml::Dom::XmlDocument{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::InsertBefore(Windows::Data::Xml::Dom::IXmlNode const& newChild, Windows::Data::Xml::Dom::IXmlNode const& referenceChild) const
    {
        void* insertedChild{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->InsertBefore(*(void**)(&newChild), *(void**)(&referenceChild), &insertedChild));
        return Windows::Data::Xml::Dom::IXmlNode{ insertedChild, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::ReplaceChild(Windows::Data::Xml::Dom::IXmlNode const& newChild, Windows::Data::Xml::Dom::IXmlNode const& referenceChild) const
    {
        void* previousChild{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->ReplaceChild(*(void**)(&newChild), *(void**)(&referenceChild), &previousChild));
        return Windows::Data::Xml::Dom::IXmlNode{ previousChild, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::RemoveChild(Windows::Data::Xml::Dom::IXmlNode const& childNode) const
    {
        void* removedChild{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->RemoveChild(*(void**)(&childNode), &removedChild));
        return Windows::Data::Xml::Dom::IXmlNode{ removedChild, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::AppendChild(Windows::Data::Xml::Dom::IXmlNode const& newChild) const
    {
        void* appendedChild{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->AppendChild(*(void**)(&newChild), &appendedChild));
        return Windows::Data::Xml::Dom::IXmlNode{ appendedChild, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::CloneNode(bool deep) const
    {
        void* newNode{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->CloneNode(deep, &newNode));
        return Windows::Data::Xml::Dom::IXmlNode{ newNode, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::NamespaceUri() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_NamespaceUri(&value));
        return Windows::Foundation::IInspectable{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::LocalName() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_LocalName(&value));
        return Windows::Foundation::IInspectable{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::Prefix() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->get_Prefix(&value));
        return Windows::Foundation::IInspectable{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::Normalize() const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->Normalize());
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNode<D>::Prefix(Windows::Foundation::IInspectable const& value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNode)->put_Prefix(*(void**)(&value)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNodeList<D>::Length() const
    {
        uint32_t value;
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNodeList)->get_Length(&value));
        return value;
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNodeList<D>::Item(uint32_t index) const
    {
        void* node{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNodeList)->Item(index, &node));
        return Windows::Data::Xml::Dom::IXmlNode{ node, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNodeSelector<D>::SelectSingleNode(param::hstring const& xpath) const
    {
        void* node{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNodeSelector)->SelectSingleNode(*(void**)(&xpath), &node));
        return Windows::Data::Xml::Dom::IXmlNode{ node, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNodeSelector<D>::SelectNodes(param::hstring const& xpath) const
    {
        void* nodelist{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNodeSelector)->SelectNodes(*(void**)(&xpath), &nodelist));
        return Windows::Data::Xml::Dom::XmlNodeList{ nodelist, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNodeSelector<D>::SelectSingleNodeNS(param::hstring const& xpath, Windows::Foundation::IInspectable const& namespaces) const
    {
        void* node{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNodeSelector)->SelectSingleNodeNS(*(void**)(&xpath), *(void**)(&namespaces), &node));
        return Windows::Data::Xml::Dom::IXmlNode{ node, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNodeSelector<D>::SelectNodesNS(param::hstring const& xpath, Windows::Foundation::IInspectable const& namespaces) const
    {
        void* nodelist{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNodeSelector)->SelectNodesNS(*(void**)(&xpath), *(void**)(&namespaces), &nodelist));
        return Windows::Data::Xml::Dom::XmlNodeList{ nodelist, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNodeSerializer<D>::GetXml() const
    {
        void* outerXml{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNodeSerializer)->GetXml(&outerXml));
        return hstring{ outerXml, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNodeSerializer<D>::InnerText() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNodeSerializer)->get_InnerText(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlNodeSerializer<D>::InnerText(param::hstring const& value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlNodeSerializer)->put_InnerText(*(void**)(&value)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlProcessingInstruction<D>::Target() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlProcessingInstruction)->get_Target(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlProcessingInstruction<D>::Data() const
    {
        void* value{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlProcessingInstruction)->get_Data(&value));
        return hstring{ value, take_ownership_from_abi };
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlProcessingInstruction<D>::Data(param::hstring const& value) const
    {
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlProcessingInstruction)->put_Data(*(void**)(&value)));
    }
    template <typename D> auto consume_Windows_Data_Xml_Dom_IXmlText<D>::SplitText(uint32_t offset) const
    {
        void* secondPart{};
        check_hresult(WINRT_IMPL_SHIM(Windows::Data::Xml::Dom::IXmlText)->SplitText(offset, &secondPart));
        return Windows::Data::Xml::Dom::IXmlText{ secondPart, take_ownership_from_abi };
    }
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IDtdEntity> : produce_base<D, Windows::Data::Xml::Dom::IDtdEntity>
    {
        int32_t __stdcall get_PublicId(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::IInspectable>(this->shim().PublicId());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SystemId(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::IInspectable>(this->shim().SystemId());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_NotationName(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::IInspectable>(this->shim().NotationName());
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IDtdNotation> : produce_base<D, Windows::Data::Xml::Dom::IDtdNotation>
    {
        int32_t __stdcall get_PublicId(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::IInspectable>(this->shim().PublicId());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_SystemId(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::IInspectable>(this->shim().SystemId());
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlAttribute> : produce_base<D, Windows::Data::Xml::Dom::IXmlAttribute>
    {
        int32_t __stdcall get_Name(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().Name());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Specified(bool* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<bool>(this->shim().Specified());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Value(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().Value());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_Value(void* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().Value(*reinterpret_cast<hstring const*>(&value));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlCDataSection> : produce_base<D, Windows::Data::Xml::Dom::IXmlCDataSection>
    {
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlCharacterData> : produce_base<D, Windows::Data::Xml::Dom::IXmlCharacterData>
    {
        int32_t __stdcall get_Data(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().Data());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_Data(void* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().Data(*reinterpret_cast<hstring const*>(&value));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Length(uint32_t* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<uint32_t>(this->shim().Length());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SubstringData(uint32_t offset, uint32_t count, void** data) noexcept final try
        {
            clear_abi(data);
            typename D::abi_guard guard(this->shim());
            *data = detach_from<hstring>(this->shim().SubstringData(offset, count));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall AppendData(void* data) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().AppendData(*reinterpret_cast<hstring const*>(&data));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall InsertData(uint32_t offset, void* data) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().InsertData(offset, *reinterpret_cast<hstring const*>(&data));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall DeleteData(uint32_t offset, uint32_t count) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().DeleteData(offset, count);
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall ReplaceData(uint32_t offset, uint32_t count, void* data) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().ReplaceData(offset, count, *reinterpret_cast<hstring const*>(&data));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlComment> : produce_base<D, Windows::Data::Xml::Dom::IXmlComment>
    {
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlDocument> : produce_base<D, Windows::Data::Xml::Dom::IXmlDocument>
    {
        int32_t __stdcall get_Doctype(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::XmlDocumentType>(this->shim().Doctype());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Implementation(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::XmlDomImplementation>(this->shim().Implementation());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DocumentElement(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::XmlElement>(this->shim().DocumentElement());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateElement(void* tagName, void** newElement) noexcept final try
        {
            clear_abi(newElement);
            typename D::abi_guard guard(this->shim());
            *newElement = detach_from<Windows::Data::Xml::Dom::XmlElement>(this->shim().CreateElement(*reinterpret_cast<hstring const*>(&tagName)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateDocumentFragment(void** newDocumentFragment) noexcept final try
        {
            clear_abi(newDocumentFragment);
            typename D::abi_guard guard(this->shim());
            *newDocumentFragment = detach_from<Windows::Data::Xml::Dom::XmlDocumentFragment>(this->shim().CreateDocumentFragment());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateTextNode(void* data, void** newTextNode) noexcept final try
        {
            clear_abi(newTextNode);
            typename D::abi_guard guard(this->shim());
            *newTextNode = detach_from<Windows::Data::Xml::Dom::XmlText>(this->shim().CreateTextNode(*reinterpret_cast<hstring const*>(&data)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateComment(void* data, void** newComment) noexcept final try
        {
            clear_abi(newComment);
            typename D::abi_guard guard(this->shim());
            *newComment = detach_from<Windows::Data::Xml::Dom::XmlComment>(this->shim().CreateComment(*reinterpret_cast<hstring const*>(&data)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateProcessingInstruction(void* target, void* data, void** newProcessingInstruction) noexcept final try
        {
            clear_abi(newProcessingInstruction);
            typename D::abi_guard guard(this->shim());
            *newProcessingInstruction = detach_from<Windows::Data::Xml::Dom::XmlProcessingInstruction>(this->shim().CreateProcessingInstruction(*reinterpret_cast<hstring const*>(&target), *reinterpret_cast<hstring const*>(&data)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateAttribute(void* name, void** newAttribute) noexcept final try
        {
            clear_abi(newAttribute);
            typename D::abi_guard guard(this->shim());
            *newAttribute = detach_from<Windows::Data::Xml::Dom::XmlAttribute>(this->shim().CreateAttribute(*reinterpret_cast<hstring const*>(&name)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateEntityReference(void* name, void** newEntityReference) noexcept final try
        {
            clear_abi(newEntityReference);
            typename D::abi_guard guard(this->shim());
            *newEntityReference = detach_from<Windows::Data::Xml::Dom::XmlEntityReference>(this->shim().CreateEntityReference(*reinterpret_cast<hstring const*>(&name)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetElementsByTagName(void* tagName, void** elements) noexcept final try
        {
            clear_abi(elements);
            typename D::abi_guard guard(this->shim());
            *elements = detach_from<Windows::Data::Xml::Dom::XmlNodeList>(this->shim().GetElementsByTagName(*reinterpret_cast<hstring const*>(&tagName)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateCDataSection(void* data, void** newCDataSection) noexcept final try
        {
            clear_abi(newCDataSection);
            typename D::abi_guard guard(this->shim());
            *newCDataSection = detach_from<Windows::Data::Xml::Dom::XmlCDataSection>(this->shim().CreateCDataSection(*reinterpret_cast<hstring const*>(&data)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_DocumentUri(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().DocumentUri());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateAttributeNS(void* namespaceUri, void* qualifiedName, void** newAttribute) noexcept final try
        {
            clear_abi(newAttribute);
            typename D::abi_guard guard(this->shim());
            *newAttribute = detach_from<Windows::Data::Xml::Dom::XmlAttribute>(this->shim().CreateAttributeNS(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaceUri), *reinterpret_cast<hstring const*>(&qualifiedName)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CreateElementNS(void* namespaceUri, void* qualifiedName, void** newElement) noexcept final try
        {
            clear_abi(newElement);
            typename D::abi_guard guard(this->shim());
            *newElement = detach_from<Windows::Data::Xml::Dom::XmlElement>(this->shim().CreateElementNS(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaceUri), *reinterpret_cast<hstring const*>(&qualifiedName)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetElementById(void* elementId, void** element) noexcept final try
        {
            clear_abi(element);
            typename D::abi_guard guard(this->shim());
            *element = detach_from<Windows::Data::Xml::Dom::XmlElement>(this->shim().GetElementById(*reinterpret_cast<hstring const*>(&elementId)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall ImportNode(void* node, bool deep, void** newNode) noexcept final try
        {
            clear_abi(newNode);
            typename D::abi_guard guard(this->shim());
            *newNode = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().ImportNode(*reinterpret_cast<Windows::Data::Xml::Dom::IXmlNode const*>(&node), deep));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlDocumentFragment> : produce_base<D, Windows::Data::Xml::Dom::IXmlDocumentFragment>
    {
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlDocumentIO> : produce_base<D, Windows::Data::Xml::Dom::IXmlDocumentIO>
    {
        int32_t __stdcall LoadXml(void* xml) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().LoadXml(*reinterpret_cast<hstring const*>(&xml));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall LoadXmlWithSettings(void* xml, void* loadSettings) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().LoadXml(*reinterpret_cast<hstring const*>(&xml), *reinterpret_cast<Windows::Data::Xml::Dom::XmlLoadSettings const*>(&loadSettings));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SaveToFileAsync(void* file, void** asyncInfo) noexcept final try
        {
            clear_abi(asyncInfo);
            typename D::abi_guard guard(this->shim());
            *asyncInfo = detach_from<Windows::Foundation::IAsyncAction>(this->shim().SaveToFileAsync(*reinterpret_cast<Windows::Storage::IStorageFile const*>(&file)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlDocumentIO2> : produce_base<D, Windows::Data::Xml::Dom::IXmlDocumentIO2>
    {
        int32_t __stdcall LoadXmlFromBuffer(void* buffer) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().LoadXmlFromBuffer(*reinterpret_cast<Windows::Storage::Streams::IBuffer const*>(&buffer));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall LoadXmlFromBufferWithSettings(void* buffer, void* loadSettings) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().LoadXmlFromBuffer(*reinterpret_cast<Windows::Storage::Streams::IBuffer const*>(&buffer), *reinterpret_cast<Windows::Data::Xml::Dom::XmlLoadSettings const*>(&loadSettings));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlDocumentStatics> : produce_base<D, Windows::Data::Xml::Dom::IXmlDocumentStatics>
    {
        int32_t __stdcall LoadFromUriAsync(void* uri, void** asyncInfo) noexcept final try
        {
            clear_abi(asyncInfo);
            typename D::abi_guard guard(this->shim());
            *asyncInfo = detach_from<Windows::Foundation::IAsyncOperation<Windows::Data::Xml::Dom::XmlDocument>>(this->shim().LoadFromUriAsync(*reinterpret_cast<Windows::Foundation::Uri const*>(&uri)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall LoadFromUriWithSettingsAsync(void* uri, void* loadSettings, void** asyncInfo) noexcept final try
        {
            clear_abi(asyncInfo);
            typename D::abi_guard guard(this->shim());
            *asyncInfo = detach_from<Windows::Foundation::IAsyncOperation<Windows::Data::Xml::Dom::XmlDocument>>(this->shim().LoadFromUriAsync(*reinterpret_cast<Windows::Foundation::Uri const*>(&uri), *reinterpret_cast<Windows::Data::Xml::Dom::XmlLoadSettings const*>(&loadSettings)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall LoadFromFileAsync(void* file, void** asyncInfo) noexcept final try
        {
            clear_abi(asyncInfo);
            typename D::abi_guard guard(this->shim());
            *asyncInfo = detach_from<Windows::Foundation::IAsyncOperation<Windows::Data::Xml::Dom::XmlDocument>>(this->shim().LoadFromFileAsync(*reinterpret_cast<Windows::Storage::IStorageFile const*>(&file)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall LoadFromFileWithSettingsAsync(void* file, void* loadSettings, void** asyncInfo) noexcept final try
        {
            clear_abi(asyncInfo);
            typename D::abi_guard guard(this->shim());
            *asyncInfo = detach_from<Windows::Foundation::IAsyncOperation<Windows::Data::Xml::Dom::XmlDocument>>(this->shim().LoadFromFileAsync(*reinterpret_cast<Windows::Storage::IStorageFile const*>(&file), *reinterpret_cast<Windows::Data::Xml::Dom::XmlLoadSettings const*>(&loadSettings)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlDocumentType> : produce_base<D, Windows::Data::Xml::Dom::IXmlDocumentType>
    {
        int32_t __stdcall get_Name(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().Name());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Entities(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::XmlNamedNodeMap>(this->shim().Entities());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Notations(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::XmlNamedNodeMap>(this->shim().Notations());
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlDomImplementation> : produce_base<D, Windows::Data::Xml::Dom::IXmlDomImplementation>
    {
        int32_t __stdcall HasFeature(void* feature, void* version, bool* featureSupported) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *featureSupported = detach_from<bool>(this->shim().HasFeature(*reinterpret_cast<hstring const*>(&feature), *reinterpret_cast<Windows::Foundation::IInspectable const*>(&version)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlElement> : produce_base<D, Windows::Data::Xml::Dom::IXmlElement>
    {
        int32_t __stdcall get_TagName(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().TagName());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetAttribute(void* attributeName, void** attributeValue) noexcept final try
        {
            clear_abi(attributeValue);
            typename D::abi_guard guard(this->shim());
            *attributeValue = detach_from<hstring>(this->shim().GetAttribute(*reinterpret_cast<hstring const*>(&attributeName)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SetAttribute(void* attributeName, void* attributeValue) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().SetAttribute(*reinterpret_cast<hstring const*>(&attributeName), *reinterpret_cast<hstring const*>(&attributeValue));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall RemoveAttribute(void* attributeName) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().RemoveAttribute(*reinterpret_cast<hstring const*>(&attributeName));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetAttributeNode(void* attributeName, void** attributeNode) noexcept final try
        {
            clear_abi(attributeNode);
            typename D::abi_guard guard(this->shim());
            *attributeNode = detach_from<Windows::Data::Xml::Dom::XmlAttribute>(this->shim().GetAttributeNode(*reinterpret_cast<hstring const*>(&attributeName)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SetAttributeNode(void* newAttribute, void** previousAttribute) noexcept final try
        {
            clear_abi(previousAttribute);
            typename D::abi_guard guard(this->shim());
            *previousAttribute = detach_from<Windows::Data::Xml::Dom::XmlAttribute>(this->shim().SetAttributeNode(*reinterpret_cast<Windows::Data::Xml::Dom::XmlAttribute const*>(&newAttribute)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall RemoveAttributeNode(void* attributeNode, void** removedAttribute) noexcept final try
        {
            clear_abi(removedAttribute);
            typename D::abi_guard guard(this->shim());
            *removedAttribute = detach_from<Windows::Data::Xml::Dom::XmlAttribute>(this->shim().RemoveAttributeNode(*reinterpret_cast<Windows::Data::Xml::Dom::XmlAttribute const*>(&attributeNode)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetElementsByTagName(void* tagName, void** elements) noexcept final try
        {
            clear_abi(elements);
            typename D::abi_guard guard(this->shim());
            *elements = detach_from<Windows::Data::Xml::Dom::XmlNodeList>(this->shim().GetElementsByTagName(*reinterpret_cast<hstring const*>(&tagName)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SetAttributeNS(void* namespaceUri, void* qualifiedName, void* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().SetAttributeNS(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaceUri), *reinterpret_cast<hstring const*>(&qualifiedName), *reinterpret_cast<hstring const*>(&value));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetAttributeNS(void* namespaceUri, void* localName, void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().GetAttributeNS(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaceUri), *reinterpret_cast<hstring const*>(&localName)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall RemoveAttributeNS(void* namespaceUri, void* localName) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().RemoveAttributeNS(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaceUri), *reinterpret_cast<hstring const*>(&localName));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SetAttributeNodeNS(void* newAttribute, void** previousAttribute) noexcept final try
        {
            clear_abi(previousAttribute);
            typename D::abi_guard guard(this->shim());
            *previousAttribute = detach_from<Windows::Data::Xml::Dom::XmlAttribute>(this->shim().SetAttributeNodeNS(*reinterpret_cast<Windows::Data::Xml::Dom::XmlAttribute const*>(&newAttribute)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetAttributeNodeNS(void* namespaceUri, void* localName, void** previousAttribute) noexcept final try
        {
            clear_abi(previousAttribute);
            typename D::abi_guard guard(this->shim());
            *previousAttribute = detach_from<Windows::Data::Xml::Dom::XmlAttribute>(this->shim().GetAttributeNodeNS(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaceUri), *reinterpret_cast<hstring const*>(&localName)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlEntityReference> : produce_base<D, Windows::Data::Xml::Dom::IXmlEntityReference>
    {
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlLoadSettings> : produce_base<D, Windows::Data::Xml::Dom::IXmlLoadSettings>
    {
        int32_t __stdcall get_MaxElementDepth(uint32_t* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<uint32_t>(this->shim().MaxElementDepth());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_MaxElementDepth(uint32_t value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().MaxElementDepth(value);
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_ProhibitDtd(bool* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<bool>(this->shim().ProhibitDtd());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_ProhibitDtd(bool value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().ProhibitDtd(value);
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_ResolveExternals(bool* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<bool>(this->shim().ResolveExternals());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_ResolveExternals(bool value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().ResolveExternals(value);
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_ValidateOnParse(bool* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<bool>(this->shim().ValidateOnParse());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_ValidateOnParse(bool value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().ValidateOnParse(value);
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_ElementContentWhiteSpace(bool* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<bool>(this->shim().ElementContentWhiteSpace());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_ElementContentWhiteSpace(bool value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().ElementContentWhiteSpace(value);
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlNamedNodeMap> : produce_base<D, Windows::Data::Xml::Dom::IXmlNamedNodeMap>
    {
        int32_t __stdcall get_Length(uint32_t* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<uint32_t>(this->shim().Length());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall Item(uint32_t index, void** node) noexcept final try
        {
            clear_abi(node);
            typename D::abi_guard guard(this->shim());
            *node = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().Item(index));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetNamedItem(void* name, void** node) noexcept final try
        {
            clear_abi(node);
            typename D::abi_guard guard(this->shim());
            *node = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().GetNamedItem(*reinterpret_cast<hstring const*>(&name)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SetNamedItem(void* node, void** previousNode) noexcept final try
        {
            clear_abi(previousNode);
            typename D::abi_guard guard(this->shim());
            *previousNode = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().SetNamedItem(*reinterpret_cast<Windows::Data::Xml::Dom::IXmlNode const*>(&node)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall RemoveNamedItem(void* name, void** previousNode) noexcept final try
        {
            clear_abi(previousNode);
            typename D::abi_guard guard(this->shim());
            *previousNode = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().RemoveNamedItem(*reinterpret_cast<hstring const*>(&name)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall GetNamedItemNS(void* namespaceUri, void* name, void** node) noexcept final try
        {
            clear_abi(node);
            typename D::abi_guard guard(this->shim());
            *node = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().GetNamedItemNS(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaceUri), *reinterpret_cast<hstring const*>(&name)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall RemoveNamedItemNS(void* namespaceUri, void* name, void** previousNode) noexcept final try
        {
            clear_abi(previousNode);
            typename D::abi_guard guard(this->shim());
            *previousNode = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().RemoveNamedItemNS(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaceUri), *reinterpret_cast<hstring const*>(&name)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SetNamedItemNS(void* node, void** previousNode) noexcept final try
        {
            clear_abi(previousNode);
            typename D::abi_guard guard(this->shim());
            *previousNode = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().SetNamedItemNS(*reinterpret_cast<Windows::Data::Xml::Dom::IXmlNode const*>(&node)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlNode> : produce_base<D, Windows::Data::Xml::Dom::IXmlNode>
    {
        int32_t __stdcall get_NodeValue(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::IInspectable>(this->shim().NodeValue());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_NodeValue(void* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().NodeValue(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&value));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_NodeType(int32_t* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::NodeType>(this->shim().NodeType());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_NodeName(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().NodeName());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_ParentNode(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().ParentNode());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_ChildNodes(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::XmlNodeList>(this->shim().ChildNodes());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_FirstChild(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().FirstChild());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LastChild(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().LastChild());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_PreviousSibling(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().PreviousSibling());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_NextSibling(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().NextSibling());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Attributes(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::XmlNamedNodeMap>(this->shim().Attributes());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall HasChildNodes(bool* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<bool>(this->shim().HasChildNodes());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_OwnerDocument(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Data::Xml::Dom::XmlDocument>(this->shim().OwnerDocument());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall InsertBefore(void* newChild, void* referenceChild, void** insertedChild) noexcept final try
        {
            clear_abi(insertedChild);
            typename D::abi_guard guard(this->shim());
            *insertedChild = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().InsertBefore(*reinterpret_cast<Windows::Data::Xml::Dom::IXmlNode const*>(&newChild), *reinterpret_cast<Windows::Data::Xml::Dom::IXmlNode const*>(&referenceChild)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall ReplaceChild(void* newChild, void* referenceChild, void** previousChild) noexcept final try
        {
            clear_abi(previousChild);
            typename D::abi_guard guard(this->shim());
            *previousChild = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().ReplaceChild(*reinterpret_cast<Windows::Data::Xml::Dom::IXmlNode const*>(&newChild), *reinterpret_cast<Windows::Data::Xml::Dom::IXmlNode const*>(&referenceChild)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall RemoveChild(void* childNode, void** removedChild) noexcept final try
        {
            clear_abi(removedChild);
            typename D::abi_guard guard(this->shim());
            *removedChild = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().RemoveChild(*reinterpret_cast<Windows::Data::Xml::Dom::IXmlNode const*>(&childNode)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall AppendChild(void* newChild, void** appendedChild) noexcept final try
        {
            clear_abi(appendedChild);
            typename D::abi_guard guard(this->shim());
            *appendedChild = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().AppendChild(*reinterpret_cast<Windows::Data::Xml::Dom::IXmlNode const*>(&newChild)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall CloneNode(bool deep, void** newNode) noexcept final try
        {
            clear_abi(newNode);
            typename D::abi_guard guard(this->shim());
            *newNode = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().CloneNode(deep));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_NamespaceUri(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::IInspectable>(this->shim().NamespaceUri());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_LocalName(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::IInspectable>(this->shim().LocalName());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Prefix(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<Windows::Foundation::IInspectable>(this->shim().Prefix());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall Normalize() noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().Normalize();
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_Prefix(void* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().Prefix(*reinterpret_cast<Windows::Foundation::IInspectable const*>(&value));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlNodeList> : produce_base<D, Windows::Data::Xml::Dom::IXmlNodeList>
    {
        int32_t __stdcall get_Length(uint32_t* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            *value = detach_from<uint32_t>(this->shim().Length());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall Item(uint32_t index, void** node) noexcept final try
        {
            clear_abi(node);
            typename D::abi_guard guard(this->shim());
            *node = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().Item(index));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlNodeSelector> : produce_base<D, Windows::Data::Xml::Dom::IXmlNodeSelector>
    {
        int32_t __stdcall SelectSingleNode(void* xpath, void** node) noexcept final try
        {
            clear_abi(node);
            typename D::abi_guard guard(this->shim());
            *node = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().SelectSingleNode(*reinterpret_cast<hstring const*>(&xpath)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SelectNodes(void* xpath, void** nodelist) noexcept final try
        {
            clear_abi(nodelist);
            typename D::abi_guard guard(this->shim());
            *nodelist = detach_from<Windows::Data::Xml::Dom::XmlNodeList>(this->shim().SelectNodes(*reinterpret_cast<hstring const*>(&xpath)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SelectSingleNodeNS(void* xpath, void* namespaces, void** node) noexcept final try
        {
            clear_abi(node);
            typename D::abi_guard guard(this->shim());
            *node = detach_from<Windows::Data::Xml::Dom::IXmlNode>(this->shim().SelectSingleNodeNS(*reinterpret_cast<hstring const*>(&xpath), *reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaces)));
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall SelectNodesNS(void* xpath, void* namespaces, void** nodelist) noexcept final try
        {
            clear_abi(nodelist);
            typename D::abi_guard guard(this->shim());
            *nodelist = detach_from<Windows::Data::Xml::Dom::XmlNodeList>(this->shim().SelectNodesNS(*reinterpret_cast<hstring const*>(&xpath), *reinterpret_cast<Windows::Foundation::IInspectable const*>(&namespaces)));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlNodeSerializer> : produce_base<D, Windows::Data::Xml::Dom::IXmlNodeSerializer>
    {
        int32_t __stdcall GetXml(void** outerXml) noexcept final try
        {
            clear_abi(outerXml);
            typename D::abi_guard guard(this->shim());
            *outerXml = detach_from<hstring>(this->shim().GetXml());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_InnerText(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().InnerText());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_InnerText(void* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().InnerText(*reinterpret_cast<hstring const*>(&value));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlProcessingInstruction> : produce_base<D, Windows::Data::Xml::Dom::IXmlProcessingInstruction>
    {
        int32_t __stdcall get_Target(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().Target());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall get_Data(void** value) noexcept final try
        {
            clear_abi(value);
            typename D::abi_guard guard(this->shim());
            *value = detach_from<hstring>(this->shim().Data());
            return 0;
        }
        catch (...) { return to_hresult(); }
        int32_t __stdcall put_Data(void* value) noexcept final try
        {
            typename D::abi_guard guard(this->shim());
            this->shim().Data(*reinterpret_cast<hstring const*>(&value));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
    template <typename D>
    struct produce<D, Windows::Data::Xml::Dom::IXmlText> : produce_base<D, Windows::Data::Xml::Dom::IXmlText>
    {
        int32_t __stdcall SplitText(uint32_t offset, void** secondPart) noexcept final try
        {
            clear_abi(secondPart);
            typename D::abi_guard guard(this->shim());
            *secondPart = detach_from<Windows::Data::Xml::Dom::IXmlText>(this->shim().SplitText(offset));
            return 0;
        }
        catch (...) { return to_hresult(); }
    };
}
namespace winrt::Windows::Data::Xml::Dom
{
    inline XmlDocument::XmlDocument() :
        XmlDocument(impl::call_factory<XmlDocument>([](auto&& f) { return f.template ActivateInstance<XmlDocument>(); }))
    {
    }
    inline auto XmlDocument::LoadFromUriAsync(Windows::Foundation::Uri const& uri)
    {
        return impl::call_factory<XmlDocument, Windows::Data::Xml::Dom::IXmlDocumentStatics>([&](auto&& f) { return f.LoadFromUriAsync(uri); });
    }
    inline auto XmlDocument::LoadFromUriAsync(Windows::Foundation::Uri const& uri, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings)
    {
        return impl::call_factory<XmlDocument, Windows::Data::Xml::Dom::IXmlDocumentStatics>([&](auto&& f) { return f.LoadFromUriAsync(uri, loadSettings); });
    }
    inline auto XmlDocument::LoadFromFileAsync(Windows::Storage::IStorageFile const& file)
    {
        return impl::call_factory<XmlDocument, Windows::Data::Xml::Dom::IXmlDocumentStatics>([&](auto&& f) { return f.LoadFromFileAsync(file); });
    }
    inline auto XmlDocument::LoadFromFileAsync(Windows::Storage::IStorageFile const& file, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings)
    {
        return impl::call_factory<XmlDocument, Windows::Data::Xml::Dom::IXmlDocumentStatics>([&](auto&& f) { return f.LoadFromFileAsync(file, loadSettings); });
    }
    inline XmlLoadSettings::XmlLoadSettings() :
        XmlLoadSettings(impl::call_factory<XmlLoadSettings>([](auto&& f) { return f.template ActivateInstance<XmlLoadSettings>(); }))
    {
    }
}
namespace std
{
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IDtdEntity> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IDtdEntity> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IDtdNotation> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IDtdNotation> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlAttribute> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlAttribute> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlCDataSection> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlCDataSection> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlCharacterData> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlCharacterData> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlComment> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlComment> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlDocument> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlDocument> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlDocumentFragment> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlDocumentFragment> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlDocumentIO> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlDocumentIO> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlDocumentIO2> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlDocumentIO2> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlDocumentStatics> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlDocumentStatics> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlDocumentType> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlDocumentType> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlDomImplementation> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlDomImplementation> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlElement> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlElement> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlEntityReference> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlEntityReference> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlLoadSettings> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlLoadSettings> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlNamedNodeMap> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlNamedNodeMap> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlNode> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlNode> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlNodeList> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlNodeList> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlNodeSelector> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlNodeSelector> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlNodeSerializer> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlNodeSerializer> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlProcessingInstruction> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlProcessingInstruction> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::IXmlText> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::IXmlText> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::DtdEntity> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::DtdEntity> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::DtdNotation> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::DtdNotation> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlAttribute> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlAttribute> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlCDataSection> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlCDataSection> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlComment> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlComment> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlDocument> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlDocument> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlDocumentFragment> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlDocumentFragment> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlDocumentType> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlDocumentType> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlDomImplementation> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlDomImplementation> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlElement> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlElement> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlEntityReference> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlEntityReference> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlLoadSettings> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlLoadSettings> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlNamedNodeMap> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlNamedNodeMap> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlNodeList> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlNodeList> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlProcessingInstruction> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlProcessingInstruction> {};
    template<> struct hash<winrt::Windows::Data::Xml::Dom::XmlText> : winrt::impl::hash_base<winrt::Windows::Data::Xml::Dom::XmlText> {};
}
#endif
