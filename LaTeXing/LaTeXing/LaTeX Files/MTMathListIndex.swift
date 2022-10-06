//
//  MTMathListIndex.swift
//	ObjC -> Swift conversion of
//
//  MTMathListIndex.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 9/6/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI

/* `MTMathListIndex` IS AN INDEX THAT points to a particular character in the MTMathList. The index is a LinkedList that represents a path from the beginning of the MTMathList to reach a particular atom in the list. The next node of the path is represented by the subIndex. The path terminates when the subIndex is nil. */
/* THE LEVEL OF AN INDEX IS THE number of nodes in the LinkedList to get to the final path. */
/* IF THERE IS A SUBINDEX, THE subIndexType denotes what branch the path takes (i.e. superscript, subscript, numerator, denominator etc.). For example, in the expression 25^{2/4}, the index of the character 4 is represented as "(1, superscript) -> (0, denominator) -> (0, none)". This can be interpreted as (a) start at index 1 (i.e. the 5), (b) go up to the superscript, (c) look at index 0 (i.e. 2/4), (d) go to the denominator, and (e) look up index 0 (i.e. the 4) which is the final index. */

/* The index of the associated atom. */
class MTMathListIndex: NSObject {
	private(set) var atomIndex = 0
	
	/* The type of subindex, e.g. superscript, numerator, etc. */
	private(set) var subIndexType: MTMathListSubIndexType!
	
	/* The index into the sublist. */
	private(set) var subIndex: MTMathListIndex?
	
	override init() {
	}
	
	/* Factory function to create a `MTMathListIndex` with no subindexes. Parameter - (index: The index of the atom that the `MTMathListIndex` points at). */
	class func level0Index(_ index: Int) -> Self {
		let mlIndex = MTMathListIndex()
		mlIndex.atomIndex = index
		return mlIndex
	}
	
	/* Factory function to create at `MTMathListIndex` with a given subIndex. Parameters - (location: The location at which the subIndex should is present, subIndex: The subIndex to be added; can be nil, type: The type of the subIndex). */
	class func atLocation(_ location: Int, withSubIndex subIndex: MTMathListIndex?, type: MTMathListSubIndexType) -> Self {
		let index = self.level0Index(location)
		
		index.subIndexType = type
		
		index.subIndex = subIndex
		
		return index
	}
	
	/* Creates a new index by attaching this index at the end of the current one. */
	func levelUp(withSubIndex subIndex: MTMathListIndex?, type: MTMathListSubIndexType) -> MTMathListIndex {
		if subIndexType == MTMathListSubIndexType.subIndexTypeNone {
			return .atLocation(atomIndex, withSubIndex: subIndex, type: type)
		}
		
		/* We have to recurse. */
		return MTMathListIndex.atLocation(atomIndex, withSubIndex: self.subIndex?.levelUp(withSubIndex: subIndex, type: type), type: subIndexType)
	}
	
	/* Creates a new index by removing the last index item. If this is the last one, then returns nil. */
	func levelDown() -> MTMathListIndex? {
		if subIndexType == MTMathListSubIndexType.subIndexTypeNone {
			return nil
		}
		
		let subIndexDown = subIndex?.levelDown()
		
		if let subIndexDown = subIndexDown {
			return .atLocation(atomIndex, withSubIndex: subIndexDown, type: subIndexType)
		} else {
			return .level0Index(atomIndex)
		}
	}
	
	/* Returns the previous index if present. Returns `nil` if there is no previous index. */
	func previous() -> MTMathListIndex? {
		if subIndexType == MTMathListSubIndexType.subIndexTypeNone {
			if atomIndex > 0 {
				return .level0Index(atomIndex - 1)
			}
		} else {
			let prevSubIndex = subIndex?.previous()
			
			if let prevSubIndex = prevSubIndex {
				return .atLocation(atomIndex, withSubIndex: prevSubIndex, type: subIndexType)
			}
		}
		
		return nil
	}
	
	/* Returns the next index. */
	func next() -> MTMathListIndex {
		if subIndexType == MTMathListSubIndexType.subIndexTypeNone {
			return .level0Index(atomIndex + 1)
		} else if subIndexType == MTMathListSubIndexType.subIndexTypeNucleus {
			return .atLocation(atomIndex + 1, withSubIndex: subIndex, type: subIndexType)
		} else {
			return .atLocation(atomIndex, withSubIndex: subIndex?.next(), type: subIndexType)
		}
	}
	
	/* Returns true if any of the subIndexes of this index have the given type. */
	func hasSubIndexOf(_ subIndexType: MTMathListSubIndexType) -> Bool {
		if self.subIndexType == subIndexType {
			return true
		} else {
			return subIndex?.hasSubIndexOf(subIndexType) ?? false
		}
	}
	
	func isAtBeginningOfLine() -> Bool {
		return finalIndex() == 0
	}
	
	func `is`(atSameLevel other: MTMathListIndex?) -> Bool {
		if subIndexType != other?.subIndexType {
			return false
		} else if subIndexType == MTMathListSubIndexType.subIndexTypeNone {		// At the same level; no subindexes
			return true
		} else if atomIndex != other?.atomIndex {						// The subindexes are used in different atoms
			return false
		} else {
			return subIndex?.`is`(atSameLevel: other?.subIndex) ?? false
		}
	}
	
	func finalIndex() -> Int {
		if subIndexType == MTMathListSubIndexType.subIndexTypeNone {
			return atomIndex
		} else {
			return subIndex?.finalIndex() ?? 0
		}
	}
	
	/* Returns the type of the innermost sub index. */
	func finalSubIndexType() -> MTMathListSubIndexType {
		if subIndex?.subIndex != nil {
			return (subIndex?.finalSubIndexType())!
		} else {
			return subIndexType
		}
	}
	
	override var description: String {
		if let subIndex = subIndex {
			return String(format: "[%lu, %d:%@]", UInt(atomIndex), subIndexType, subIndex)
		}
		
		return String(format: "[%lu]", UInt(atomIndex))
	}
	
	func isEqual(to index: MTMathListIndex?) -> Bool {
		if atomIndex != index?.atomIndex || subIndexType != index?.subIndexType {
			return false
		}
		
		if let subIndex = subIndex {
			return subIndex == index?.subIndex
		} else {
			return index?.subIndex == nil
		}
	}
	
	override func isEqual(_ anObject: Any?) -> Bool {
		if self == (anObject as? MTMathListIndex) {
			return true
		}
		
		if anObject == nil || !(anObject is MTMathListIndex) {
			return false
		}
		
		return isEqual(to: anObject as? MTMathListIndex)
	}
	
	override var hash: Int {
		let prime = 31
		
		var hash = atomIndex
		
		hash = hash * prime + subIndexType.rawValue
		
		hash = hash * prime + (subIndex?.hash ?? 0)
		
		return hash
	}
}

/* The type of the subindex, which denotes what branch the path to the atom that this index points to takes. */
enum MTMathListSubIndexType : Int {
	case subIndexTypeNone = 0		/* The index denotes the whole atom; subIndex is nil. */
	
	case subIndexTypeNucleus		/* The position in the subindex is an index into the nucleus. */
	
	case subIndexTypeSuperscript	/* The subindex indexes into the superscript. */
	
	case subIndexTypeSubscript		/* The subindex indexes into the subscript. */
	
	case subIndexTypeNumerator		/* The subindex indexes into the numerator (only valid for fractions). */
	
	case subIndexTypeDenominator	/* The subindex indexes into the denominator (only valid for fractions). */
	
	case subIndexTypeRadicand		/* The subindex indexes into the radicand (only valid for radicals). */
	
	case subIndexTypeDegree			/* The subindex indexes into the degree (only valid for radicals). */
	
	case subIndexTypeInner			/* The subindex indexes into the inner list (only valid for inner). */
}


/* A range of atoms in an `MTMathList`. This is similar to `NSRange` with a start and length, except that the starting location is defined by a `MTMathListIndex` rather than an ordinary integer. */
class MTMathListRange: NSObject {
	private(set) var start: MTMathListIndex			// The starting location of the range; cannot be `nil`
	
	private(set) var length = 0			// The size of the range
	
	override init() {
	}
	
	init(start: MTMathListIndex?, length: Int) {
		super.init()
		
		if let start = start {
			self.start = start
		}
		
		self.length = length
	}
	
	/* Creates a valid range. */
	class func make(_ start: MTMathListIndex, length: Int) -> MTMathListRange {
		return MTMathListRange(start: start, length: length)
	}
	
	/* Makes a range of length 1. */
	class func make(_ start: MTMathListIndex) -> MTMathListRange {
		return self.make(start, length: 1)
	}
	
	/* Makes a range of length 1 at the level 0 index start. */
	class func make(for start: Int) -> MTMathListRange {
		return self.make(MTMathListIndex.level0Index(start))
	}
	
	/* Creates a range at level 0 from the give range. */
	class func makeRange(for range: NSRange) -> MTMathListRange {
		return self.make(MTMathListIndex.level0Index(range.location), length: range.length)
	}
	
	override var description: String {
		return String(format: "(%@, %lu)", start, UInt(length))
	}
	
	func subIndex() -> MTMathListRange? {
		if start.subIndexType != MTMathListSubIndexType.subIndexTypeNone {
			if let aSubIndex = start.subIndex {
				return .make(aSubIndex, length: length)
			}
			
			return nil
		}
		
		return nil
	}
	
	func finalRange() -> NSRange {
		return NSRange(location: start.finalIndex(), length: length)
	}
	
	/* Appends the current range to range and returns the resulting range. Any elements between the two are included in the range. */
	func union(_ range: MTMathListRange) -> MTMathListRange? {
		if !self.start.`is`(atSameLevel: range.start) {
			assert(false, "Cannot union ranges at different levels: \(self), \(range)")
			
			return nil
		}
		
		let r1 = finalRange()
		
		let r2 = range.finalRange()
		
		let unionRange = NSUnionRange(r1, r2)
		
		var start: MTMathListIndex?
		
		if unionRange.location == r1.location {
			start = self.start
		} else {
			assert(unionRange.location == r2.location)
			start = range.start
		}
		
		if let start = start {
			return .make(start, length: unionRange.length)
		}
		
		return nil
	}
	
	/* Unions all ranges in the given array of ranges. */
	class func unionRanges(_ ranges: [MTMathListRange]) -> MTMathListRange? {
		assert((ranges.count > 0), "Need to union at least one range")
		
		let unioned = ranges[0]
		
		for i in 1..<ranges.count {
			let next = ranges[i]
			
			unioned.union(next)
		}
		
		return unioned
	}
}
