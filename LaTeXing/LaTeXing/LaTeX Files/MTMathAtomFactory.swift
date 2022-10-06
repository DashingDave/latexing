//
//	MTMathAtomFactory.swift
//	ObjC -> Swift conversion of
//
//  MathAtomFactory.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI

let MTSymbolMultiplication: String? = nil
let MTSymbolMultiplication = "\u{00D7}"

let MTSymbolDivision: String? = nil
let MTSymbolDivision = "\u{00F7}"

let MTSymbolFractionSlash: String? = nil
let MTSymbolFractionSlash = "\u{2044}"

let MTSymbolWhiteSquare: String? = nil
let MTSymbolWhiteSquare = "\u{25A1}"

let MTSymbolBlackSquare: String? = nil
let MTSymbolBlackSquare = "\u{25A0}"

let MTSymbolLessEqual: String? = nil
let MTSymbolLessEqual = "\u{2264}"

let MTSymbolGreaterEqual: String? = nil
let MTSymbolGreaterEqual = "\u{2265}"

let MTSymbolNotEqual: String? = nil
let MTSymbolNotEqual = "\u{2260}"

let MTSymbolSquareRoot: String? = nil
let MTSymbolSquareRoot = "\u{221A}" // \sqrt

let MTSymbolCubeRoot: String? = nil
let MTSymbolCubeRoot = "\u{221B}"

let MTSymbolInfinity: String? = nil
let MTSymbolInfinity = "\u{221E}" // \infty

let MTSymbolAngle: String? = nil
let MTSymbolAngle = "\u{2220}" // \angle

let MTSymbolDegree: String? = nil
let MTSymbolDegree = "\u{00B0}" // \circ

/* A factory to create commonly used MTMathAtoms. */
class MTMathAtomFactory: NSObject {
	/* Returns an atom for the multiplication sign: "\times" or "*" */
	class func times() -> MTMathAtom {
		return MTMathAtom(type: kMTMathAtomBinaryOperator, value: MTSymbolMultiplication)
	}
	
	/* Returns an atom for the division sign. "\div" or "/" */
	class func divide() -> MTMathAtom {
		return MTMathAtom(type: kMTMathAtomBinaryOperator, value: MTSymbolDivision)
	}
	
	/* Returns an atom which is a placeholder square. */
	class func placeholder() -> MTMathAtom {
		return MTMathAtom(type: kMTMathAtomPlaceholder, value: MTSymbolWhiteSquare)
	}
	
	/* Returns a fraction with a placeholder for the numerator and denominator. */
	class func placeholderFraction() -> MTFraction {
		let frac = MTFraction()
		
		frac.numerator = MTMathList()
		
		frac.numerator.add(self.placeholder())
		
		frac.denominator = MTMathList()
		
		frac.denominator.add(self.placeholder())
		
		return frac
	}
	
	/* Returns a radical with a placeholder as the radicand. */
	class func placeholderRadical() -> MTRadical {
		let rad = MTRadical()
		
		rad.degree = MTMathList()
		
		rad.radicand = MTMathList()
		
		rad.degree.add(self.placeholder())
		
		rad.radicand.add(self.placeholder())
		
		return rad
	}
	
	/* Returns a square root with a placeholder as the radicand. */
	class func placeholderSquareRoot() -> MTRadical {
		let rad = MTRadical()
		
		rad.radicand = MTMathList()
		
		rad.radicand.add(self.placeholder())
		
		return rad
	}
	
	/* Returns a large opertor for the given name. If limits is true, limits are set up on the operator and displyed differently. */
	class func `operator`(withName name: String, limits: Bool) -> MTLargeOperator {
		return MTLargeOperator(value: name, limits: limits)
	}
	
	class func atom(forCharacter ch: unichar) -> MTMathAtom? {
		var ch = ch
		
		let chStr = String(characters: &ch)
		
		if ch > 0x0410 && ch < 0x044f {
			/* show basic cyrillic alphabet. Latin Modern Math font is not good for cyrillic symbols */
			return MTMathAtom(type: kMTMathAtomOrdinary, value: chStr)
		}
		else if ch < 0x21 || ch > 0x7e {		// Skip non ascii characters and spaces
			return nil
		}
		else if ch == "$" || ch == "%" || ch == "#" || ch == "&" || ch == "~" || ch == "\'" {		// Latex control characters
			return nil
		}
		else if ch == "^" || ch == "_" || ch == "{" || ch == "}" || ch == "\\" {		// More special LaTex characters
			return nil
		}
		else if ch == "(" || ch == "[" {
			return MTMathAtom(type: kMTMathAtomOpen, value: chStr)
		}
		else if ch == ")" || ch == "]" || ch == "!" || ch == "?" {
			return MTMathAtom(type: kMTMathAtomClose, value: chStr)
		}
		else if ch == "," || ch == ";" {
			return MTMathAtom(type: kMTMathAtomPunctuation, value: chStr)
		}
		else if ch == "=" || ch == ">" || ch == "<" {
			return MTMathAtom(type: kMTMathAtomRelation, value: chStr)
		}
		else if ch == ":" {
			return MTMathAtom(type: kMTMathAtomRelation, value: "\u{2236}")			// Ratio is ":"; colon is "\colon"
		}
		else if ch == "-" {
			return MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2212}")		// Use the math minus sign.
		}
		else if ch == "+" || ch == "*" {
			return MTMathAtom(type: kMTMathAtomBinaryOperator, value: chStr)
		}
		else if ch == "." || (ch >= "0" && ch <= "9") {
			return MTMathAtom(type: kMTMathAtomNumber, value: chStr)
		}
		else if (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") {
			return MTMathAtom(type: kMTMathAtomVariable, value: chStr)
		}
		else if ch == "\"" || ch == "/" || ch == "@" || ch == "`" || ch == "|" {
			return MTMathAtom(type: kMTMathAtomOrdinary, value: chStr)
		}
		else {
			assert(false, "Unknown ascii character \(NSNumber(value: ch)). Should have been accounted for.")
			return nil
		}
	}
	
	class func mathList(forCharacters chars: String) -> MTMathList {
		assert(chars != nil, "Invalid parameter not satisfying: chars != nil")
		
		let len = chars.count
		
		let buff = [unichar](repeating: 0, count: len)
		
		(chars as NSString).getCharacters(&buff, range: NSRange(location: 0, length: len))
		
		let list = MTMathList()
		
		for i in 0..<len {
			let atom = self.atom(forCharacter: buff[i])
		
			if let atom = atom {
				list.add(atom)
			}
		}
		
		return list
	}
	
	/* Returns an atom with the right type for a given latex symbol (e.g. theta). If the latex symbol is unknown this will return nil. This supports LaTeX aliases as well. */
	class func atom(forLatexSymbolName symbolName: String) -> MTMathAtom? {
		var symbolName = symbolName
		
		assert(symbolName != nil, "Invalid parameter not satisfying: symbolName != nil")
		
		let aliases = MTMathAtomFactory.aliases()
		
		/* First, check if this is an alias. */
		let canonicalName = aliases[symbolName] as? String
		
		if let canonicalName = canonicalName {
			/* Switch to the canonical name */
			symbolName = canonicalName
		}
		
		let commands = self.supportedLatexSymbols()
		
		let atom = commands[symbolName]
		
		if atom != nil {
			/* Return a copy of the atom because atoms are mutable. */
			return atom.copy()
		}
		
		return nil
	}
	
	/* Finds the name of the LaTeX symbol name for the given atom. This function is a reverse of the above function. If no latex symbol name corresponds to the atom, then this returns nil. */
	/* If nucleus of the atom is empty, then this will return nil . This is not an exact reverse of the above in the case of aliases. If an LaTeX alias points to a given symbol, then this function will return the original symbol name and not the alias. */
	/* This function does not convert MathSpaces to latex command names either. */
	class func latexSymbolName(for atom: MTMathAtom) -> String? {
		if atom.nucleus.length == 0 {
			return nil
		}
		
		let dict = MTMathAtomFactory.textToLatexSymbolNames()
		
		return dict[atom.nucleus]
	}
	
	/* Define a latex symbol for rendering. This function allows defining custom symbols that are not already present in the default set, or override existing symbols with new meaning. For example, to define a symbol for "lcm" one can call: `[MTMathAtomFactory addLatexSymbol:@"lcm" value:[MTMathAtomFactory operatorWithName:@"lcm" limits:NO]]` */
	class func addLatexSymbol(_ name: String, value atom: MTMathAtom) {
		assert(name != nil, "Invalid parameter not satisfying: name != nil")
		
		assert(atom != nil, "Invalid parameter not satisfying: atom != nil")
		
		var commands = self.supportedLatexSymbols()
		
		commands[name] = atom
		
		if atom.nucleus.length != 0 {
			var dict = self.textToLatexSymbolNames()
		
			dict[atom.nucleus] = name
		}
	}
	
	/* Returns a list of all supported lated symbols names. */
	class func supportedLatexSymbolNames() -> [String] {
		let commands = MTMathAtomFactory.supportedLatexSymbols()
		
		return commands.keys
	}
	
	/* Returns an accent with the given name. The name of the accent is the LaTeX name such as `grave`, `hat` etc. If the name is not a recognized accent name, this returns nil. The `innerList` of the returned `MTAccent` is nil. */
	class func accent(withName accentName: String) -> MTAccent? {
		let accents = MTMathAtomFactory.accents()
		
		let accentValue = accents[accentName]
		
		if accentValue != nil {
			return MTAccent(value: accentValue)
		} else {
			return nil
		}
	}
	
	/* Returns the accent name for the given accent. This is the reverse of the above function. */
	class func accentName(_ accent: MTAccent) -> String {
		let dict = MTMathAtomFactory.accentValueToName()
		
		return dict[accent.nucleus] as? String ?? ""
	}
	
	/* Creates a new boundary atom for the given delimiter name. If the delimiter name is not recognized it returns nil. A delimiter name can be a single character such as "(" or a latex command such as "\uparrow". */
	/* In order to distinguish between the delimiter "|" and the delimiter "\|", the delimiter "\|" the has been renamed to "||". */
	class func boundaryAtom(forDelimiterName delimName: String) -> MTMathAtom? {
		let delims = MTMathAtomFactory.delimiters()
		
		let delimValue = delims[delimName]
		
		if delimValue == nil {
			return nil
		}
		
		return MTMathAtom(type: kMTMathAtomBoundary, value: delimValue)
	}
	
	/* Returns the delimiter name for a boundary atom. This is a reverse of the above function. If the atom is not a boundary atom or if the delimiter value is unknown this returns `nil`. */
	/* This is not an exact reverse of the above function. Some delimiters have two names (e.g.`<` and `langle`) and this function always returns the shorter name. */
	class func delimiterName(forBoundaryAtom boundary: MTMathAtom) -> String? {
		if boundary.type != kMTMathAtomBoundary {
			return ""
		}
		
		let dict = self.delimValueToName()
		
		return dict[boundary.nucleus] as? String ?? ""
	}
	
	/* Returns a font style associated with the name. If none is found, returns NSNotFound. */
	class func fontStyle(withName fontName: String) -> MTFontStyle {
		let fontStyles = self.fontStyles()
		
		let style = fontStyles[fontName]
		
		if style == nil {
			return NSNotFound
		}
		
		return style.intValue
	}
	
	/* Returns the latex font name for a given style. */
	class func fontName(for fontStyle: MTFontStyle) -> String {
		switch fontStyle {
			case kMTFontStyleDefault:
				return "mathnormal"
			case kMTFontStyleRoman:
				return "mathrm"
			case kMTFontStyleBold:
				return "mathbf"
			case kMTFontStyleFraktur:
				return "mathfrak"
			case kMTFontStyleCaligraphic:
				return "mathcal"
			case kMTFontStyleItalic:
				return "mathit"
			case kMTFontStyleSansSerif:
				return "mathsf"
			case kMTFontStyleBlackboard:
				return "mathbb"
			case kMTFontStyleTypewriter:
				return "mathtt"
			case kMTFontStyleBoldItalic:
				return "bm"
			default:
				break
		}
	}
	
	/* Returns a fraction with the given numerator and denominator. */
	class func fraction(withNumerator num: MTMathList, denominator denom: MTMathList) -> MTFraction {
		let frac = MTFraction()
		
		frac.numerator = num
		
		frac.denominator = denom
		
		return frac
	}
	
	/* Simplification of above function when numerator and denominator are simple strings. This function uses `mathListForCharacters` to convert the strings to `MTMathList`s. */
	class func fraction(withNumeratorStr numStr: String, denominatorStr denomStr: String) -> MTFraction {
		let num = self.mathList(forCharacters: numStr)
		
		let denom = self.mathList(forCharacters: denomStr)
		
		return self.fraction(withNumerator: num, denominator: denom)
	}
	
	/* Builds a table for a given environment with the given rows. Returns a `MTMathAtom` containing the table and any other atoms necessary for the given environment. Returns nil and sets error if the table could not be built. Parameter env: The environment to use to build the table. If the env is nil, then the default table is built. */
	/* The reason this function returns a `MTMathAtom` and not a `MTMathTable` is because some matrix environments are have builtin delimiters added to the table and hence are returned as inner atoms. */
	static var tableMatrixEnvs: [String : [AnyHashable]]? = nil
	
	class func table(withEnvironment env: String?, rows: [[MTMathList]]) throws -> MTMathAtom? {
		let table = MTMathTable(environment: env)
		
		for i in 0..<rows.count {
			let row = rows[i]
			
			for j in 0..<row.count {
				table.setCell(row[j], forRow: i, column: j)
			}
		}
		
		if tableMatrixEnvs == nil {
			tableMatrixEnvs = [
				"matrix": [],
				"pmatrix": ["(", ")"],
				"bmatrix": ["[", "]"],
				"Bmatrix": ["{", "}"],
				"vmatrix": ["vert", "vert"],
				"Vmatrix": ["Vert", "Vert"]
			]
		}
		
		/* It is set to matrix as the delimiters are converted to latex outside the table. */
		if tableMatrixEnvs?[env ?? ""] != nil {
			table.environment = "matrix"
			
			table.interRowAdditionalSpacing = 0
			
			table.interColumnSpacing = 18
			
			/* All the lists are in textstyle */
			let style = MTMathStyle(style: kMTLineStyleText) as? MTMathAtom
			
			for i in 0..<table.cells.count {
				let row = table.cells[i] as? [MTMathList]
			
				for j in 0..<(row?.count ?? 0) {
					row?[j]?.insert(style, atIndex: 0)
				}
			}
			
			/* Add delimiters */
			let delims = tableMatrixEnvs?[env ?? ""]
			
			if (delims?.count ?? 0) == 2 {
				let inner = MTInner()
				
				inner.leftBoundary = self.boundaryAtom(forDelimiterName: delims?[0] as? String ?? "")
				
				inner.rightBoundary = self.boundaryAtom(forDelimiterName: delims?[1] as? String ?? "")
				
				inner.innerList = MTMathList(atoms: table, nil)
				
				return inner
			} else {
				return table
			}
		} else if env == nil {
			/* The default env. */
			table.interRowAdditionalSpacing = 1
			
			table.interColumnSpacing = 0
			
			let cols = table.numColumns
			
			for i in 0..<cols {
				table.setAlignment(kMTColumnAlignmentLeft, forColumn: i)
			}
			
			return table
		} else if (env == "eqalign") || (env == "split") || (env == "aligned") {
			if table.numColumns != 2 {
				let message = "\(env ?? "") environment can only have 2 columns"
				
				if error != nil {
					error = NSError(domain: MTParseError, code: Int(MTParseErrorInvalidNumColumns), userInfo: [
						NSLocalizedDescriptionKey: message
					])
				}
				
				return nil
			}
			/* Add a spacer before each of the second column elements. This is to create the correct spacing for = and other releations. */
			let spacer = MTMathAtom(type: kMTMathAtomOrdinary, value: "")
			
			for i in 0..<table.cells.count {
				let row = table.cells[i] as? [MTMathList]
				
				if (row?.count ?? 0) > 1 {
					row?[1]?.insert(spacer, atIndex: 0)
				}
			}
			
			table.interRowAdditionalSpacing = 1
			
			table.interColumnSpacing = 0
			
			table.setAlignment(kMTColumnAlignmentRight, forColumn: 0)
			
			table.setAlignment(kMTColumnAlignmentLeft, forColumn: 1)
			
			return table
		} else if (env == "displaylines") || (env == "gather") {
			if table.numColumns != 1 {
				let message = "\(env ?? "") environment can only have 1 column"
				
				if error != nil {
					error = NSError(domain: MTParseError, code: Int(MTParseErrorInvalidNumColumns), userInfo: [
						NSLocalizedDescriptionKey: message
					])
				}
				
				return nil
			}
			
			table.interRowAdditionalSpacing = 1
			
			table.interColumnSpacing = 0
			
			table.setAlignment(kMTColumnAlignmentCenter, forColumn: 0)
			
			return table
		} else if env == "eqnarray" {
			if table.numColumns != 3 {
				let message = "eqnarray environment can only have 3 columns"
				
				if error != nil {
					error = NSError(domain: MTParseError, code: Int(MTParseErrorInvalidNumColumns), userInfo: [
						NSLocalizedDescriptionKey: message
					])
				}
				
				return nil
			}
			
			table.interRowAdditionalSpacing = 1
			
			table.interColumnSpacing = 18
			
			table.setAlignment(kMTColumnAlignmentRight, forColumn: 0)
			
			table.setAlignment(kMTColumnAlignmentCenter, forColumn: 1)
			
			table.setAlignment(kMTColumnAlignmentLeft, forColumn: 2)
			
			return table
		} else if env == "cases" {
			if table.numColumns != 2 {
				let message = "cases environment can only have 2 columns"
				
				if error != nil {
					error = NSError(domain: MTParseError, code: Int(MTParseErrorInvalidNumColumns), userInfo: [
						NSLocalizedDescriptionKey: message
					])
				}
				
				return nil
			}
			
			table.interRowAdditionalSpacing = 0
			
			table.interColumnSpacing = 18
			
			table.setAlignment(kMTColumnAlignmentLeft, forColumn: 0)
			
			table.setAlignment(kMTColumnAlignmentLeft, forColumn: 1)
			
			/* All the lists are in textstyle */
			let style = MTMathStyle(style: kMTLineStyleText) as? MTMathAtom
			
			for i in 0..<table.cells.count {
				let row = table.cells[i] as? [MTMathList]
				
				for j in 0..<(row?.count ?? 0) {
					row?[j]?.insert(style, atIndex: 0)
				}
			}
			
			/* Add delimiters */
			let inner = MTInner()
			
			inner.leftBoundary = self.boundaryAtom(forDelimiterName: "{")
			
			inner.rightBoundary = self.boundaryAtom(forDelimiterName: ".")
			
			let space = self.atom(forLatexSymbolName: ",")
			
			inner.innerList = MTMathList(atoms: space, table, nil)
			
			return inner
		}
		
		if error != nil {
			let message = "Unknown environment: \(env ?? "")"
			
			error = NSError(domain: MTParseError, code: Int(MTParseErrorInvalidEnv), userInfo: [
				NSLocalizedDescriptionKey: message
			])
		}
		
		return nil
	}
	
	static var supportedLatexSymbolsCommands: [String : MTMathAtom]? = nil
	
	class func supportedLatexSymbols() -> [String : MTMathAtom] {
		if supportedLatexSymbolsCommands == nil {
			supportedLatexSymbolsCommands = [
				"square": MTMathAtomFactory.placeholder(),
				
				/* lowercase Greek characters */
				"alpha": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03B1}"),
				"beta": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03B2}"),
				"gamma": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03B3}"),
				"delta": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03B4}"),
				"varepsilon": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03B5}"),
				"zeta": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03B6}"),
				"eta": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03B7}"),
				"theta": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03B8}"),
				"iota": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03B9}"),
				"kappa": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03BA}"),
				"lambda": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03BB}"),
				"mu": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03BC}"),
				"nu": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03BD}"),
				"xi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03BE}"),
				"omicron": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03BF}"),
				"pi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C0}"),
				"rho": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C1}"),
				"varsigma": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C2}"),
				"sigma": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C3}"),
				"tau": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C4}"),
				"upsilon": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C5}"),
				"varphi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C6}"),
				"chi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C7}"),
				"psi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C8}"),
				"omega": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03C9}"),
				"vartheta": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03D1}"),
				"phi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03D5}"),
				"varpi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03D6}"),
				"varkappa": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03F0}"),
				"varrho": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03F1}"),
				"epsilon": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03F5}"),
				
				/* Uppercase greek characters */
				"Gamma": MTMathAtom(type: kMTMathAtomVariable, value: "\u{0393}"),
				"Delta": MTMathAtom(type: kMTMathAtomVariable, value: "\u{0394}"),
				"Theta": MTMathAtom(type: kMTMathAtomVariable, value: "\u{0398}"),
				"Lambda": MTMathAtom(type: kMTMathAtomVariable, value: "\u{039B}"),
				"Xi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{039E}"),
				"Pi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03A0}"),
				"Sigma": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03A3}"),
				"Upsilon": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03A5}"),
				"Phi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03A6}"),
				"Psi": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03A8}"),
				"Omega": MTMathAtom(type: kMTMathAtomVariable, value: "\u{03A9}"),
				
				/* Open */
				"lceil": MTMathAtom(type: kMTMathAtomOpen, value: "\u{2308}"),
				"lfloor": MTMathAtom(type: kMTMathAtomOpen, value: "\u{230A}"),
				"langle": MTMathAtom(type: kMTMathAtomOpen, value: "\u{27E8}"),
				"lgroup": MTMathAtom(type: kMTMathAtomOpen, value: "\u{27EE}"),
				
				/* Close */
				"rceil": MTMathAtom(type: kMTMathAtomClose, value: "\u{2309}"),
				"rfloor": MTMathAtom(type: kMTMathAtomClose, value: "\u{230B}"),
				"rangle": MTMathAtom(type: kMTMathAtomClose, value: "\u{27E9}"),
				"rgroup": MTMathAtom(type: kMTMathAtomClose, value: "\u{27EF}"),
				
				/* Arrows */
				"leftarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2190}"),
				"uparrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2191}"),
				"rightarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2192}"),
				"downarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2193}"),
				"leftrightarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2194}"),
				"updownarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2195}"),
				"nwarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2196}"),
				"nearrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2197}"),
				"searrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2198}"),
				"swarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2199}"),
				"mapsto": MTMathAtom(type: kMTMathAtomRelation, value: "\u{21A6}"),
				"Leftarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{21D0}"),
				"Uparrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{21D1}"),
				"Rightarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{21D2}"),
				"Downarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{21D3}"),
				"Leftrightarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{21D4}"),
				"Updownarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{21D5}"),
				"longleftarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{27F5}"),
				"longrightarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{27F6}"),
				"longleftrightarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{27F7}"),
				"Longleftarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{27F8}"),
				"Longrightarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{27F9}"),
				"Longleftrightarrow": MTMathAtom(type: kMTMathAtomRelation, value: "\u{27FA}"),
				
				/* Relations */
				"leq": MTMathAtom(type: kMTMathAtomRelation, value: MTSymbolLessEqual),
				"geq": MTMathAtom(type: kMTMathAtomRelation, value: MTSymbolGreaterEqual),
				"neq": MTMathAtom(type: kMTMathAtomRelation, value: MTSymbolNotEqual),
				"in": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2208}"),
				"notin": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2209}"),
				"ni": MTMathAtom(type: kMTMathAtomRelation, value: "\u{220B}"),
				"propto": MTMathAtom(type: kMTMathAtomRelation, value: "\u{221D}"),
				"mid": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2223}"),
				"parallel": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2225}"),
				"sim": MTMathAtom(type: kMTMathAtomRelation, value: "\u{223C}"),
				"simeq": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2243}"),
				"cong": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2245}"),
				"approx": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2248}"),
				"asymp": MTMathAtom(type: kMTMathAtomRelation, value: "\u{224D}"),
				"doteq": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2250}"),
				"equiv": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2261}"),
				"gg": MTMathAtom(type: kMTMathAtomRelation, value: "\u{226B}"),
				"ll": MTMathAtom(type: kMTMathAtomRelation, value: "\u{226A}"),
				"prec": MTMathAtom(type: kMTMathAtomRelation, value: "\u{227A}"),
				"succ": MTMathAtom(type: kMTMathAtomRelation, value: "\u{227B}"),
				"subset": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2282}"),
				"supset": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2283}"),
				"subseteq": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2286}"),
				"supseteq": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2287}"),
				"sqsubset": MTMathAtom(type: kMTMathAtomRelation, value: "\u{228F}"),
				"sqsupset": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2290}"),
				"sqsubseteq": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2291}"),
				"sqsupseteq": MTMathAtom(type: kMTMathAtomRelation, value: "\u{2292}"),
				"models": MTMathAtom(type: kMTMathAtomRelation, value: "\u{22A7}"),
				"perp": MTMathAtom(type: kMTMathAtomRelation, value: "\u{27C2}"),
				
				/* operators */
				"times": MTMathAtomFactory.times(),
				"div": MTMathAtomFactory.divide(),
				"pm": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{00B1}"),
				"dagger": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2020}"),
				"ddagger": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2021}"),
				"mp": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2213}"),
				"setminus": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2216}"),
				"ast": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2217}"),
				"circ": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2218}"),
				"bullet": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2219}"),
				"wedge": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2227}"),
				"vee": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2228}"),
				"cap": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2229}"),
				"cup": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{222A}"),
				"wr": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2240}"),
				"uplus": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{228E}"),
				"sqcap": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2293}"),
				"sqcup": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2294}"),
				"oplus": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2295}"),
				"ominus": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2296}"),
				"otimes": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2297}"),
				"oslash": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2298}"),
				"odot": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2299}"),
				"star": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{22C6}"),
				"cdot": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{22C5}"),
				"amalg": MTMathAtom(type: kMTMathAtomBinaryOperator, value: "\u{2A3F}"),
				
				/* No limit operators */
				"log": MTMathAtomFactory.`operator`(withName: "log", limits: false),
				"lg": MTMathAtomFactory.`operator`(withName: "lg", limits: false),
				"ln": MTMathAtomFactory.`operator`(withName: "ln", limits: false),
				"sin": MTMathAtomFactory.`operator`(withName: "sin", limits: false),
				"arcsin": MTMathAtomFactory.`operator`(withName: "arcsin", limits: false),
				"sinh": MTMathAtomFactory.`operator`(withName: "sinh", limits: false),
				"cos": MTMathAtomFactory.`operator`(withName: "cos", limits: false),
				"arccos": MTMathAtomFactory.`operator`(withName: "arccos", limits: false),
				"cosh": MTMathAtomFactory.`operator`(withName: "cosh", limits: false),
				"tan": MTMathAtomFactory.`operator`(withName: "tan", limits: false),
				"arctan": MTMathAtomFactory.`operator`(withName: "arctan", limits: false),
				"tanh": MTMathAtomFactory.`operator`(withName: "tanh", limits: false),
				"cot": MTMathAtomFactory.`operator`(withName: "cot", limits: false),
				"coth": MTMathAtomFactory.`operator`(withName: "coth", limits: false),
				"sec": MTMathAtomFactory.`operator`(withName: "sec", limits: false),
				"csc": MTMathAtomFactory.`operator`(withName: "csc", limits: false),
				"arg": MTMathAtomFactory.`operator`(withName: "arg", limits: false),
				"ker": MTMathAtomFactory.`operator`(withName: "ker", limits: false),
				"dim": MTMathAtomFactory.`operator`(withName: "dim", limits: false),
				"hom": MTMathAtomFactory.`operator`(withName: "hom", limits: false),
				"exp": MTMathAtomFactory.`operator`(withName: "exp", limits: false),
				"deg": MTMathAtomFactory.`operator`(withName: "deg", limits: false),
				
				/* Limit operators */
				"lim": MTMathAtomFactory.`operator`(withName: "lim", limits: true),
				"limsup": MTMathAtomFactory.`operator`(withName: "lim sup", limits: true),
				"liminf": MTMathAtomFactory.`operator`(withName: "lim inf", limits: true),
				"max": MTMathAtomFactory.`operator`(withName: "max", limits: true),
				"min": MTMathAtomFactory.`operator`(withName: "min", limits: true),
				"sup": MTMathAtomFactory.`operator`(withName: "sup", limits: true),
				"inf": MTMathAtomFactory.`operator`(withName: "inf", limits: true),
				"det": MTMathAtomFactory.`operator`(withName: "det", limits: true),
				"Pr": MTMathAtomFactory.`operator`(withName: "Pr", limits: true),
				"gcd": MTMathAtomFactory.`operator`(withName: "gcd", limits: true),
				
				/* Large operators */
				"prod": MTMathAtomFactory.`operator`(withName: "\u{220F}", limits: true),
				"coprod": MTMathAtomFactory.`operator`(withName: "\u{2210}", limits: true),
				"sum": MTMathAtomFactory.`operator`(withName: "\u{2211}", limits: true),
				"int": MTMathAtomFactory.`operator`(withName: "\u{222B}", limits: false),
				"oint": MTMathAtomFactory.`operator`(withName: "\u{222E}", limits: false),
				"bigwedge": MTMathAtomFactory.`operator`(withName: "\u{22C0}", limits: true),
				"bigvee": MTMathAtomFactory.`operator`(withName: "\u{22C1}", limits: true),
				"bigcap": MTMathAtomFactory.`operator`(withName: "\u{22C2}", limits: true),
				"bigcup": MTMathAtomFactory.`operator`(withName: "\u{22C3}", limits: true),
				"bigodot": MTMathAtomFactory.`operator`(withName: "\u{2A00}", limits: true),
				"bigoplus": MTMathAtomFactory.`operator`(withName: "\u{2A01}", limits: true),
				"bigotimes": MTMathAtomFactory.`operator`(withName: "\u{2A02}", limits: true),
				"biguplus": MTMathAtomFactory.`operator`(withName: "\u{2A04}", limits: true),
				"bigsqcup": MTMathAtomFactory.`operator`(withName: "\u{2A06}", limits: true),
				
				/* Latex command characters */
				"{": MTMathAtom(type: kMTMathAtomOpen, value: "{"),
				"}": MTMathAtom(type: kMTMathAtomClose, value: "}"),
				"$": MTMathAtom(type: kMTMathAtomOrdinary, value: "$"),
				"&": MTMathAtom(type: kMTMathAtomOrdinary, value: "&"),
				"#": MTMathAtom(type: kMTMathAtomOrdinary, value: "#"),
				"%": MTMathAtom(type: kMTMathAtomOrdinary, value: "%"),
				"_": MTMathAtom(type: kMTMathAtomOrdinary, value: "_"),
				" ": MTMathAtom(type: kMTMathAtomOrdinary, value: " "),
				"backslash": MTMathAtom(type: kMTMathAtomOrdinary, value: "\\"),
				
				/* Punctuation */
				"colon": MTMathAtom(type: kMTMathAtomPunctuation, value: ":"),		// \colon is different from : which is a relation
				"cdotp": MTMathAtom(type: kMTMathAtomPunctuation, value: "\u{00B7}"),
				
				/* Other symbols */
				"degree": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{00B0}"),
				"neg": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{00AC}"),
				"angstrom": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{00C5}"),
				"|": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2016}"),
				"vert": MTMathAtom(type: kMTMathAtomOrdinary, value: "|"),
				"ldots": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2026}"),
				"prime": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2032}"),
				"hbar": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{210F}"),
				"Im": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2111}"),
				"ell": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2113}"),
				"wp": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2118}"),
				"Re": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{211C}"),
				"mho": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2127}"),
				"aleph": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2135}"),
				"forall": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2200}"),
				"exists": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2203}"),
				"emptyset": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2205}"),
				"nabla": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2207}"),
				"infty": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{221E}"),
				"angle": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{2220}"),
				"top": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{22A4}"),
				"bot": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{22A5}"),
				"vdots": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{22EE}"),
				"cdots": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{22EF}"),
				"ddots": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{22F1}"),
				"triangle": MTMathAtom(type: kMTMathAtomOrdinary, value: "\u{25B3}"),
				"imath": MTMathAtom(type: kMTMathAtomOrdinary, value: "0001D6A4"),
				"jmath": MTMathAtom(type: kMTMathAtomOrdinary, value: "0001D6A5"),
				"partial": MTMathAtom(type: kMTMathAtomOrdinary, value: "0001D715"),
				
				/* Spacing */
				",": MTMathSpace(space: 3),
				">": MTMathSpace(space: 4),
				";": MTMathSpace(space: 5),
				"!": MTMathSpace(space: -3),
				"quad": MTMathSpace(space: 18) /* quad = 1em = 18mu */,
				"qquad": MTMathSpace(space: 36) /* qquad = 2em */,
				
				/* Style */
				"displaystyle": MTMathStyle(style: kMTLineStyleDisplay),
				"textstyle": MTMathStyle(style: kMTLineStyleText),
				"scriptstyle": MTMathStyle(style: kMTLineStyleScript),
				"scriptscriptstyle": MTMathStyle(style: kMTLineStyleScriptScript)
			]
		}
		
		return supportedLatexSymbolsCommands ?? [:]
	}
	
	static var aliasesVar: [AnyHashable : Any]? = nil
	
	class func aliases() -> [AnyHashable : Any] {
		if aliasesVar == nil {
			aliasesVar = [
				"lnot": "neg",
				"land": "wedge",
				"lor": "vee",
				"ne": "neq",
				"le": "leq",
				"ge": "geq",
				"lbrace": "{",
				"rbrace": "}",
				"Vert": "|",
				"gets": "leftarrow",
				"to": "rightarrow",
				"iff": "Longleftrightarrow",
				"AA": "angstrom"
			]
		}
		
		return aliasesVar ?? [:]
	}
	
	static var textToLatexSymbolNamesTextToCommands: [String : String]? = nil
	
	class func textToLatexSymbolNames() -> [String : String] {
		if textToLatexSymbolNamesTextToCommands == nil {
			let commands = self.supportedLatexSymbols()
			
			textToLatexSymbolNamesTextToCommands = [AnyHashable : Any](minimumCapacity: commands.count) as? [String : String]
			
			for command in commands {
				guard let command = command as? String else {
					continue
				}
			
				let atom = commands[command]
				
				if atom.nucleus.length == 0 {
					continue
				}
				
				let existingCommand = textToLatexSymbolNamesTextToCommands?[atom.nucleus]
				
				if let existingCommand = existingCommand {
					/* If there are 2 commands for the same symbol, choose one deterministically. */
					if command.count > existingCommand.count {
						/* Keep the shorter command */
						continue
					} else if command.count == existingCommand.count {
						/* If the length is the same, sort alphabetically */
						if command.compare(existingCommand) == .orderedDescending {
							continue
						}
					}
				}
				
				/* In other cases replace the command. */
				textToLatexSymbolNamesTextToCommands?[atom.nucleus] = command
			}
		}
		
		return textToLatexSymbolNamesTextToCommands ?? [:]
	}
	
	static var accentsVar: [AnyHashable : Any]? = nil
	
	class func accents() -> [String : String] {
		if accentsVar == nil {
			accentsVar = [
				"grave": "\u{0300}",
				"acute": "\u{0301}",
				"hat": "\u{0302}"		// `hat` and `widehat` behave the same.
				"tilde": "\u{0303}"		// `tilde` and `widetilde` behave the same.
				"bar": "\u{0304}",
				"breve": "\u{0306}",
				"dot": "\u{0307}",
				"ddot": "\u{0308}",
				"check": "\u{030C}",
				"vec": "\u{20D7}",
				"widehat": "\u{0302}",
				"widetilde": "\u{0303}"
			]
		}
		
		return accentsVar as? [String : String] ?? [:]
	}
	
	static var accentValueToNameAccentToCommands: [AnyHashable : Any]? = nil
	
	class func accentValueToName() -> [AnyHashable : Any] {
		if accentValueToNameAccentToCommands == nil {
			let accents = self.accents()
			
			var mutableDict = [AnyHashable : Any](minimumCapacity: accents.count)
			
			for command in accents {
				let acc = accents[command]
				
				let existingCommand = mutableDict[acc] as? String
				
				if let existingCommand = existingCommand {
					if command.count > existingCommand.count {
						/* Keep the shorter command. */
						continue
					} else if command.count == existingCommand.count {
						/* If the length is the same, sort alphabetically. */
						if command.compare(existingCommand) == .orderedDescending {
							continue
						}
					}
				}
				
				/* In other cases replace the command. */
				mutableDict[acc] = command
			}
			
			accentValueToNameAccentToCommands = mutableDict
		}
		
		return accentValueToNameAccentToCommands ?? [:]
	}
	
	static var delimitersDelims: [AnyHashable : Any]? = nil
	
	class func delimiters() -> [String : String] {
		if delimitersDelims == nil {
			delimitersDelims = [
				".": ""			// "." means no delimiter
				"(": "(",
				")": ")",
				"[": "[",
				"]": "]",
				"<": "\u{2329}",
				">": "\u{232A}",
				"/": "/",
				"\\": "\\",
				"|": "|",
				"lgroup": "\u{27EE}",
				"rgroup": "\u{27EF}",
				"||": "\u{2016}",
				"Vert": "\u{2016}",
				"vert": "|",
				"uparrow": "\u{2191}",
				"downarrow": "\u{2193}",
				"updownarrow": "\u{2195}",
				"Uparrow": "21D1",
				"Downarrow": "21D3",
				"Updownarrow": "21D5",
				"backslash": "\\",
				"rangle": "\u{232A}",
				"langle": "\u{2329}",
				"rbrace": "}",
				"}": "}",
				"{": "{",
				"lbrace": "{",
				"lceil": "\u{2308}",
				"rceil": "\u{2309}",
				"lfloor": "\u{230A}",
				"rfloor": "\u{230B}"
			]
		}
		
		return delimitersDelims as? [String : String] ?? [:]
	}
	
	static var delimValueToNameDelimToCommands: [AnyHashable : Any]? = nil
	
	class func delimValueToName() -> [AnyHashable : Any] {
		if delimValueToNameDelimToCommands == nil {
			let delims = self.delimiters()
			
			var mutableDict = [AnyHashable : Any](minimumCapacity: delims.count)
			
			for command in delims {
				let delim = delims[command]
				
				let existingCommand = mutableDict[delim] as? String
				
				if let existingCommand = existingCommand {
					if command.count > existingCommand.count {
						/* Keep the shorter command. */
						continue
					} else if command.count == existingCommand.count {
						/* If the length is the same, sort alphabetically. */
						if command.compare(existingCommand) == .orderedDescending {
							continue
						}
					}
				}
				
				/* In other cases, replace the command. */
				mutableDict[delim] = command
			}

			delimValueToNameDelimToCommands = mutableDict
		}
		
		return delimValueToNameDelimToCommands ?? [:]
	}
	
	static var fontStylesVar: [String : NSNumber]? = nil
	
	class func fontStyles() -> [String : NSNumber] {
		if fontStylesVar == nil {
			fontStylesVar = [
				"mathnormal": NSNumber(value: kMTFontStyleDefault),
				"mathrm": NSNumber(value: kMTFontStyleRoman),
				"textrm": NSNumber(value: kMTFontStyleRoman),
				"rm": NSNumber(value: kMTFontStyleRoman),
				"mathbf": NSNumber(value: kMTFontStyleBold),
				"bf": NSNumber(value: kMTFontStyleBold),
				"textbf": NSNumber(value: kMTFontStyleBold),
				"mathcal": NSNumber(value: kMTFontStyleCaligraphic),
				"cal": NSNumber(value: kMTFontStyleCaligraphic),
				"mathtt": NSNumber(value: kMTFontStyleTypewriter),
				"texttt": NSNumber(value: kMTFontStyleTypewriter),
				"mathit": NSNumber(value: kMTFontStyleItalic),
				"textit": NSNumber(value: kMTFontStyleItalic),
				"mit": NSNumber(value: kMTFontStyleItalic),
				"mathsf": NSNumber(value: kMTFontStyleSansSerif),
				"textsf": NSNumber(value: kMTFontStyleSansSerif),
				"mathfrak": NSNumber(value: kMTFontStyleFraktur),
				"frak": NSNumber(value: kMTFontStyleFraktur),
				"mathbb": NSNumber(value: kMTFontStyleBlackboard),
				"mathbfit": NSNumber(value: kMTFontStyleBoldItalic),
				"bm": NSNumber(value: kMTFontStyleBoldItalic),
				"text": NSNumber(value: kMTFontStyleRoman)
			]
		}
		
		return fontStylesVar ?? [:]
	}
}
