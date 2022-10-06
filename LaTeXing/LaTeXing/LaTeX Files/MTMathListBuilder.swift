//
//	MTMathListBuilder.swift
//	ObjC -> Swift conversion of
//
//  MTMathListBuilder.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 8/28/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI

let MTParseError = ""
let MTParseError = "ParseError"

/* The error encountered when parsing a LaTeX string. The `code` in the `NSError` is one of the following indicating why the LaTeX string could not be parsed. */
enum MTParseErrors : Int {
		case mismatchBraces = 1		// The braces { } do not match.
		
		case invalidCommand			// A command in the string is not recognized.
		
		case characterNotFound		// An expected character such as ] was not found.
		
		case missingDelimiter		// The \left or \right command was not followed by a delimiter.
		
		case invalidDelimiter		// The delimiter following \left or \right was not a valid delimiter.
		
		case missingRight			// There is no \right corresponding to the \left command.
		
		case missingLeft			// There is no \left corresponding to the \right command.
		
		case invalidEnv				// The environment given to the \begin command is not recognized.
		
		case missingEnv				// A command is used which is only valid inside a \begin or \end environment.
		
		case missingBegin			// There is no \begin corresponding to the \end command.
		
		case missingEnd				// There is no \end corresponding to the \begin command.
			
		case invalidNumColumns		// There is no \end corresponding to the \begin command.
		
		case internalError			// Internal error, due to a programming mistake.
		
		case invalidLimits			// Limit control applied incorrectly
	}

/* `MTMathListBuilder` is a class for parsing LaTeX into an `MTMathList` that can be rendered and processed mathematically. */
class MTMathListBuilder: NSObject {
	private var chars: UnsafeMutablePointer<unichar>?
	
	private var currentChar = 0
	
	private var length = 0
	
	private var currentInnerAtom: MTInner?
	
	private var currentEnv: MTEnvProperties?
	
	private var currentFontStyle: MTFontStyle?
	
	private var spacesAllowed = false

	/* Contains any error that occurred during parsing. */
	private(set) var error: Error?
	
	override init() {
	}
	
	/* Create a `MTMathListBuilder` for the given string. After instantiating the `MTMathListBuilder, use `build` to build the mathlist. Create a new `MTMathListBuilder` for each string that needs to be parsed. Do not reuse the object. */
	/* Parameter - (str: The LaTeX string to be used to build the `MTMathList`) */
	required init(string str: String) {
		super.init()
		
		error = nil
		
		chars = malloc(MemoryLayout<unichar>.size * str.count)
		
		length = str.count
		if let chars = chars {
			(str as NSString).getCharacters(chars, range: NSRange(location: 0, length: str.count))
		}
		
		currentChar = 0
		
		currentFontStyle = kMTFontStyleDefault
	}
	
	deinit {
		free(chars)
	}
	
	func hasCharacters() -> Bool {
		return currentChar < length
	}
	
	/* Gets the next character and moves the pointer ahead/ */
	func getNextCharacter() -> unichar {
		assert(hasCharacters(), String(format: "Retrieving character at index %d beyond length %lu", currentChar, UInt(length)))
		
		return unichar(chars?[currentChar] ?? 0)
		
		currentChar += 1
	}
	
	func unlookCharacter() {
		assert(currentChar > 0, "Unlooking when at the first character.")
		
		currentChar -= 1
	}
	
	/* Builds a MathList from the given string. Returns nil if there is an error. */
	func build() -> MTMathList? {
		let list = buildInternal(false)
		
		if hasCharacters() && error == nil {
			/* something went wrong most likely braces mismatched */
			var errorMessage: String? = nil
			
			if let chars = chars {
				errorMessage = "Mismatched braces: \(String(characters: chars))"
			}
			
			setError(.mismatchBraces, message: errorMessage)
		}
		
		if error != nil {
			return nil
		}
		
		return list
	}
	
	func buildInternal(_ oneCharOnly: Bool) -> MTMathList? {
		return buildInternal(oneCharOnly, stopChar: unichar(0))
	}
	
	func buildInternal(_ oneCharOnly: Bool, stopChar stop: unichar) -> MTMathList? {
		let list = MTMathList()
		
		assert(!(oneCharOnly && (stop > 0)), "Cannot set both oneCharOnly and stopChar.")
		
		var prevAtom: MTMathAtom? = nil
		
		while hasCharacters() {
			if error != nil {
				/* If there is an error, then bail out. */
				return nil
			}
		
			var atom: MTMathAtom? = nil
			
			let ch = getNextCharacter()
			
			if oneCharOnly {
				if ch == "^" || ch == "}" || ch == "_" || ch == "&" {
					unlookCharacter()		// This is not the character we are looking for.

					return list
				}
			}
			
			/* If there is a stop character, keep scanning till we find it. */
			if stop > 0 && ch == stop {
				return list
			}
			
			if ch == "^" {
				assert(!oneCharOnly, "This should have been handled before")
				
				if prevAtom == nil || prevAtom?.superScript || !prevAtom?.scriptsAllowed {
					/* If there is no previous atom, or if it already has a superscript or if scripts are not allowed for it, then add an empty node. */
					prevAtom = MTMathAtom(type: kMTMathAtomOrdinary, value: "")
				
					list.add(prevAtom)
				}
				/* This is a superscript for the previous atom. If the next char is the stopChar, it will be consumed by the ^ and so it doesn't count as stop. */
				prevAtom?.superScript = buildInternal(true)
				
				continue
			} else if ch == "_" {
				assert(!oneCharOnly, "This should have been handled before")
				
				if prevAtom == nil || prevAtom?.subScript || !prevAtom?.scriptsAllowed {
					/* If there is no previous atom, or if it already has a subcript or if scripts are not allowed for it, then add an empty node. */
					prevAtom = MTMathAtom(type: kMTMathAtomOrdinary, value: "")
					
					list.add(prevAtom)
				}
				
				/* This is a subscript for the previous atom. If the next char is the stopChar, it will be consumed by the _ and so it doesn't count as stop */
				prevAtom?.subScript = buildInternal(true)
				
				continue
			} else if ch == "{" {
				/* This puts us in a recursive routine, and sets oneCharOnly to false with no stop character. */
				let sublist = buildInternal(false, stopChar: unichar("}"))
				
				prevAtom = sublist?.atoms.last as? MTMathAtom
				
				list.append(sublist)
				
				if oneCharOnly {
					return list
				}
				
				continue
			} else if ch == "}" {
				assert(!oneCharOnly, "This should have been handled before")
				
				assert(stop == 0, "This should have been handled before")
				
				/* We encountered a closing brace when there is no stop set, that means there was no corresponding opening brace. */
				let errorMessage = "Mismatched braces."
				
				setError(.mismatchBraces, message: errorMessage)
				
				return nil
			} else if ch == "\\" {			// "\" means a command
				let command = readCommand()
				
				let done = stopCommand(command, list: list, stopChar: stop)
				
				if let done = done {
					return done
				} else if error != nil {
					return nil
				}
				
				if applyModifier(command, atom: prevAtom) {
					continue
				}
				
				let fontStyle = MTMathAtomFactory.fontStyle(withName: command)
				
				if Int(fontStyle) != NSNotFound {
					let oldSpacesAllowed = spacesAllowed
					
					/* Text has special consideration where it allows spaces without escaping. */
					spacesAllowed = command == "text"
					
					let oldFontStyle = currentFontStyle
					
					currentFontStyle = fontStyle
					
					let sublist = buildInternal(true)
					
					/* Restore the font style. */
					currentFontStyle = oldFontStyle
					
					spacesAllowed = oldSpacesAllowed
					
					prevAtom = sublist?.atoms.last as? MTMathAtom
					
					list.append(sublist)
					
					if oneCharOnly {
						return list
					}
					
					continue
				}
				
				atom = self.atom(forCommand: command)
				
				if atom == nil {
					/* Unknown command; flag an error and return. */
					/* `setError` will not set the error if there is already one, so we flag internal error in the odd case that an _error is not set. */
					setError(.internalError, message: "Internal error")
					
					return nil
				}
			} else if ch == "&" {		// Used for column separation in tables
				assert(!oneCharOnly, "This should have been handled before")
				
				if currentEnv != nil {
					return list
				} else {
					/* Create a new table with the current list and a default env. */
					let table = buildTable(nil, firstList: list, row: false)
					
					return MTMathList(atoms: table, nil)
				}
			} else if spacesAllowed && ch == " " {			// Allowed spaces do not need "\" escape being used.
				atom = MTMathAtomFactory.atom(forLatexSymbolName: " ")
			} else {
				atom = MTMathAtomFactory.atom(forCharacter: ch)
				
				if atom == nil {		// Unrecognized character
					continue
				}
			}
			
			assert(atom != nil, "Atom shouldn't be nil")
			
			atom?.fontStyle = currentFontStyle
			
			list.add(atom)
			
			prevAtom = atom
			
			if oneCharOnly {		// We consumed our oneChar
				return list
			}
		}
		
		if stop > 0 {
			if stop == "}" {
				/* We did not find a corresponding closing brace. */
				setError(.mismatchBraces, message: "Missing closing brace")
			} else {
				/* We never found our stop character. */
				let errorMessage = "Expected character not found: \(stop)"
				
				setError(.characterNotFound, message: errorMessage)
			}
		}
		
		return list
	}
	
	/* A string of all upper and lower case characters. */
	func readString() -> String? {
		var mutable = ""
		
		while hasCharacters() {
			var ch = getNextCharacter()
			
			if (ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") {
				mutable += String(characters: &ch)
			} else {
				/* We went too far. */
				unlookCharacter()
			
				break
			}
		}
		
		return mutable
	}
	
	func readColor() -> String? {
		if !expectCharacter(unichar("{")) {
			/* We didn't find an opening brace, so no env found. */
			setError(.characterNotFound, message: "Missing {")
			
			return nil
		}
		
		/* Ignore spaces and nonascii. */
		skipSpaces()
		
		/* A string of all upper and lower case characters. */
		var mutable = ""
		
		while hasCharacters() {
			var ch = getNextCharacter()
			
			if ch == "#" || (ch >= "A" && ch <= "F") || (ch >= "a" && ch <= "f") || (ch >= "0" && ch <= "9") {
				mutable += String(characters: &ch)
			} else {
				/* We went too far. */
				unlookCharacter()
				
				break
			}
		}
		
		if !expectCharacter(unichar("}")) {
			/* We didn't find an closing brace, so invalid format. */
			setError(.characterNotFound, message: "Missing }")
			
			return nil
		}
		
		return mutable
	}
	
	func skipSpaces() {
		while hasCharacters() {
			let ch = getNextCharacter()
			
			if ch < 0x21 || ch > 0x7e {
				/* Ignore spaces and nonascii. */
				continue
			} else {
				unlookCharacter()
				
				return
			}
		}
	}
	
	func MTAssertNotSpace(_ ch: Any) {
		assert(ch >= 0x21 && ch <= 0x7e, "Expected non space character \(ch)")
	}
	
	func expectCharacter(_ ch: unichar) -> Bool {
		MTAssertNotSpace(ch)
		
		skipSpaces()
		
		if hasCharacters() {
			let c = getNextCharacter()
			
			MTAssertNotSpace(c)
			
			if c == ch {
				return true
			} else {
				unlookCharacter()
			
				return false
			}
		}
		
		return false
	}
	
	static var readCommandSingleCharCommands: Set<NSNumber>? = nil
	
	func readCommand() -> String? {
		if !MTMathListBuilder.readCommandSingleCharCommands {
			let singleChars =
				[NSNumber(value: String("{").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String("}").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String("$").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String("#").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String("%").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String("_").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String("|").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String(" ").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String(",").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String(">").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String(";").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String("!").utf8.map{ Int8($0) }.first ?? 0),
				 NSNumber(value: String("\\").utf8.map{ Int8($0) }.first ?? 0)]
			
			MTMathListBuilder.readCommandSingleCharCommands = Set<AnyHashable>(array: singleChars)
		}
		if hasCharacters() {
			/* Check if we have a single character command. */
			var ch = getNextCharacter()
			
			if MTMathListBuilder.readCommandSingleCharCommands.contains(NSNumber(value: ch)) {		// Single char commands
				return String(characters: &ch)
			} else {
				/* Not a known single character command */
				unlookCharacter()
			}
		}

		/* Otherwise a command is a string of all upper and lower case characters. */
		return readString()
	}
	
	func readDelimiter() -> String? {
		/* Ignore spaces and nonascii. */
		skipSpaces()
		
		while hasCharacters() {
			var ch = getNextCharacter()
			
			MTAssertNotSpace(ch)
			
			if ch == "\\" {			// "\" means a command
				let command = readCommand()
				
				/* "|" is a command and also a regular delimiter. We use the || command to distinguish between the 2 cases for the caller. */
				if command == "|" {
					return "||"
				}
				
				return command
			} else {
				return String(characters: &ch)
			}
		}
		
		/* We ran out of characters for delimiter. */
		return nil
	}
	
	func readEnvironment() -> String? {
		if !expectCharacter(unichar("{")) {
			/* We didn't find an opening brace, so no env found. */
			setError(.characterNotFound, message: "Missing {")
			
			return nil
		}
		
		/* Ignore spaces and nonascii. */
		skipSpaces()
		
		let env = readString()
		
		if !expectCharacter(unichar("}")) {
			/* We didn't find an closing brace, so invalid format. */
			setError(.characterNotFound, message: "Missing }")
			
			return nil
		}
		
		return env
	}
	
	func getBoundaryAtom(_ delimiterType: String?) -> MTMathAtom? {
		let delim = readDelimiter()
		
		if delim == nil {
			let errorMessage = "Missing delimiter for \\\(delimiterType ?? "")"
			
			setError(.missingDelimiter, message: errorMessage)
			
			return nil
		}
		
		let boundary = MTMathAtomFactory.boundaryAtom(forDelimiterName: delim)
		
		if boundary == nil {
			let errorMessage = "Invalid delimiter for \\\(delimiterType ?? ""): \(delim ?? "")"
			
			setError(.invalidDelimiter, message: errorMessage)
			
			return nil
		}
		
		return boundary
	}
	
	func atom(forCommand command: String?) -> MTMathAtom? {
		let atom = MTMathAtomFactory.atom(forLatexSymbolName: command)
		
		if let atom = atom {
			return atom
		}
		
		let accent = MTMathAtomFactory.accent(withName: command)
		
		if let accent = accent {		// The command is an accent.
			accent?.innerList = buildInternal(true)
			
			return accent
		}
		else if command == "frac" {			// A fraction command has 2 arguments.
			let frac = MTFraction()
			
			frac.numerator = buildInternal(true)
			
			frac.denominator = buildInternal(true)
			
			return frac
		}
		else if command == "binom" {		// A binom command has 2 arguments.
			let frac = MTFraction(rule: false)
			
			frac.numerator = buildInternal(true)
			
			frac.denominator = buildInternal(true)
			
			frac.leftDelimiter = "("
			
			frac.rightDelimiter = ")"
			
			return frac
		}
		else if command == "sqrt" {			// A sqrt command with one argument.
			let rad = MTRadical()
			
			let ch = getNextCharacter()
			
			if ch == "[" {			// Special handling for sqrt[degree]{radicand}.
				rad.degree = buildInternal(false, stopChar: unichar("]"))
				
				rad.radicand = buildInternal(true)
			} else {
				unlookCharacter()
				
				rad.radicand = buildInternal(true)
			}
			
			return rad
		}
		else if command == "left" {
			/* Save the current inner while a new one gets built. */
			let oldInner = currentInnerAtom
			
			currentInnerAtom = MTInner()
			
			currentInnerAtom?.leftBoundary = getBoundaryAtom("left")
			
			if !currentInnerAtom?.leftBoundary {
				return nil
			}
			
			currentInnerAtom?.innerList = buildInternal(false)
			
			if !currentInnerAtom?.rightBoundary {
				/* A right node would have set the right boundary, so we must be missing the right node. */
				let errorMessage = "Missing \\right"
				
				setError(.missingRight, message: errorMessage)
				
				return nil
			}
			let newInner = currentInnerAtom			// Reinstate the old inner atom.
			
			currentInnerAtom = oldInner
			
			return newInner
		}
		else if command == "overline" {			// The overline command has 1 argument.
			let over = MTOverLine()
			
			over.innerList = buildInternal(true)
			
			return over
		}
		else if command == "underline" {		// The underline command has 1 argument.
			let under = MTUnderLine()
			
			under.innerList = buildInternal(true)
			
			return under
		}
		else if command == "begin" {
			let env = readEnvironment()
			
			if env == nil {
				return nil
			}
			
			let table = buildTable(env, firstList: nil, row: false)
			
			return table
		}
		else if command == "color" {		// A color command has 2 arguments.
			let mathColor = MTMathColor()
			
			mathColor.colorString = readColor()
			
			mathColor.innerList = buildInternal(true)
			
			return mathColor
		}
		else if command == "colorbox" {			// A color command has 2 arguments
			let mathColorbox = MTMathColorbox()
			
			mathColorbox.colorString = readColor()
			
			mathColorbox.innerList = buildInternal(true)
			
			return mathColorbox
		}
		else {
			let errorMessage = "Invalid command \\\(command ?? "")"
			
			setError(.invalidCommand, message: errorMessage)
			
			return nil
		}
	}
	
	static var stopCommandFractionCommands: [String : [AnyHashable]]? = nil
	
	func stopCommand(_ command: String?, list: MTMathList?, stopChar: unichar) -> MTMathList? {
		if !MTMathListBuilder.stopCommandFractionCommands {
			MTMathListBuilder.stopCommandFractionCommands = [
				"over": [],
				"atop": [],
				"choose": ["(", ")"],
				"brack": ["[", "]"],
				"brace": ["{", "}"]
			]
		}
		if command == "right" {
			if currentInnerAtom == nil {
				let errorMessage = "Missing \\left"
				
				setError(.missingLeft, message: errorMessage)
				
				return nil
			}
			
			currentInnerAtom?.rightBoundary = getBoundaryAtom("right")
			
			if !currentInnerAtom?.rightBoundary {
				return nil
			}
			
			/* Return the list read so far. */
			return list
		} else if MTMathListBuilder.stopCommandFractionCommands[command ?? ""] != nil {
			var frac: MTFraction? = nil
			
			if command == "over" {
				frac = MTFraction()
			} else {
				frac = MTFraction(rule: false)
			}
			
			let delims = MTMathListBuilder.stopCommandFractionCommands[command ?? ""] as? [AnyHashable]
			
			if (delims?.count ?? 0) == 2 {
				frac?.leftDelimiter = delims?[0]
				
				frac?.rightDelimiter = delims?[1]
			}
			
			frac?.numerator = list
			
			frac?.denominator = buildInternal(false, stopChar: stopChar)
			
			if error != nil {
				return nil
			}
			
			let fracList = MTMathList()
			
			fracList.addAtom(frac)
			
			return fracList
		} else if (command == "\\") || (command == "cr") {
			if currentEnv != nil {
				/* Stop the current list and increment the row count. */
				currentEnv?.numRows = (currentEnv?.numRows ?? 0) + 1
				
				return list
			} else {
				/* Create a new table with the current list and a default env. */
				let table = buildTable(nil, firstList: list, row: true)
				
				return MTMathList(atoms: table, nil)
			}
		} else if command == "end" {
			if currentEnv == nil {
				let errorMessage = "Missing \\begin"
				
				setError(.missingBegin, message: errorMessage)
				
				return nil
			}
			
			let env = readEnvironment()
			
			if env == nil {
				return nil
			}
			
			if env != currentEnv?.envName {
				let errorMessage = "Begin environment name \(currentEnv?.envName ?? "") does not match end name: \(env ?? "")"
				
				setError(.invalidEnv, message: errorMessage)
				
				return nil
			}
			/* Finish the current environment. */
			currentEnv?.ended = true
			
			return list
		}
		return nil
	}
	
	/* Applies the modifier to the atom. Returns true if modifier applied. */
	func applyModifier(_ modifier: String?, atom: MTMathAtom?) -> Bool {
		if modifier == "limits" {
			if atom?.type != kMTMathAtomLargeOperator {
				let errorMessage = "limits can only be applied to an operator."
				
				setError(.invalidLimits, message: errorMessage)
			} else {
				let op = atom as? MTLargeOperator
				
				op?.limits = true
			}
			
			return true
		} else if modifier == "nolimits" {
			if atom?.type != kMTMathAtomLargeOperator {
				let errorMessage = "nolimits can only be applied to an operator."
				
				setError(.invalidLimits, message: errorMessage)
				
				return true
			} else {
				let op = atom as? MTLargeOperator
				
				op?.limits = false
			}
			
			return true
		}
		
		return false
	}
	
	func setError(_ code: MTParseErrors, message: String?) {
		/* Only record the first error. */
		if error == nil {
			error = NSError(domain: MTParseError, code: code.rawValue, userInfo: [
				NSLocalizedDescriptionKey: message ?? ""
			])
		}
	}
	
	func buildTable(_ env: String?, firstList: MTMathList?, row isRow: Bool) -> MTMathAtom? {
		/* Save the current env until a new one gets built. */
		let oldEnv = currentEnv
		
		currentEnv = MTEnvProperties(name: env)
		
		var currentRow = 0
		
		var currentCol = 0
		
		var rows: [[MTMathList]]? = []
		
		rows?[0] = []
		
		if let firstList = firstList {
			rows?[currentRow][currentCol] = firstList
			
			if isRow {
				currentEnv?.numRows = (currentEnv?.numRows ?? 0) + 1
				
				currentRow += 1
				
				rows?[currentRow] = []
			} else {
				currentCol += 1
			}
		}
		
		while !(currentEnv?.ended ?? false) && hasCharacters() {
			let list = buildInternal(false)
			
			if list == nil {
				/* If there is an error building the list, bail out early. */
				return nil
			}
			
			rows?[currentRow][currentCol] = list
			
			currentCol += 1
			
			if (currentEnv?.numRows ?? 0) > currentRow {
				currentRow = currentEnv?.numRows ?? 0
				
				if (rows?.count ?? 0) > currentRow {
					rows?[currentRow] = []
				} else {
					rows?.append([AnyHashable]())
				}
				
				currentCol = 0
			}
		}
		
		if !(currentEnv?.ended ?? false) && currentEnv?.envName != nil {
			setError(.missingEnd, message: "Missing \\end")
			
			return nil
		}
		
		var error: Error?
		
		let table = MTMathAtomFactory.table(withEnvironment: currentEnv?.envName, rows: rows, error: &error)
		
		if table == nil && self.error == nil {
			self.error = error
			
			return nil
		}
		
		/* Reinstate the old env. */
		currentEnv = oldEnv
		
		return table
	}
	
	static var spaceToCommandsVar: [AnyHashable : Any]? = nil
	
	class func spaceToCommands() -> [AnyHashable : Any]? {
		if spaceToCommandsVar == nil {
			spaceToCommandsVar = [
				NSNumber(value: 3): ",",
				NSNumber(value: 4): ">",
				NSNumber(value: 5): ";",
				NSNumber(value: -3): "!",
				NSNumber(value: 18): "quad",
				NSNumber(value: 36): "qquad"
			]
		}
		
		return spaceToCommandsVar
	}
	
	static var styleToCommandsVar: [AnyHashable : Any]? = nil
	
	class func styleToCommands() -> [AnyHashable : Any]? {
		if styleToCommandsVar == nil {
			styleToCommandsVar = [
				NSNumber(value: kMTLineStyleDisplay): "displaystyle",
				NSNumber(value: kMTLineStyleText): "textstyle",
				NSNumber(value: kMTLineStyleScript): "scriptstyle",
				NSNumber(value: kMTLineStyleScriptScript): "scriptscriptstyle"
			]
		}
		
		return styleToCommandsVar
	}
	
	/* Construct a math list from a given string. If there is parse error, returns nil. To retrieve the error use the function `[MTMathListBuilder buildFromString:error:]`. */
	class func build(from str: String) -> MTMathList? {
		let builder = MTMathListBuilder(string: str)
		
		return builder.build()
	}
	
	/* Construct a math list from a given string. If there is an error while constructing the string, this returns nil. The error is returned in the `error` parameter. */
	class func build(from str: String) throws -> MTMathList? {
		let builder = MTMathListBuilder(string: str)
		
		let output = builder.build()
		
		if builder.error != nil {
			if error != nil {
				error = builder.error
			}
		
			return nil
		}
		
		return output
	}
	
	class func delim(toString delim: MTMathAtom?) -> String? {
		let command = MTMathAtomFactory.delimiterName(forBoundaryAtom: delim)
		
		if command != nil {
			let singleChars = ["(", ")", "[", "]", "<", ">", "|", ".", "/"]
			
			if singleChars.contains(command) {
				return command
			} else if command == "||" {
				return "\\|" /* special case for || */
			} else {
				return "\\\(command)"
			}
		}
		
		return ""
	}
	
	/* This converts the MTMathList to LaTeX. */
	class func mathList(toString ml: MTMathList) -> String {
		var str = ""
		
		var currentfontStyle = kMTFontStyleDefault
		
		for atom in ml.atoms {
			if currentfontStyle != atom.fontStyle {
				if currentfontStyle != kMTFontStyleDefault {
					/* Close the previous font style. */
					str += "}"
				}
				
				if atom.fontStyle != kMTFontStyleDefault {
					/* Open new font style. */
					let fontStyleName = MTMathAtomFactory.fontName(forStyle: atom.fontStyle)
					
					str.appendFormat("\\%@{", fontStyleName)
				}
				currentfontStyle = atom.fontStyle
			}
			if atom.type == kMTMathAtomFraction {
				let frac = atom as? MTFraction
				
				if frac?.hasRule {
					if let numerator = frac?.numerator, let denominator = frac?.denominator {
						str.appendFormat("\\frac{%@}{%@}", self.mathList(toString: numerator), self.mathList(toString: denominator))
					}
				} else {
					var command: String? = nil
					
					if !frac?.leftDelimiter && !frac?.rightDelimiter {
						command = "atop"
					} else if (frac?.leftDelimiter == "(") && (frac?.rightDelimiter == ")") {
						command = "choose"
					} else if (frac?.leftDelimiter == "{") && (frac?.rightDelimiter == "}") {
						command = "brace"
					} else if (frac?.leftDelimiter == "[") && (frac?.rightDelimiter == "]") {
						command = "brack"
					} else {
						if let leftDelimiter = frac?.leftDelimiter, let rightDelimiter = frac?.rightDelimiter {
							command = "atopwithdelims\(leftDelimiter)\(rightDelimiter)"
						}
					}
					
					if let numerator = frac?.numerator, let denominator = frac?.denominator {
						str.appendFormat("{%@ \\%@ %@}", self.mathList(toString: numerator), command, self.mathList(toString: denominator))
					}
				}
			}
			else if atom.type == kMTMathAtomRadical {
				str += "\\sqrt"
				
				let rad = atom as? MTRadical
				
				if rad?.degree {
					if let degree = rad?.degree {
						str += "[\(self.mathList(toString: degree))]"
					}
				}
				
				if let radicand = rad?.radicand {
					str.appendFormat("{%@}", self.mathList(toString: radicand))
				}
			}
			else if atom.type == kMTMathAtomInner {
				let inner = atom as? MTInner
				
				if inner?.leftBoundary || inner?.rightBoundary {
					if inner?.leftBoundary {
						str += "\\left\(self.delim(toString: inner?.leftBoundary) ?? "") "
					} else {
						str += "\\left. "
					}
					
					if let innerList = inner?.innerList {
						str += self.mathList(toString: innerList)
					}
					
					if inner?.rightBoundary {
						str += "\\right\(self.delim(toString: inner?.rightBoundary) ?? "") "
					} else {
						str += "\\right. "
					}
				} else {
					if let innerList = inner?.innerList {
						str.appendFormat("{%@}", self.mathList(toString: innerList))
					}
				}
			}
			else if atom.type == kMTMathAtomTable {
				let table = atom as? MTMathTable
				
				if table?.environment {
					if let environment = table?.environment {
						str.appendFormat("\\begin{%@}", table?.environment)
					}
				}
				for i in 0..<(table?.numRows ?? 0) {
					let row = table?.cells[i] as? [MTMathList]
					
					for j in 0..<(row?.count ?? 0) {
						var cell = row?[j]
						
						if table?.environment == "matrix" {
							if (cell?.atoms.count ?? 0) >= 1 && cell?.atoms[0].type == kMTMathAtomStyle {
								/* Remove the first atom. */
								let atoms = cell?.atoms.subarray(with: NSRange(location: 1, length: (cell?.atoms.count ?? 0) - 1))
								
								cell = MTMathList(atomsArray: atoms)
							}
						}
						
						if (table?.environment == "eqalign") || (table?.environment == "aligned") || (table?.environment == "split") {
							if j == 1 && (cell?.atoms.count ?? 0) >= 1 && cell?.atoms[0].type == kMTMathAtomOrdinary && cell?.atoms[0].nucleus.length == 0 {
								/* Empty nucleus added for spacing. Remove it. */
								let atoms = cell?.atoms.subarray(with: NSRange(location: 1, length: (cell?.atoms.count ?? 0) - 1))
								
								cell = MTMathList(atomsArray: atoms)
							}
						}
						
						if let cell = cell {
							str += self.mathList(toString: cell)
						}
						
						if j < (row?.count ?? 0) - 1 {
							str += "&"
						}
					}
					
					if i < (table?.numRows ?? 0) - 1 {
						str += "\\\\ "
					}
				}
				
				if table?.environment {
					if let environment = table?.environment {
						str.appendFormat("\\end{%@}", table?.environment)
					}
				}
			}
			else if atom.type == kMTMathAtomOverline {
				str += "\\overline"
				
				let over = atom as? MTOverLine
				
				if let innerList = over?.innerList {
					str.appendFormat("{%@}", self.mathList(toString: innerList))
				}
			}
			else if atom.type == kMTMathAtomUnderline {
				str += "\\underline"
				
				let under = atom as? MTUnderLine
				
				if let innerList = under?.innerList {
					str.appendFormat("{%@}", self.mathList(toString: innerList))
				}
			}
			else if atom.type == kMTMathAtomAccent {
				let accent = atom as? MTAccent
				
				if let innerList = accent?.innerList {
					str.appendFormat("\\%@{%@}", MTMathAtomFactory.accentName(accent), self.mathList(toString: innerList))
				}
			}
			else if atom.type == kMTMathAtomLargeOperator {
				let op = atom as? MTLargeOperator
				
				var command = MTMathAtomFactory.latexSymbolName(for: atom)
				
				let originalOp = MTMathAtomFactory.atom(forLatexSymbolName: command) as? MTLargeOperator
				
				str += "\\\(command) "
				
				if originalOp?.limits != op?.limits {
					if op?.limits {
						str += "\\limits "
					} else {
						str += "\\nolimits "
					}
				}
			}
			else if atom.type == kMTMathAtomSpace {
				let space = atom as? MTMathSpace
				
				let spaceToCommands = MTMathListBuilder.spaceToCommands()
				
				var command = spaceToCommands?[NSNumber(value: space?.space)] as? String
				
				if let command = command {
					str += "\\\(command) "
				} else {
					if let aSpace = space?.space {
						str += String(format: "\\mkern%.1fmu", aSpace)
					}
				}
			}
			else if atom.type == kMTMathAtomStyle {
				let style = atom as? MTMathStyle
				
				let styleToCommands = MTMathListBuilder.styleToCommands()
				
				var command = styleToCommands?[NSNumber(value: style?.style)] as? String
				
				str += "\\\(command ?? "") "
			}
			else if atom.nucleus.length == 0 {
				str += "{}"
			}
			else if atom.nucleus == "\u{2236}" {
				str += ":"								// math colon
			}
			else if atom.nucleus == "\u{2212}" {
				str += "-"								// math minus
			}
			else {
				var command = MTMathAtomFactory.latexSymbolName(for: atom)
				
				if command != nil {
					str += "\\\(command) "
				} else {
					str += atom.nucleus
				}
			}

			if atom.superScript {
				str.appendFormat("^{%@}", self.mathList(toString: atom.superScript))
			}

			if atom.subScript {
				str.appendFormat("_{%@}", self.mathList(toString: atom.subScript))
			}
		}
		
		if currentfontStyle != kMTFontStyleDefault {
			str += "}"
		}
		
		return str
	}
}

class MTEnvProperties: NSObject {
	private(set) var envName: String?
	
	var ended = false
	
	var numRows = 0

	init(name: String?) {
		super.init()
		
		envName = name
		
		numRows = 0
		
		ended = false
	}
}
