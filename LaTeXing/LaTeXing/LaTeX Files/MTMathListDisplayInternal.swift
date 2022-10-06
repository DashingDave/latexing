//
//	MTMathListDisplayInternal.swift
//	ObjC -> Swift conversion of
//
//  MTMathListDisplay+Internal.h
//  iosMath
//  Created by Kostub Deshmukh on 6/21/16.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

// TODO: Is most of this code extraneous (compare to MTMathListDisplay.swift), or are these all supposed to be extensions?


class MTDisplay {
	private var ascent: CGFloat = 0.0
	
	private var descent: CGFloat = 0.0
	
	private var width: CGFloat = 0.0
	
	private var range: NSRange?
	
	private var hasScript = false
}

/* The Downshift protocol allows an MTDisplay to be shifted down by a given amount. */
@objc protocol DownShift: NSObjectProtocol {
	var shiftDown: CGFloat { get set }
}

class MTMathListDisplay {
	private var type: MTLinePosition?
	
	private var index = 0

	private init() {
	}

	private required init(displays: [MTDisplay]?, range: NSRange) {
	}
}

class MTCTLineDisplay {
	private required init(string attrString: NSAttributedString?, position: CGPoint, range: NSRange, font: MTFont?, atoms: [MTMathAtom]?) {
	}

	private init() {
	}
}

class MTFractionDisplay {
	private var numeratorUp: CGFloat = 0.0
	
	private var denominatorDown: CGFloat = 0.0
	
	private var linePosition: CGFloat = 0.0
	
	private var lineThickness: CGFloat = 0.0

	private required init(numerator: MTMathListDisplay?, denominator: MTMathListDisplay?, position: CGPoint, range: NSRange) {
	}

	private init() {
	}
}

class MTRadicalDisplay {
	private var topKern: CGFloat = 0.0
	
	private var lineThickness: CGFloat = 0.0

	private required func initWitRadicand(_ radicand: MTMathListDisplay?, glpyh glyph: MTDisplay?, position: CGPoint, range: NSRange) -> Self {
	}

	private func setDegree(_ degree: MTMathListDisplay?, fontMetrics: MTFontMathTable?) {
	}
}

/* Rendering of an large glyph as an MTDisplay. */
class MTGlyphDisplay: DownShift {
	private required init(glpyh glyph: CGGlyph, range: NSRange, font: MTFont?) {
	}
}

/* Rendering of a constructed glyph as an MTDisplay. */
class MTGlyphConstructionDisplay: MTDisplay, DownShift {
	init() {
	}

	required init(glyphs: [NSNumber]?, offsets: [NSNumber]?, font: MTFont?) {
	}
}

class MTLargeOpLimitsDisplay {
	private var upperLimitGap: CGFloat = 0.0
	
	private var lowerLimitGap: CGFloat = 0.0

	private required init(nucleus: MTDisplay?, upperLimit: MTMathListDisplay?, lowerLimit: MTMathListDisplay?, limitShift: CGFloat, extraPadding: CGFloat) {
	}

	private init() {
	}
}

class MTLineDisplay {
	/* How much the line should be moved up. */
	private var lineShiftUp: CGFloat = 0.0
	
	private var lineThickness: CGFloat = 0.0

	private required init(inner: MTMathListDisplay?, position: CGPoint, range: NSRange) {
	}
}

class MTAccentDisplay {
	private required init(accent glyph: MTGlyphDisplay?, accentee: MTMathListDisplay?, range: NSRange) {
	}
}

class MTInnerDisplay {
	private var inner: MTMathListDisplay?
	
	private var leftDelimiter: MTDisplay?
	
	private var rightDelimiter: MTDisplay?
	
	private var index = 0

	private required init(inner: MTMathListDisplay?, leftDelimiter: MTDisplay?, rightDelimiter: MTDisplay?, at index: Int) {
	}
}
