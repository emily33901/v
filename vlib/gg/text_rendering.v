// Copyright (c) 2019-2021 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license that can be found in the LICENSE file.
module gg

import sokol.sgl
import gx
import os

enum FontVariant {
	normal = 0
	bold
	mono
	italic
}

struct FT {
pub:
	fons        voidptr
	font_normal int
	font_bold   int
	font_mono   int
	font_italic int
	scale       f32 = 1.0
}

struct FTConfig {
	font_path             string
	custom_bold_font_path string
	scale                 f32 = 1.0
	font_size             int
	bytes_normal          []byte
	bytes_bold            []byte
	bytes_mono            []byte
	bytes_italic          []byte
}

struct StringToRender {
	x    int
	y    int
	text string
	cfg  gx.TextCfg
}

fn new_ft(c FTConfig) ?&FT {
	// fons := sfons.create(512, 512, 1)
	return &FT{
		fons: voidptr(0)
		// font_normal: C.fonsAddFontMem(fons, 'sans', bytes.data, bytes.len, false
		// font_bold: C.fonsAddFontMem(fons, 'sans', bytes_bold.data, bytes_bold.len, false)
		// font_mono: C.fonsAddFontMem(fons, 'sans', bytes_mono.data, bytes_mono.len, false)
		// font_italic: C.fonsAddFontMem(fons, 'sans', bytes_italic.data, bytes_italic.len,)
			// false)
		scale: c.scale
	}
}

fn (ctx &Context) set_cfg(cfg gx.TextCfg) {
	// if !ctx.font_inited {
	// 	return
	// }
	// if cfg.bold {
	// 	ctx.ft.fons.set_font(ctx.ft.font_bold)
	// } else if cfg.mono {
	// 	ctx.ft.fons.set_font(ctx.ft.font_mono)
	// } else if cfg.italic {
	// 	ctx.ft.fons.set_font(ctx.ft.font_italic)
	// } else {
	// 	ctx.ft.fons.set_font(ctx.ft.font_normal)
	// }
	// scale := if ctx.ft.scale == 0 { f32(1) } else { ctx.ft.scale }
	// size := if cfg.mono { cfg.size - 2 } else { cfg.size }
	// ctx.ft.fons.set_size(scale * f32(size))
	// C.fonsSetAlign(ctx.ft.fons, int(cfg.align) | int(cfg.vertical_align))
	// color := C.sfons_rgba(cfg.color.r, cfg.color.g, cfg.color.b, cfg.color.a)
	// if cfg.color.a != 255 {
	// 	sgl.load_pipeline(ctx.timage_pip)
	// }
	// C.fonsSetColor(ctx.ft.fons, color)
	// ascender := f32(0.0)
	// descender := f32(0.0)
	// lh := f32(0.0)
	// ctx.ft.fons.vert_metrics(&ascender, &descender, &lh)
}

pub fn (ctx &Context) draw_text(x int, y int, text_ string, cfg gx.TextCfg) {
	$if macos {
		if ctx.native_rendering {
			if cfg.align == gx.align_right {
				width := ctx.text_width(text_)
				C.darwin_draw_string(x - width, ctx.height - y, text_, cfg)
			} else {
				C.darwin_draw_string(x, ctx.height - y, text_, cfg)
			}
			return
		}
	}
	if !ctx.font_inited {
		eprintln('gg: draw_text(): font not initialized')
		return
	}
	// text := text_.trim_space() // TODO remove/optimize
	// mut text := text_
	// if text.contains('\t') {
	// text = text.replace('\t', '    ')
	// }
	ctx.set_cfg(cfg)
	scale := if ctx.ft.scale == 0 { f32(1) } else { ctx.ft.scale }
	// C.fonsDrawText(ctx.ft.fons, x * scale, y * scale, text_.str, 0) // TODO: check offsets/alignment
}

pub fn (ctx &Context) draw_text_def(x int, y int, text string) {
	ctx.draw_text(x, y, text, {})
}

/*
pub fn (mut gg FT) init_font() {
}
*/
pub fn (ft &FT) flush() {
	// sfons.flush(ft.fons)
}

pub fn (ctx &Context) text_width(s string) int {
	$if macos {
		if ctx.native_rendering {
			return C.darwin_text_width(s)
		}
	}
	// ctx.set_cfg(cfg) TODO
	if !ctx.font_inited {
		return 0
	}
	mut buf := [4]f32{}
	// C.fonsTextBounds(ctx.ft.fons, 0, 0, s.str, 0, buf)
	if s.ends_with(' ') {
		return int((buf[2] - buf[0]) / ctx.scale) +
			ctx.text_width('i') // TODO fix this in fontstash?
	}
	res := int((buf[2] - buf[0]) / ctx.scale)
	// println('TW "$s" = $res')
	$if macos {
		if ctx.native_rendering {
			return res * 2
		}
	}
	return int((buf[2] - buf[0]) / ctx.scale)
}

pub fn (ctx &Context) text_height(s string) int {
	// ctx.set_cfg(cfg) TODO
	if !ctx.font_inited {
		return 0
	}
	mut buf := [4]f32{}
	// C.fonsTextBounds(ctx.ft.fons, 0, 0, s.str, 0, buf)
	return int((buf[3] - buf[1]) / ctx.scale)
}

pub fn (ctx &Context) text_size(s string) (int, int) {
	// ctx.set_cfg(cfg) TODO
	if !ctx.font_inited {
		return 0, 0
	}
	mut buf := [4]f32{}
	// C.fonsTextBounds(ctx.ft.fons, 0, 0, s.str, 0, buf)
	return int((buf[2] - buf[0]) / ctx.scale), int((buf[3] - buf[1]) / ctx.scale)
}

pub fn system_font_path() string {
	env_font := os.getenv('VUI_FONT')
	if env_font != '' && os.exists(env_font) {
		return env_font
	}
	$if windows {
		return 'C:\\Windows\\Fonts\\arial.ttf'
	}
	mut fonts := ['Ubuntu-R.ttf', 'Arial.ttf', 'LiberationSans-Regular.ttf', 'NotoSans-Regular.ttf',
		'FreeSans.ttf', 'DejaVuSans.ttf']
	$if macos {
		fonts = ['/System/Library/Fonts/SFNS.ttf', '/System/Library/Fonts/SFNSText.ttf', '/Library/Fonts/Arial.ttf']
		for font in fonts {
			if os.is_file(font) {
				return font
			}
		}
	}
	s := os.exec('fc-list') or { panic('failed to fetch system fonts') }
	system_fonts := s.output.split('\n')
	for line in system_fonts {
		for font in fonts {
			if line.contains(font) && line.contains(':') {
				res := line.all_before(':')
				println('Using font $res')
				return res
			}
		}
	}
	panic('failed to init the font')
}

fn get_font_path_variant(font_path string, variant FontVariant) string {
	// TODO: find some way to make this shorter and more eye-pleasant
	// NotoSans, LiberationSans, DejaVuSans, Arial and SFNS should work
	mut fpath := font_path.replace('.ttf', '')
	match variant {
		.normal {}
		.bold {
			if fpath.ends_with('-Regular') {
				fpath = fpath.replace('-Regular', '-Bold')
			} else if fpath.starts_with('DejaVuSans') {
				fpath += '-Bold'
			} else if fpath.to_lower().starts_with('arial') {
				fpath += 'bd'
			} else {
				fpath += '-bold'
			}
			$if macos {
				if os.exists('SFNS-bold') {
					fpath = 'SFNS-bold'
				}
			}
		}
		.italic {
			if fpath.ends_with('-Regular') {
				fpath = fpath.replace('-Regular', '-Italic')
			} else if fpath.starts_with('DejaVuSans') {
				fpath += '-Oblique'
			} else if fpath.to_lower().starts_with('arial') {
				fpath += 'i'
			} else {
				fpath += 'Italic'
			}
		}
		.mono {
			if !fpath.ends_with('Mono-Regular') && fpath.ends_with('-Regular') {
				fpath = fpath.replace('-Regular', 'Mono-Regular')
			} else if fpath.to_lower().starts_with('arial') {
				// Arial has no mono variant
			} else {
				fpath += 'Mono'
			}
		}
	}
	return fpath + '.ttf'
}

fn debug_font_println(s string) {
	$if debug_font ? {
		println(s)
	}
}
