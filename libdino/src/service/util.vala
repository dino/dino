using Dino.Entities;

namespace Dino {

public class Util {
    #if _WIN32
    [CCode (cname = "ShellExecuteA")]
    private static extern int ShellExecuteA(int* hwnd, string operation, string file, string parameters, string directory, int showCmd);

    private static int ShellExecute(string file) {
        return ShellExecuteA(null, null, file, null, null, 0);
    }
    #endif

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

    public static void launch_default_for_uri(string file_uri)
    {
#if _WIN32
        Dino.Util.ShellExecute(file_uri);
#else
        AppInfo.launch_default_for_uri(file_uri, null);
#endif
    }
    
    public static string get_content_type(FileInfo fileInfo)
    {
#if _WIN32
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
#endif
        return fileInfo.get_content_type();
    }
}
}
