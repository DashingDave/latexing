//
//  MTMathListDisplay.swift
//	ObjC -> Swift conversion of
//
//  MTLine.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 8/27/13.
//  Copyright (C) 2013 MathChat
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import CoreText
import SwiftUI
import QuartzCore

/* The base case for rendering a math equation. */
class MTDisplay: NSObject {
	private(set) var ascent: CGFloat = 0.0		// The distance from the axis to the top of the display

	private(set) var descent: CGFloat = 0.0		// The distance from the axis to the bottom of the display

	private(set) var width: CGFloat = 0.0		// The width of the display

	var position = CGPoint.zero				// Position of the display with respect to the parent view or display

	private(set) var range: NSRange?		// The range of characters supported by this item

	private(set) var hasScript = false		// Whether the display has a subscript/superscript following it.

	var textColor: MTColor?					// The text color for this display

	var localTextColor: MTColor?			// The local color, if the color was mutated local with the color command

	var localBackgroundColor: MTColor?		// The background color for this display

	/* Draw itself in the given graphics context. */
	func draw(_ context: CGContext?) {
		if let localBackgroundColor = localBackgroundColor {
			context?.saveGState()
			
			context?.setBlendMode(.normal)
			
			context?.setFillColor(localBackgroundColor.cgColor)
			
			context?.fill(displayBounds())
			
			context?.restoreGState()
		}

	}

	/* Get the bounding rectangle for the MTDisplay. */
	func displayBounds() -> CGRect {
		return CGRect(x: position.x, y: position.y - descent, width: width, height: ascent + descent)
	}
	
	/* Debug method skipped for Mac. */
	#if os(iOS)
	
	func debugQuickLookObject() -> Any? {
		let size = CGSize(width: width, height: ascent + descent)
		
		UIGraphicsBeginImageContext(size)
		
		/* Get a reference to the context we created. */
		let context = UIGraphicsGetCurrentContext()
		
		/* Translate/flip the graphics context (for transforming from CG coords to UI coords. */
		context?.translateBy(x: 0, y: size.height)
		
		context?.scaleBy(x: 1.0, y: -1.0)
		
		/* Move the position to (0,0). */
		context?.translateBy(x: -position.x, y: -position.y)
		
		/* Move the line up by self.descent. */
		context?.translateBy(x: 0, y: descent)
		
		/* Draw self on context. */
		draw(context)
		
		/* Generate a new UIImage from the graphics context we drew. */
		let img = UIGraphicsGetImageFromCurrentImageContext()
		
		return img
	}
	
	#endif
}

/* A rendering of a single CTLine as an MTDisplay */
class MTCTLineDisplay: MTDisplay {
	private(set) var line: CTLine?			// The CTLine being displayed
	
	/* The attributed string used to generate the CTLineRef. Note setting this does not reset the dimensions of the display. So set only when [??]*/
	
	private var _attributedString: NSAttributedString?
	
	var attributedString: NSAttributedString {
		get {
			_attributedString
		}
		set(attrString) {
			if line != nil {
			}
			_attributedString = attrString
			
			if let string = _attributedString as CFAttributedString? {
				line = CTLineCreateWithAttributedString(string)
			}
		}
	}
	
	/* An array of MTMathAtoms that this CTLine displays. Used for indexing back into the MTMathList. */
	private(set) var atoms: [MTMathAtom] = nil
	
	override init() {
	}
	
	init(string attrString: NSAttributedString, position: CGPoint, range: NSRange, font: MTFont, atoms: [MTMathAtom]) {
		super.init()
		
		self.position = position
		
		attributedString = attrString
		
		self.range = range
		
		self.atoms = atoms
		
		/* We can't use typographic bounds here as the ascent and descent returned are for the font and not for the line. */
		if let line = line {
			width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
		}
		
		if isIos6Supported() {
			var bounds: CGRect? = nil
			
			if let line = line {
				bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
			}
			
			ascent = CGFloat(max(0, (bounds?.maxY ?? 0.0) - 0))
			
			descent = CGFloat(max(0, 0 - (bounds?.minY ?? 0.0)))
			
/* TODO: Should we use this width or the typographic width? They are slightly different. Don't know why. */
			/* _width = CGRectGetMaxX(bounds) */
		} else {
			/* Our own implementation of the ios6 function to get glyph path bounds. */
			computeDimensions(font)
		}
	}
	
	override var textColor: MTColor? {
		get {
			super.textColor
		}
		set(textColor) {
			super.textColor = textColor
			
			let attrStr = attributedString as? NSMutableAttributedString
			
			attrStr?.addAttribute(
				NSAttributedString.Key(kCTForegroundColorAttributeName as String),
				
				value: self.textColor?.cgColor,
				
				range: NSRange(location: 0, length: attrStr?.length ?? 0))
			
			if let attrStr = attrStr {
				attributedString = attrStr
			}
		}
	}
	
	func computeDimensions(_ font: MTFont) {
		var runs: [AnyHashable]? = nil
		
		if let line = line {
			runs = (CTLineGetGlyphRuns(line)) as? [AnyHashable]
		}
		
		for obj in runs ?? [] {
			let run = obj as? CTRun
			
			var numGlyphs: CFIndex? = nil
			
			if let run = run {
				numGlyphs = CTRunGetGlyphCount(run)
			}
			
			let glyphs = [CGGlyph](repeating: , count: numGlyphs)
			
			if let run = run {
				CTRunGetGlyphs(run, CFRangeMake(CFIndex(0), numGlyphs ?? 0), &glyphs)
			}
			
			let bounds = CTFontGetBoundingRectsForGlyphs(font.ctFont, .kCTFontHorizontalOrientation, &glyphs, nil, numGlyphs ?? 0)
			
			let ascent = CGFloat(max(0, bounds.maxY - 0))
			
			/* Descent is how much the line goes below the origin. However, if the line is all above the origin, then descent can't be negative. */
			let descent = CGFloat(max(0, 0 - bounds.minY))
			
			if ascent > self.ascent {
				self.ascent = ascent
			}
			
			if descent > self.descent {
				self.descent = descent
			}
		}
	}
	
	deinit {
	}

	override func draw(_ context: CGContext?) {
		super.draw(context)
		
		context?.saveGState()

		context?.textPosition = CGPoint(x: position.x, y: position.y)
		
		if let line = line, let context = context {
			CTLineDraw(line, context)
		}

		context?.restoreGState()
	}
}

/* An MTLine is a rendered form of MTMathList in one line. It can render itself using the draw method. `MTLinePosition` indicates type of position for a line, i.e. subscript/superscript or regular. */
enum MTLinePosition : Int {
	case regular		// Regular
	case `subscript`	// Positioned at a subscript
	case superscript	// Positioned at a superscript
	case inner			// Positioned at an inner
}

/* Where the line is positioned. */
class MTMathListDisplay: MTDisplay {
	private(set) var type: MTLinePosition!
	
	/* An array of MTDisplays which are positioned relative to the position of the the current display. */
	private(set) var subDisplays: [MTDisplay] = nil
	
	/* If a subscript or superscript, this denotes the location in the parent MTList. For a regular list, this is NSNotFound */
	private(set) var index = 0
	
	override init() {
	}
	
	init(displays: [MTDisplay], range: NSRange) {
		super.init()
		
		subDisplays = displays
		
		position = CGPoint.zero
		
		type = MTLinePosition.regular
		
		index = NSNotFound
		
		self.range = range
		
		recomputeDimensions()
	}
	
	var type: MTLinePosition! {
		get {
			super.type
		}
		set(type) {
			_type = type
		}
	}
	
	var index: Int {
		get {
			super.index
		}
		set(index) {
			_index = index
		}
	}
	
	override var textColor: MTColor? {
		get {
			super.textColor
		}
		set(textColor) {
			/* Set the color on all subdisplays. */
			super.textColor = textColor
			
			for displayAtom in subDisplays {
				/* Set the global color, if there is no local color. */
				if displayAtom.localTextColor == nil {
					displayAtom.textColor = textColor
				} else {
					displayAtom.textColor = displayAtom.localTextColor
				}
			}
		}
	}
	
	override func draw(_ context: CGContext?) {
		super.draw(context)
		
		context?.saveGState()
		
		/* Make the current position the origin as all the positions of the sub atoms are relative to the origin. */
		context?.translateBy(x: position.x, y: position.y)
		
		context?.textPosition = CGPoint(x: 0, y: 0)
		
		/* Draw each atom separately. */
		for displayAtom in subDisplays {
			displayAtom.draw(context)
		}
		
		context?.restoreGState()
	}
	
	func recomputeDimensions() {
		var max_ascent: CGFloat = 0
		
		var max_descent: CGFloat = 0
		
		var max_width: CGFloat = 0
		
		for atom in subDisplays {
			let ascent = CGFloat(max(0, atom.position.y + atom.ascent))
			
			if ascent > max_ascent {
				max_ascent = ascent
			}
			
			let descent = CGFloat(max(0, 0 - (atom.position.y - atom.descent)))
			
			if descent > max_descent {
				max_descent = descent
			}
			
			let width = atom.width + atom.position.x
			
			if width > max_width {
				max_width = width
			}
		}
		
		self.ascent = max_ascent
		
		self.descent = max_descent
		
		self.width = max_width
	}
}

/* Rendering of an MTFraction as an MTDisplay */
class MTFractionDisplay: MTDisplay {
	/* A display representing the numerator of the fraction. Its position is relative to the parent and is not treated as a sub-display. */
	private(set) var numerator: MTMathListDisplay?
	
	/* A display representing the denominator of the fraction. Its position is relative to the parent and is not treated as a sub-display. */
	private(set) var denominator: MTMathListDisplay?
	
	override init() {
	}
	
	init(numerator: MTMathListDisplay, denominator: MTMathListDisplay, position: CGPoint, range: NSRange) {
		super.init()
		
		self.numerator = numerator
		
		self.denominator = denominator
		
		self.position = position
		
		self.range = range
		
		assert((self.range?.length ?? 0) == 1, String(format: "Fraction range length not 1 - range (%lu, %lu)", UInt(range.location), UInt(range.length)))
	}
	
	override var ascent: CGFloat {
		get {
			return (numerator?.ascent ?? 0.0) + numeratorUp
		}
		set {
			super.ascent = newValue
		}
	}
	
	override var descent: CGFloat {
		get {
			return (denominator?.descent ?? 0.0) + denominatorDown
		}
		set {
			super.descent = newValue
		}
	}
	
	override var width: CGFloat {
		get {
			return CGFloat(max(numerator?.width, denominator?.width))
		}
		set {
			super.width = newValue
		}
	}
	
	func setDenominatorDown(_ denominatorDown: CGFloat) {
		self.denominatorDown = denominatorDown
		
		updateDenominatorPosition()
	}
	
	func setNumeratorUp(_ numeratorUp: CGFloat) {
		self.numeratorUp = numeratorUp
		
		updateNumeratorPosition()
	}
	
	func updateDenominatorPosition() {
		denominator?.position = CGPoint(x: position.x + (width - (denominator?.width ?? 0.0)) / 2, y: position.y - denominatorDown)
	}
	
	func updateNumeratorPosition() {
		numerator?.position = CGPoint(x: position.x + (width - (numerator?.width ?? 0.0)) / 2, y: position.y + numeratorUp)
	}
	
	override var position: CGPoint {
		get {
			super.position
		}
		set(position) {
			super.position = position
			
			updateDenominatorPosition()
			
			updateNumeratorPosition()
		}
	}
	
	override var textColor: MTColor? {
		get {
			super.textColor
		}
		set(textColor) {
			super.textColor = textColor
			
			numerator?.textColor = textColor
			
			denominator?.textColor = textColor
		}
	}
	
	override func draw(_ context: CGContext?) {
		super.draw(context)
		
		numerator?.draw(context)
		
		denominator?.draw(context)
		
		context?.saveGState()
		
		textColor?.setStroke()
		
		/* Draw the horizontal line. */
		let path = MTBezierPath()
		
		path.move(toPoint: CGPoint(x: position.x, y: position.y + linePosition))
		
		path.addLine(toPoint: CGPoint(x: position.x + width, y: position.y + linePosition))
		
		path.lineWidth = lineThickness
		
		path.stroke()
		
		context?.restoreGState()
	}
}

/* Rendering of an MTRadical as an MTDisplay */
class MTRadicalDisplay: MTDisplay {
	private var radicalGlyph: MTDisplay?
	
	private var radicalShift: CGFloat = 0.0
	
	/* A display representing the radicand of the radical. Its position is relative to the parent and is not treated as a sub-display. */
	private(set) var radicand: MTMathListDisplay?
	
	/* A display representing the degree of the radical. Its position is relative to the parent and is not treated as a sub-display. */
	private(set) var degree: MTMathListDisplay?
	
	override init() {
	}
	
	func initWitRadicand(_ radicand: MTMathListDisplay, glpyh glyph: MTDisplay, position: CGPoint, range: NSRange) -> Self {
		super.init()
		
		self.radicand = radicand
		
		radicalGlyph = glyph
		
		radicalShift = 0
		
		self.position = position
		
		self.range = range
		
		return self
	}
	
	/* Sets the degree of the radical. */
	func setDegree(_ degree: MTMathListDisplay, fontMetrics: MTFontMathTable) {
		/* The layout is: kernBefore, raise, degree, kernAfter, radical */
		var kernBefore = fontMetrics.radicalKernBeforeDegree
		
		let kernAfter = fontMetrics.radicalKernAfterDegree
		
		let raise = fontMetrics.radicalDegreeBottomRaisePercent * (ascent - descent)
		
		self.degree = degree
		
		/* The radical is now shifted by kernBefore + degree.width + kernAfter */
		radicalShift = kernBefore + degree.width + kernAfter
		
		if radicalShift < 0 {
			/* We can't have the radical shift backwards, so instead we increase the kernBefore such that `_radicalShift` will be 0. */
			kernBefore -= radicalShift
			
			radicalShift = 0
		}
		
		/* Position of degree is relative to parent. */
		self.degree.position = CGPoint(x: position.x + kernBefore, y: position.y + raise)
		
		/* Update the width by the `_radicalShift`. */
		width = radicalShift + (radicalGlyph?.width ?? 0.0) + radicand.width
		
		/* Update the position of the radicand. */
		updateRadicandPosition()
	}
	
	override var position: CGPoint {
		get {
			super.position
		}
		set(position) {
			super.position = position
			
			updateRadicandPosition()
		}
	}
	
	/* The position of the radicand includes the position of the MTRadicalDisplay. This is to make the positioning of the radical consistent with fractions and have the cursor position-finding algorithm work correctly. */
	func updateRadicandPosition() {
		/* Move the radicand by the width of the radical sign. */
		radicand.position = CGPoint(x: position.x + radicalShift + (radicalGlyph?.width ?? 0.0), y: position.y)
	}
	
	override var textColor: MTColor? {
		get {
			super.textColor
		}
		set(textColor) {
			super.textColor = textColor
			
			radicand.textColor = textColor
			
			degree?.textColor = textColor
		}
	}
	
	override func draw(_ context: CGContext?) {
		super.draw(context)
		
		/* Draw the radicand & degree at its position. */
		radicand.draw(context)
		
		degree?.draw(context)
		
		context?.saveGState()
		
		textColor?.setStroke()
		
		textColor?.setFill()
		
		/* Make the current position the origin (all the positions of the sub atoms are relative to the origin). */
		context?.translateBy(x: position.x + radicalShift, y: position.y)
		
		context?.textPosition = CGPoint(x: 0, y: 0)
		
		/* Draw the glyph. */
		radicalGlyph?.draw(context)
		
		/* Draw the VBOX. For the kern of it, we don't need to draw anything. */
		let heightFromTop = topKern
		
		/* Draw the horizontal line with the given thickness. */
		let path = MTBezierPath()
		
		/* Subtract half the line thickness to center the line. */
		let lineStart = CGPoint(x: radicalGlyph?.width ?? 0.0, y: ascent - heightFromTop - lineThickness / 2)
		
		let lineEnd = CGPoint(x: lineStart.x + radicand.width, y: lineStart.y)
		
		path.move(to: lineStart)
		
		path.addLine(to: lineEnd)
		
		path.lineWidth = lineThickness
		
		path.lineCapStyle = CGLineCap.round
		
		path.stroke()
		
		context?.restoreGState()
	}
}

/* Rendering a glyph as a display */
class MTGlyphDisplay: MTDisplay {
	private var glyph: CGGlyph?
	
	private var font: MTFont?
	
	override init() {
	}
	
	init(glpyh glyph: CGGlyph, range: NSRange, font: MTFont) {
		super.init()
		
		self.font = font
		
		self.glyph = glyph
		
		position = CGPoint.zero
		
		self.range = range
	}
	
	override func draw(_ context: CGContext?) {
		super.draw(context)
		
		context?.saveGState()
		
		textColor?.setFill()
		
		/* Make the current position the origin (all the positions of the sub atoms are relative to the origin). */
		context?.translateBy(x: position.x, y: position.y - shiftDown)
		
		context?.textPosition = CGPoint(x: 0, y: 0)
		
		if let ctFont = font?.ctFont, let context = context {
			CTFontDrawGlyphs(ctFont, &glyph, &CGPoint.zero, 1, context)
		}
		
		context?.restoreGState()
	}
	
	override var ascent: CGFloat {
		get {
			return super.ascent - shiftDown
		}
		set {
			super.ascent = newValue
		}
	}
	
	override var descent: CGFloat {
		get {
			return super.descent + shiftDown
		}
		set {
			super.descent = newValue
		}
	}
}

/* Rendering a large operator with limits as an MTDisplay */
class MTLargeOpLimitsDisplay: MTDisplay {
	private var limitShift: CGFloat = 0.0
	
	private var upperLimitGap: CGFloat = 0.0
	
	private var lowerLimitGap: CGFloat = 0.0
	
	private var extraPadding: CGFloat = 0.0
	
	private var nucleus: MTDisplay?
	
	/* A display representing the upper limit of the large operator. Its position is relative to the parent and is not treated as a sub-display. */
	private(set) var upperLimit: MTMathListDisplay?
	
	/* A display representing the lower limit of the large operator. Its position is relative to the parent and is not treated as a sub-display. */
	private(set) var lowerLimit: MTMathListDisplay?
	
	override init() {
	}
	
	init(nucleus: MTDisplay, upperLimit: MTMathListDisplay, lowerLimit: MTMathListDisplay, limitShift: CGFloat, extraPadding: CGFloat) {
		super.init()
		
		self.upperLimit = upperLimit
		
		self.lowerLimit = lowerLimit
		
		self.nucleus = nucleus
		
		var maxWidth = CGFloat(max(nucleus.width, upperLimit.width))
		
		maxWidth = CGFloat(max(maxWidth, lowerLimit.width))
		
		self.limitShift = limitShift
		
		upperLimitGap = 0
		
		lowerLimitGap = 0
		
		self.extraPadding = extraPadding 		// \xi_13 in TeX
		
		width = maxWidth
	}
	
	override var ascent: CGFloat {
		get {
			if let upperLimit = upperLimit {
				return (nucleus?.ascent ?? 0.0) + extraPadding + upperLimit.ascent + upperLimitGap + upperLimit.descent
			} else {
				return nucleus?.ascent ?? 0.0
			}
		}
		set {
			super.ascent = newValue
		}
	}
	
	override var descent: CGFloat {
		get {
			if let lowerLimit = lowerLimit {
				return (nucleus?.descent ?? 0.0) + extraPadding + lowerLimitGap + lowerLimit.descent + lowerLimit.ascent
			} else {
				return nucleus?.descent ?? 0.0
			}
		}
		set {
			super.descent = newValue
		}
	}
	
	func setLowerLimitGap(_ lowerLimitGap: CGFloat) {
		self.lowerLimitGap = lowerLimitGap
		
		updateLowerLimitPosition()
	}
	
	func setUpperLimitGap(_ upperLimitGap: CGFloat) {
		self.upperLimitGap = upperLimitGap
		
		updateUpperLimitPosition()
	}
	
	override var position: CGPoint {
		get {
			super.position
		}
		set(position) {
			super.position = position
			
			updateLowerLimitPosition()
			
			updateUpperLimitPosition()
			
			updateNucleusPosition()
		}
	}
	
	/* The position of the lower limit includes the position of the MTLargeOpLimitsDisplay. This is to make the positioning of the radical consistent with fractions and radicals. */
	func updateLowerLimitPosition() {
		if let lowerLimit = lowerLimit {
			/* Move the starting point to below the nucleus leaving a gap of _lowerLimitGap and subtract the ascent to to get the baseline. Also center and shift it to the left by _limitShift. */
			lowerLimit.position = CGPoint(
				x: position.x - limitShift + (width - lowerLimit.width) / 2,
				
				y: position.y - (nucleus?.descent ?? 0.0) - lowerLimitGap - lowerLimit.ascent)
		}
	}
	
	/* The position of the upper limit includes the position of the MTLargeOpLimitsDisplay. This is to make the positioning of the radical consistent with fractions and radicals. */
	func updateUpperLimitPosition() {
		if let upperLimit = upperLimit {
			/* Move the starting point to above the nucleus leaving a gap of _upperLimitGap and add the descent to to get the baseline. Also center and shift it to the right by _limitShift. */
			upperLimit.position = CGPoint(
				x: position.x + limitShift + (width - upperLimit.width) / 2,
				
				y: position.y + (nucleus?.ascent ?? 0.0) + upperLimitGap + upperLimit.descent)
		}
	}
	
	func updateNucleusPosition() {
		/* Center the nucleus. */
		nucleus?.position = CGPoint(x: position.x + (width - (nucleus?.width ?? 0.0)) / 2, y: position.y)
	}
	
	override var textColor: MTColor? {
		get {
			super.textColor
		}
		set(textColor) {
			super.textColor = textColor
			
			upperLimit?.textColor = textColor
			
			lowerLimit?.textColor = textColor
			
			nucleus?.textColor = textColor
		}
	}
	
	override func draw(_ context: CGContext?) {
		super.draw(context)
		
		/* Draw the elements. */
		upperLimit?.draw(context)
		
		lowerLimit?.draw(context)
		
		nucleus?.draw(context)
	}
}

/* Rendering of an list with an overline or underline */
class MTLineDisplay: MTDisplay {
	/* A display representing the inner list that is underlined. It's position is relative to the parent is not treated as a sub-display. */
	private(set) var inner: MTMathListDisplay?
	
	override init() {
	}
	
	init(inner: MTMathListDisplay, position: CGPoint, range: NSRange) {
		super.init()
		
		self.inner = inner
		
		self.position = position
		
		self.range = range
	}
	
	override var textColor: MTColor? {
		get {
			super.textColor
		}
		set(textColor) {
			super.textColor = textColor
			
			inner?.textColor = textColor
		}
	}
	
	override func draw(_ context: CGContext?) {
		super.draw(context)
		
		inner.draw(context)
		
		context?.saveGState()
		
		textColor?.setStroke()
		
		/* Draw the horizontal line. */
		let path = MTBezierPath()
		
		let lineStart = CGPoint(x: position.x, y: position.y + lineShiftUp)
		
		let lineEnd = CGPoint(x: lineStart.x + inner.width, y: lineStart.y)
		
		path.move(to: lineStart)
		
		path.addLine(to: lineEnd)
		
		path.lineWidth = lineThickness
		
		path.stroke()
		
		context?.restoreGState()
	}
	
	override var position: CGPoint {
		get {
			super.position
		}
		set(position) {
			super.position = position
			
			updateInnerPosition()
		}
	}
	
	func updateInnerPosition() {
		inner.position = CGPoint(x: position.x, y: position.y)
	}
}

/* Rendering an accent as a display */
class MTAccentDisplay: MTDisplay {
	/* A display representing the inner list that is accented. Its position is relative to the parent and is not treated as a sub-display. */
	private(set) var accentee: MTMathListDisplay?
	
	/* A display representing the accent. Its position is relative to the current display. */
	private(set) var accent: MTGlyphDisplay?
	
	override init() {
	}
	
	init(accent glyph: MTGlyphDisplay, accentee: MTMathListDisplay, range: NSRange) {
		super.init()
		
		accent = glyph
		
		self.accentee = accentee
		
		self.accentee?.position = CGPoint.zero
		
		self.range = range
	}
	
	override var textColor: MTColor? {
		get {
			super.textColor
		}
		set(textColor) {
			super.textColor = textColor
			
			accentee?.textColor = textColor
			
			accent?.textColor = textColor
		}
	}
	
	override var position: CGPoint {
		get {
			super.position
		}
		set(position) {
			super.position = position
			
			updateAccenteePosition()
		}
	}
	
	func updateAccenteePosition() {
		accentee.position = CGPoint(x: position.x, y: position.y)
	}
	
	override func draw(_ context: CGContext?) {
		super.draw(context)
		
		accentee.draw(context)
		
		context?.saveGState()
		
		context?.translateBy(x: position.x, y: position.y)
		
		context?.textPosition = CGPoint(x: 0, y: 0)
		
		accent.draw(context)
		
		context?.restoreGState()
	}
}

/* Rendering of an list with delimiters */
class MTInnerDisplay: MTDisplay {
	/* A display representing the inner list that can be wrapped in delimiters. Its position is relative to the parent and is not treated as a sub-display. */
	private(set) var inner: MTMathListDisplay?
	
	/* A display representing the delimiters. Their position is relative to the parent are not treated as a sub-display. */
	private(set) var leftDelimiter: MTDisplay?
	
	private(set) var rightDelimiter: MTDisplay?
	
	/* Denotes the location in the parent MTList. */
	private(set) var index = 0
	
	override init() {
	}
	
	init(inner: MTMathListDisplay, leftDelimiter: MTDisplay, rightDelimiter: MTDisplay, at index: Int) {
		super.init()
		
		self.leftDelimiter = leftDelimiter
		
		self.rightDelimiter = rightDelimiter
		
		self.inner = inner
		
		self.index = index
		
		range = NSRange(location: self.index, length: 1)
		
		width = leftDelimiter.width + inner.width + rightDelimiter.width
	}
	
	override var position: CGPoint {
		get {
			super.position
		}
		set(position) {
			super.position = position
			
			updateLeftDelimiterPosition()
			
			updateInnerPosition()
			
			updateRightDelimiterPosition()
		}
	}
	
	func updateLeftDelimiterPosition() {
		if leftDelimiter != nil {
			leftDelimiter?.position = position
		}
	}
	
	func updateRightDelimiterPosition() {
		if rightDelimiter != nil {
			rightDelimiter?.position = CGPoint(x: (inner?.position.x ?? 0.0) + (inner?.width ?? 0.0), y: position.y)
		}
	}
	
	func updateInnerPosition() {
		if leftDelimiter != nil {
			inner?.position = CGPoint(x: (leftDelimiter?.position.x ?? 0.0) + (leftDelimiter?.width ?? 0.0), y: position.y)
		} else {
			inner?.position = position
		}
	}
	
	override var ascent: CGFloat {
		get {
			if leftDelimiter != nil {
				return leftDelimiter?.ascent ?? 0.0
			}
			
			if rightDelimiter != nil {
				return rightDelimiter?.ascent ?? 0.0
			}
			
			return inner?.ascent ?? 0.0
		}
		set {
			super.ascent = newValue
		}
	}
	
	override var descent: CGFloat {
		get {
			if leftDelimiter != nil {
				return leftDelimiter?.descent ?? 0.0
			}
			
			if rightDelimiter != nil {
				return rightDelimiter?.descent ?? 0.0
			}
			
			return inner?.descent ?? 0.0
		}
		set {
			super.descent = newValue
		}
	}
	
	override var width: CGFloat {
		get {
			var w = inner?.width ?? 0.0
			
			if leftDelimiter != nil {
				w += leftDelimiter?.width ?? 0.0
			}
			
			if rightDelimiter != nil {
				w += rightDelimiter?.width ?? 0.0
			}
			
			return w
		}
		set {
			super.width = newValue
		}
	}
	
	override var textColor: MTColor? {
		get {
			super.textColor
		}
		set(textColor) {
			super.textColor = textColor
			
			leftDelimiter?.textColor = textColor
			
			rightDelimiter?.textColor = textColor
			
			inner?.textColor = textColor
		}
	}
	
	override func draw(_ context: CGContext?) {
		super.draw(context)
		
		/* Draw the elements. */
		leftDelimiter?.draw(context)
		
		rightDelimiter?.draw(context)
		
		inner?.draw(context)
	}
}

var isIos6SupportedInitialized = false

var supported = false

private func isIos6Supported() -> Bool {
	if !isIos6SupportedInitialized {
#if os(iOS)
		let reqSysVer = "6.0"
		
		let currSysVer = UIDevice.current.systemVersion
		
		if currSysVer.compare(reqSysVer, options: .numeric, range: nil, locale: .current) != .orderedAscending {
			supported = true
		}
#else
		supported = true
#endif
		
		isIos6SupportedInitialized = true
	}
	return supported
}

class MTGlyphConstructionDisplay {
	private var glyphs: CGGlyph?
	
	private var positions = CGPoint.zero
	
	private var font: MTFont?
	
	private var numGlyphs = 0
	
	init(glyphs: [NSNumber], offsets: [NSNumber], font: MTFont) {
		super.init()
		
		assert(glyphs.count == offsets.count, "Glyphs and offsets need to match")
		
		numGlyphs = glyphs.count
		
		self.glyphs = malloc(MemoryLayout<CGGlyph>.size * numGlyphs)
		
		positions = malloc(MemoryLayout<CGPoint>.size * numGlyphs)
		
		for i in 0..<numGlyphs {
			self.glyphs?[i] = glyphs[i].int16Value
			
			positions[i] = CGPoint(x: 0, y: CGFloat(offsets[i].floatValue))
		}
		
		self.font = font
		
		position = CGPoint.zero
	}
	
	func draw(_ context: CGContext?) {
		super.draw(context)
		
		context?.saveGState()
		
		textColor.setFill()
		
		/* Make the current position the origin (all the positions of the sub atoms are relative to the origin). */
		context?.translateBy(x: position.x, y: position.y - shiftDown)
		
		context?.textPosition = CGPoint(x: 0, y: 0)
		
		/* Draw the glyphs. */
		if let ctFont = font?.ctFont, let context = context {
			CTFontDrawGlyphs(ctFont, &glyphs, &positions, numGlyphs, context)
		}
		
		context?.restoreGState()
	}
	
	func ascent() -> CGFloat {
		return super.ascent - shiftDown
	}
	
	func descent() -> CGFloat {
		return super.descent + shiftDown
	}
	
	deinit {
		free(glyphs)
		
		free(positions)
	}
}
