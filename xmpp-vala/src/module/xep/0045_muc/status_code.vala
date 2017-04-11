namespace Xmpp.Xep.Muc {

public const StatusCode[] ROOM_CONFIGURATION_CODES = {
    StatusCode.LOGGING_ENABLED,
    StatusCode.LOGGING_DISABLED,
    StatusCode.NON_ANONYMOUS,
    StatusCode.SEMI_ANONYMOUS
};

public const StatusCode[] USER_REMOVED_CODES = {
    StatusCode.BANNED,
    StatusCode.KICKED,
    StatusCode.REMOVED_AFFILIATION_CHANGE,
    StatusCode.REMOVED_MEMBERS_ONLY,
    StatusCode.REMOVED_SHUTDOWN
};

public enum StatusCode {
    /** Inform user that any occupant is allowed to see the user's full JID */
    JID_VISIBLE = 100,
    /** Inform user that his or her affiliation changed while not in the room */
    AFFILIATION_CHANGED = 101,
    /** Inform occupants that room now shows unavailable members */
    SHOWS_UNAVIABLE_MEMBERS = 102,
    /** Inform occupants that room now does not show unavailable members */
    SHOWS_UNAVIABLE_MEMBERS_NOT = 103,
    /** Inform occupants that a non-privacy-related room configuration change has occurred */
    CONFIG_CHANGE_NON_PRIVACY = 104,
    /** Inform user that presence refers to itself */
    SELF_PRESENCE = 110,
    /** Inform occupants that room logging is now enabled */
    LOGGING_ENABLED = 170,
    /** Inform occupants that room logging is now disabled */
    LOGGING_DISABLED = 171,
    /** Inform occupants that the room is now non-anonymous */
    NON_ANONYMOUS = 172,
    /** Inform occupants that the room is now semi-anonymous */
    SEMI_ANONYMOUS = 173,
    /** Inform user that a new room has been created */
    NEW_ROOM_CREATED = 201,
    /** Inform user that service has assigned or modified occupant's roomnick */
    MODIFIED_NICK = 210,
    /** Inform user that he or she has been banned from the room */
    BANNED = 301,
    /** Inform all occupants of new room nickname */
    ROOM_NICKNAME = 303,
    /** Inform user that he or she has been kicked from the room */
    KICKED = 307,
    /** Inform user that he or she is being removed from the room */
    REMOVED_AFFILIATION_CHANGE = 321,
    /** Inform user that he or she is being removed from the room because the room has been changed to members-only
    and the user is not a member */
    REMOVED_MEMBERS_ONLY = 322,
    /** Inform user that he or she is being removed from the room because the MUC service is being shut down */
    REMOVED_SHUTDOWN = 332
}

}