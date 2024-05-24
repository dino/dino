using Gdk;

namespace Dino.Ui {

// Adapted from https://discourse.gnome.org/t/python-how-do-you-implement-a-paintable-for-gif-animations/16054/4
class AnimationPaintable : Object, Gdk.Paintable {
	private Gdk.PixbufAnimation animation;
	private Gdk.PixbufAnimationIter iterator;

	public AnimationPaintable.from_file(File file) throws GLib.Error {
		animation = new Gdk.PixbufAnimation.from_file(file.get_path());

		// Null here means to just take the current time
		iterator = animation.get_iter(null);

		tick();
	}

	private static void tick_lambda(AnimationPaintable self) {
		self.tick();
	}

	public void tick() {
		var delay = iterator.get_delay_time();
		if (delay >= 0) {
			Dino.WeakTimeout.add_once(delay, this, tick_lambda);
		}

		invalidate_contents();
	}

	public int get_intrinsic_height() {
		return animation.get_height();
	}

	public int get_intrinsic_width() {
		return animation.get_width();
	}

	public void snapshot(Gdk.Snapshot snapshot, double width, double height) {
		// Null again here means take the current time, so it runs 1sec/sec
		iterator.advance(null);

		var pixbuf = iterator.get_pixbuf();
		var texture = Gdk.Texture.for_pixbuf(pixbuf);

		texture.snapshot(snapshot, width, height);
	}
}

}
