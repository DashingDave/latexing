//
//	MTTypesetter.swift
//	ObjC -> Swift conversion of
//
//  MTTypesetter.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 6/21/16.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI

enum MTInterElementSpaceType : Int {
	case spaceInvalid = -1

	case spaceNone = 0

	case spaceThin

	case spaceNSThin	// Thin but not in script mode

	case spaceNSMedium

	case spaceNSThick
}

func IS_GREEK_SYMBOL(_ ch: Any) -> Bool {
	greekSymbolOrder(ch) != NSNotFound
}

private let kMTUnicodeGreekCapitalStart = unichar(0x0391)
private let kMTUnicodeGreekCapitalEnd = unichar(0x03a9)

private let kMTUnicodeGreekLowerStart = unichar(0x03b1)
private let kMTUnicodeGreekLowerEnd = unichar(0x03c9)

private let kMTUnicodePlanksConstant = unichar(0x210e)

private let kMTUnicodeMathCapitalItalicStart: UTF32Char = 0x1d434
private let kMTUnicodeMathLowerItalicStart: UTF32Char = 0x1d44e

private let kMTUnicodeMathCapitalBoldStart: UTF32Char = 0x1d400
private let kMTUnicodeMathLowerBoldStart: UTF32Char = 0x1d41a
private let kMTUnicodeNumberBoldStart: UTF32Char = 0x1d7ce

private let kMTUnicodeMathCapitalBoldItalicStart: UTF32Char = 0x1d468
private let kMTUnicodeMathLowerBoldItalicStart: UTF32Char = 0x1d482

private let kMTUnicodeGreekCapitalItalicStart: UTF32Char = 0x1d6e2
private let kMTUnicodeGreekLowerItalicStart: UTF32Char = 0x1d6fc
private let kMTUnicodeGreekSymbolItalicStart: UTF32Char = 0x1d716

private let kMTUnicodeGreekCapitalBoldStart: UTF32Char = 0x1d6a8
private let kMTUnicodeGreekLowerBoldStart: UTF32Char = 0x1d6c2
private let kMTUnicodeGreekSymbolBoldStart: UTF32Char = 0x1d6dc

private let kMTUnicodeGreekCapitalBoldItalicStart: UTF32Char = 0x1d71c
private let kMTUnicodeGreekLowerBoldItalicStart: UTF32Char = 0x1d736
private let kMTUnicodeGreekSymbolBoldItalicStart: UTF32Char = 0x1d750

private let kMTUnicodeMathCapitalScriptStart: UTF32Char = 0x1d49c

private let kMTUnicodeMathCapitalTTStart: UTF32Char = 0x1d670
private let kMTUnicodeMathLowerTTStart: UTF32Char = 0x1d68a
private let kMTUnicodeNumberTTStart: UTF32Char = 0x1d7f6

private let kMTUnicodeMathCapitalSansSerifStart: UTF32Char = 0x1d5a0
private let kMTUnicodeMathLowerSansSerifStart: UTF32Char = 0x1d5ba
private let kMTUnicodeNumberSansSerifStart: UTF32Char = 0x1d7e2

private let kMTUnicodeMathCapitalFrakturStart: UTF32Char = 0x1d504
private let kMTUnicodeMathLowerFrakturStart: UTF32Char = 0x1d51e

private let kMTUnicodeMathCapitalBlackboardStart: UTF32Char = 0x1d538
private let kMTUnicodeMathLowerBlackboardStart: UTF32Char = 0x1d552
private let kMTUnicodeNumberBlackboardStart: UTF32Char = 0x1d7d8

let kBaseLineSkipMultiplier: CGFloat = 1.2		// default base line stretch is 12 pt for 10pt font.
let kJotMultiplier: CGFloat = 0.3				// A "jot" is 3pt for a 10pt font.
let kLineSkipMultiplier: CGFloat = 0.1			// default is 1pt for 10pt font.
let kLineSkipLimitMultiplier: CGFloat = 0

/* Delimiter shortfall from plain.tex */
let kDelimiterFactor = 901
let kDelimiterShortfallPoints = 5

/* This class does all the LaTeX typesetting logic. **For advanced use only**. */
class MTTypesetter: NSObject {
	private var font: MTFont?
	
	private var displayAtoms: [MTDisplay] = nil
	
	private var currentPosition = CGPoint.zero
	
	private var currentLine: NSMutableAttributedString?
	
	private var currentAtoms: [AnyHashable] = nil		// List of atoms that make the line
	
	private var currentLineIndexRange: NSRange?
	
	private var style: MTLineStyle?
	
	private var styleFont: MTFont?
	
	private var cramped = false
	
	private var spaced = false
	
	/* Renders a MTMathList as a list of displays. */
	class func createLine(for mathList: MTMathList, font: MTFont, style: MTLineStyle) -> MTMathListDisplay {
		let finalizedList = mathList.finalized
		
		/* Default is 'not cramped' */
		return self.createLine(for: finalizedList, font: font, style: style, cramped: false)
	}
	
	/* Internal */
	class func createLine(for mathList: MTMathList, font: MTFont, style: MTLineStyle, cramped: Bool) -> MTMathListDisplay {
		return self.createLine(for: mathList, font: font, style: style, cramped: cramped, spaced: false)
	}
	
	/* Internal */
	class func createLine(for mathList: MTMathList, font: MTFont, style: MTLineStyle, cramped: Bool, spaced: Bool) -> MTMathListDisplay {
		assert(font != nil, "Invalid parameter not satisfying: font != nil")
		
		let preprocessedAtoms = self.preprocessMathList(mathList)
		
		let typesetter = MTTypesetter(font: font, style: style, cramped: cramped, spaced: spaced)
		
		typesetter.createDisplayAtoms(preprocessedAtoms)
		
		let lastAtom = mathList.atoms.last as? MTMathAtom
		
		var line: MTMathListDisplay? = nil
		
		if let indexRange = lastAtom?.indexRange {
			line = MTMathListDisplay(displays: typesetter.displayAtoms, range: NSRange(location: 0, length: NSMaxRange(indexRange)))
		}
		
		return line!
	}
	
	class func placeholderColor() -> MTColor {
		return .blue()
	}
	
	init(font: MTFont, style: MTLineStyle, cramped: Bool, spaced: Bool) {
		super.init()
		
		self.font = font
		
		displayAtoms = []
		
		currentPosition = CGPoint.zero
		
		self.cramped = cramped
		
		self.spaced = spaced
		
		currentLine = NSMutableAttributedString()
		
		currentAtoms = []
		
		self.style = style
		
		currentLineIndexRange = NSRange(location: NSNotFound, length: NSNotFound)
	}
	
	/* Some of the preprocessing described by the TeX algorithm is done in the finalize method of MTMathList, specifically rules 5 & 6 in Appendix G. This function does not do a complete preprocessing as specified by TeX, either. It just removes any special atom types that are not included in TeX and applies Rule 14 to merge ordinary characters. */
	class func preprocessMathList(_ ml: MTMathList) -> [AnyHashable] {
		var preprocessed = [AnyHashable](repeating: 0, count: ml.atoms.count)
		
		var prevNode: MTMathAtom? = nil
		
		for atom in ml.atoms {
			/* These are not TeX type nodes. TeX does this during parsing the input. */
			if atom.type == kMTMathAtomVariable || atom.type == kMTMathAtomNumber {
				/* Switch to using the font specified in the atom. */
				let newFont = changeFont(atom.nucleus, atom.fontStyle)
				
				/* Convert it to 'ordinary'. */
				atom.type = kMTMathAtomOrdinary
				
				atom.nucleus = newFont
			} else if atom.type == kMTMathAtomUnaryOperator {
				/* TeX treats these as 'ordinary', so we do as well. */
				atom.type = kMTMathAtomOrdinary
			}
			
			/* This is Rule 14 to merge ordinary characters. */
			if atom.type == kMTMathAtomOrdinary {
				/* Combine ordinary atoms together */
				if prevNode != nil && prevNode?.type == kMTMathAtomOrdinary && !prevNode?.subScript && !prevNode?.superScript {
					prevNode?.fuse(atom)
					
					/* We're done, so skip the current node. */
					continue
				}
			}
			
/* TODO: add italic correction here or in second pass? */

			prevNode = atom
			
			preprocessed.append(atom)
		}
		
		return preprocessed
	}
	
	/* Returns the size of the font in this style */
	class func getStyleSize(_ style: MTLineStyle, font: MTFont) -> CGFloat {
		let original = font.fontSize
		
		switch style {
			case kMTLineStyleDisplay, kMTLineStyleText:
				return original
			
			case kMTLineStyleScript:
				return original * font.mathTable.scriptScaleDown
			
			case kMTLineStyleScriptScript:
				return original * font.mathTable.scriptScriptScaleDown
			
			default:
				break
		}
	}
	
	func setStyle(_ style: MTLineStyle) {
		self.style = style
		
		if let style = self.style, let font = font {
			styleFont = font?.copy(withSize: getStyleSize(style, font: font))
		}
	}
	
	func addInterElementSpace(_ prevNode: MTMathAtom, currentType type: MTMathAtomType) {
		var interElementSpace: CGFloat = 0
		
		if prevNode != nil {
			interElementSpace = getInterElementSpace(prevNode.type, right: type)
		} else if spaced {
			/* For the first atom of a spaced list, treat it as if it is preceded by an open. */
			interElementSpace = getInterElementSpace(kMTMathAtomOpen, right: type)
		}
		
		currentPosition.x += interElementSpace
	}
	
	/* Items should contain all the nodes that need to be layed out. Convert to a list of `MTDisplayAtoms`. */
	func createDisplayAtoms(_ preprocessed: [AnyHashable]) {
		var prevNode: MTMathAtom? = nil
		
		var lastType: MTMathAtomType = 0
		
		for atom in preprocessed {
			guard let atom = atom as? MTMathAtom else {
				continue
			}
			
			switch atom.type {
				case kMTMathAtomNumber, kMTMathAtomVariable, kMTMathAtomUnaryOperator:
					assert(false, "These types should never show here as they are removed by preprocessing.")
				
				case kMTMathAtomBoundary:
					assert(false, "A boundary atom should never be inside a mathlist.")
				
				case kMTMathAtomSpace:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}
					
					let space = atom as? MTMathSpace
					
					/* Add the desired space. */
					currentPosition.x += space?.space * styleFont?.mathTable.muUnit
					
					/* Because this is extra space, the desired inter-element space between the prevAtom and the next node is still preserved. To avoid resetting the prevAtom and lastType, we skip to the next node. */
					continue
				
				case kMTMathAtomStyle:
					if (currentLine?.length ?? 0) > 0 {
						addDisplayLine()
					}
					
					let style = atom as? MTMathStyle
					
					self.style = style?.style
					
					/* We need to preserve the prevNode for any inter-element space changes, so we skip to the next node. */
					continue
				
				case kMTMathAtomColor:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}
					
					let colorAtom = atom as? MTMathColor
					
					var display: MTDisplay? = nil
					
					if let innerList = colorAtom?.innerList, let font = font, let style = self.style {
						display = MTTypesetter.createLine(for: innerList, font: font, style: style) as? MTDisplay
					}
					
					display?.localTextColor = MTColor(fromHexString: colorAtom?.colorString)
					
					display?.position = currentPosition
					
					currentPosition.x += display?.width ?? 0.0
					
					if let display = display {
						displayAtoms.append(display)
					}
				
				case kMTMathAtomColorbox:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}
					
					let colorboxAtom = atom as? MTMathColorbox
					
					var display: MTDisplay? = nil
					
					if let innerList = colorboxAtom?.innerList, let font = font, let style = self.style {
						display = MTTypesetter.createLine(for: innerList, font: font, style: style) as? MTDisplay
					}
					
					display?.localBackgroundColor = MTColor(fromHexString: colorboxAtom?.colorString)
					
					display?.position = currentPosition
					
					currentPosition.x += display?.width ?? 0.0
					
					if let display = display {
						displayAtoms.append(display)
					}
				
				case kMTMathAtomRadical:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}
					
					/* Radicals are considered as Ord in rule 16. */
					let rad = atom as? MTRadical
					
					if let prevNode = prevNode {
						addInterElementSpace(prevNode, currentType: kMTMathAtomOrdinary)
					}
					
					var displayRad: MTRadicalDisplay? = nil
					
					if let radicand = rad?.radicand, let indexRange = rad?.indexRange {
						displayRad = makeRadical(radicand, range: indexRange)
					}
					
					if rad?.degree {
						var degree: MTMathListDisplay? = nil
						
						/* Add the degree to the radical. */
						if let aDegree = rad?.degree, let font = font {
							degree = MTTypesetter.createLine(for: aDegree, font: font, style: kMTLineStyleScriptScript)
						}
						
						displayRad?.setDegree(degree, fontMetrics: styleFont?.mathTable)
					}
					
					if let displayRad = displayRad {
						displayAtoms.append(displayRad)
					}
					
					currentPosition.x += displayRad?.width ?? 0.0
					
					if atom.subScript || atom.superScript {
						if let displayRad = displayRad {
							/* Add super-, subscripts. */
							makeScripts(atom, display: displayRad, index: rad?.indexRange.location ?? 0, delta: 0)
						}
					}
					
					/* Change type to Ord. atom.type = kMTMathAtomOrdinary */
				
				case kMTMathAtomFraction:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}

					let frac = atom as? MTFraction
					
					if let prevNode = prevNode {
						addInterElementSpace(prevNode, currentType: atom.type)
					}
					
					var display: MTDisplay? = nil
					
					if let frac = frac {
						display = make(frac)
					}
					
					if let display = display {
						displayAtoms.append(display)
					}
					
					currentPosition.x += display?.width ?? 0.0
					
					if atom.subScript || atom.superScript {
						if let display = display {
							/* Add super-, subscripts. */
							makeScripts(atom, display: display, index: frac?.indexRange.location ?? 0, delta: 0)
						}
					}
				
				case kMTMathAtomLargeOperator:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}

					if let prevNode = prevNode {
						addInterElementSpace(prevNode, currentType: atom.type)
					}
					
					let op = atom as? MTLargeOperator
					
					var display: MTDisplay? = nil
					
					if let op = op {
						display = makeLargeOp(op)
					}
					
					if let display = display {
						displayAtoms.append(display)
					}
				
				case kMTMathAtomInner:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}

					if let prevNode = prevNode {
						addInterElementSpace(prevNode, currentType: atom.type)
					}
					
					let inner = atom as? MTInner
					
					var display: MTInnerDisplay? = nil
					
					if let inner = inner {
						display = make(inner, at: atom.indexRange.location)
					}
					
					display?.position = currentPosition
					
					currentPosition.x += display?.width ?? 0.0
					
					if let display = display {
						displayAtoms.append(display)
					}
					
					if atom.subScript || atom.superScript {
						if let display = display {
							/* Add super-, subscripts. */
							makeScripts(atom, display: display, index: atom.indexRange.location, delta: 0)
						}
					}
				
				case kMTMathAtomUnderline:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}

					/* Underline is considered as Ord in rule 16. */
					if let prevNode = prevNode {
						addInterElementSpace(prevNode, currentType: kMTMathAtomOrdinary)
					}
					
					atom.type = kMTMathAtomOrdinary
					
					let under = atom as? MTUnderLine
					
					var display: MTDisplay? = nil
					
					if let under = under {
						display = makeUnderline(under)
					}
					
					if let display = display {
						displayAtoms.append(display)
					}
					
					currentPosition.x += display?.width ?? 0.0
					
					if atom.subScript || atom.superScript {
						if let display = display {
							/* Add super-, subscripts. */
							makeScripts(atom, display: display, index: atom.indexRange.location, delta: 0)
						}
					}
				
				case kMTMathAtomOverline:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}

					/* Overline is considered as Ord in rule 16. */
					if let prevNode = prevNode {
						addInterElementSpace(prevNode, currentType: kMTMathAtomOrdinary)
					}
					
					atom.type = kMTMathAtomOrdinary
					
					let over = atom as? MTOverLine
					
					var display: MTDisplay? = nil
					
					if let over = over {
						display = makeOverline(over)
					}
					
					if let display = display {
						displayAtoms.append(display)
					}
					
					currentPosition.x += display?.width ?? 0.0
					
					if atom.subScript || atom.superScript {
						if let display = display {
							/* Add super-, subscripts. */
							makeScripts(atom, display: display, index: atom.indexRange.location, delta: 0)
						}
					}
				
				case kMTMathAtomAccent:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}

					/* Accent is considered as Ord in rule 16. */
					if let prevNode = prevNode {
						addInterElementSpace(prevNode, currentType: kMTMathAtomOrdinary)
					}
					
					atom.type = kMTMathAtomOrdinary
					
					let accent = atom as? MTAccent
					
					var display: MTDisplay? = nil
					
					if let accent = accent {
						display = make(accent)
					}
					
					if let display = display {
						displayAtoms.append(display)
					}
					
					currentPosition.x += display?.width ?? 0.0
					
					if atom.subScript || atom.superScript {
						if let display = display {
							/* Add super-, subscripts. */
							makeScripts(atom, display: display, index: atom.indexRange.location, delta: 0)
						}
					}
				
				case kMTMathAtomTable:
					if (currentLine?.length ?? 0) > 0 {
						/* Stash the existing layout. */
						addDisplayLine()
					}

					/* We consider tables as inner. */
					if let prevNode = prevNode {
						addInterElementSpace(prevNode, currentType: kMTMathAtomInner)
					}
					
					atom.type = kMTMathAtomInner
					
					let table = atom as? MTMathTable
					
					var display: MTDisplay? = nil
					
					if let table = table {
						display = make(table)
					}
					
					if let display = display {
						displayAtoms.append(display)
					}
					
					/* A table doesn't have sub-, superscripts. */
					currentPosition.x += display?.width ?? 0.0

				/* The rendering for all the rest is pretty similar. All we need is to render the character and set the inter-element space. */
				case kMTMathAtomOrdinary, kMTMathAtomBinaryOperator, kMTMathAtomRelation, kMTMathAtomOpen, kMTMathAtomClose, kMTMathAtomPlaceholder, kMTMathAtomPunctuation:
					if let prevNode = prevNode {
						let interElementSpace = getInterElementSpace(prevNode.type, right: atom.type)
						
						if (currentLine?.length ?? 0) > 0 {
							if interElementSpace > 0 {
								/* Add a kerning of that space to the previous character. */
								if let range = (currentLine?.string as NSString?).rangeOfComposedCharacterSequence(at: (currentLine?.length ?? 0) - 1) {
									currentLine?.addAttribute(NSAttributedString.Key(kCTKernAttributeName as String), value: NSNumber(value: Float(interElementSpace)), range: range)
								}
							}
						} else {
							/* Increase the space. */
							currentPosition.x += interElementSpace
						}
					}
					
					var current: NSAttributedString? = nil
					
					if atom.type == kMTMathAtomPlaceholder {
						let color = MTTypesetter.placeholderColor()
						
						if let CGColor = color.cgColor {
							current = NSAttributedString(string: atom.nucleus, attributes: [kCTForegroundColorAttributeName as String: CGColor] as? [NSAttributedString.Key : Any])
						}
					} else {
						current = NSAttributedString(string: atom.nucleus)
					}
					
					if let current = current {
						currentLine?.append(current)
					}
					
					if currentLineIndexRange?.location == NSNotFound {
						/* Add the atom to the current range. */
						currentLineIndexRange = atom.indexRange
					} else {
						(currentLineIndexRange?.length ?? 0) += atom.indexRange.length
					}
					
					if atom.fusedAtoms {
						/* Add the fused atoms. */
						currentAtoms.append(contentsOf: atom.fusedAtoms)
					} else {
						currentAtoms.append(atom)
					}
					
					/* Stash the existing line. We don't check _currentLine.length here because we want to allow empty lines with super-, subscripts. */
					if atom.subScript || atom.superScript {
						let line = addDisplayLine()
						
						var delta: CGFloat = 0
						
						if atom.nucleus.length > 0 {
							/* Use the italic correction of the last character. */
							let glyph = findGlyphForCharacter(at: atom.nucleus.length - 1, in: atom.nucleus)
							
							delta = styleFont?.mathTable.getItalicCorrection(glyph) ?? 0.0
						}
						if delta > 0 && !atom.subScript {
							/* Add a kern of magnitude delta. */
							currentPosition.x += delta
						}
						
						/* Add super-, subscripts. */
						makeScripts(atom, display: line, index: NSMaxRange(atom.indexRange) - 1, delta: delta)
					}
				
				default:
					break
			}
			
			lastType = atom.type
			
			prevNode = atom
		}
		
		if (currentLine?.length ?? 0) > 0 {
			addDisplayLine()
		}
		
		if spaced && lastType != nil {
			/* If _spaced, then add an interelement space between the last type and close. */
			var display = displayAtoms.last
			
			let interElementSpace = getInterElementSpace(lastType, right: kMTMathAtomClose)
			
			display?.width += interElementSpace
		}
	}
	
	func addDisplayLine() -> MTCTLineDisplay {
		/* Add the font. */
		currentLine?.addAttribute(NSAttributedString.Key(kCTFontAttributeName as String), value: (styleFont?.ctFont), range: NSRange(location: 0, length: currentLine?.length ?? 0))
		/* NSAssert(_currentLineIndexRange.length == numCodePoints(_currentLine.string),
		 @"The length of the current line: %@ does not match the length of the range (%d, %d)",
		 _currentLine, _currentLineIndexRange.location, _currentLineIndexRange.length); */
		
		let displayAtom = MTCTLineDisplay(string: currentLine, position: currentPosition, range: currentLineIndexRange, font: styleFont, atoms: currentAtoms)
		displayAtoms.append(displayAtom)
		
		/* Update the position. */
		currentPosition.x += displayAtom.width
		
		/* Clear the string and the range. */
		currentLine = NSMutableAttributedString()
		
		currentAtoms = []
		
		currentLineIndexRange = NSRange(location: NSNotFound, length: NSNotFound)
		
		return displayAtom
	}
	
	/* Returned in units of mu = 1/18 em. */
	func getSpacingInMu(_ type: MTInterElementSpaceType) -> Int {
		switch type {
			case MTInterElementSpaceType.spaceInvalid:
				return -1
			
			case MTInterElementSpaceType.spaceNone:
				return 0
			
			case MTInterElementSpaceType.spaceThin:
				return 3
			
			case MTInterElementSpaceType.spaceNSThin:
				if let style = style {
					return (style < kMTLineStyleScript) ? 3 : 0
				}
				return 0
			
			case MTInterElementSpaceType.spaceNSMedium:
				if let style = style {
					return (style < kMTLineStyleScript) ? 4 : 0
				}
				return 0
			
			case MTInterElementSpaceType.spaceNSThick:
				if let style = style {
					return (style < kMTLineStyleScript) ? 5 : 0
				}
				return 0
		}
	}
	
	func getInterElementSpace(_ left: MTMathAtomType, right: MTMathAtomType) -> CGFloat {
		let leftIndex = getInterElementSpaceArrayIndexForType(left, true)
		
		let rightIndex = getInterElementSpaceArrayIndexForType(right, false)
		
		let spaceArray = getInterElementSpaces()?[leftIndex] as? [AnyHashable]
		
		let spaceTypeObj = spaceArray?[rightIndex] as? NSNumber
		
		let spaceType = MTInterElementSpaceType(rawValue: spaceTypeObj?.intValue ?? 0)
		
		assert(spaceType != MTInterElementSpaceType.spaceInvalid, String(format: "Invalid space between %lu and %lu", UInt(left), UInt(right)))
		
		var spaceMultipler: Int? = nil
		
		if let spaceType = spaceType {
			spaceMultipler = getSpacingInMu(spaceType)
		}
		
		if (spaceMultipler ?? 0) > 0 {
			/* 1 em = size of font in pt. Space multipler is in multiples of mu = 1/18 em */
			return CGFloat((spaceMultipler ?? 0) * (styleFont?.mathTable.muUnit ?? 0))
		}
		
		return 0
	}
	
	func scriptStyle() -> MTLineStyle {
		switch style {
			case kMTLineStyleDisplay, kMTLineStyleText:
				return kMTLineStyleScript
			
			case kMTLineStyleScript:
				return kMTLineStyleScriptScript
			
			case kMTLineStyleScriptScript:
				return kMTLineStyleScriptScript
			
			default:
				break
		}
	}
	
	/* Subscript is always cramped. */
	func subscriptCramped() -> Bool {
		return true
	}
	
	/* Superscript is cramped only if the current style is cramped. */
	func superScriptCramped() -> Bool {
		return cramped
	}
	
	func superScriptShiftUp() -> CGFloat {
		if cramped {
			return styleFont?.mathTable.superscriptShiftUpCramped ?? 0.0
		} else {
			return styleFont?.mathTable.superscriptShiftUp ?? 0.0
		}
	}
	
	/* Make scripts for the last atom. Index is the index of the element which is getting the sub-, super scripts. */
	func makeScripts(_ atom: MTMathAtom, display: MTDisplay, index: Int, delta: CGFloat) {
		assert(atom.subScript || atom.superScript)
		
		var superScriptShiftUp: Double = 0
		
		var subscriptShiftDown: Double = 0
		
		display.hasScript = true
		
		if !(display is MTCTLineDisplay) {
			/* Get the font in script style. */
			var scriptFontSize: CGFloat? = nil
			
			if let font = font {
				scriptFontSize = getStyleSize(scriptStyle(), font: font)
			}
			
			let scriptFont = font?.copy(withSize: scriptFontSize)
			
			let scriptFontMetrics = scriptFont?.mathTable
			
			/* If it is not a simple line... */
			superScriptShiftUp = display.ascent - scriptFontMetrics?.superscriptBaselineDropMax
			
			subscriptShiftDown = display.descent + scriptFontMetrics?.subscriptBaselineDropMin
		}
		
		if !atom.superScript {
			assert(atom.subScript)
			
			var `subscript`: MTMathListDisplay? = nil
			
			if let font = font {
				`subscript` = MTTypesetter.createLine(for: atom.subScript, font: font, style: scriptStyle(), cramped: subscriptCramped())
			}
			
			`subscript`?.type = kMTLinePositionSubscript
			
			`subscript`?.index = index
			
			subscriptShiftDown = Double(fmax(Float(subscriptShiftDown), styleFont?.mathTable.subscriptShiftDown ?? 0.0))
			
			subscriptShiftDown = Double(fmax(Float(subscriptShiftDown), `subscript`?.ascent - styleFont?.mathTable.subscriptTopMax))
			
			/* Add the subscript. */
			`subscript`?.position = CGPoint(x: currentPosition.x, y: CGFloat(currentPosition.y - subscriptShiftDown))
			
			if let object = `subscript` {
				displayAtoms.append(object)
			}
			
			/* Update the position. */
			currentPosition.x += `subscript`?.width + styleFont?.mathTable.spaceAfterScript
			
			return
		}
		
		var superScript: MTMathListDisplay? = nil
		
		if let font = font {
			superScript = MTTypesetter.createLine(for: atom.superScript, font: font, style: scriptStyle(), cramped: superScriptCramped())
		}
		
		superScript?.type = kMTLinePositionSuperscript
		
		superScript?.index = index
		
		superScriptShiftUp = Double(fmax(Float(superScriptShiftUp), Float(self.superScriptShiftUp())))
		
		superScriptShiftUp = Double(fmax(Float(superScriptShiftUp), superScript?.descent + styleFont?.mathTable.superscriptBottomMin))
		
		if !atom.subScript {
			superScript?.position = CGPoint(x: currentPosition.x, y: CGFloat(currentPosition.y + superScriptShiftUp))
			
			if let superScript = superScript {
				displayAtoms.append(superScript)
			}
			
			/* Update the position. */
			currentPosition.x += superScript?.width + styleFont?.mathTable.spaceAfterScript
			
			return
		}
		
		var `subscript`: MTMathListDisplay? = nil
		
		if let font = font {
			`subscript` = MTTypesetter.createLine(for: atom.subScript, font: font, style: scriptStyle(), cramped: subscriptCramped())
		}
		
		`subscript`?.type = kMTLinePositionSubscript
		
		`subscript`?.index = index
		
		subscriptShiftDown = Double(fmax(Float(subscriptShiftDown), styleFont?.mathTable.subscriptShiftDown ?? 0.0))
		
		/* Joint positioning of subscript & superscript. */
		let subSuperScriptGap = CGFloat((superScriptShiftUp - (superScript?.descent ?? 0.0)) + (subscriptShiftDown - (`subscript`?.ascent ?? 0.0)))
		
		if subSuperScriptGap < (styleFont?.mathTable.subSuperscriptGapMin ?? 0.0) {
			/* Set the gap to at least as much. */
			subscriptShiftDown += (styleFont?.mathTable.subSuperscriptGapMin ?? 0.0) - subSuperScriptGap
			
			let superscriptBottomDelta = CGFloat((styleFont?.mathTable.superscriptBottomMaxWithSubscript ?? 0.0) - (superScriptShiftUp - (superScript?.descent ?? 0.0)))
			
			if superscriptBottomDelta > 0 {
				/* Superscript is lower than the max allowed by the font with a subscript. */
				superScriptShiftUp += superscriptBottomDelta
				
				subscriptShiftDown -= superscriptBottomDelta
			}
		}
		
		/* The delta is the italic correction above that shift superscript position. */
		superScript?.position = CGPoint(x: currentPosition.x + delta, y: CGFloat(currentPosition.y + superScriptShiftUp))
		
		if let superScript = superScript {
			displayAtoms.append(superScript)
		}
		
		`subscript`?.position = CGPoint(x: currentPosition.x, y: CGFloat(currentPosition.y - subscriptShiftDown))
		
		if let object = `subscript` {
			displayAtoms.append(object)
		}
		
		if let spaceAfterScript = styleFont?.mathTable.spaceAfterScript {
			currentPosition.x += CGFloat(max((superScript?.width ?? 0.0) + delta, `subscript`?.width) + spaceAfterScript)
		}
	}
	
	func numeratorShiftUp(_ hasRule: Bool) -> CGFloat {
		if hasRule {
			if style == kMTLineStyleDisplay {
				return styleFont?.mathTable.fractionNumeratorDisplayStyleShiftUp ?? 0.0
			} else {
				return styleFont?.mathTable.fractionNumeratorShiftUp ?? 0.0
			}
		} else {
			if style == kMTLineStyleDisplay {
				return styleFont?.mathTable.stackTopDisplayStyleShiftUp ?? 0.0
			} else {
				return styleFont?.mathTable.stackTopShiftUp ?? 0.0
			}
		}
	}
	
	func numeratorGapMin() -> CGFloat {
		if style == kMTLineStyleDisplay {
			return styleFont?.mathTable.fractionNumeratorDisplayStyleGapMin ?? 0.0
		} else {
			return styleFont?.mathTable.fractionNumeratorGapMin ?? 0.0
		}
	}
	
	func denominatorShiftDown(_ hasRule: Bool) -> CGFloat {
		if hasRule {
			if style == kMTLineStyleDisplay {
				return styleFont?.mathTable.fractionDenominatorDisplayStyleShiftDown ?? 0.0
			} else {
				return styleFont?.mathTable.fractionDenominatorShiftDown ?? 0.0
			}
		} else {
			if style == kMTLineStyleDisplay {
				return styleFont?.mathTable.stackBottomDisplayStyleShiftDown ?? 0.0
			} else {
				return styleFont?.mathTable.stackBottomShiftDown ?? 0.0
			}
		}
	}
	
	func denominatorGapMin() -> CGFloat {
		if style == kMTLineStyleDisplay {
			return styleFont?.mathTable.fractionDenominatorDisplayStyleGapMin ?? 0.0
		} else {
			return styleFont?.mathTable.fractionDenominatorGapMin ?? 0.0
		}
	}
	
	func stackGapMin() -> CGFloat {
		if style == kMTLineStyleDisplay {
			return styleFont?.mathTable.stackDisplayStyleGapMin ?? 0.0
		} else {
			return styleFont?.mathTable.stackGapMin() ?? 0.0
		}
	}
	
	func fractionDelimiterHeight() -> CGFloat {
		if style == kMTLineStyleDisplay {
			return styleFont?.mathTable.fractionDelimiterDisplayStyleSize ?? 0.0
		} else {
			return styleFont?.mathTable.fractionDelimiterSize ?? 0.0
		}
	}
	
	func fractionStyle() -> MTLineStyle {
		if style == kMTLineStyleScriptScript {
			return kMTLineStyleScriptScript
		}
		return Int(style ?? 0) + 1
	}
	
	func make(_ frac: MTFraction) -> MTDisplay {
		/* Lay out the parts of the fraction. */
		let fractionStyle = self.fractionStyle()
		
		var numeratorDisplay: MTMathListDisplay? = nil
		
		if let font = font {
			numeratorDisplay = MTTypesetter.createLine(for: frac.numerator, font: font, style: fractionStyle, cramped: false)
		}
		
		var denominatorDisplay: MTMathListDisplay? = nil
		
		if let font = font {
			denominatorDisplay = MTTypesetter.createLine(for: frac.denominator, font: font, style: fractionStyle, cramped: true)
		}
		
		/* Determine the location of the numerator. */
		var numeratorShiftUp = self.numeratorShiftUp(frac.hasRule)
		
		var denominatorShiftDown = self.denominatorShiftDown(frac.hasRule)
		
		let barLocation = styleFont?.mathTable.axisHeight ?? 0.0
		
		let barThickness: CGFloat = ((frac.hasRule) ? styleFont?.mathTable.fractionRuleThickness : 0) ?? 0.0
		
		if frac.hasRule {
			/* This is the difference between the lowest edge of the numerator and the top edge of the fraction bar. */
			let distanceFromNumeratorToBar = (numeratorShiftUp - (numeratorDisplay?.descent ?? 0.0)) - (barLocation + barThickness / 2)
			
			let minNumeratorGap = numeratorGapMin()
			
			/* The distance should at least be displayGap. */
			if distanceFromNumeratorToBar < minNumeratorGap {
				/* This makes the distance between the bottom of the numerator and the top edge of the fraction bar at least minNumeratorGap. */
				numeratorShiftUp += minNumeratorGap - distanceFromNumeratorToBar
			}
			
			/* This is the difference between the top edge of the denominator and the bottom edge of the fraction bar. */
			let distanceFromDenominatorToBar = (barLocation - barThickness / 2) - ((denominatorDisplay?.ascent ?? 0.0) - denominatorShiftDown)
			
			let minDenominatorGap = denominatorGapMin()
			
			/* The distance should at least be denominator gap */
			if distanceFromDenominatorToBar < minDenominatorGap {
				/* This makes the distance between the top of the denominator and the bottom of the fraction bar to be exactly minDenominatorGap. */
				denominatorShiftDown += minDenominatorGap - distanceFromDenominatorToBar
			}
		} else {
			/* This is the distance between the numerator and the denominator. */
			let clearance = (numeratorShiftUp - (numeratorDisplay?.descent ?? 0.0)) - ((denominatorDisplay?.ascent ?? 0.0) - denominatorShiftDown)
			
			/* This is the minimum clearance between the numerator and denominator. */
			let minGap = stackGapMin()
			
			if clearance < minGap {
				numeratorShiftUp += (minGap - clearance) / 2
				
				denominatorShiftDown += (minGap - clearance) / 2
			}
		}
		
		let display = MTFractionDisplay(
			numerator: numeratorDisplay,
			denominator: denominatorDisplay,
			position: currentPosition,
			range: frac.indexRange)
		
		display.numeratorUp = numeratorShiftUp
		
		display.denominatorDown = denominatorShiftDown
		
		display.lineThickness = barThickness
		
		display.linePosition = barLocation
		
		if !frac.leftDelimiter && !frac.rightDelimiter {
			return display
		} else {
			return addDelimiters(to: display, for: frac)
		}
	}
	
	func addDelimiters(to display: MTFractionDisplay, for frac: MTFraction) -> MTDisplay {
		assert(frac.leftDelimiter || frac.rightDelimiter, "Fraction should have a delimiters to call this function")
		
		var innerElements: [AnyHashable] = []
		
		let glyphHeight = fractionDelimiterHeight()
		
		var position = CGPoint.zero
		
		if frac.leftDelimiter.length > 0 {
			let leftGlyph = findGlyph(forBoundary: frac.leftDelimiter, withHeight: glyphHeight)
			
			leftGlyph?.position = position
			
			position.x += leftGlyph.width
			
			innerElements.append(leftGlyph)
		}
		
		display.position = position
		
		position.x += display.width
		
		innerElements.append(display)
		
		if frac.rightDelimiter.length > 0 {
			let rightGlyph = findGlyph(forBoundary: frac.rightDelimiter, withHeight: glyphHeight)
			
			rightGlyph?.position = position
			
			position.x += rightGlyph.width
			
			innerElements.append(rightGlyph)
		}
		
		let innerDisplay = MTMathListDisplay(displays: innerElements, range: frac.indexRange)
		
		innerDisplay.position = currentPosition
		
		return innerDisplay
	}
	
	func radicalVerticalGap() -> CGFloat {
		if style == kMTLineStyleDisplay {
			return styleFont?.mathTable.radicalDisplayStyleVerticalGap ?? 0.0
		} else {
			return styleFont?.mathTable.radicalVerticalGap() ?? 0.0
		}
	}
	
	func getRadicalGlyph(withHeight radicalHeight: CGFloat) -> MTDisplay & DownShift {
		var glyphAscent: CGFloat
		
		var glyphDescent: CGFloat
		
		var glyphWidth: CGFloat
		
		let radicalGlyph = findGlyphForCharacter(at: 0, in: "\u{221A}")
		
		let glyph = find(radicalGlyph, withHeight: radicalHeight, glyphAscent: UnsafeMutablePointer<CGFloat>(mutating: &glyphAscent), glyphDescent: UnsafeMutablePointer<CGFloat>(mutating: &glyphDescent), glyphWidth: UnsafeMutablePointer<CGFloat>(mutating: &glyphWidth))
		
		var glyphDisplay: (MTDisplay & DownShift)?
		
		if glyphAscent + glyphDescent < radicalHeight {
			/* The glyph is not as large as required. A glyph needs to be constructed using the extenders. */
			glyphDisplay = constructGlyph(radicalGlyph, withHeight: radicalHeight)
		}
		
		if glyphDisplay == nil {
			/* No constructed display, so use the glyph we got. */
			glyphDisplay = MTGlyphDisplay(glpyh: glyph, range: NSRange(location: NSNotFound, length: 0), font: styleFont)
			
			glyphDisplay?.ascent = glyphAscent
			
			glyphDisplay?.descent = glyphDescent
			
			glyphDisplay?.width = glyphWidth
		}
		return glyphDisplay!
	}
	
	func makeRadical(_ radicand: MTMathList, range: NSRange) -> MTRadicalDisplay {
		var innerDisplay: MTMathListDisplay? = nil
		
		if let font = font, let style = style {
			innerDisplay = MTTypesetter.createLine(for: radicand, font: font, style: style, cramped: true)
		}
		
		var clearance = radicalVerticalGap()
		
		let radicalRuleThickness = styleFont?.mathTable.radicalRuleThickness ?? 0.0
		
		let radicalHeight = innerDisplay?.ascent + innerDisplay?.descent + clearance + radicalRuleThickness
		
		let glyph = getRadicalGlyph(withHeight: radicalHeight) as? (MTDisplay & DownShift)
		
		
		/* This is a departure from Latex. Latex assumes that glyphAscent == thickness. Open type math makes no such assumption, and ascent and descent are independent of the thickness. Latex computes delta as descent - (h(inner) + d(inner) + clearance) but since we may not have ascent == thickness, we modify the delta calculation slightly. If the font designer follows Latex conventions, it will be identical. */
		let delta = (glyph?.descent + glyph?.ascent) - (innerDisplay?.ascent + innerDisplay?.descent + clearance + radicalRuleThickness)

		if delta > 0 {
			/* Increase the clearance to center the radicand inside the sign. */
			clearance += delta / 2
		}
		
		/* We need to shift the radical glyph up, to coincide with the baseline of inner. The new ascent of the radical glyph should be thickness + adjusted clearance + h(inner) */
		let radicalAscent = radicalRuleThickness + clearance + (innerDisplay?.ascent ?? 0.0)
		
		/* If the font designer followed latex conventions, this is the same as glyphAscent == thickness. */
		let shiftUp = radicalAscent - (glyph?.ascent ?? 0.0)
		
		glyph?.shiftDown = -shiftUp
		
		var radical = MTRadicalDisplay.initWitRadicand(innerDisplay, glpyh: glyph, position: currentPosition, range: range)
		
		radical?.ascent = radicalAscent + (styleFont?.mathTable.radicalExtraAscender ?? 0.0)
		
		radical?.topKern = styleFont?.mathTable.radicalExtraAscender
		
		radical?.lineThickness = radicalRuleThickness
		
		/* Until we have radical construction from parts, it is possible that glyphAscent + glyphDescent is less than the requested height of the glyph (i.e. radicalHeight), so if the innerDisplay has a larger descent, we use the innerDisplay's descent. */
		radical?.descent = max(glyph?.ascent + glyph?.descent - radicalAscent, innerDisplay?.descent)
		
		radical?.width = glyph?.width + innerDisplay?.width
		
		return radical!
	}

	func find(_ glyph: CGGlyph, withHeight height: CGFloat, glyphAscent: UnsafeMutablePointer<CGFloat>?, glyphDescent: UnsafeMutablePointer<CGFloat>?, glyphWidth: UnsafeMutablePointer<CGFloat>?) -> CGGlyph {
		var glyphAscent = glyphAscent
		
		var glyphDescent = glyphDescent
		
		var glyphWidth = glyphWidth
		
		let variants = styleFont?.mathTable.getVerticalVariants(for: glyph)
		
		let numVariants = CFIndex((variants?.count ?? 0))
		
		let glyphs = [CGGlyph](repeating: , count: numVariants)
		
		for i in 0..<numVariants {
			let glyph = variants?[i]?.int16Value ?? 0
			glyphs[i] = glyph
		}
		
		let bboxes = [CGRect](repeating: CGRect.zero, count: numVariants)
		
		let advances = [CGSize](repeating: CGSize.zero, count: numVariants)
		
		/* Get the bounds for these glyphs. */
		if let ctFont = styleFont?.ctFont {
			CTFontGetBoundingRectsForGlyphs(ctFont, .kCTFontHorizontalOrientation, &glyphs, &bboxes, numVariants)
			
			CTFontGetAdvancesForGlyphs(ctFont, .kCTFontHorizontalOrientation, &glyphs, &advances, numVariants)
		}
		
		var ascent: CGFloat = 0.0
		
		var descent: CGFloat = 0.0
		
		var width: CGFloat = 0.0
		
		for i in 0..<numVariants {
			let bounds = bboxes[i]
			
			width = advances[i].width
			
			getBboxDetails(bounds, UnsafeMutablePointer<CGFloat>(mutating: &ascent), UnsafeMutablePointer<CGFloat>(mutating: &descent))
			
			if ascent + descent >= height {
				glyphAscent = UnsafeMutablePointer<CGFloat>(mutating: &ascent)
				
				glyphDescent = UnsafeMutablePointer<CGFloat>(mutating: &descent)
				
				glyphWidth = UnsafeMutablePointer<CGFloat>(mutating: &width)
				
				return glyphs[i]
			}
		}
		
		glyphAscent = UnsafeMutablePointer<CGFloat>(mutating: &ascent)
		
		glyphDescent = UnsafeMutablePointer<CGFloat>(mutating: &descent)
		
		glyphWidth = UnsafeMutablePointer<CGFloat>(mutating: &width)
		
		return glyphs[numVariants - 1]
	}
	
	func constructGlyph(_ glyph: CGGlyph, withHeight glyphHeight: CGFloat) -> MTGlyphConstructionDisplay {
		let parts = styleFont?.mathTable.getVerticalGlyphAssembly(for: glyph)
		
		if (parts?.count ?? 0) == 0 {
			return nil
		}
		
		var glyphs: [NSNumber]?
		
		var offsets: [NSNumber]?
		
		var height: CGFloat
		
		if let parts = parts {
			constructGlyph(withParts: parts, height: glyphHeight, glyphs: &glyphs, offsets: &offsets, height: UnsafeMutablePointer<CGFloat>(mutating: &height))
		}
		
		var first = glyphs?[0].int16Value ?? 0
		
		var width: CGFloat? = nil
		
		if let ctFont = styleFont?.ctFont {
			width = CGFloat(CTFontGetAdvancesForGlyphs(ctFont, .kCTFontHorizontalOrientation, &first, nil, CFIndex(1)))
		}
		
		var display = MTGlyphConstructionDisplay(glyphs: glyphs, offsets: offsets, font: styleFont)
		
		display.width = width
		
		display.ascent = height
		
		display.descent = 0			// It's up to the rendering to adjust the display up or down. */
		
		return display
	}
	
	func constructGlyph(withParts parts: [MTGlyphPart], height glyphHeight: CGFloat, glyphs: [NSNumber], offsets: [NSNumber], height: UnsafeMutablePointer<CGFloat>?) {
		var glyphs = glyphs
		
		var offsets = offsets
		
		var height = height
		
		assert(glyphs != nil, "Invalid parameter not satisfying: glyphs != nil")
		
		assert(offsets != nil, "Invalid parameter not satisfying: offsets != nil")
		
		var numExtenders = 0
		
		while true {
			var glyphsRv: [NSNumber]? = []
			
			var offsetsRv: [NSNumber]? = []
			
			var prev: MTGlyphPart? = nil
			
			let minDistance = styleFont?.mathTable.minConnectorOverlap ?? 0.0
			
			var minOffset: CGFloat = 0
			
			var maxDelta = CGFloat.greatestFiniteMagnitude /* the maximum amount we can increase the offsets by */
			
			for part in parts {
				var repeats = 1
				
				if part.isExtender {
					repeats = numExtenders
				}
				
				/* Add the extender numExtenders times. */
				for i in 0..<repeats {
					glyphsRv?.append(NSNumber(value: part.glyph))
					
					if let prev = prev {
						let maxOverlap = CGFloat(min(prev.endConnectorLength, part.startConnectorLength))
						
						let minOffsetDelta = prev.fullAdvance - maxOverlap		// Minimum amount we can add to the offset
						
						let maxOffsetDelta = prev.fullAdvance - minDistance		// Maximum amount we can add to the offset
						
						/* We can increase the offsets by at most (max - min). */
						maxDelta = CGFloat(min(maxDelta, maxOffsetDelta - minOffsetDelta))
						
						minOffset = minOffset + minOffsetDelta
					}
					
					offsetsRv?.append(NSNumber(value: Float(minOffset)))
					
					prev = part
				}
			}
			
			assert((glyphsRv?.count ?? 0) == (offsetsRv?.count ?? 0), "Offsets should match the glyphs")
			
			/* Maybe only extenders are present. */
			if prev == nil {
				continue
			}
			
			let minHeight = minOffset + (prev?.fullAdvance ?? 0.0)
			
			let maxHeight = minHeight + maxDelta * CGFloat(((glyphsRv?.count ?? 0) - 1))
			
			if minHeight >= glyphHeight {
				/* We are done. */
				if let glyphsRv = glyphsRv {
					glyphs = glyphsRv
				}
				
				if let offsetsRv = offsetsRv {
					offsets = offsetsRv
				}
				
				height = UnsafeMutablePointer<CGFloat>(mutating: &minHeight)
				
				return
			} else if glyphHeight <= maxHeight {
				/* Spread the delta equally between all the connectors. */
				let delta = glyphHeight - minHeight
				
				let deltaIncrease = delta / CGFloat(((glyphsRv?.count ?? 0) - 1))
				
				var lastOffset: CGFloat = 0
				
				for i in 0..<(offsetsRv?.count ?? 0) {
					let offset = CGFloat(offsetsRv?[i].floatValue ?? 0.0) + CGFloat(i) * deltaIncrease
					
					offsetsRv?[i] = NSNumber(value: Float(offset))
					
					lastOffset = offset
				}
				
				/* We are done. */
				if let glyphsRv = glyphsRv {
					glyphs = glyphsRv
				}
				
				if let offsetsRv = offsetsRv {
					offsets = offsetsRv
				}
				
				height = UnsafeMutablePointer<CGFloat>(mutating: lastOffset + (prev?.fullAdvance ?? 0.0))
				
				return
			}
			
			numExtenders += 1
		}
	}
	
	func findGlyphForCharacter(at index: Int, in str: String) -> CGGlyph {
		/* Get the character at index, taking into account UTF-32 characters. */
		let range = (str as NSString).rangeOfComposedCharacterSequence(at: index)
		
		let chars = [unichar](repeating: 0, count: range.length)
		
		(str as NSString).getCharacters(&chars, range: range)
		
		/* Get the glyph from the font */
		let glyph = [CGGlyph](repeating: , count: range.length)
		
		var found = false
		
		if let ctFont = styleFont?.ctFont {
			found = CTFontGetGlyphsForCharacters(ctFont, &chars, &glyph, CFIndex(range.length))
		}
		
		if !found {
			/* The font did not contain a glyph for our character, so we just return 0 (notdef). */
			return 0
		}
		
		return glyph[0]
	}
	
	func makeLargeOp(_ op: MTLargeOperator) -> MTDisplay {
		let limits = op.limits && style == kMTLineStyleDisplay
		
		var delta: CGFloat = 0
		
		if op.nucleus.length == 1 {
			var glyph = findGlyphForCharacter(at: 0, in: op.nucleus)
			
			if style == kMTLineStyleDisplay && Int(glyph) != 0 {
				/* Enlarge the character in display style. */
				if let getLargerGlyph = styleFont?.mathTable.getLargerGlyph(glyph) {
					glyph = getLargerGlyph
				}
			}
			
			/* This is be the italic correction of the character. */
			delta = styleFont?.mathTable.getItalicCorrection(glyph) ?? 0.0
			
			/* Center vertically. */
			var bbox: CGRect? = nil
			
			if let ctFont = styleFont?.ctFont {
				bbox = CTFontGetBoundingRectsForGlyphs(ctFont, .kCTFontHorizontalOrientation, &glyph, nil, CFIndex(1))
			}
			
			var width: CGFloat? = nil
			
			if let ctFont = styleFont?.ctFont {
				width = CGFloat(CTFontGetAdvancesForGlyphs(ctFont, .kCTFontHorizontalOrientation, &glyph, nil, CFIndex(1)))
			}
			
			var ascent: CGFloat
			
			var descent: CGFloat
			
			getBboxDetails(bbox ?? CGRect.zero, UnsafeMutablePointer<CGFloat>(mutating: &ascent), UnsafeMutablePointer<CGFloat>(mutating: &descent))
			
			let shiftDown = 0.5 * (ascent - descent) - (styleFont?.mathTable.axisHeight ?? 0.0)
			
			var glyphDisplay = MTGlyphDisplay(glpyh: glyph, range: op.indexRange, font: styleFont)
			
			glyphDisplay.ascent = ascent
			
			glyphDisplay.descent = descent
			
			glyphDisplay.width = width
			
			if op.subScript && !limits {
				/* Remove italic correction from the width of the glyph if there is a subscript and limits is not set. */
				glyphDisplay.width -= delta
			}
			
			glyphDisplay.shiftDown = shiftDown
			
			glyphDisplay.position = currentPosition
			
			return addLimits(to: glyphDisplay, for: op, delta: delta)
		} else {
			/* Create a regular node. */
			let line = NSMutableAttributedString(string: op.nucleus)
			
			/* Add the font. */
			line.addAttribute(NSAttributedString.Key(kCTFontAttributeName as String), value: (styleFont?.ctFont), range: NSRange(location: 0, length: line.length))
			
			let displayAtom = MTCTLineDisplay(string: line, position: currentPosition, range: op.indexRange, font: styleFont, atoms: [op])
			
			return addLimits(to: displayAtom, for: op, delta: 0)
		}
	}
	
	func addLimits(to display: MTDisplay, for op: MTLargeOperator, delta: CGFloat) -> MTDisplay {
		/* If there is no subscript or superscript, just return the current display. */
		if !op.subScript && !op.superScript {
			currentPosition.x += display.width
			
			return display
		}
		
		if op.limits && style == kMTLineStyleDisplay {
			/* Create limits. */
			var superScript: MTMathListDisplay? = nil
			
			var subScript: MTMathListDisplay? = nil
			
			if op.superScript {
				if let font = font {
					superScript = MTTypesetter.createLine(for: op.superScript, font: font, style: scriptStyle(), cramped: superScriptCramped())
				}
			}
			
			if op.subScript {
				if let font = font {
					subScript = MTTypesetter.createLine(for: op.subScript, font: font, style: scriptStyle(), cramped: subscriptCramped())
				}
			}
			
			assert(superScript != nil || subScript != nil, "Atleast one of superscript or subscript should have been present.")
			
			let opsDisplay = MTLargeOpLimitsDisplay(nucleus: display, upperLimit: superScript, lowerLimit: subScript, limitShift: delta / 2, extraPadding: 0)
			
			if let superScript = superScript {
				let upperLimitGap = CGFloat(max(styleFont?.mathTable.upperLimitGapMin, styleFont?.mathTable.upperLimitBaselineRiseMin - superScript.descent))
				
				opsDisplay.upperLimitGap = upperLimitGap
			}
			if let subScript = subScript {
				let lowerLimitGap = CGFloat(max(styleFont?.mathTable.lowerLimitGapMin, styleFont?.mathTable.lowerLimitBaselineDropMin - subScript.ascent))
				
				opsDisplay.lowerLimitGap = lowerLimitGap
			}
			
			opsDisplay.position = currentPosition
			
			opsDisplay.range = op.indexRange
			
			currentPosition.x += opsDisplay.width
			
			return opsDisplay
		} else {
			currentPosition.x += display.width
			
			makeScripts(op, display: display, index: op.indexRange.location, delta: delta)
			
			return display
		}
	}
	
	func findGlyph(forBoundary delimiter: String, withHeight glyphHeight: CGFloat) -> MTDisplay {
		var glyphAscent: CGFloat
		
		var glyphDescent: CGFloat
		
		var glyphWidth: CGFloat
		
		let leftGlyph = findGlyphForCharacter(at: 0, in: delimiter)
		
		let glyph = find(leftGlyph, withHeight: glyphHeight, glyphAscent: UnsafeMutablePointer<CGFloat>(mutating: &glyphAscent), glyphDescent: UnsafeMutablePointer<CGFloat>(mutating: &glyphDescent), glyphWidth: UnsafeMutablePointer<CGFloat>(mutating: &glyphWidth))
		
		var glyphDisplay: (MTDisplay & DownShift)?
		
		if glyphAscent + glyphDescent < glyphHeight {
			/* We didn't find a pre-built glyph that is large enough. */
			glyphDisplay = constructGlyph(leftGlyph, withHeight: glyphHeight)
		}
		
		if glyphDisplay == nil {
			/* Create a glyph display. */
			glyphDisplay = MTGlyphDisplay(glpyh: glyph, range: NSRange(location: NSNotFound, length: 0), font: styleFont)
			
			glyphDisplay?.ascent = glyphAscent
			
			glyphDisplay?.descent = glyphDescent
			
			glyphDisplay?.width = glyphWidth
		}
		
		/* Center the glyph on the axis. */
		let shiftDown: CGFloat = 0.5 * (glyphDisplay?.ascent - glyphDisplay?.descent) - (styleFont?.mathTable.axisHeight ?? 0.0)
		
		glyphDisplay?.shiftDown = shiftDown
		
		return glyphDisplay!
	}
	
	func makeUnderline(_ under: MTUnderLine) -> MTDisplay {
		var innerListDisplay: MTMathListDisplay? = nil
		
		if let font = font, let style = style {
			innerListDisplay = MTTypesetter.createLine(for: under.innerList, font: font, style: style, cramped: cramped)
		}
		
		var underDisplay = MTLineDisplay(inner: innerListDisplay, position: currentPosition, range: under.indexRange)
		
		/* Move the line down by the vertical gap. */
		underDisplay.lineShiftUp = -(innerListDisplay?.descent + styleFont?.mathTable.underbarVerticalGap)
		
		underDisplay.lineThickness = styleFont?.mathTable.underbarRuleThickness
		
		underDisplay.ascent = innerListDisplay?.ascent
		
		underDisplay.descent = innerListDisplay?.descent + styleFont?.mathTable.underbarVerticalGap + styleFont?.mathTable.underbarRuleThickness + styleFont?.mathTable.underbarExtraDescender
		
		underDisplay.width = innerListDisplay?.width
		
		return underDisplay
	}
	
	func makeOverline(_ over: MTOverLine) -> MTDisplay {
		var innerListDisplay: MTMathListDisplay? = nil
		
		if let font = font, let style = style {
			innerListDisplay = MTTypesetter.createLine(for: over.innerList, font: font, style: style, cramped: true)
		}
		
		var overDisplay = MTLineDisplay(inner: innerListDisplay, position: currentPosition, range: over.indexRange)
		
		overDisplay.lineShiftUp = innerListDisplay?.ascent + styleFont?.mathTable.overbarVerticalGap
		
		overDisplay.lineThickness = styleFont?.mathTable.underbarRuleThickness
		
		overDisplay.ascent = innerListDisplay?.ascent + styleFont?.mathTable.overbarVerticalGap + styleFont?.mathTable.overbarRuleThickness + styleFont?.mathTable.overbarExtraAscender
		
		overDisplay.descent = innerListDisplay?.descent
		
		overDisplay.width = innerListDisplay?.width
		
		return overDisplay
	}
	
	func isSingleCharAccentee(_ accent: MTAccent) -> Bool {
		if accent.innerList.atoms.count != 1 {
			return false		// Not a single-character list
		}
		
		let innerAtom = accent.innerList.atoms[0] as? MTMathAtom
		
		if innerAtom?.nucleus.unicodeLength != 1 {
			return false		// A complex atom, not a simple character
		}
		
		if innerAtom?.subScript || innerAtom?.superScript {
			return false
		}
		
		return true
	}
	
	/* Determine the distance that the accent must be moved from the beginning. */
	func getSkew(_ accent: MTAccent, accenteeWidth width: CGFloat, accentGlyph: CGGlyph) -> CGFloat {
		if accent.nucleus.length == 0 {
			return 0			// No accent
		}
		
		let accentAdjustment = styleFont?.mathTable.getTopAccentAdjustment(accentGlyph) ?? 0.0
		
		var accenteeAdjustment: CGFloat = 0
		
		if !isSingleCharAccentee(accent) {
			/* Use the center of the accentee. */
			accenteeAdjustment = width / 2
		} else {
			let innerAtom = accent.innerList.atoms[0] as? MTMathAtom
			
			let accenteeGlyph = findGlyphForCharacter(at: (innerAtom?.nucleus.length ?? 0) - 1, in: innerAtom?.nucleus ?? "")
			
			accenteeAdjustment = styleFont?.mathTable.getTopAccentAdjustment(accenteeGlyph) ?? 0.0
		}
		
		/* The adjustments need to aligned, so skew just equals the difference. */
		return accenteeAdjustment - accentAdjustment
	}
	
	/* Find the largest horizontal variant if it exists, with width less than max width. */
	func findVariantGlyph(_ glyph: CGGlyph, withMaxWidth maxWidth: CGFloat, glyphAscent: UnsafeMutablePointer<CGFloat>?, glyphDescent: UnsafeMutablePointer<CGFloat>?, glyphWidth: UnsafeMutablePointer<CGFloat>?) -> CGGlyph {
		var glyphAscent = glyphAscent
		
		var glyphDescent = glyphDescent
		
		var glyphWidth = glyphWidth
		
		let variants = styleFont?.mathTable.getHorizontalVariants(for: glyph)
		
		let numVariants = CFIndex((variants?.count ?? 0))
		
		assert(numVariants > 0, "A glyph is always it's own variant, so number of variants should be > 0")
		
		let glyphs = [CGGlyph](repeating: , count: numVariants)
		
		for i in 0..<numVariants {
			let glyph = variants?[i]?.int16Value ?? 0
			
			glyphs[i] = glyph
		}
		
		var curGlyph = glyphs[0] /* if no other glyph is found, we'll return the first one. */
		
		let bboxes = [CGRect](repeating: CGRect.zero, count: numVariants)
		
		let advances = [CGSize](repeating: CGSize.zero, count: numVariants)
		
		/* Get the bounds for these glyphs. */
		if let ctFont = styleFont?.ctFont {
			CTFontGetBoundingRectsForGlyphs(ctFont, .kCTFontHorizontalOrientation, &glyphs, &bboxes, numVariants)
			CTFontGetAdvancesForGlyphs(ctFont, .kCTFontHorizontalOrientation, &glyphs, &advances, numVariants)
		}
		
		for i in 0..<numVariants {
			let bounds = bboxes[i]
			
			var ascent: CGFloat
			
			var descent: CGFloat
			
			let width = bounds.maxX
			
			getBboxDetails(bounds, UnsafeMutablePointer<CGFloat>(mutating: &ascent), UnsafeMutablePointer<CGFloat>(mutating: &descent))
			
			if width > maxWidth {
				if i == 0 {
					/* Glyph dimensions are not yet set. */
					glyphWidth = UnsafeMutablePointer<CGFloat>(mutating: advances[i].width)
					
					glyphAscent = UnsafeMutablePointer<CGFloat>(mutating: &ascent)
					
					glyphDescent = UnsafeMutablePointer<CGFloat>(mutating: &descent)
				}
				return curGlyph
			} else {
				curGlyph = glyphs[i]
				
				glyphWidth = UnsafeMutablePointer<CGFloat>(mutating: advances[i].width)
				
				glyphAscent = UnsafeMutablePointer<CGFloat>(mutating: &ascent)
				
				glyphDescent = UnsafeMutablePointer<CGFloat>(mutating: &descent)
			}
		}
		
		/* We exhausted all the variants and none were larger than the width, so we return the largest. */
		return curGlyph
	}
	
	func make(_ accent: MTAccent) -> MTDisplay {
		var accentee: MTMathListDisplay? = nil
		
		if let font = font, let style = style {
			accentee = MTTypesetter.createLine(for: accent.innerList, font: font, style: style, cramped: true)
		}
		
		if accent.nucleus.length == 0 {
			/* no accent! */
			return accentee!
		}
		
		var accentGlyph = findGlyphForCharacter(at: accent.nucleus.length - 1, in: accent.nucleus)
		
		let accenteeWidth = accentee?.width ?? 0.0
		
		var glyphAscent: CGFloat
		
		var glyphDescent: CGFloat
		
		var glyphWidth: CGFloat
		
		accentGlyph = findVariantGlyph(accentGlyph, withMaxWidth: accenteeWidth, glyphAscent: UnsafeMutablePointer<CGFloat>(mutating: &glyphAscent), glyphDescent: UnsafeMutablePointer<CGFloat>(mutating: &glyphDescent), glyphWidth: UnsafeMutablePointer<CGFloat>(mutating: &glyphWidth))
		
		let delta = CGFloat(min(accentee?.ascent, styleFont?.mathTable.accentBaseHeight))
		
		let skew = getSkew(accent, accenteeWidth: accenteeWidth, accentGlyph: accentGlyph)
		
		let height = (accentee?.ascent ?? 0.0) - delta 		// Always positive because delta <= height
		
		let accentPosition = CGPoint(x: skew, y: height)
		
		var accentGlyphDisplay = MTGlyphDisplay(glpyh: accentGlyph, range: accent.indexRange, font: styleFont)
		
		accentGlyphDisplay.ascent = glyphAscent
		
		accentGlyphDisplay.descent = glyphDescent
		
		accentGlyphDisplay.width = glyphWidth
		
		accentGlyphDisplay.position = accentPosition
		
		if isSingleCharAccentee(accent) && (accent.subScript || accent.superScript) {
			/* Attach the super-, subscripts to the accentee instead of the accent. */
			let innerAtom = accent.innerList.atoms[0] as? MTMathAtom
			
			innerAtom?.superScript = accent.superScript
			
			innerAtom?.subScript = accent.subScript
			
			accent.superScript = nil
			
			accent.subScript = nil
			
			/* Latex adjusts the heights in case the height of the char is different in non-cramped mode. However, this shouldn't be the case because cramping only affects fractions and superscripts. Therefore, we skip adjusting the heights. */
			if let font = font, let style = style {
				/* Remake the accentee (now with sub-, superscripts). */
				accentee = MTTypesetter.createLine(for: accent.innerList, font: font, style: style, cramped: cramped)
			}
		}
		
		var display = MTAccentDisplay(accent: accentGlyphDisplay, accentee: accentee, range: accent.indexRange)
		
		display.width = accentee?.width
		
		display.descent = accentee?.descent
		
		let ascent = (accentee?.ascent ?? 0.0) - delta + glyphAscent
		
		display.ascent = max(accentee?.ascent, ascent)
		
		display.position = currentPosition
		
		return display
	}
	
	func make(_ table: MTMathTable) -> MTDisplay {
		let numColumns = table.numColumns
		
		/* Empty table */
		if numColumns == 0 || table.numRows == 0 {
			return MTMathListDisplay(displays: [AnyHashable](), range: table.indexRange)
		}
		
		let columnWidths = [CGFloat](repeating: 0.0, count: numColumns)
		
		/* Using memset to initialize columnWidths array avoids Xcode Analysis "Assigned value is garbage or undefined". */
		/* https://stackoverflow.com/questions/21191194/analyzer-warning-assigned-value-is-garbage-or-undefined */
		memset(columnWidths, 0, MemoryLayout.size(ofValue: columnWidths))
		
		let displays = typesetCells(table, columnWidths: columnWidths)
		
		/* Position all of the columns in each row. */
		var rowDisplays = [AnyHashable](repeating: 0, count: table.cells.count) as? [MTDisplay]
		
		for row in displays {
			let rowDisplay = makeRow(withColumns: row, for: table, columnWidths: columnWidths)
			
			rowDisplays?.append(rowDisplay)
		}
		
		/* Position all of the rows. */
		if let rowDisplays = rowDisplays {
			positionRows(rowDisplays, for: table)
		}
		
		let tableDisplay = MTMathListDisplay(displays: rowDisplays, range: table.indexRange)
		
		tableDisplay.position = currentPosition
		
		return tableDisplay
	}
	
	/* Typeset every cell in the table, and consequently calculate the max column width of each column. */
	func typesetCells(_ table: MTMathTable, columnWidths: [CGFloat]) -> [[MTDisplay]] {
		var displays = [AnyHashable](repeating: 0, count: table.numRows) as? [[MTDisplay]]
		
		for row in table.cells {
			var colDisplays = [AnyHashable](repeating: 0, count: row.count) as? [MTDisplay]
			
			if let colDisplays = colDisplays {
				displays?.append(colDisplays)
			}
			
			for i in 0..<row.count {
				var disp: MTMathListDisplay? = nil
				
				if let font = font, let style = style {
					disp = MTTypesetter.createLine(for: row[i], font: font, style: style, cramped: false)
				}
				
				columnWidths[i] = CGFloat(max(disp?.width, columnWidths[i]))
				
				if let disp = disp {
					colDisplays?.append(disp)
				}
			}
		}
		
		return displays ?? []
	}
	
	func makeRow(withColumns cols: [MTDisplay], for table: MTMathTable, columnWidths: [CGFloat]) -> MTMathListDisplay {
		var columnStart: CGFloat = 0
		
		var rowRange = NSRange(location: NSNotFound, length: 0)
		
		for i in 0..<cols.count {
			let col = cols[i]
			
			let colWidth = columnWidths[i]
			
			let alignment = table.getAlignmentForColumn(i)
			
			var cellPos = columnStart
			
			switch alignment {
				case kMTColumnAlignmentRight:
					cellPos += colWidth - col.width
				
				case kMTColumnAlignmentCenter:
					cellPos += (colWidth - col.width) / 2
				
				case kMTColumnAlignmentLeft:
					break		// No changes if already left-aligned
				
				default:
					break
			}
			
			if rowRange.location != NSNotFound {
				rowRange = NSUnionRange(rowRange, col.range)
			} else {
				rowRange = col.range
			}
			
			col.position = CGPoint(x: cellPos, y: 0)
			
			columnStart += colWidth + table.interColumnSpacing * styleFont?.mathTable.muUnit
		}
		
		/* Create a display for the row. */
		let rowDisplay = MTMathListDisplay(displays: cols, range: rowRange)
		
		return rowDisplay
	}
	
	/* Position the rows by first setting the rows starting from 0, and then centering the whole table vertically. */
	func positionRows(_ rows: [MTDisplay], for table: MTMathTable) {
		var currPos: CGFloat = 0
		
		let openup = table.interRowAdditionalSpacing * kJotMultiplier * (styleFont?.fontSize ?? 0.0)
		
		let baselineSkip = openup + kBaseLineSkipMultiplier * (styleFont?.fontSize ?? 0.0)
		
		let lineSkip = openup + kLineSkipMultiplier * (styleFont?.fontSize ?? 0.0)
		
		let lineSkipLimit = openup + kLineSkipLimitMultiplier * (styleFont?.fontSize ?? 0.0)
		
		var prevRowDescent: CGFloat = 0
		
		var ascent: CGFloat = 0
		
		var first = true
		
		for row in rows {
			if first {
				row.position = CGPoint.zero
				
				ascent += row.ascent
				
				first = false
			} else {
				var skip = baselineSkip
				
				if skip - (prevRowDescent + row.ascent) < lineSkipLimit {
					/* Rows are too close to each other. Space them apart further. */
					skip = prevRowDescent + row.ascent + lineSkip
				}
				
				/* We are moving downward, so decrease the y-value. */
				currPos -= skip
				
				row.position = CGPoint(x: 0, y: currPos)
			}
			
			prevRowDescent = row.descent
		}
		
		/* Vertically center the whole structure around the axis. The descent of the structure is the position of the last row plus the descent of the last row. */
		let descent = -currPos + prevRowDescent
		
		let shiftDown = 0.5 * (ascent - descent) - (styleFont?.mathTable.axisHeight ?? 0.0)
		
		for row in rows {
			row.position = CGPoint(x: row.position.x, y: row.position.y - shiftDown)
		}
	}
	
	func make(_ inner: MTInner, at index: Int) -> MTInnerDisplay {
		assert(inner.leftBoundary || inner.rightBoundary, "Inner should have a boundary to call this function")
		
		var innerListDisplay: MTMathListDisplay? = nil
		
		if let font = font, let style = style {
			innerListDisplay = MTTypesetter.createLine(for: inner.innerList, font: font, style: style, cramped: cramped)
		}
		
		let axisHeight = styleFont?.mathTable.axisHeight ?? 0.0
		
		/* Delta is the max distance from the axis. */
		let delta = CGFloat(max((innerListDisplay?.ascent ?? 0.0) - axisHeight, (innerListDisplay?.descent ?? 0.0) + axisHeight))
		
		let d1 = (delta / 500) * CGFloat(kDelimiterFactor) /* This represents atleast 90% of the formula */
		
		let d2 = 2 * delta - CGFloat(kDelimiterShortfallPoints) /* This represents a shortfall of 5pt */
		
		/* The size of the delimiter glyph should cover at least 90% of the formula or be no more than 5pt short. */
		let glyphHeight = CGFloat(max(d1, d2))
		
		var leftDelimiter: MTDisplay? = nil
		
		if inner.leftBoundary && inner.leftBoundary.nucleus.length > 0 {
			let leftGlyph = findGlyph(forBoundary: inner.leftBoundary.nucleus, withHeight: glyphHeight)
			
			if leftGlyph != nil {
				leftDelimiter = leftGlyph
			}
		}
		
		var rightDelimiter: MTDisplay? = nil
		
		if inner.rightBoundary && inner.rightBoundary.nucleus.length > 0 {
			let rightGlyph = findGlyph(forBoundary: inner.rightBoundary.nucleus, withHeight: glyphHeight)
			
			if rightGlyph != nil {
				rightDelimiter = rightGlyph
			}
		}
		
		let innerDisplay = MTInnerDisplay(inner: innerListDisplay, leftDelimiter: leftDelimiter, rightDelimiter: rightDelimiter, at: index)
		
		return innerDisplay
	}
}

var getInterElementSpacesInterElementSpaceArray: [AnyHashable]? = nil

func getInterElementSpaces() -> [AnyHashable]? {
	if getInterElementSpacesInterElementSpaceArray == nil {
		getInterElementSpacesInterElementSpaceArray =
		[
			[	// ordinary
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSMedium.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThick.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue)
			],
			[	// operator
				NSNumber(value: MTInterElementSpaceType.spaceThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceInvalid.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThick.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue)
			],
			[	// binary
				NSNumber(value: MTInterElementSpaceType.spaceNSMedium.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSMedium.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceInvalid.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceInvalid.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSMedium.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceInvalid.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceInvalid.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSMedium.rawValue)
			],
			[	// relation
				NSNumber(value: MTInterElementSpaceType.spaceNSThick.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThick.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceInvalid.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThick.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThick.rawValue)
			],
			[	// open
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceInvalid.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue)
			],
			[	// close
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSMedium.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThick.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue)
			],
			[	// punctuation
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceInvalid.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue)
			],
			[	// fraction
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSMedium.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThick.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue)
			],
			[	// radical
				NSNumber(value: MTInterElementSpaceType.spaceNSMedium.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSMedium.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThick.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNone.rawValue),
				NSNumber(value: MTInterElementSpaceType.spaceNSThin.rawValue)
			]
		]
	}
	
	return getInterElementSpacesInterElementSpaceArray
}

/* Identify the index for the given type. If row is `true`, then the index is for the row (i.e., left element); otherwise it's for the column (right element). */
func getInterElementSpaceArrayIndexForType(_ type: MTMathAtomType, _ row: Bool) -> Int {
	switch type {
		case kMTMathAtomColor, kMTMathAtomColorbox, kMTMathAtomOrdinary,
			kMTMathAtomPlaceholder							// A placeholder is treated as Ordinary.
			return 0
		
		case kMTMathAtomLargeOperator:
			return 1
		
		case kMTMathAtomBinaryOperator:
			return 2
		
		case kMTMathAtomRelation:
			return 3
		
		case kMTMathAtomOpen:
			return 4
		
		case kMTMathAtomClose:
			return 5
		
		case kMTMathAtomPunctuation:
			return 6
		
		case kMTMathAtomFraction, kMTMathAtomInner:			// Fractions and Inner are treated the same.
			return 7
		
		/* Radicals have inter-element spaces only when on the left side. This is a departure from latex but we don't want \sqrt{4}4 to look weird so we put a space in between. They have the same spacing as ordinary except with ordinary.*/
		case kMTMathAtomRadical:
			if row {
				return 8
			} else {
				assert(false, "Interelement space undefined for radical on the right. Treat radical as ordinary.")
				
				return -1
			}
		
		default:
			assert(false, String(format: "Interelement space undefined for type %lu", UInt(type)))
			
			return -1
	}
}

func IS_LOWER_EN(_ ch: Any) -> Bool {
	ch >= "a" && ch <= "z"
}

func IS_UPPER_EN(_ ch: Any) -> Bool {
	ch >= "A" && ch <= "Z"
}

func IS_NUMBER(_ ch: Any) -> Bool {
	ch >= "0" && ch <= "9"
}

func IS_LOWER_GREEK(_ ch: Any) -> Bool {
	ch >= kMTUnicodeGreekLowerStart && ch <= kMTUnicodeGreekLowerEnd
}

func IS_CAPITAL_GREEK(_ ch: Any) -> Bool {
	ch >= kMTUnicodeGreekCapitalStart && ch <= kMTUnicodeGreekCapitalEnd
}

var greekSymbolOrderGreekSymbols: [AnyHashable]?

/* In unicode, the Greek symbols epsilon, vartheta, varkappa, phi, varrho, varpi always appear in this particular order following the alphabet. */
func greekSymbolOrder(_ ch: unichar) -> Int {
	if greekSymbolOrderGreekSymbols == nil {
		greekSymbolOrderGreekSymbols = [NSNumber(value: 0x03f5), NSNumber(value: 0x03d1), NSNumber(value: 0x03f0), NSNumber(value: 0x03d5), NSNumber(value: 0x03f1), NSNumber(value: 0x03d6)]
	}
	
	return greekSymbolOrderGreekSymbols?.firstIndex(of: NSNumber(value: ch)) ?? NSNotFound
}

/* Italic (`mathit`): there are no italicized numbers in unicode so we don't support italicizing numbers. */
func getItalicized(_ ch: unichar) -> UTF32Char {
	var unicode = ch

	switch ch {
		case unichar("h"):
			return kMTUnicodePlanksConstant		 // Planck's constant
		default:
			break
	}
	
	if IS_UPPER_EN(ch) {
		if let aCh = (kMTUnicodeMathCapitalItalicStart + (ch - "A")) as? UTF32Char {
			unicode = aCh
		}
	}
	else if IS_LOWER_EN(ch) {
		if let aCh = (kMTUnicodeMathLowerItalicStart + (ch - "a")) as? UTF32Char {
			unicode = aCh
		}
	}
	else if IS_CAPITAL_GREEK(ch) {
		unicode = unichar(kMTUnicodeGreekCapitalItalicStart) + (ch - kMTUnicodeGreekCapitalStart)
	}
	else if IS_LOWER_GREEK(ch) {
		unicode = unichar(kMTUnicodeGreekLowerItalicStart) + (ch - kMTUnicodeGreekLowerStart)
	}
	else if IS_GREEK_SYMBOL(ch) {
		return Int(kMTUnicodeGreekSymbolItalicStart) + greekSymbolOrder(ch)
	}

	return unicode
}

/* Bold Face (`mathbf`) */
func getBold(_ ch: unichar) -> UTF32Char {
	var unicode = ch
	if IS_UPPER_EN(ch) {
		if let aCh = (kMTUnicodeMathCapitalBoldStart + (ch - "A")) as? UTF32Char {
			unicode = aCh
		}
	}
	else if IS_LOWER_EN(ch) {
		if let aCh = (kMTUnicodeMathLowerBoldStart + (ch - "a")) as? UTF32Char {
			unicode = aCh
		}
	}
	else if IS_CAPITAL_GREEK(ch) {
		unicode = unichar(kMTUnicodeGreekCapitalBoldStart) + (ch - kMTUnicodeGreekCapitalStart)
	}
	else if IS_LOWER_GREEK(ch) {
		unicode = unichar(kMTUnicodeGreekLowerBoldStart) + (ch - kMTUnicodeGreekLowerStart)
	}
	else if IS_GREEK_SYMBOL(ch) {
		return Int(kMTUnicodeGreekSymbolBoldStart) + greekSymbolOrder(ch)
	}
	else if IS_NUMBER(ch) {
		if let aCh = (kMTUnicodeNumberBoldStart + (ch - "0")) as? UTF32Char {
			unicode = aCh
		}
	}

	return unicode
}

/* Bold + Italic (`mathbfit`): There are no bold+italicized numbers, so we just bold them. */
func getBoldItalic(_ ch: unichar) -> UTF32Char {
	var unicode = ch
	if IS_UPPER_EN(ch) {
		if let aCh = (kMTUnicodeMathCapitalBoldItalicStart + (ch - "A")) as? UTF32Char {
			unicode = aCh
		}
	}
	else if IS_LOWER_EN(ch) {
		if let aCh = (kMTUnicodeMathLowerBoldItalicStart + (ch - "a")) as? UTF32Char {
			unicode = aCh
		}
	}
	else if IS_CAPITAL_GREEK(ch) {
		unicode = unichar(kMTUnicodeGreekCapitalBoldItalicStart) + (ch - kMTUnicodeGreekCapitalStart)
	}
	else if IS_LOWER_GREEK(ch) {
		unicode = unichar(kMTUnicodeGreekLowerBoldItalicStart) + (ch - kMTUnicodeGreekLowerStart)
	}
	else if IS_GREEK_SYMBOL(ch) {
		return Int(kMTUnicodeGreekSymbolBoldItalicStart) + greekSymbolOrder(ch)
	}
	else if IS_NUMBER(ch) {
		unicode = getBold(ch)
	}

	return unicode
}

/* LaTeX default  */
func getDefaultStyle(_ ch: unichar) -> UTF32Char {
	if IS_LOWER_EN(ch) || IS_UPPER_EN(ch) || IS_LOWER_GREEK(ch) || IS_GREEK_SYMBOL(ch) {
		return getItalicized(ch)
	} else if IS_NUMBER(ch) || IS_CAPITAL_GREEK(ch) {
		return ch		// Capital Greek & numbers are Roman
	} else if ch == "." {
		return ch		// "." is treated as a number in our code but it doesn't change fonts.

	} else {
		throw NSException(
			name: NSExceptionName("IllegalCharacter"),
			reason: "Unknown character \(ch) for default style.",
			userInfo: nil)
	}
	return ch
}

/* TODO: static const UTF32Char kMTUnicodeMathLowerScriptStart = 0x1D4B6; is unused in Latin Modern Math. If another font is used, determine if this should be applicable. */

/* Caligraphy (`mathcal`) and Script (`mathscr`) */
func getCaligraphic(_ ch: unichar) -> UTF32Char {
	switch ch {
		case unichar("B"):
			return 0x212c 		// Script B (bernoulli)
		case unichar("E"):
			return 0x2130 		// Script E (emf)
		
		case unichar("F"):
			return 0x2131 		// Script F (fourier)
		case unichar("H"):
			return 0x210b 		// Script H (hamiltonian)
		
		case unichar("I"):
			return 0x2110 		// Script I */
		case unichar("L"):
			return 0x2112 		// Script L (laplace)
		
		case unichar("M"):
			return 0x2133 		// Script M (M-matrix)
		case unichar("R"):
			return 0x211b 		// Script R (Riemann integral)

		case unichar("e"):
			return 0x212f 		// Script e (Natural exponent)
		case unichar("g"):
			return 0x210a 		// Script g (real number)
		case unichar("o"):
			return 0x2134 		// Script o (order)
		
		default:
			break
	}
	
	var unicode: UTF32Char
	
	if IS_UPPER_EN(ch) {
		if let aCh = (kMTUnicodeMathCapitalScriptStart + (ch - "A")) as? UTF32Char {
			unicode = aCh
		}
	}
	else if IS_LOWER_EN(ch) {
		/* Latin Modern Math does not have lowercase caligraphic characters, so we use the default style. */
		unicode = getDefaultStyle(ch)
	}
	else {
		/* Caligraphic characters don't exist for greek or numbers, so we use the default style. */
		unicode = getDefaultStyle(ch)
	}
	
	return unicode
}

/* Monospace (`mathtt`) */
func getTypewriter(_ ch: unichar) -> UTF32Char {
	if IS_UPPER_EN(ch) {
		return (kMTUnicodeMathCapitalTTStart + (ch - "A")) as! UTF32Char
	}
	else if IS_LOWER_EN(ch) {
		return (kMTUnicodeMathLowerTTStart + (ch - "a")) as! UTF32Char
	}
	else if IS_NUMBER(ch) {
		return (kMTUnicodeNumberTTStart + (ch - "0")) as! UTF32Char
	}
	
	/* Monospace characters don't exist for greek, so we use the default style. */
	return getDefaultStyle(ch)
}

/* Sans-Serif (`mathsf`) */
func getSansSerif(_ ch: unichar) -> UTF32Char {
	if IS_UPPER_EN(ch) {
		return (kMTUnicodeMathCapitalSansSerifStart + (ch - "A")) as! UTF32Char
	}
	else if IS_LOWER_EN(ch) {
		return (kMTUnicodeMathLowerSansSerifStart + (ch - "a")) as! UTF32Char
	}
	else if IS_NUMBER(ch) {
		return (kMTUnicodeNumberSansSerifStart + (ch - "0")) as! UTF32Char
	}
	
	/* Sans-serif characters don't exist for greek, so we use the default style. */
	return getDefaultStyle(ch)
}

/* Fraktur (`mathfrak`) */
func getFraktur(_ ch: unichar) -> UTF32Char {
	switch ch {
		case unichar("C"):
			return 0x212d 		// C Fraktur
		case unichar("H"):
			return 0x210c 		// Hilbert space
		
		case unichar("I"):
			return 0x2111 		// Imaginary
		case unichar("R"):
			return 0x211c 		// Real
		case unichar("Z"):
			return 0x2128 		// Z Fraktur
		
		default:
			break
	}
	
	if IS_UPPER_EN(ch) {
		return (kMTUnicodeMathCapitalFrakturStart + (ch - "A")) as! UTF32Char
	}
	else if IS_LOWER_EN(ch) {
		return (kMTUnicodeMathLowerFrakturStart + (ch - "a")) as! UTF32Char
	}
	
	/* Fraktur characters don't exist for greek & numbers, so we use the default style. */
	return getDefaultStyle(ch)
}

/* Double-Struck/Blackboard (`mathbb`) */
func getBlackboard(_ ch: unichar) -> UTF32Char {
	switch ch {
		case unichar("C"):
			return 0x2102 		// Complex numbers
		case unichar("H"):
			return 0x210d		// Quarternions
		
		case unichar("N"):
			return 0x2115 		// Natural numbers
		case unichar("P"):
			return 0x2119 		// Primes
		
		case unichar("Q"):
			return 0x211a 		// Rationals
		case unichar("R"):
			return 0x211d 		// Reals
		case unichar("Z"):
			return 0x2124 		// Integers
		
		default:
			break
	}
	
	if IS_UPPER_EN(ch) {
		return (kMTUnicodeMathCapitalBlackboardStart + (ch - "A")) as! UTF32Char
	}
	else if IS_LOWER_EN(ch) {
		return (kMTUnicodeMathLowerBlackboardStart + (ch - "a")) as! UTF32Char
	}
	else if IS_NUMBER(ch) {
		return (kMTUnicodeNumberBlackboardStart + (ch - "0")) as! UTF32Char
	}
	
	/* Blackboard characters don't exist for greek, so we use the default style. */
	return getDefaultStyle(ch)
}

private func styleCharacter(_ ch: unichar, _ fontStyle: MTFontStyle) -> UTF32Char {
	switch fontStyle {
		case kMTFontStyleDefault:
			return getDefaultStyle(ch)
		
		case kMTFontStyleRoman:
			return ch
		
		case kMTFontStyleBold:
			return getBold(ch)
		
		case kMTFontStyleItalic:
			return getItalicized(ch)
		
		case kMTFontStyleBoldItalic:
			return getBoldItalic(ch)
		
		case kMTFontStyleCaligraphic:
			return getCaligraphic(ch)
		
		case kMTFontStyleTypewriter:
			return getTypewriter(ch)
		
		case kMTFontStyleSansSerif:
			return getSansSerif(ch)
		
		case kMTFontStyleFraktur:
			return getFraktur(ch)
		
		case kMTFontStyleBlackboard:
			return getBlackboard(ch)
		
		default:
			throw NSException(
				name: NSExceptionName("Invalid style"),
				reason: String(format: "Unknown style %lu for font.", UInt(fontStyle)),
				userInfo: nil)
	}
	
	return ch
}

private func changeFont(_ str: String?, _ fontStyle: MTFontStyle) -> String? {
	var retval = String(repeating: "\0", count: str?.count ?? 0)
	
	let charBuffer = [unichar](repeating: 0, count: (str?.count ?? 0))
	
	(str as NSString?)?.getCharacters(&charBuffer, range: NSRange(location: 0, length: str?.count ?? 0))
	
	for i in 0..<(str?.count ?? 0) {
		let ch = charBuffer[i]
		
		var unicode = styleCharacter(ch, fontStyle)
		
		unicode = NSSwapHostIntToLittle(UInt32(unicode))
		
		let charStr = String(bytes: &unicode, encoding: .utf32LittleEndian)
		
		retval += charStr ?? ""
	}
	
	return retval
}

private func getBboxDetails(_ bbox: CGRect, _ ascent: UnsafeMutablePointer<CGFloat>?, _ descent: UnsafeMutablePointer<CGFloat>?) {
	var ascent = ascent
	
	var descent = descent
	
	if ascent != nil {
		ascent = max(0, bbox.maxY - 0)
	}
	
	/* Descent is how much the line goes below the origin. However, if the line is all above the origin, descent can't be negative. */
	if descent != nil {
		descent = max(0, 0 - bbox.minY)
	}
}
