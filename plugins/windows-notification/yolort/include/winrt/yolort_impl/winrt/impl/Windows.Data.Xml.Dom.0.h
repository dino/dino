// C++/WinRT v2.0.190620.2

// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#ifndef WINRT_Windows_Data_Xml_Dom_0_H
#define WINRT_Windows_Data_Xml_Dom_0_H
namespace winrt::Windows::Foundation
{
    struct IAsyncAction;
    struct Uri;
}
namespace winrt::Windows::Storage
{
    struct IStorageFile;
}
namespace winrt::Windows::Storage::Streams
{
    struct IBuffer;
}
namespace winrt::Windows::Data::Xml::Dom
{
    enum class NodeType : int32_t
    {
        Invalid = 0,
        ElementNode = 1,
        AttributeNode = 2,
        TextNode = 3,
        DataSectionNode = 4,
        EntityReferenceNode = 5,
        EntityNode = 6,
        ProcessingInstructionNode = 7,
        CommentNode = 8,
        DocumentNode = 9,
        DocumentTypeNode = 10,
        DocumentFragmentNode = 11,
        NotationNode = 12,
    };
    struct IDtdEntity;
    struct IDtdNotation;
    struct IXmlAttribute;
    struct IXmlCDataSection;
    struct IXmlCharacterData;
    struct IXmlComment;
    struct IXmlDocument;
    struct IXmlDocumentFragment;
    struct IXmlDocumentIO;
    struct IXmlDocumentIO2;
    struct IXmlDocumentStatics;
    struct IXmlDocumentType;
    struct IXmlDomImplementation;
    struct IXmlElement;
    struct IXmlEntityReference;
    struct IXmlLoadSettings;
    struct IXmlNamedNodeMap;
    struct IXmlNode;
    struct IXmlNodeList;
    struct IXmlNodeSelector;
    struct IXmlNodeSerializer;
    struct IXmlProcessingInstruction;
    struct IXmlText;
    struct DtdEntity;
    struct DtdNotation;
    struct XmlAttribute;
    struct XmlCDataSection;
    struct XmlComment;
    struct XmlDocument;
    struct XmlDocumentFragment;
    struct XmlDocumentType;
    struct XmlDomImplementation;
    struct XmlElement;
    struct XmlEntityReference;
    struct XmlLoadSettings;
    struct XmlNamedNodeMap;
    struct XmlNodeList;
    struct XmlProcessingInstruction;
    struct XmlText;
}
namespace winrt::impl
{
    template <> struct category<Windows::Data::Xml::Dom::IDtdEntity>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IDtdNotation>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlAttribute>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlCDataSection>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlCharacterData>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlComment>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlDocument>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlDocumentFragment>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlDocumentIO>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlDocumentIO2>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlDocumentStatics>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlDocumentType>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlDomImplementation>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlElement>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlEntityReference>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlLoadSettings>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlNamedNodeMap>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlNode>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlNodeList>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlNodeSelector>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlNodeSerializer>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlProcessingInstruction>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::IXmlText>
    {
        using type = interface_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::DtdEntity>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::DtdNotation>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlAttribute>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlCDataSection>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlComment>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlDocument>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlDocumentFragment>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlDocumentType>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlDomImplementation>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlElement>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlEntityReference>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlLoadSettings>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlNamedNodeMap>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlNodeList>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlProcessingInstruction>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::XmlText>
    {
        using type = class_category;
    };
    template <> struct category<Windows::Data::Xml::Dom::NodeType>
    {
        using type = enum_category;
    };
    template <> struct name<Windows::Data::Xml::Dom::IDtdEntity>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IDtdEntity" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IDtdNotation>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IDtdNotation" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlAttribute>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlAttribute" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlCDataSection>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlCDataSection" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlCharacterData>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlCharacterData" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlComment>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlComment" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlDocument>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlDocument" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlDocumentFragment>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlDocumentFragment" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlDocumentIO>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlDocumentIO" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlDocumentIO2>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlDocumentIO2" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlDocumentStatics>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlDocumentStatics" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlDocumentType>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlDocumentType" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlDomImplementation>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlDomImplementation" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlElement>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlElement" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlEntityReference>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlEntityReference" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlLoadSettings>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlLoadSettings" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlNamedNodeMap>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlNamedNodeMap" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlNode>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlNode" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlNodeList>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlNodeList" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlNodeSelector>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlNodeSelector" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlNodeSerializer>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlNodeSerializer" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlProcessingInstruction>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlProcessingInstruction" };
    };
    template <> struct name<Windows::Data::Xml::Dom::IXmlText>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.IXmlText" };
    };
    template <> struct name<Windows::Data::Xml::Dom::DtdEntity>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.DtdEntity" };
    };
    template <> struct name<Windows::Data::Xml::Dom::DtdNotation>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.DtdNotation" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlAttribute>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlAttribute" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlCDataSection>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlCDataSection" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlComment>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlComment" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlDocument>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlDocument" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlDocumentFragment>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlDocumentFragment" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlDocumentType>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlDocumentType" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlDomImplementation>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlDomImplementation" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlElement>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlElement" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlEntityReference>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlEntityReference" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlLoadSettings>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlLoadSettings" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlNamedNodeMap>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlNamedNodeMap" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlNodeList>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlNodeList" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlProcessingInstruction>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlProcessingInstruction" };
    };
    template <> struct name<Windows::Data::Xml::Dom::XmlText>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.XmlText" };
    };
    template <> struct name<Windows::Data::Xml::Dom::NodeType>
    {
        static constexpr auto & value{ L"Windows.Data.Xml.Dom.NodeType" };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IDtdEntity>
    {
        static constexpr guid value{ 0x6A0B5FFC,0x63B4,0x480F,{ 0x9E,0x6A,0x8A,0x92,0x81,0x6A,0xAD,0xE4 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IDtdNotation>
    {
        static constexpr guid value{ 0x8CB4E04D,0x6D46,0x4EDB,{ 0xAB,0x73,0xDF,0x83,0xC5,0x1A,0xD3,0x97 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlAttribute>
    {
        static constexpr guid value{ 0xAC144AA4,0xB4F1,0x4DB6,{ 0xB2,0x06,0x8A,0x22,0xC3,0x08,0xDB,0x0A } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlCDataSection>
    {
        static constexpr guid value{ 0x4D04B46F,0xC8BD,0x45B4,{ 0x88,0x99,0x04,0x00,0xD7,0xC2,0xC6,0x0F } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlCharacterData>
    {
        static constexpr guid value{ 0x132E42AB,0x4E36,0x4DF6,{ 0xB1,0xC8,0x0C,0xE6,0x2F,0xD8,0x8B,0x26 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlComment>
    {
        static constexpr guid value{ 0xBCA474D5,0xB61F,0x4611,{ 0x9C,0xAC,0x2E,0x92,0xE3,0x47,0x6D,0x47 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlDocument>
    {
        static constexpr guid value{ 0xF7F3A506,0x1E87,0x42D6,{ 0xBC,0xFB,0xB8,0xC8,0x09,0xFA,0x54,0x94 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlDocumentFragment>
    {
        static constexpr guid value{ 0xE2EA6A96,0x0C21,0x44A5,{ 0x8B,0xC9,0x9E,0x4A,0x26,0x27,0x08,0xEC } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlDocumentIO>
    {
        static constexpr guid value{ 0x6CD0E74E,0xEE65,0x4489,{ 0x9E,0xBF,0xCA,0x43,0xE8,0x7B,0xA6,0x37 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlDocumentIO2>
    {
        static constexpr guid value{ 0x5D034661,0x7BD8,0x4AD5,{ 0x9E,0xBF,0x81,0xE6,0x34,0x72,0x63,0xB1 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlDocumentStatics>
    {
        static constexpr guid value{ 0x5543D254,0xD757,0x4B79,{ 0x95,0x39,0x23,0x2B,0x18,0xF5,0x0B,0xF1 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlDocumentType>
    {
        static constexpr guid value{ 0xF7342425,0x9781,0x4964,{ 0x8E,0x94,0x9B,0x1C,0x6D,0xFC,0x9B,0xC7 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlDomImplementation>
    {
        static constexpr guid value{ 0x6DE58132,0xF11D,0x4FBB,{ 0x8C,0xC6,0x58,0x3C,0xBA,0x93,0x11,0x2F } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlElement>
    {
        static constexpr guid value{ 0x2DFB8A1F,0x6B10,0x4EF8,{ 0x9F,0x83,0xEF,0xCC,0xE8,0xFA,0xEC,0x37 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlEntityReference>
    {
        static constexpr guid value{ 0x2E2F47BC,0xC3D0,0x4CCF,{ 0xBB,0x86,0x0A,0xB8,0xC3,0x6A,0x61,0xCF } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlLoadSettings>
    {
        static constexpr guid value{ 0x58AA07A8,0xFED6,0x46F7,{ 0xB4,0xC5,0xFB,0x1B,0xA7,0x21,0x08,0xD6 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlNamedNodeMap>
    {
        static constexpr guid value{ 0xB3A69EB0,0xAAB0,0x4B82,{ 0xA6,0xFA,0xB1,0x45,0x3F,0x7C,0x02,0x1B } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlNode>
    {
        static constexpr guid value{ 0x1C741D59,0x2122,0x47D5,{ 0xA8,0x56,0x83,0xF3,0xD4,0x21,0x48,0x75 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlNodeList>
    {
        static constexpr guid value{ 0x8C60AD77,0x83A4,0x4EC1,{ 0x9C,0x54,0x7B,0xA4,0x29,0xE1,0x3D,0xA6 } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlNodeSelector>
    {
        static constexpr guid value{ 0x63DBBA8B,0xD0DB,0x4FE1,{ 0xB7,0x45,0xF9,0x43,0x3A,0xFD,0xC2,0x5B } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlNodeSerializer>
    {
        static constexpr guid value{ 0x5CC5B382,0xE6DD,0x4991,{ 0xAB,0xEF,0x06,0xD8,0xD2,0xE7,0xBD,0x0C } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlProcessingInstruction>
    {
        static constexpr guid value{ 0x2707FD1E,0x1E92,0x4ECE,{ 0xB6,0xF4,0x26,0xF0,0x69,0x07,0x8D,0xDC } };
    };
    template <> struct guid_storage<Windows::Data::Xml::Dom::IXmlText>
    {
        static constexpr guid value{ 0xF931A4CB,0x308D,0x4760,{ 0xA1,0xD5,0x43,0xB6,0x74,0x50,0xAC,0x7E } };
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::DtdEntity>
    {
        using type = Windows::Data::Xml::Dom::IDtdEntity;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::DtdNotation>
    {
        using type = Windows::Data::Xml::Dom::IDtdNotation;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlAttribute>
    {
        using type = Windows::Data::Xml::Dom::IXmlAttribute;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlCDataSection>
    {
        using type = Windows::Data::Xml::Dom::IXmlCDataSection;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlComment>
    {
        using type = Windows::Data::Xml::Dom::IXmlComment;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlDocument>
    {
        using type = Windows::Data::Xml::Dom::IXmlDocument;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlDocumentFragment>
    {
        using type = Windows::Data::Xml::Dom::IXmlDocumentFragment;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlDocumentType>
    {
        using type = Windows::Data::Xml::Dom::IXmlDocumentType;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlDomImplementation>
    {
        using type = Windows::Data::Xml::Dom::IXmlDomImplementation;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlElement>
    {
        using type = Windows::Data::Xml::Dom::IXmlElement;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlEntityReference>
    {
        using type = Windows::Data::Xml::Dom::IXmlEntityReference;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlLoadSettings>
    {
        using type = Windows::Data::Xml::Dom::IXmlLoadSettings;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlNamedNodeMap>
    {
        using type = Windows::Data::Xml::Dom::IXmlNamedNodeMap;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlNodeList>
    {
        using type = Windows::Data::Xml::Dom::IXmlNodeList;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlProcessingInstruction>
    {
        using type = Windows::Data::Xml::Dom::IXmlProcessingInstruction;
    };
    template <> struct default_interface<Windows::Data::Xml::Dom::XmlText>
    {
        using type = Windows::Data::Xml::Dom::IXmlText;
    };
    template <> struct abi<Windows::Data::Xml::Dom::IDtdEntity>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_PublicId(void**) noexcept = 0;
            virtual int32_t __stdcall get_SystemId(void**) noexcept = 0;
            virtual int32_t __stdcall get_NotationName(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IDtdNotation>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_PublicId(void**) noexcept = 0;
            virtual int32_t __stdcall get_SystemId(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlAttribute>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Name(void**) noexcept = 0;
            virtual int32_t __stdcall get_Specified(bool*) noexcept = 0;
            virtual int32_t __stdcall get_Value(void**) noexcept = 0;
            virtual int32_t __stdcall put_Value(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlCDataSection>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlCharacterData>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Data(void**) noexcept = 0;
            virtual int32_t __stdcall put_Data(void*) noexcept = 0;
            virtual int32_t __stdcall get_Length(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall SubstringData(uint32_t, uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall AppendData(void*) noexcept = 0;
            virtual int32_t __stdcall InsertData(uint32_t, void*) noexcept = 0;
            virtual int32_t __stdcall DeleteData(uint32_t, uint32_t) noexcept = 0;
            virtual int32_t __stdcall ReplaceData(uint32_t, uint32_t, void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlComment>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlDocument>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Doctype(void**) noexcept = 0;
            virtual int32_t __stdcall get_Implementation(void**) noexcept = 0;
            virtual int32_t __stdcall get_DocumentElement(void**) noexcept = 0;
            virtual int32_t __stdcall CreateElement(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateDocumentFragment(void**) noexcept = 0;
            virtual int32_t __stdcall CreateTextNode(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateComment(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateProcessingInstruction(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateAttribute(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateEntityReference(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetElementsByTagName(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateCDataSection(void*, void**) noexcept = 0;
            virtual int32_t __stdcall get_DocumentUri(void**) noexcept = 0;
            virtual int32_t __stdcall CreateAttributeNS(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall CreateElementNS(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetElementById(void*, void**) noexcept = 0;
            virtual int32_t __stdcall ImportNode(void*, bool, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlDocumentFragment>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlDocumentIO>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall LoadXml(void*) noexcept = 0;
            virtual int32_t __stdcall LoadXmlWithSettings(void*, void*) noexcept = 0;
            virtual int32_t __stdcall SaveToFileAsync(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlDocumentIO2>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall LoadXmlFromBuffer(void*) noexcept = 0;
            virtual int32_t __stdcall LoadXmlFromBufferWithSettings(void*, void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlDocumentStatics>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall LoadFromUriAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall LoadFromUriWithSettingsAsync(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall LoadFromFileAsync(void*, void**) noexcept = 0;
            virtual int32_t __stdcall LoadFromFileWithSettingsAsync(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlDocumentType>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Name(void**) noexcept = 0;
            virtual int32_t __stdcall get_Entities(void**) noexcept = 0;
            virtual int32_t __stdcall get_Notations(void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlDomImplementation>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall HasFeature(void*, void*, bool*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlElement>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_TagName(void**) noexcept = 0;
            virtual int32_t __stdcall GetAttribute(void*, void**) noexcept = 0;
            virtual int32_t __stdcall SetAttribute(void*, void*) noexcept = 0;
            virtual int32_t __stdcall RemoveAttribute(void*) noexcept = 0;
            virtual int32_t __stdcall GetAttributeNode(void*, void**) noexcept = 0;
            virtual int32_t __stdcall SetAttributeNode(void*, void**) noexcept = 0;
            virtual int32_t __stdcall RemoveAttributeNode(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetElementsByTagName(void*, void**) noexcept = 0;
            virtual int32_t __stdcall SetAttributeNS(void*, void*, void*) noexcept = 0;
            virtual int32_t __stdcall GetAttributeNS(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall RemoveAttributeNS(void*, void*) noexcept = 0;
            virtual int32_t __stdcall SetAttributeNodeNS(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetAttributeNodeNS(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlEntityReference>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlLoadSettings>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_MaxElementDepth(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall put_MaxElementDepth(uint32_t) noexcept = 0;
            virtual int32_t __stdcall get_ProhibitDtd(bool*) noexcept = 0;
            virtual int32_t __stdcall put_ProhibitDtd(bool) noexcept = 0;
            virtual int32_t __stdcall get_ResolveExternals(bool*) noexcept = 0;
            virtual int32_t __stdcall put_ResolveExternals(bool) noexcept = 0;
            virtual int32_t __stdcall get_ValidateOnParse(bool*) noexcept = 0;
            virtual int32_t __stdcall put_ValidateOnParse(bool) noexcept = 0;
            virtual int32_t __stdcall get_ElementContentWhiteSpace(bool*) noexcept = 0;
            virtual int32_t __stdcall put_ElementContentWhiteSpace(bool) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlNamedNodeMap>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Length(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall Item(uint32_t, void**) noexcept = 0;
            virtual int32_t __stdcall GetNamedItem(void*, void**) noexcept = 0;
            virtual int32_t __stdcall SetNamedItem(void*, void**) noexcept = 0;
            virtual int32_t __stdcall RemoveNamedItem(void*, void**) noexcept = 0;
            virtual int32_t __stdcall GetNamedItemNS(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall RemoveNamedItemNS(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall SetNamedItemNS(void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlNode>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_NodeValue(void**) noexcept = 0;
            virtual int32_t __stdcall put_NodeValue(void*) noexcept = 0;
            virtual int32_t __stdcall get_NodeType(int32_t*) noexcept = 0;
            virtual int32_t __stdcall get_NodeName(void**) noexcept = 0;
            virtual int32_t __stdcall get_ParentNode(void**) noexcept = 0;
            virtual int32_t __stdcall get_ChildNodes(void**) noexcept = 0;
            virtual int32_t __stdcall get_FirstChild(void**) noexcept = 0;
            virtual int32_t __stdcall get_LastChild(void**) noexcept = 0;
            virtual int32_t __stdcall get_PreviousSibling(void**) noexcept = 0;
            virtual int32_t __stdcall get_NextSibling(void**) noexcept = 0;
            virtual int32_t __stdcall get_Attributes(void**) noexcept = 0;
            virtual int32_t __stdcall HasChildNodes(bool*) noexcept = 0;
            virtual int32_t __stdcall get_OwnerDocument(void**) noexcept = 0;
            virtual int32_t __stdcall InsertBefore(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall ReplaceChild(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall RemoveChild(void*, void**) noexcept = 0;
            virtual int32_t __stdcall AppendChild(void*, void**) noexcept = 0;
            virtual int32_t __stdcall CloneNode(bool, void**) noexcept = 0;
            virtual int32_t __stdcall get_NamespaceUri(void**) noexcept = 0;
            virtual int32_t __stdcall get_LocalName(void**) noexcept = 0;
            virtual int32_t __stdcall get_Prefix(void**) noexcept = 0;
            virtual int32_t __stdcall Normalize() noexcept = 0;
            virtual int32_t __stdcall put_Prefix(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlNodeList>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Length(uint32_t*) noexcept = 0;
            virtual int32_t __stdcall Item(uint32_t, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlNodeSelector>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall SelectSingleNode(void*, void**) noexcept = 0;
            virtual int32_t __stdcall SelectNodes(void*, void**) noexcept = 0;
            virtual int32_t __stdcall SelectSingleNodeNS(void*, void*, void**) noexcept = 0;
            virtual int32_t __stdcall SelectNodesNS(void*, void*, void**) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlNodeSerializer>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall GetXml(void**) noexcept = 0;
            virtual int32_t __stdcall get_InnerText(void**) noexcept = 0;
            virtual int32_t __stdcall put_InnerText(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlProcessingInstruction>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall get_Target(void**) noexcept = 0;
            virtual int32_t __stdcall get_Data(void**) noexcept = 0;
            virtual int32_t __stdcall put_Data(void*) noexcept = 0;
        };
    };
    template <> struct abi<Windows::Data::Xml::Dom::IXmlText>
    {
        struct __declspec(novtable) type : inspectable_abi
        {
            virtual int32_t __stdcall SplitText(uint32_t, void**) noexcept = 0;
        };
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IDtdEntity
    {
        [[nodiscard]] auto PublicId() const;
        [[nodiscard]] auto SystemId() const;
        [[nodiscard]] auto NotationName() const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IDtdEntity>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IDtdEntity<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IDtdNotation
    {
        [[nodiscard]] auto PublicId() const;
        [[nodiscard]] auto SystemId() const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IDtdNotation>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IDtdNotation<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlAttribute
    {
        [[nodiscard]] auto Name() const;
        [[nodiscard]] auto Specified() const;
        [[nodiscard]] auto Value() const;
        auto Value(param::hstring const& value) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlAttribute>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlAttribute<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlCDataSection
    {
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlCDataSection>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlCDataSection<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlCharacterData
    {
        [[nodiscard]] auto Data() const;
        auto Data(param::hstring const& value) const;
        [[nodiscard]] auto Length() const;
        auto SubstringData(uint32_t offset, uint32_t count) const;
        auto AppendData(param::hstring const& data) const;
        auto InsertData(uint32_t offset, param::hstring const& data) const;
        auto DeleteData(uint32_t offset, uint32_t count) const;
        auto ReplaceData(uint32_t offset, uint32_t count, param::hstring const& data) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlCharacterData>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlCharacterData<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlComment
    {
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlComment>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlComment<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlDocument
    {
        [[nodiscard]] auto Doctype() const;
        [[nodiscard]] auto Implementation() const;
        [[nodiscard]] auto DocumentElement() const;
        auto CreateElement(param::hstring const& tagName) const;
        auto CreateDocumentFragment() const;
        auto CreateTextNode(param::hstring const& data) const;
        auto CreateComment(param::hstring const& data) const;
        auto CreateProcessingInstruction(param::hstring const& target, param::hstring const& data) const;
        auto CreateAttribute(param::hstring const& name) const;
        auto CreateEntityReference(param::hstring const& name) const;
        auto GetElementsByTagName(param::hstring const& tagName) const;
        auto CreateCDataSection(param::hstring const& data) const;
        [[nodiscard]] auto DocumentUri() const;
        auto CreateAttributeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& qualifiedName) const;
        auto CreateElementNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& qualifiedName) const;
        auto GetElementById(param::hstring const& elementId) const;
        auto ImportNode(Windows::Data::Xml::Dom::IXmlNode const& node, bool deep) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlDocument>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlDocument<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlDocumentFragment
    {
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlDocumentFragment>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlDocumentFragment<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlDocumentIO
    {
        auto LoadXml(param::hstring const& xml) const;
        auto LoadXml(param::hstring const& xml, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings) const;
        auto SaveToFileAsync(Windows::Storage::IStorageFile const& file) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlDocumentIO>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlDocumentIO<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlDocumentIO2
    {
        auto LoadXmlFromBuffer(Windows::Storage::Streams::IBuffer const& buffer) const;
        auto LoadXmlFromBuffer(Windows::Storage::Streams::IBuffer const& buffer, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlDocumentIO2>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlDocumentIO2<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlDocumentStatics
    {
        auto LoadFromUriAsync(Windows::Foundation::Uri const& uri) const;
        auto LoadFromUriAsync(Windows::Foundation::Uri const& uri, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings) const;
        auto LoadFromFileAsync(Windows::Storage::IStorageFile const& file) const;
        auto LoadFromFileAsync(Windows::Storage::IStorageFile const& file, Windows::Data::Xml::Dom::XmlLoadSettings const& loadSettings) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlDocumentStatics>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlDocumentStatics<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlDocumentType
    {
        [[nodiscard]] auto Name() const;
        [[nodiscard]] auto Entities() const;
        [[nodiscard]] auto Notations() const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlDocumentType>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlDocumentType<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlDomImplementation
    {
        auto HasFeature(param::hstring const& feature, Windows::Foundation::IInspectable const& version) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlDomImplementation>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlDomImplementation<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlElement
    {
        [[nodiscard]] auto TagName() const;
        auto GetAttribute(param::hstring const& attributeName) const;
        auto SetAttribute(param::hstring const& attributeName, param::hstring const& attributeValue) const;
        auto RemoveAttribute(param::hstring const& attributeName) const;
        auto GetAttributeNode(param::hstring const& attributeName) const;
        auto SetAttributeNode(Windows::Data::Xml::Dom::XmlAttribute const& newAttribute) const;
        auto RemoveAttributeNode(Windows::Data::Xml::Dom::XmlAttribute const& attributeNode) const;
        auto GetElementsByTagName(param::hstring const& tagName) const;
        auto SetAttributeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& qualifiedName, param::hstring const& value) const;
        auto GetAttributeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& localName) const;
        auto RemoveAttributeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& localName) const;
        auto SetAttributeNodeNS(Windows::Data::Xml::Dom::XmlAttribute const& newAttribute) const;
        auto GetAttributeNodeNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& localName) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlElement>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlElement<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlEntityReference
    {
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlEntityReference>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlEntityReference<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlLoadSettings
    {
        [[nodiscard]] auto MaxElementDepth() const;
        auto MaxElementDepth(uint32_t value) const;
        [[nodiscard]] auto ProhibitDtd() const;
        auto ProhibitDtd(bool value) const;
        [[nodiscard]] auto ResolveExternals() const;
        auto ResolveExternals(bool value) const;
        [[nodiscard]] auto ValidateOnParse() const;
        auto ValidateOnParse(bool value) const;
        [[nodiscard]] auto ElementContentWhiteSpace() const;
        auto ElementContentWhiteSpace(bool value) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlLoadSettings>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlLoadSettings<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap
    {
        [[nodiscard]] auto Length() const;
        auto Item(uint32_t index) const;
        auto GetNamedItem(param::hstring const& name) const;
        auto SetNamedItem(Windows::Data::Xml::Dom::IXmlNode const& node) const;
        auto RemoveNamedItem(param::hstring const& name) const;
        auto GetNamedItemNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& name) const;
        auto RemoveNamedItemNS(Windows::Foundation::IInspectable const& namespaceUri, param::hstring const& name) const;
        auto SetNamedItemNS(Windows::Data::Xml::Dom::IXmlNode const& node) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlNamedNodeMap>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlNamedNodeMap<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlNode
    {
        [[nodiscard]] auto NodeValue() const;
        auto NodeValue(Windows::Foundation::IInspectable const& value) const;
        [[nodiscard]] auto NodeType() const;
        [[nodiscard]] auto NodeName() const;
        [[nodiscard]] auto ParentNode() const;
        [[nodiscard]] auto ChildNodes() const;
        [[nodiscard]] auto FirstChild() const;
        [[nodiscard]] auto LastChild() const;
        [[nodiscard]] auto PreviousSibling() const;
        [[nodiscard]] auto NextSibling() const;
        [[nodiscard]] auto Attributes() const;
        auto HasChildNodes() const;
        [[nodiscard]] auto OwnerDocument() const;
        auto InsertBefore(Windows::Data::Xml::Dom::IXmlNode const& newChild, Windows::Data::Xml::Dom::IXmlNode const& referenceChild) const;
        auto ReplaceChild(Windows::Data::Xml::Dom::IXmlNode const& newChild, Windows::Data::Xml::Dom::IXmlNode const& referenceChild) const;
        auto RemoveChild(Windows::Data::Xml::Dom::IXmlNode const& childNode) const;
        auto AppendChild(Windows::Data::Xml::Dom::IXmlNode const& newChild) const;
        auto CloneNode(bool deep) const;
        [[nodiscard]] auto NamespaceUri() const;
        [[nodiscard]] auto LocalName() const;
        [[nodiscard]] auto Prefix() const;
        auto Normalize() const;
        auto Prefix(Windows::Foundation::IInspectable const& value) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlNode>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlNode<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlNodeList
    {
        [[nodiscard]] auto Length() const;
        auto Item(uint32_t index) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlNodeList>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlNodeList<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlNodeSelector
    {
        auto SelectSingleNode(param::hstring const& xpath) const;
        auto SelectNodes(param::hstring const& xpath) const;
        auto SelectSingleNodeNS(param::hstring const& xpath, Windows::Foundation::IInspectable const& namespaces) const;
        auto SelectNodesNS(param::hstring const& xpath, Windows::Foundation::IInspectable const& namespaces) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlNodeSelector>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlNodeSelector<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlNodeSerializer
    {
        auto GetXml() const;
        [[nodiscard]] auto InnerText() const;
        auto InnerText(param::hstring const& value) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlNodeSerializer>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlNodeSerializer<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlProcessingInstruction
    {
        [[nodiscard]] auto Target() const;
        [[nodiscard]] auto Data() const;
        auto Data(param::hstring const& value) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlProcessingInstruction>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlProcessingInstruction<D>;
    };
    template <typename D>
    struct consume_Windows_Data_Xml_Dom_IXmlText
    {
        auto SplitText(uint32_t offset) const;
    };
    template <> struct consume<Windows::Data::Xml::Dom::IXmlText>
    {
        template <typename D> using type = consume_Windows_Data_Xml_Dom_IXmlText<D>;
    };
}
#endif
