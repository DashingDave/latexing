//
//	MTMathList.swift
//	ObjC -> Swift conversion of
//
//  MathList.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 8/26/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import CoreGraphics
import SwiftUI

/* The type of atom in a `MTMathList`. The type of the atom determines how it is rendered and spacing between the atoms. */
enum MTMathAtomType : Int {
	case ordinary = 1		// A number or text in ordinary format - Ord in TeX
	
	case number				// A number - Does not exist in TeX
	
	case variable			// A variable (i.e. text in italic format) - Does not exist in TeX
	
	case largeOperator		// A large operator such as (sin/cos, integral etc.) - Op in TeX
	
	case binaryOperator		// A binary operator - Bin in TeX
	
	case unaryOperator		// A unary operator - Does not exist in TeX
	
	case relation			// A relation, e.g. = > < etc. - Rel in TeX
	
	case `open`				// Open brackets - Open in TeX
	
	case close				// Close brackets - Close in TeX
	
	case fraction			// An fraction e.g 1/2 - generalized fraction noad in TeX
	
	case radical			// A radical operator e.g. sqrt(2)
	
	case punctuation		// Punctuation such as , - Punct in TeX
	
	case placeholder		// A placeholder square for future input. Does not exist in TeX
	
	case inner				// An inner atom, i.e. an embedded math list - Inner in TeX
	
	case underline			// An underlined atom - Under in TeX
	
	case overline			// An overlined atom - Over in TeX
	
	case accent				// An accented atom - Accent in TeX
	
	/* ATOMS AFTER THIS POINT do not support subscripts or superscripts */
	
	/* A left atom - Left & Right in TeX. We don't need two since we track boundaries separately. */
	case boundary = 101
	
	/* ATOMS AFTER THIS POINT are non-math TeX nodes that are still useful in math mode. They do not have the usual structure. */
	
	/* Spacing between math atoms. This denotes both glue and kern for TeX. We don't distinguish between glue and kern. */
	case space = 201
	
	/* Denote style changes during rendering. */
	case style
	case color
	case colorbox
	
	/* ATOMS AFTER THIS POINT are not part of TeX and do not have the usual structure. */
	
	/* An table atom. This atom does not exist in TeX. It is equivalent to the TeX command halign which is handled outside of the TeX math rendering engine. We bring it into our math typesetting to handle matrices and other tables. */
	case table = 1001
}

/* The font style of a character. The fontstyle of the atom determines what style the character is rendered in. This only applies to atoms of type kMTMathAtomVariable and kMTMathAtomNumber. None of the other atom types change their font style. */
enum MTFontStyle : Int {
	
	case `default` = 0			// The default latex rendering style. i.e. variables are italic and numbers are roman.
	
	case roman			// Roman font style i.e. \mathrm
	
	case bold		// Bold font style i.e. \mathbf
	
	case caligraphic		// Caligraphic font style i.e. \mathcal
	
	case typewriter			// Typewriter (monospace) style i.e. \mathtt
	
	case italic			// Italic style i.e. \mathit
	
	case sansSerif			// Sans-serif font i.e. \mathss
	
	case fraktur		// Fractur font i.e \mathfrak
	
	case blackboard			// Blackboard font i.e. \mathbb
	
	case boldItalic			// Bold italic
}

/* Styling of a line of math */
enum MTLineStyle : Int {
	
	case display		// Display style
	
	case text		// Text style (inline)
	
	case script			// Script style (for sub/super scripts)
	
	case scriptScript		// Script script style (for scripts of scripts)
}

/* A `MTMathAtom` IS THE BASIC UNIT of a math list. Each atom represents a single character or mathematical operator in a list. However certain atoms can represent more complex structures such as fractions and radicals. Each atom has a type which determines how the atom is rendered and a nucleus. The nucleus contains the character(s) that need to be rendered. However the nucleus may be empty for certain types of atoms. An atom has an optional subscript or superscript which represents the subscript or superscript that is to be rendered. */

/* Certain types of atoms inherit from `MTMathAtom` and may have additional fields. */
class MTMathAtom: NSObject, NSCopying {
	/* Returns a string representation of the MTMathAtom */
	var stringValue: String {
		var str = nucleus
		
		if let superScript = superScript {
			str.appendFormat("^{%@}", superScript.stringValue)
		}
		
		if let subScript = subScript {
			str.appendFormat("_{%@}", subScript.stringValue)
		}
		
		return str
	}
	
	/* The type of the atom. */
	var type: MTMathAtomType!
	
	/* The nucleus of the atom. */
	var nucleus: String = ""
	
	/* An optional superscript. */
	private var _superScript: MTMathList?
	
	var superScript: MTMathList? {
		get {
			_superScript
		}
		set(superScript) {
			if superScript != nil && !scriptsAllowed() {
				throw NSException(
					name: NSExceptionName("Error"),
					reason: "Superscripts not allowed for atom of type \(typeToText(type))",
					userInfo: nil)
			}
			
			_superScript = superScript
		}
	}
	
	/* An optional subscript. */
	private var _subScript: MTMathList?
	
	var subScript: MTMathList? {
		get {
			_subScript
		}
		set(subScript) {
			if subScript != nil && !scriptsAllowed() {
				throw NSException(
					name: NSExceptionName("Error"),
					reason: "Subscripts not allowed for atom of type \(typeToText(type))",
					userInfo: nil)
			}
			
			_subScript = subScript
		}
	}
	
	/* The font style to be used for the atom. */
	var fontStyle: MTFontStyle!
	
	/* If this atom was formed by fusion of multiple atoms, then this stores the list of atoms that were fused to create this one. This is used in the finalizing and preprocessing steps. */
	private(set) var fusedAtoms: [MTMathAtom]?
	
	/* The index range in the MTMathList this MTMathAtom tracks. This is used by the finalizing and preprocessing steps which fuse `MTMathAtom`s to track the position of the current MTMathAtom in the original list. */
	private(set) var indexRange: NSRange?
	
	/* Factory function to create an atom with a given type and value. Parameters - (type: The type of the atom to instantiate, value: The value of the atoms nucleus. The value is ignored for fractions and radicals.) */
	convenience init(type: MTMathAtomType, value: String) {
		switch type {
			case MTMathAtomType.fraction:
				MTFraction()
				return
			
			case MTMathAtomType.placeholder:
				/* A placeholder is created with a white square. */
				self.init(type: MTMathAtomType.placeholder, value: "\u{25A1}")
				return
			
			case MTMathAtomType.radical:
				MTRadical()
				return
			
			case MTMathAtomType.largeOperator:
				/* Default setting of limits is true */
				MTLargeOperator(value: value, limits: true)
				return
			
			case MTMathAtomType.inner:
				MTInner()
				return
			
			case MTMathAtomType.overline:
				MTOverLine()
				return
			
			case MTMathAtomType.underline:
				MTUnderLine()
				return
			
			case MTMathAtomType.accent:
				MTAccent(value: value)
				return
			
			case MTMathAtomType.space:
				MTMathSpace(space: 0)
				return
			
			case MTMathAtomType.color:
				MTMathColor()
				return
			
			case MTMathAtomType.colorbox:
				MTMathColorbox()
				return
			
			default:
				self.init(type: type, value: value)
				return
		}
	}
	
	init(type: CXHandle.HandleType, value: String) {
		super.init()
		
		self.type = MTMathAtomType!(rawValue: type.rawValue)
		nucleus = value
	}
	
	/* Do not use init. Use `atomWithType:value:` to instantiate atoms. */
	convenience init() {
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTMathAtom init] cannot be called. Use [MTMathAtom initWithType:value:] instead.",
			userInfo: nil)
	}
	
	/* Makes a _deep_ copy of the atom */
	func copy(with zone: NSZone? = nil) -> Any {
		let atom = self.init(type: type, value: nucleus)
		
		atom.type = type
		
		atom.nucleus = nucleus
		
		atom.subScript = subScript?.copy(with: zone) as? MTMathList
		
		atom.superScript = superScript?.copy(with: zone) as? MTMathList
		
		atom.indexRange = indexRange
		
		atom.fontStyle = fontStyle
		
		return atom
	}
	
	/* Returns true if this atom allows scripts (sub or super). */
	func scriptsAllowed() -> Bool {
		return type < MTMathAtomType.boundary
	}
	
	override var description: String {
		var str = typeToText(type)
		
		str += ": \(stringValue)"
		
		return str
	}
	
	/* Fuse the given atom with this one by combining their nucleii. */
	func fuse(_ atom: MTMathAtom) {
		assert(!subScript! != nil, "Cannot fuse into an atom which has a subscript: \(self)")
		
		assert(!superScript! != nil, "Cannot fuse into an atom which has a superscript: \(self)")
		
		assert(atom.type == type, "Only atoms of the same type can be fused. \(self), \(atom)")
		
		/* Update the fused atoms list */
		if fusedAtoms == nil {
			fusedAtoms = [self]
		}
		
		if atom.fusedAtoms != nil {
			if let aFusedAtoms = atom.fusedAtoms {
				fusedAtoms?.append(contentsOf: aFusedAtoms)
			}
		} else {
			fusedAtoms?.append(atom)
		}
		
		/* Update the nucleus */
		var str = nucleus
		
		str += atom.nucleus
		
		nucleus = str
		
		/* Update the range */
		let newRange = indexRange
		
		newRange.length += atom.indexRange?.length ?? 0
		
		indexRange = newRange
		
		/* Update super-, subscripts */
		subScript = atom.subScript
		
		superScript = atom.superScript
	}
	
	/* Returns a finalized copy of the atom */
	func finalized() -> Self {
		let newNode = self
		
		if newNode.superScript != nil {
			newNode.superScript = newNode.superScript?.finalized()
		}
		
		if newNode.subScript != nil {
			newNode.subScript = newNode.subScript?.finalized()
		}
		
		return newNode
	}
}

/* An atom of type fraction. This atom has a numerator and denominator. */
class MTFraction: MTMathAtom {
	/* */
	var numerator: MTMathList?			// Numerator of the fraction
	
	/* */
	var denominator: MTMathList?		// Denominator of the fraction
	
	/* If true, the fraction has a rule (i.e. a line) between the numerator and denominator. The default value is true. */
	private(set) var hasRule = false
	
	/* */
	var leftDelimiter: String?			// An optional delimiter for a fraction on the left.
	
	/* */
	var rightDelimiter: String?			// An optional delimiter for a fraction on the right.
	
	convenience init() {
		self.init(rule: true)
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.fraction {
			self.init()
			
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTFraction initWithType:value:] cannot be called. Use [MTFraction init] instead.",
			userInfo: nil)
	}
	
	/* Creates an empty fraction with the given value of hasRule. */
	required init(rule hasRule: Bool) {
		/* fractions have no nucleus */
		super.init(type: MTMathAtomType.fraction, value: "")
		
		self.hasRule = hasRule
	}
	
	override var stringValue: String {
		get {
			var str = ""
			
			if hasRule {
				str += "\\atop"
			} else {
				str += "\\frac"
			}
			
			if leftDelimiter != nil || rightDelimiter != nil {
				str += "[\(leftDelimiter ?? "")][\(rightDelimiter ?? "")]"
			}
			
			str.appendFormat("{%@}{%@}", numerator.stringValue, denominator.stringValue)
			
			if let superScript = superScript {
				str.appendFormat("^{%@}", superScript?.stringValue)
			}
			
			if let subScript = subScript {
				str.appendFormat("_{%@}", subScript?.stringValue)
			}
			
			return str
		}
		set {
			super.stringValue = newValue
		}
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let frac = super.copy(with: zone) as? MTFraction
		
		frac?.numerator = numerator.copy(with: zone) as? MTMathList
		
		frac?.denominator = denominator.copy(with: zone) as? MTMathList
		
		frac?.hasRule = hasRule
		
		frac?.leftDelimiter = leftDelimiter?.copy(with: zone) as? String
		
		frac?.rightDelimiter = rightDelimiter?.copy(with: zone) as? String
		
		return frac!
	}
	
	override func finalized() -> Self {
		let newFrac = super.finalized() as? MTFraction
		
		newFrac?.numerator = newFrac?.numerator?.finalized()
		
		newFrac?.denominator = newFrac?.denominator?.finalized()
		
		return newFrac!
	}
}

/* An atom of type radical (square root). */
class MTRadical: MTMathAtom {
	/* Denotes the term under the square root sign */
	var radicand: MTMathList?
	
	/* Denotes the degree of the radical, i.e. the value to the top left of the radical sign. This can be null if there is no degree. */
	var degree: MTMathList?
	
	required init() {
		/* radicals have no nucleus */
		super.init(type: MTMathAtomType.radical, value: "")
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.radical {
			self.init()
			
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTRadical initWithType:value:] cannot be called. Use [MTRadical init] instead.",
			userInfo: nil)
	}
	
	override var stringValue: String {
		get {
			var str = "\\sqrt"
			
			if let degree = degree {
				str += "[\(degree.stringValue)]"
			}
			
			str.appendFormat("{%@}", radicand?.stringValue)
			
			if let superScript = superScript {
				str.appendFormat("^{%@}", superScript?.stringValue)
			}
			
			if let subScript = subScript {
				str.appendFormat("_{%@}", subScript?.stringValue)
			}
			
			return str
		}
		set {
			super.stringValue = newValue
		}
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let rad = super.copy(with: zone) as? MTRadical
		
		rad?.radicand = radicand?.copy(with: zone) as? MTMathList
		
		rad?.degree = degree?.copy(with: zone) as? MTMathList
		
		return rad!
	}
	
	override func finalized() -> Self {
		let newRad = super.finalized() as? MTRadical
		
		newRad?.radicand = newRad?.radicand?.finalized()
		
		newRad?.degree = newRad?.degree?.finalized()
		
		return newRad!
	}
}

/* A `MTMathAtom` of type `kMTMathAtomLargeOperator`. */
class MTLargeOperator: MTMathAtom {
	/* Indicates whether the limits (if present) should be displayed above and below the operator in display mode. If limits is false, then the limits (if present) and displayed like a regular subscript/superscript. */
	var limits = false
	
	/* Designated initializer. Initialize a large operator with the given value and setting for limits. */
	required init(value: String, limits: Bool) {
		super.init(type: MTMathAtomType.largeOperator, value: value)

		self.limits = limits
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.largeOperator {
			self.init(value: value, limits: false)

			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTLargeOperator initWithType:value:] cannot be called. Use [MTLargeOperator initWithValue:limits:] instead.",
			userInfo: nil)
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let op = super.copy(with: zone) as? MTLargeOperator

		op?.limits = limits

		return op!
	}
}

/* An inner atom. This denotes an atom which contains a math list inside it. An inner atom has optional boundaries. Only one boundary may be present, it is not required to have both. */
class MTInner: MTMathAtom {
	/* The inner math list */
	var innerList: MTMathList?
	
	/* The left boundary atom. This must be a node of type kMTMathAtomBoundary. */
	private var _leftBoundary: MTMathAtom?
	
	var leftBoundary: MTMathAtom? {
		get {
			_leftBoundary
		}
		set(leftBoundary) {
			if leftBoundary != nil && leftBoundary?.type != MTMathAtomType.boundary {
				throw NSException(
					name: NSExceptionName("Error"),
					reason: "Left boundary must be of type kMTMathAtomBoundary",
					userInfo: nil)
			}
			
			_leftBoundary = leftBoundary
		}
	}

	/* The right boundary atom. This must be a node of type kMTMathAtomBoundary. */
	private var _rightBoundary: MTMathAtom?

	var rightBoundary: MTMathAtom? {
		get {
			_rightBoundary
		}
		set(rightBoundary) {
			if rightBoundary != nil && rightBoundary?.type != MTMathAtomType.boundary {
				throw NSException(
					name: NSExceptionName("Error"),
					reason: "Left boundary must be of type kMTMathAtomBoundary",
					userInfo: nil)
			}

			_rightBoundary = rightBoundary
		}
	}
	
	/* Creates an empty inner. */
	required init() {
		/* Inner atoms have no nucleus. */
		super.init(type: MTMathAtomType.inner, value: "")
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.inner {
			self.init()
			
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTInner initWithType:value:] cannot be called. Use [MTInner init] instead.",
			userInfo: nil)
	}
	
	override var stringValue: String {
		get {
			var str = "\\inner"
			
			if let leftBoundary = leftBoundary {
				str += "[\(leftBoundary.nucleus)]"
			}
			
			str.appendFormat("{%@}", innerList?.stringValue)
			
			if let rightBoundary = rightBoundary {
				str += "[\(rightBoundary.nucleus)]"
			}
			
			if let superScript = superScript {
				str.appendFormat("^{%@}", superScript?.stringValue)
			}
			
			if let subScript = subScript {
				str.appendFormat("_{%@}", subScript?.stringValue)
			}
			
			return str
		}
		set {
			super.stringValue = newValue
		}
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let inner = super.copy(with: zone) as? MTInner
		
		inner?.innerList = innerList?.copy(with: zone) as? MTMathList
		
		inner?.leftBoundary = leftBoundary?.copy(with: zone) as? MTMathAtom
		
		inner?.rightBoundary = rightBoundary?.copy(with: zone) as? MTMathAtom
		
		return inner!
	}
	
	override func finalized() -> Self {
		let newInner = super.finalized() as? MTInner
		
		newInner?.innerList = newInner?.innerList?.finalized()
		
		return newInner!
	}
}

/* An atom with a line over the contained math list. */
class MTOverLine: MTMathAtom {
	/* The inner math list */
	var innerList: MTMathList?
	
	/* Creates an empty over */
	required init() {
		super.init(type: MTMathAtomType.overline, value: "")
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.overline {
			self.init()
			
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTOverline initWithType:value:] cannot be called. Use [MTOverline init] instead.",
			userInfo: nil)
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let op = super.copy(with: zone) as? MTOverLine
		
		op?.innerList = innerList?.copy(with: zone) as? MTMathList
		
		return op!
	}
	
	override func finalized() -> Self {
		let newOverline = super.finalized() as? MTOverLine
		newOverline?.innerList = newOverline?.innerList?.finalized()
		
		return newOverline!
	}
}

/* An atom with a line under the contained math list. */
class MTUnderLine: MTMathAtom {
	/* The inner math list */
	var innerList: MTMathList?
	
	/* Creates an empty under */
	required init() {
		super.init(type: MTMathAtomType.underline, value: "")
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.underline {
			self.init()
	
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTUnderline initWithType:value:] cannot be called. Use [MTUnderline init] instead.",
			userInfo: nil)
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let op = super.copy(with: zone) as? MTUnderLine
		
		op?.innerList = innerList?.copy(with: zone) as? MTMathList
		
		return op!
	}
	
	override func finalized() -> Self {
		let newUnderline = super.finalized() as? MTUnderLine
		newUnderline?.innerList = newUnderline?.innerList?.finalized()
		
		return newUnderline!
	}
}

/* An atom with an accent. */
class MTAccent: MTMathAtom {
	/* The mathlist under the accent. */
	var innerList: MTMathList?
	
	required init(value: String) {
		super.init(type: MTMathAtomType.accent, value: value)
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.accent {
			self.init(value: value)
			
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTAccent initWithType:value:] cannot be called. Use [MTAccent initWithValue:] instead.",
			userInfo: nil)
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let op = super.copy(with: zone) as? MTAccent
		
		op?.innerList = innerList?.copy(with: zone) as? MTMathList
		
		return op!
	}
	
	override func finalized() -> Self {
		let newAccent = super.finalized() as? MTAccent
		
		newAccent?.innerList = newAccent?.innerList?.finalized()
		
		return newAccent!
	}
}

/* An atom representing space. None of the usual fields of the `MTMathAtom` apply even though this class inherits from `MTMathAtom`. i.e. it is meaningless to have a value in the nucleus, subscript or superscript fields. */
class MTMathSpace: MTMathAtom {
	/* The amount of space represented by this object in mu units. */
	private(set) var space: CGFloat = 0.0
	
	/* Creates a new `MTMathSpace` with the given spacing. Parameter - (space: The amount of space in mu units). */
	required init(space: CGFloat) {
		super.init(type: MTMathAtomType.space, value: "")
		
		self.space = space
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.space {
			self.init(space: 0)
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTMathSpace initWithType:value:] cannot be called. Use [MTMathSpace initWithSpace:] instead.",
			userInfo: nil)
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let op = super.copy(with: zone) as? MTMathSpace
		
		op?.space = space
		
		return op!
	}
}

class MTMathStyle: MTMathAtom {
	/* The style represented by this object. */
	private(set) var style: MTLineStyle!
	
	/* Creates a new `MTMathStyle` with the given style. Parameter - (style: The style to be applied to the rest of the list). */
	required init(style: MTLineStyle) {
		super.init(type: MTMathAtomType.style, value: "")
		
		self.style = style
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.style {
			self.init(style: .display)
		
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTMathStyle initWithType:value:] cannot be called. Use [MTMathStyle initWithStyle:] instead.",
			userInfo: nil)
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let op = super.copy(with: zone) as? MTMathStyle
		
		op?.style = style
		
		return op!
	}
}

/* An atom representing an color element. None of the usual fields of the `MTMathAtom` apply even though this class inherits from `MTMathAtom`. i.e. it is meaningless to have a value in the nucleus, subscript or superscript fields. */
class MTMathColor: MTMathAtom {
	/* The style represented by this object. */
	var colorString: String?
	
	/* The inner math list */
	var innerList: MTMathList?
	
	/* Creates an empty color with a nil environment */
	required init() {
		super.init(type: MTMathAtomType.color, value: "")
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.color {
			self.init()
	
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTMathColor initWithType:value:] cannot be called. Use [MTMathColor init] instead.",
			userInfo: nil)
	}
	
	override var stringValue: String {
		get {
			var str = "\\color"
			
			str.appendFormat("{%@}{%@}", colorString, innerList?.stringValue)
			
			return str
		}
		set {
			super.stringValue = newValue
		}
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let op = super.copy(with: zone) as? MTMathColor
		
		op?.innerList = innerList?.copy(with: zone) as? MTMathList
		
		op?.colorString = colorString
		
		return op!
	}
	
	override func finalized() -> Self {
		let newInner = super.finalized() as? MTMathColor
		newInner?.innerList = newInner?.innerList?.finalized()
		return newInner!
	}
}

/* An atom representing an colorbox element. None of the usual fields of the `MTMathAtom` apply even though this class inherits from `MTMathAtom`. i.e. it is meaningless to have a value in the nucleus, subscript or superscript fields. */
class MTMathColorbox: MTMathAtom {
	/* The style represented by this object. */
	var colorString: String?
	
	/* The inner math list */
	var innerList: MTMathList?
	
	/* Creates an empty color with a nil environment */
	required init() {
		super.init(type: MTMathAtomType.colorbox, value: "")
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.colorbox {
			self.init()
	
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTMathColorbox initWithType:value:] cannot be called. Use [MTMathColorbox init] instead.",
			userInfo: nil)
	}
	
	override var stringValue: String {
		get {
			var str = "\\colorbox"
			
			str.appendFormat("{%@}{%@}", colorString, innerList?.stringValue)
			
			return str
		}
		set {
			super.stringValue = newValue
		}
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let op = super.copy(with: zone) as? MTMathColorbox
		
		op?.innerList = innerList?.copy(with: zone) as? MTMathList
		
		op?.colorString = colorString
		
		return op!
	}
	
	override func finalized() -> Self {
		let newInner = super.finalized() as? MTMathColorbox
		
		newInner?.innerList = newInner?.innerList?.finalized()
		
		return newInner!
	}
}

/* AN ATOM REPRESENTING A TABLE element. This atom is not like other atoms and is not present in TeX. We use it to represent the `\halign` command in TeX with some simplifications. This is used for matrices, equation alignments and other uses of multiline environments. */
/* THE CELLS IN THE TABLE are represented as a two dimensional array of `MTMathList` objects. The `MTMathList`s could be empty to denote a missing value in the cell. Additionally an array of alignments indicates how each column will be aligned. */

/* Alignment for a column of MTMathTable */
enum MTColumnAlignment : Int {
	case left			// align left
	case center			// align center
	case right			// align right
}

/* Creates an empty table with a nil environment */
class MTMathTable: MTMathAtom {
	/* The alignment for each column (left, right, center). The default alignment for a column (if not set) is center. */
	private(set) var alignments: [NSNumber] = []
	
	/* The cells in the table as a two dimensional array. */
	private(set) var cells: [[MTMathList]] = []
	
	/* The name of the environment that this table denotes. */
	var environment: String?
	
	/* Spacing between each column in mu units. */
	var interColumnSpacing: CGFloat = 0.0
	
	/* Additional spacing between rows in jots (one jot is 0.3 times font size). If the additional spacing is 0, then normal row spacing is used are used. */
	var interRowAdditionalSpacing: CGFloat = 0.0
	
	/* Creates a table with a given environment */
	required init(environment env: String?) {
		super.init(type: MTMathAtomType.table, value: "")
		
		alignments = []
		
		cells = []
		
		interRowAdditionalSpacing = 0
		
		interColumnSpacing = 0
		
		environment = env
	}
	
	convenience init() {
		self.init(environment: nil)
	}
	
	convenience init(type: CXHandle.HandleType, value: String) {
		if type == MTMathAtomType.table {
			self.init()
			
			return
		}
		throw NSException(
			name: NSExceptionName("InvalidMethod"),
			reason: "[MTMathTable initWithType:value:] cannot be called. Use [MTMathTable init] instead.",
			userInfo: nil)
	}
	
	override func copy(with zone: NSZone? = nil) -> Any {
		let op = super.copy(with: zone) as? MTMathTable
		
		op?.interRowAdditionalSpacing = interRowAdditionalSpacing
		
		op?.interColumnSpacing = interColumnSpacing
		
		op?.environment = environment
		
		op?.alignments = alignments
		
		/* Perform a deep copy of the cells. */
		var cellCopy = [AnyHashable](repeating: 0, count: cells.count)
		
		for row in cells {
			cellCopy.append(row /* copyItems: true */)
		}
		
		if let cellCopy = cellCopy as? [[MTMathList]] {
			op?.cells = cellCopy
		}
		
		return op!
	}
	
	override func finalized() -> Self {
		let table = super.finalized() as? MTMathTable
		
		for row in table?.cells ?? [] {
			for i in 0..<row.count {
				row[i] = row[i].finalized()
			}
		}
		
		return table!
	}
	
	/* Set the value of a given cell. The table is automatically resized to contain this cell. */
	func setCell(_ list: MTMathList, forRow row: Int, column: Int) {
		assert(list != nil, "Invalid parameter not satisfying: list != nil")
		
		if cells.count <= row {
			/* Add more rows */
			for i in cells.count...row {
				cells[i] = []
			}
		}
		
		var rowArray = cells[row]
		
		if rowArray.count <= column {
			/* Add more columns */
			for i in rowArray.count..<column {
				rowArray[i] = MTMathList()
			}
		}
		
		rowArray[column] = list
	}
	
	/* Set the alignment of a particular column. The table is automatically resized to contain this column and any new columns added have their alignment set to center. */
	func setAlignment(_ alignment: MTColumnAlignment, forColumn column: Int) {
		if alignments.count < column {
			/* Add more columns */
			for i in alignments.count..<column {
				alignments[i] = NSNumber(value: MTColumnAlignment.center.rawValue)
			}
		}
		
		alignments[column] = NSNumber(value: alignment.rawValue)
	}
	
	/* Gets the alignment for a given column. If the alignment is not specified it defaults to center. */
	func getAlignmentForColumn(_ column: Int) -> MTColumnAlignment {
		if alignments.count <= column {
			return MTColumnAlignment.center
		} else {
			return (MTColumnAlignment(rawValue: alignments[column].intValue))!
		}
	}
	
	/* Number of columns in the table. */
	func numColumns() -> Int {
		var numColumns = 0
		
		for row in cells {
			numColumns = Int(max(numColumns, row.count))
		}
		
		return numColumns
	}
	
	/* Number of rows in the table. */
	func numRows() -> Int {
		return cells.count
	}
}

/* A representation of a list of math objects. This class is for ADVANCED usage only. */
/* This list can be constructed directly or built with the help of the MTMathListBuilder. It is not required that the mathematics represented make sense (i.e. this can represent something like "x 2 = +". This list can be used for display using MTLine or can be a list of tokens to be used by a parser after finalizedMathList is called. */
class MTMathList: NSObject, NSCopying {
	/* A list of MathAtoms */
	private(set) var atoms: [MTMathAtom] = nil
	
	/* converts the MTMathList to a string form. Note: This is not the LaTeX form. */
	var stringValue: String {
		var str = ""
		
		for atom in atoms {
			str += atom.stringValue
		}
		
		return str
	}
	
	/* Create a `MTMathList` given a list of atoms. The list of atoms should be terminated by `nil`. */
	convenience init(atoms firstAtom: MTMathAtom) {
		let list = self.init()
		
		let args: va_list
		
		va_start(args, firstAtom)
		
		var atom = firstAtom
		
		while atom != nil {
			list.add(atom)
		
			atom = va_arg(args, MTMathAtom)
		}
		
		va_end(args)
		
		return list
	}
	
	/* Create a `MTMathList` given a list of atoms. */
	convenience init(atomsArray atoms: [MTMathAtom]) {
		let list = self.init()
		
		list.atoms.append(contentsOf: atoms)
		
		return list
	}
	
	/* Initializes an empty math list. */
	required init() {
		super.init()
		
		atoms = []
	}
	
	func isAtomAllowed(_ atom: MTMathAtom) -> Bool {
		return atom.type != MTMathAtomType.boundary
	}
	
	/* Add an atom to the end of the list. */
	/* Throws `NSException` if the atom is of type `kMTMathAtomBoundary`; throws `NSInvalidArgumentException` if the atom is `nil`. Parameter - (atom: The atom to be inserted). This cannot be `nil` and cannot have the type `kMTMathAtomBoundary`. */
	func add(_ atom: MTMathAtom) {
		assert(atom != nil, "Invalid parameter not satisfying: atom != nil")

		if !isAtomAllowed(atom) {
			throw NSException(
				name: NSExceptionName("Error"),
				reason: "Cannot add atom of type \(typeToText(atom.type)) in a mathlist",
				userInfo: nil)
		}

		atoms.append(atom)
	}
	
	/* Inserts an atom at the given index. If index is already occupied, the objects at index and beyond are shifted by adding 1 to their indices to make room. */
	/* Throws `NSException` if the atom is of type kMTMathAtomBoundary, `NSInvalidArgumentException` if the atom is nil, and ` NSRangeException` if the index is greater than the number of atoms in the math list. */
	/* Parameters - (atom: The atom to be inserted; this cannot be `nil` and cannot have the type `kMTMathAtomBoundary`, index: The index where the atom is to be inserted. The index should be less than or equal to the number of elements in the math list. */
	func insert(_ atom: MTMathAtom, at index: Int) {
		if !isAtomAllowed(atom) {
			throw NSException(
				name: NSExceptionName("Error"),
				reason: "Cannot add atom of type \(typeToText(atom.type)) in a mathlist",
				userInfo: nil)
		}
		atoms.insert(atom, at: index)
	}
	
	/* Append the given list to the end of the current list. Parameter - (list: The list to append). */
	func append(_ list: MTMathList) {
		atoms.append(contentsOf: list.atoms)
	}
	
	/* Removes the last atom from the math list. If there are no atoms in the list this does nothing. */
	func removeLastAtom() {
		if atoms.count > 0 {
			atoms.removeLast()
		}
	}
	
	/* Removes the atom at the given index. Parameter - (index: The index at which to remove the atom; must be less than the number of atoms) in the list. */
	func removeAtom(at index: Int) {
		atoms.remove(at: index)
	}
	
	/* Removes all the atoms within the given range. */
	func removeAtoms(in range: NSRange) {
		if let subRange = Range(range) { atoms.removeSubrange(subRange) }
	}
	
	override var description: String {
		return atoms.description
	}
	
	/* Create a new math list as a final expression and update atoms by combining like atoms that occur together and converting unary operators to binary operators. This function does not modify the current MTMathList */
	func finalized() -> MTMathList {
		let finalized = MTMathList()
		
		let zeroRange = NSRange(location: 0, length: 0)
		
		var prevNode: MTMathAtom? = nil
		
		for atom in atoms {
			let newNode = atom.finalized()
		
			/* Each character is given a separate index. */
			if let anIndexRange = atom.indexRange {
				if NSEqualRanges(zeroRange, anIndexRange) {
					let index = (prevNode == nil) ? 0 : (prevNode?.indexRange?.location ?? 0) + (prevNode?.indexRange?.length ?? 0)
					
					newNode.indexRange = NSRange(location: index, length: 1)
				}
			}
			
			switch newNode.type {
				case MTMathAtomType.binaryOperator:
					if let prevNode = prevNode {
						if isNotBinaryOperator(prevNode) {
							newNode.type = MTMathAtomType.unaryOperator
						}
					}
				
				case MTMathAtomType.relation, MTMathAtomType.punctuation, MTMathAtomType.close:
					if prevNode != nil && prevNode?.type == MTMathAtomType.binaryOperator {
						prevNode?.type = MTMathAtomType.unaryOperator
					}
				
				case MTMathAtomType.number:
					/* combine numbers together */
					if prevNode != nil && prevNode?.type == MTMathAtomType.number && prevNode?.subScript == nil && prevNode?.superScript == nil {
						prevNode?.fuse(newNode)
						
						/* skip the current node, we are done here. */
						continue
					}
				
				default:
					break
			}
			
			finalized.add(newNode)
			
			prevNode = newNode
		}
		
		if prevNode != nil && prevNode?.type == MTMathAtomType.binaryOperator {
			/* It isn't a binary, because there's nothing after it. Make it a unary. */
			prevNode?.type = MTMathAtomType.unaryOperator
		}
		
		return finalized
	}
	
	/* Makes a deep copy of the list. */
	func copy(with zone: NSZone? = nil) -> Any {
		let list = self.init()
		
		list.atoms = atoms /* copyItems: true */
		
		return list
	}
}

/* Returns true if the current binary operator is not really binary. */
private func isNotBinaryOperator(_ prevNode: MTMathAtom) -> Bool {
	if prevNode == nil {
		return true
	}
	
	if prevNode.type == MTMathAtomType.binaryOperator || prevNode.type == MTMathAtomType.relation || prevNode.type == MTMathAtomType.`open` || prevNode.type == MTMathAtomType.punctuation || prevNode.type == MTMathAtomType.largeOperator {
		return true
	}
	
	return false
}

private func typeToText(_ type: MTMathAtomType) -> String {
	switch type {
		case MTMathAtomType.ordinary:
			return "Ordinary"
		case MTMathAtomType.number:
			return "Number"
		case MTMathAtomType.variable:
			return "Variable"
		case MTMathAtomType.binaryOperator:
			return "Binary Operator"
		case MTMathAtomType.unaryOperator:
			return "Unary Operator"
		case MTMathAtomType.relation:
			return "Relation"
		case MTMathAtomType.`open`:
			return "Open"
		case MTMathAtomType.close:
			return "Close"
		case MTMathAtomType.fraction:
			return "Fraction"
		case MTMathAtomType.radical:
			return "Radical"
		case MTMathAtomType.punctuation:
			return "Punctuation"
		case MTMathAtomType.placeholder:
			return "Placeholder"
		case MTMathAtomType.largeOperator:
			return "Large Operator"
		case MTMathAtomType.inner:
			return "Inner"
		case MTMathAtomType.underline:
			return "Underline"
		case MTMathAtomType.overline:
			return "Overline"
		case MTMathAtomType.accent:
			return "Accent"
		case MTMathAtomType.boundary:
			return "Boundary"
		case MTMathAtomType.space:
			return "Space"
		case MTMathAtomType.style:
			return "Style"
		case MTMathAtomType.color:
			return "Color"
		case MTMathAtomType.colorbox:
			return "Colorbox"
		case MTMathAtomType.table:
			return "Table"
	}
}
