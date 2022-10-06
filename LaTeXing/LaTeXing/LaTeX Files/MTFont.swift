//
//	MTFont.swift
//	ObjC -> Swift conversion of
//
//  MTFont.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 5/18/16.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import CoreGraphics
import CoreText
import SwiftUI

/* MTFont wraps the inconvenient distinction between CTFont and CGFont as well as the data loaded from the math table. */
class MTFont: NSObject {
	/* The size of this font in points. */
	var fontSize: CGFloat {
		return CTFontGetSize(ctFont)
	}

	private var _defaultCGFont: CGFont?

	private var defaultCGFont: CGFont? {
	    get {
			_defaultCGFont
	    }
	    set(defaultCGFont) {
			if let _defaultCGFont = _defaultCGFont {
			}
			if let defaultCGFont = defaultCGFont {
				CFRetain(defaultCGFont)
			}
			_defaultCGFont = defaultCGFont
	    }
	}

	private var _ctFont: CTFont?

	private var ctFont: CTFont? {
	    get {
			_ctFont
	    }
	    set(ctFont) {
			if let _ctFont = _ctFont {
			}
			if let ctFont = ctFont {
				CFRetain(ctFont)
			}
			_ctFont = ctFont
	    }
	}

	private var mathTable: MTFontMathTable?

	private var rawMathTable: [AnyHashable : Any]?

	init(fontWithName name: String?, size: CGFloat) {
		super.init()
		
		/* CTFontCreateWithName does not load the complete math font, it only has about half the glyphs of the full math font. In particular it does not have the math italic characters which breaks our variable rendering. So we first load a CGFont from the file and then convert it to a CTFont. */
		let bundle = MTFont.fontBundle()

		let fontPath = bundle?.path(forResource: name, ofType: "otf")

		var fontDataProvider: CGDataProvider? = nil

		if let UTF8String = fontPath?.utf8CString {
			fontDataProvider = CGDataProvider(filename: UTF8String)
		}
		if let fontDataProvider = fontDataProvider {
			defaultCGFont = CGFont(fontDataProvider)
		}

		if let defaultCGFont = defaultCGFont {
			ctFont = CTFontCreateWithGraphicsFont(defaultCGFont, size, nil, nil)
		}

		let mathTablePlist = bundle?.path(forResource: name, ofType: "plist")

		let dict = NSDictionary(contentsOfFile: mathTablePlist ?? "") as Dictionary?
		rawMathTable = dict

		if let rawMathTable = rawMathTable {
			mathTable = MTFontMathTable(font: self, mathTable: rawMathTable)
		}
	}

	class func fontBundle() -> Bundle? {
		// Uses bundle for class so that this can be access by the unit tests.
		if let url = Bundle(for: self).url(forResource: "mathFonts", withExtension: "bundle") {
			return Bundle(url: url)
		}
		
		return nil
	}

	/* Returns a copy of this font but with a different size. */
	func copy(withSize size: CGFloat) -> MTFont {
		let copyFont = self.init()

		copyFont.defaultCGFont = defaultCGFont
		
		// Retain the font as we are adding another reference to it.
		CGFontRetain(copyFont.defaultCGFont)

		if let defaultCGFont = defaultCGFont {
			copyFont.ctFont = CTFontCreateWithGraphicsFont(defaultCGFont, size, nil, nil)
		}

		copyFont.rawMathTable = rawMathTable

		if let aRawMathTable = copyFont.rawMathTable {
			copyFont.mathTable = MTFontMathTable(font: copyFont, mathTable: aRawMathTable)
		}

		return copyFont
	}

	func getGlyphName(_ glyph: CGGlyph) -> String? {
		let name = CFBridgingRelease(defaultCGFont?.name(for: glyph))
		return name
	}

	func getGlyphWithName(_ glyphName: String?) -> CGGlyph {
		return (defaultCGFont?.getGlyphWithGlyphName(name: name))!
	}

	deinit {
		defaultCGFont = nil
		ctFont = nil
	}
}
