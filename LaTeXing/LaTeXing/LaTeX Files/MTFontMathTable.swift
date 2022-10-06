//
//	MTFontMathTable.swift
//	ObjC -> Swift conversion of
//
//  MTFontMathTable.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import CoreText
import SwiftUI

let kConstants = "constants"

let kVertVariants = "v_variants"

let kHorizVariants = "h_variants"

let kItalic = "italic"

let kAccents = "accents"

let kVertAssembly = "v_assembly"

let kAssemblyParts = "parts"

/* MTGlyphPart represents a part of a glyph used for assembling a large vertical or horizontal glyph. */
class MTGlyphPart: NSObject {
	private(set) var glyph: CGGlyph?		// The glyph that represents this part

	private(set) var fullAdvance: CGFloat = 0.0			// Full advance width/height for this part, in the direction of the extension in points.

	private(set) var startConnectorLength: CGFloat = 0.0		// Advance width/ height of the straight bar connector material at the beginning of the glyph in points.

	private(set) var endConnectorLength: CGFloat = 0.0			// Advance width/ height of the straight bar connector material at the end of the glyph in points.

	private(set) var isExtender = false			// If this part is an extender. If set, the part can be skipped or repeated.
}

/* This class represents the Math table of an open type font. The math table is documented here: https://www.microsoft.com/typography/otspec/math.htm How the constants in this class affect the display is documented here: http://www.tug.org/TUGboat/tb30-1/tb94vieth.pdf */
/* We don't parse the math table from the open type font. Rather we parse it in python and convert it to a .plist file which is easily consumed by this class. This approach is preferable to spending an inordinate amount of time figuring out how to parse the returned NSData object using the open type rules. This class is not meant to be used outside of this library. */
class MTFontMathTable: NSObject {
	private var unitsPerEm = 0

	private var fontSize: CGFloat = 0.0

	private var mathTable: [AnyHashable : Any] = [:]

	/* MU unit in points */
	var muUnit: CGFloat {
		return fontSize / 18
	}
	
	/* Math Font Metrics from the opentype specification: */
	
	/* \sigma_8 in TeX */
	var fractionNumeratorDisplayStyleShiftUp: CGFloat {
		return constant(fromTable: "FractionNumeratorDisplayStyleShiftUp")
	}

	/* \sigma_9 in TeX */
	var fractionNumeratorShiftUp: CGFloat {
		return constant(fromTable: "FractionNumeratorShiftUp")
	}

	/* \sigma_11 in TeX */
	var fractionDenominatorDisplayStyleShiftDown: CGFloat {
		return constant(fromTable: "FractionDenominatorDisplayStyleShiftDown")
	}

	/* \sigma_12 in TeX */
	var fractionDenominatorShiftDown: CGFloat {
		return constant(fromTable: "FractionDenominatorShiftDown")
	}

	/* 3 \xi_8 in TeX */
	var fractionNumeratorDisplayStyleGapMin: CGFloat {
		return constant(fromTable: "FractionNumDisplayStyleGapMin")
	}

	/* \xi_8 in TeX */
	var fractionNumeratorGapMin: CGFloat {
		return constant(fromTable: "FractionNumeratorGapMin")
	}

	/* 3 \xi_8 in TeX */
	var fractionDenominatorDisplayStyleGapMin: CGFloat {
		return constant(fromTable: "FractionDenomDisplayStyleGapMin")
	}

	/* \xi_8 in TeX */
	var fractionDenominatorGapMin: CGFloat {
		return constant(fromTable: "FractionDenominatorGapMin")
	}

	/* \xi_8 in TeX */
	var fractionRuleThickness: CGFloat {
		return constant(fromTable: "FractionRuleThickness")
	}

	/* \sigma_20 in TeX */
	var fractionDelimiterDisplayStyleSize: CGFloat {
		// Modified constant from 2.4 to 2.39 to match KaTeX and improve appearance. */
		return 2.39 * fontSize
	}

	/* \sigma_21 in TeX */
	var fractionDelimiterSize: CGFloat {
		return 1.01 * fontSize
	}

	/* \sigma_8 in TeX */
	var stackTopDisplayStyleShiftUp: CGFloat {
		return constant(fromTable: "StackTopDisplayStyleShiftUp")
	}

	/* \sigma_10 in TeX */
	var stackTopShiftUp: CGFloat {
		return constant(fromTable: "StackTopShiftUp")
	}

	/* 7 \xi_8 in TeX */
	var stackDisplayStyleGapMin: CGFloat {
		return constant(fromTable: "StackDisplayStyleGapMin")
	}

	/* 3 \xi_8 in TeX */
	var stackGapMin: CGFloat {
		return constant(fromTable: "StackGapMin")
	}

	/* \sigma_11 in TeX */
	var stackBottomDisplayStyleShiftDown: CGFloat {
		return constant(fromTable: "StackBottomDisplayStyleShiftDown")
	}

	/* \sigma_12 in TeX */
	var stackBottomShiftDown: CGFloat {
		return constant(fromTable: "StackBottomShiftDown")
	}

	/* \sigma_13, \sigma_14 in TeX */
	var superscriptShiftUp: CGFloat {
		return constant(fromTable: "SuperscriptShiftUp")
	}

	/* \sigma_15 in TeX */
	var superscriptShiftUpCramped: CGFloat {
		return constant(fromTable: "SuperscriptShiftUpCramped")
	}

	/* \sigma_16, \sigma_17 in TeX */
	var subscriptShiftDown: CGFloat {
		return constant(fromTable: "SubscriptShiftDown")
	}

	/* \sigma_18 in TeX */
	var superscriptBaselineDropMax: CGFloat {
		return constant(fromTable: "SuperscriptBaselineDropMax")
	}

	/* \sigma_19 in TeX */
	var subscriptBaselineDropMin: CGFloat {
		return constant(fromTable: "SubscriptBaselineDropMin")
	}

	/* 1/4 \sigma_5 in TeX */
	var superscriptBottomMin: CGFloat {
		return constant(fromTable: "SuperscriptBottomMin")
	}

	/* 4/5 \sigma_5 in TeX */
	var subscriptTopMax: CGFloat {
		return constant(fromTable: "SubscriptTopMax")
	}

	/* 4 \xi_8 in TeX */
	var subSuperscriptGapMin: CGFloat {
		return constant(fromTable: "SubSuperscriptGapMin")
	}

	/* 4/5 \sigma_5 in TeX */
	var superscriptBottomMaxWithSubscript: CGFloat {
		return constant(fromTable: "SuperscriptBottomMaxWithSubscript")
	}

	var spaceAfterScript: CGFloat {
		return constant(fromTable: "SpaceAfterScript")
	}

	/* \xi_8 in TeX */
	var radicalExtraAscender: CGFloat {
		return constant(fromTable: "RadicalExtraAscender")
	}

	/* \xi_8 in TeX */
	var radicalRuleThickness: CGFloat {
		return constant(fromTable: "RadicalRuleThickness")
	}

	/* \xi_8 + 1/4 \sigma_5 in TeX */
	var radicalDisplayStyleVerticalGap: CGFloat {
		return constant(fromTable: "RadicalDisplayStyleVerticalGap")
	}

	/* 5/4 \xi_8 in Tex */
	var radicalVerticalGap: CGFloat {
		return constant(fromTable: "RadicalVerticalGap")
	}

	/* 5 mu in Tex */
	var radicalKernBeforeDegree: CGFloat {
		return constant(fromTable: "RadicalKernBeforeDegree")
	}

	/* -10 mu in Tex */
	var radicalKernAfterDegree: CGFloat {
		return constant(fromTable: "RadicalKernAfterDegree")
	}

	/* 60% in Text */
	var radicalDegreeBottomRaisePercent: CGFloat {
		return percent(fromTable: "RadicalDegreeBottomRaisePercent")
	}

	/* \xi_11 in TeX */
	var upperLimitBaselineRiseMin: CGFloat {
		return constant(fromTable: "UpperLimitBaselineRiseMin")
	}

	/* \xi_9 in TeX */
	var upperLimitGapMin: CGFloat {
		return constant(fromTable: "UpperLimitGapMin")
	}

	/* \xi_10 in TeX */
	var lowerLimitGapMin: CGFloat {
		return constant(fromTable: "LowerLimitGapMin")
	}

	/* \xi_12 in TeX */
	var lowerLimitBaselineDropMin: CGFloat {
		return constant(fromTable: "LowerLimitBaselineDropMin")
	}

	/* \xi_13 in TeX... */
	var limitExtraAscenderDescender: CGFloat {
		/* ...but not present in OpenType fonts. */
		return 0
	}

	/* 3 \xi_8 in TeX */
	var underbarVerticalGap: CGFloat {
		return constant(fromTable: "UnderbarVerticalGap")
	}

	/* \xi_8 in TeX */
	var underbarRuleThickness: CGFloat {
		return constant(fromTable: "UnderbarRuleThickness")
	}

	/* \xi_8 in TeX */
	var underbarExtraDescender: CGFloat {
		return constant(fromTable: "UnderbarExtraDescender")
	}

	/* 3 \xi_8 in TeX */
	var overbarVerticalGap: CGFloat {
		return constant(fromTable: "OverbarVerticalGap")
	}

	/* \xi_8 in TeX */
	var overbarRuleThickness: CGFloat {
		return constant(fromTable: "OverbarRuleThickness")
	}

	/* \xi_8 in TeX */
	var overbarExtraAscender: CGFloat {
		return constant(fromTable: "OverbarExtraAscender")
	}

	/* \sigma_22 in TeX */
	var axisHeight: CGFloat {
		return constant(fromTable: "AxisHeight")
	}

	var scriptScaleDown: CGFloat {
		return percent(fromTable: "ScriptPercentScaleDown")
	}

	var scriptScriptScaleDown: CGFloat {
		return percent(fromTable: "ScriptScriptPercentScaleDown")
	}

	/* \fontdimen5 in TeX (x-height) */
	var accentBaseHeight: CGFloat {
		return constant(fromTable: "AccentBaseHeight")
	}

	/* Minimum overlap of connecting glyphs during glyph construction */
	var minConnectorOverlap: CGFloat {
		return constant(fromTable: "MinConnectorOverlap")
	}
	private weak var font: MTFont?

	override init() {
	}

	required init(font: MTFont, mathTable: [AnyHashable : Any]) {
		super.init()
		
		assert(font != nil, "Invalid parameter not satisfying: font != nil")
		assert(font.ctFont != nil, "Invalid parameter not satisfying: font.ctFont != nil")
		
		self.font = font
		
		/* Do domething with font. */
		if let aCtFont = font.ctFont {
			unitsPerEm = Int(CTFontGetUnitsPerEm(aCtFont))
		}
		
		fontSize = font.fontSize
		
		self.mathTable = mathTable
		
		if "1.3" != self.mathTable["version"] {
			/* Invalid version */
			throw NSException(
				name: .internalInconsistencyException,
				reason: "Invalid version of math table plist: \(self.mathTable["version"])",
				userInfo: nil)
		}
	}

	func fontUnits(toPt fontUnits: Int) -> CGFloat {
		return CGFloat(fontUnits) * fontSize / CGFloat(unitsPerEm)
	}

	func constant(fromTable constName: String?) -> CGFloat {
		let consts = mathTable[kConstants] as? [AnyHashable : Any]
		let val = consts?[constName ?? ""] as? NSNumber
		return fontUnits(toPt: val?.intValue ?? 0)
	}

	func percent(fromTable percentName: String?) -> CGFloat {
		let consts = mathTable[kConstants] as? [AnyHashable : Any]
		let val = consts?[percentName ?? ""] as? NSNumber
		return CGFloat(val?.floatValue ?? 0.0 / 100)
	}

	func skewedFractionHorizontalGap() -> CGFloat {
		return constant(fromTable: "SkewedFractionHorizontalGap")
	}

	func skewedFractionVerticalGap() -> CGFloat {
		return constant(fromTable: "SkewedFractionVerticalGap")
	}

	func mathLeading() -> CGFloat {
		return constant(fromTable: "MathLeading")
	}

	func delimitedSubFormulaMinHeight() -> CGFloat {
		return constant(fromTable: "DelimitedSubFormulaMinHeight")
	}

	func flattenedAccentBaseHeight() -> CGFloat {
		return constant(fromTable: "FlattenedAccentBaseHeight")
	}

	func displayOperatorMinHeight() -> CGFloat {
		return constant(fromTable: "DisplayOperatorMinHeight")
	}

	func stretchStackBottomShiftDown() -> CGFloat {
		return constant(fromTable: "StretchStackBottomShiftDown")
	}

	func stretchStackGapAboveMin() -> CGFloat {
		return constant(fromTable: "StretchStackGapAboveMin")
	}

	func stretchStackGapBelowMin() -> CGFloat {
		return constant(fromTable: "StretchStackGapBelowMin")
	}

	func stretchStackTopShiftUp() -> CGFloat {
		return constant(fromTable: "StretchStackTopShiftUp")
	}

	/* Returns an NSArray of all the vertical variants of the glyph, if any. If there are no variants for the glyph, the array contains the given glyph. */
	func getVerticalVariants(for glyph: CGGlyph) -> [NSNumber] {
		let variants = mathTable[kVertVariants] as? [AnyHashable : Any]
		
		return getVariantsFor(glyph, inDictionary: variants)
	}

	/* Returns an NSArray of all the horizontal variants of the glyph, if any. If there are no variants for the glyph, the array contains the given glyph. */
	func getHorizontalVariants(for glyph: CGGlyph) -> [NSNumber] {
		let variants = mathTable[kHorizVariants] as? [AnyHashable : Any]
		
		return getVariantsFor(glyph, inDictionary: variants)
	}

	func getVariantsFor(_ glyph: CGGlyph, inDictionary variants: [AnyHashable : Any]?) -> [NSNumber]? {
		let glyphName = font?.getGlyphName(glyph)
		
		let variantGlyphs = variants?[glyphName ?? ""] as? [AnyHashable]
		
		var glyphArray = [AnyHashable](repeating: 0, count: variantGlyphs?.count ?? 0)
		
		if variantGlyphs == nil {
			/* There are no extra variants, so just add the current glyph to it. */
			let glyph = font?.getGlyphWithName(glyphName)
			
			glyphArray.append(NSNumber(value: glyph!))
			
			return glyphArray as? [NSNumber]
		}
		
		for glyphVariantName in variantGlyphs ?? [] {
			guard let glyphVariantName = glyphVariantName as? String else {
			    continue
			}
			
			let variantGlyph = font?.getGlyphWithName(glyphVariantName)
			
			glyphArray.append(NSNumber(value: variantGlyph!))
		}
		
		return glyphArray as? [NSNumber]
	}

	/* Returns a larger vertical variant of the given glyph, if any. If there is no larger version, this returns the current glyph. */
	func getLargerGlyph(_ glyph: CGGlyph) -> CGGlyph {
		let variants = mathTable[kVertVariants] as? [AnyHashable : Any]
		
		let glyphName = font?.getGlyphName(glyph)
		
		let variantGlyphs = variants?[glyphName ?? ""] as? [AnyHashable]
		
		if variantGlyphs == nil {
			/* There are no extra variants, so just return the current glyph. */
			return glyph
		}
		
		/* Find the first variant with a different name. */
		for glyphVariantName in variantGlyphs ?? [] {
			guard let glyphVariantName = glyphVariantName as? String else {
			    continue
			}
			
			if glyphVariantName != glyphName {
				let variantGlyph = font?.getGlyphWithName(glyphVariantName)
				
				return variantGlyph!
			}
		}
		
		/* We did not find any variants of this glyph so return it. */
		return glyph
	}

	/* Returns the italic correction for the given glyph, if any. If there isn't any this returns 0. */
	func getItalicCorrection(_ glyph: CGGlyph) -> CGFloat {
		let italics = mathTable[kItalic] as? [AnyHashable : Any]
		let glyphName = font?.getGlyphName(glyph)
		let val = italics?[glyphName ?? ""] as? NSNumber
		// if val is nil, this returns 0.
		return fontUnits(toPt: val?.intValue ?? 0)
	}

	/* Returns the adjustment to the top accent for the given glyph, if any. If there aren't any, this returns -1. */
	func getTopAccentAdjustment(_ glyph: CGGlyph) -> CGFloat {
		var glyph = glyph
		
		let accents = mathTable[kAccents] as? [AnyHashable : Any]
		
		let glyphName = font?.getGlyphName(glyph)
		
		let val = accents?[glyphName ?? ""] as? NSNumber
		
		if let val = val {
			return fontUnits(toPt: val.intValue)
		} else {
			/* If no top accent is defined, then it is the center of the advance width. */
			var advances: CGSize
		
			if let aCtFont = font?.ctFont {
				CTFontGetAdvancesForGlyphs(aCtFont, .kCTFontHorizontalOrientation, &glyph, &advances, CFIndex(1))
			}
			
			return advances.width / 2
		}
	}

	/* Returns an array of the glyph parts to be used for constructing vertical variants of this glyph. If there is no glyph assembly defined, returns nil. */
	func getVerticalGlyphAssembly(for glyph: CGGlyph) -> [MTGlyphPart]? {
		let assemblyTable = mathTable[kVertAssembly] as? [AnyHashable : Any]
		
		let glyphName = font?.getGlyphName(glyph)
		
		let assemblyInfo = assemblyTable?[glyphName ?? ""] as? [AnyHashable : Any]
		
		if assemblyInfo == nil {
			/* No vertical assembly defined for glyph. */
			return nil
		}
		
		let parts = assemblyInfo?[kAssemblyParts] as? [AnyHashable]
		
		if parts == nil {
			/* Parts should always have been defined, but if it isn't return nil. */
			return nil
		}
		
		var rv: [MTGlyphPart]? = []
		
		for partInfo in parts ?? [] {
			guard let partInfo = partInfo as? [AnyHashable : Any] else {
			    continue
			}
		
			let part = MTGlyphPart()
			
			let adv = partInfo["advance"] as? NSNumber
			
			part.fullAdvance = fontUnits(toPt: adv?.intValue ?? 0)
			
			let end = partInfo["endConnector"] as? NSNumber
			
			part.endConnectorLength = fontUnits(toPt: end?.intValue ?? 0)
			
			let start = partInfo["startConnector"] as? NSNumber
			
			part.startConnectorLength = fontUnits(toPt: start?.intValue ?? 0)
			
			let ext = partInfo["extender"] as? NSNumber
			
			part.isExtender = ext?.boolValue ?? false
			
			let glyphName = partInfo["glyph"] as? String
			
			part.glyph = font?.getGlyphWithName(glyphName)

			rv?.append(part)
		}
		
		return rv
	}
}
