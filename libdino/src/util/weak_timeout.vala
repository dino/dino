public class Dino.WeakTimeout {
    // XXX: If you get an error saying your function doesn't match the delegate, make sure it's static!
    //      These are marked as "has_taget=false" so you can't close over "this" and leak it in your lambda.
    [CCode (has_target = false)]
    public delegate bool SourceFunc<T> (T object);

    [CCode (has_target = false)]
    public delegate void SourceOnceFunc<T> (T object);

    public static uint add<T>(uint interval, T object, owned SourceFunc<T> function, int priority = GLib.Priority.DEFAULT) {
        var weak = WeakRef((Object)object);
        return GLib.Timeout.add(interval, () => {
            var strong = weak.get();
            if (strong == null) return false;

            return function(strong);
        }, priority);
    }

    public static uint add_once<T>(uint interval, T object, owned SourceOnceFunc<T> function, int priority = GLib.Priority.DEFAULT) {
        var weak = WeakRef((Object)object);
        return GLib.Timeout.add(interval, () => {
            var strong = weak.get();
            if (strong == null) return false;

            function(strong);
            return false;
        }, priority);
    }

    public static uint add_seconds<T>(uint interval, T object, owned SourceFunc<T> function, int priority = GLib.Priority.DEFAULT) {
        return add(interval * 1000, object, (owned) function, priority);
    }

    // This one doesn't have an upstream equivalent, but it seems pretty obvious to me
    public static uint add_seconds_once<T>(uint interval, T object, owned SourceOnceFunc<T> function, int priority = GLib.Priority.DEFAULT) {
        return add_once(interval * 1000, object, (owned) function, priority);
    }

}
