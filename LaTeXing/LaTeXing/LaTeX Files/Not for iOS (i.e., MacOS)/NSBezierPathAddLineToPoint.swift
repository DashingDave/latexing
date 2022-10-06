//
//	NSBezierPathAddLineToPoint.swift
//	ObjC -> Swift conversion of
//
//  NSBezierPath+addLineToPoint.h/.m
//  MacOSMath
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import Cocoa

#if !TARGET_OS_IPHONE

extension NSBezierPath {
	func addLine(to point: CGPoint) {
		line(to: point as? NSPoint ?? NSPoint.zero)
	}
}

#endif
