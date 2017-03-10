using Gee;
using Gtk;

using Dino.Entities;

namespace Dino.Ui.ConversationSummary {

private class MergedStatusItem : Expander {

    private StreamInteractor stream_interactor;
    private Conversation conversation;
    private ArrayList<Show> statuses = new ArrayList<Show>();

    public MergedStatusItem(StreamInteractor stream_interactor, Conversation conversation, Show show) {
        set_hexpand(true);
        add_status(show);
    }

    public void add_status(Show show) {
        statuses.add(show);
        StatusItem status_item = new StatusItem(stream_interactor, conversation, @"is $(show.as)");
        if (statuses.size == 1) {
            label = show.as;
        } else {
            label = @"changed their status $(statuses.size) times";
            add(new Label(show.as));
        }
    }
}
}