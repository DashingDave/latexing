//
//	MTFontManager.swift
//	ObjC -> Swift conversion of
//
//  MTFontManager.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 8/30/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI

let kDefaultFontSize = 20

/* A manager to load font files from disc and keep them in memory. */
class MTFontManager: NSObject {
	private var nameToFontMap: [String : MTFont] = [:]

	static var manager: MTFontManager? = nil		// Get the singleton instance of MTFontManager.

	convenience init() {
		if manager == nil {
			manager = MTFontManager()
		}
		return manager!
	}

	override init() {
		super.init()
		nameToFontMap = [:]
	}

	/* Load a font with the given name. For the font to load, there must be a .otf file with the given name and a .plist file containing the math table data. The math table can be extracted using math_table_to_plist python script. */
	/* Parameters: (name: The name of the font file, size: The size of the font to return) */
	func font(withName name: String, size: CGFloat) -> MTFont {
		var f = nameToFontMap[name]
		if f == nil {
			f = MTFont(fontWithName: name, size: size)
			nameToFontMap[name] = f
		}
		if f.fontSize == size {
			return f
		} else {
			return f.copy(withSize: size)
		}
	}

	/* Helper function to return the Latin Modern Math font. */
	func latinModernFont(withSize size: CGFloat) -> MTFont {
		return font(withName: "latinmodern-math", size: size)
	}

	/* Helper function to return the Xits Math font. */
	func xitsFont(withSize size: CGFloat) -> MTFont {
		return font(withName: "xits-math", size: size)
	}

	/* Helper function to return the Tex Gyre Termes Math font. */
	func termesFont(withSize size: CGFloat) -> MTFont {
		return font(withName: "texgyretermes-math", size: size)
	}

	/* Returns the default font, which is Latin Modern Math with 20pt */
	func defaultFont() -> MTFont {
		return latinModernFont(withSize: CGFloat(kDefaultFontSize))
	}
}
