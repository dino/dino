using Dino.Entities;

namespace Dino {

public class Util {
    public static Message.Type get_message_type_for_conversation(Conversation conversation) {
        switch (conversation.type_) {
            case Conversation.Type.CHAT:
                return Entities.Message.Type.CHAT;
            case Conversation.Type.GROUPCHAT:
                return Entities.Message.Type.GROUPCHAT;
            case Conversation.Type.GROUPCHAT_PM:
                return Entities.Message.Type.GROUPCHAT_PM;
        }
        assert_not_reached();
    }

    public static Conversation.Type get_conversation_type_for_message(Message message) {
        switch (message.type_) {
            case Entities.Message.Type.CHAT:
                return Conversation.Type.CHAT;
            case Entities.Message.Type.GROUPCHAT:
                return Conversation.Type.GROUPCHAT;
            case Entities.Message.Type.GROUPCHAT_PM:
                return Conversation.Type.GROUPCHAT_PM;
        }
        assert_not_reached();
    }
    
    public static string get_content_type(FileInfo fileInfo)
    {
//#if WIN32
        string fileName = fileInfo.get_name();
        int fileNameLength = fileName.length;
        int extIndex = fileName.index_of(".");
        if (extIndex < fileNameLength)
        {
            string extension = fileName.substring(extIndex, fileNameLength - extIndex);
            string mime_type = ContentType.get_mime_type(extension);
            if (mime_type != null && mime_type.length != 0)
            {
                return mime_type;
            }
        }
//#endif

        return fileInfo.get_content_type();
    }
}
}
