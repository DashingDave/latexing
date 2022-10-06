//
//	MTFontInternal.swift
//	ObjC -> Swift conversion of
//
//  MTFont+Internal.h
//  iosMath
//  Created by Kostub Deshmukh on 5/20/16.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

// TODO: Would this extension's code be better placed within 'class MTFont' (see MTFont.swift); does it need to be in its own separate file?


/* This category add functions to MTFont that are meant to be internal to this library for rendering purposes. */

extension MTFont {
	private(set) var ctFont: CTFont			// Access to the raw CTFontRef if needed.

	private(set) var mathTable: MTFontMathTable			// The font math table.


	/* Load the font with a given name. This is the designated initializer. */
	init(fontWithName name: String, size: CGFloat) {
	}

	/* Returns the name of the given glyph or null if the glyph is not associated with the font. */
	func getGlyphName(_ glyph: CGGlyph) -> String? {
	}

	/* Returns a glyph associated with the given name. */
	func getGlyphWithName(_ glyphName: String) -> CGGlyph {
	}
}
