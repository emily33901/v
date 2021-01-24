module gx

// TODO: remove these and uae the enum everywhere
const (
	align_left = HorizontalAlign.left
	align_right = HorizontalAlign.right
)

pub enum HorizontalAlign {
	left = 0
	center = 1
	right = 2
}

pub enum VerticalAlign {
	top = 0
	middle = 1
	bottom = 2
	baseline = 3
}

pub struct TextCfg {
pub:
	color          Color = black
	size           int = 16
	align          HorizontalAlign = .left
	vertical_align VerticalAlign = .top
	max_width      int
	family         string
	bold           bool
	mono           bool
	italic         bool
}
