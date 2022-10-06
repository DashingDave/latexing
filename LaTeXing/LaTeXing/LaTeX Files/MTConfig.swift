//
//	MTConfig.swift
//	ObjC -> Swift conversion of
//
//  MTConfig.h
//  MacOSMath
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import AppKit
import UIKit

#if os(iOS)
typealias MTView = UIView
typealias MTColor = UIColor
typealias MTBezierPath = UIBezierPath
typealias MTEdgeInsets = UIEdgeInsets
typealias MTLabel = UILabel
typealias MTRect = CGRect

let MTEdgeInsetsZero = UIEdgeInsets.zero

func MTGraphicsGetCurrentContext() -> CGContext? {
	UIGraphicsGetCurrentContext()
}

#else
typealias MTView = NSView
typealias MTColor = NSColor
typealias MTBezierPath = NSBezierPath
typealias MTEdgeInsets = NSEdgeInsets
typealias MTRect = NSRect

/* For backward compatibility, DO NOT use NSEdgeInsetsZero (Available from OS X 10.10). */
func MTEdgeInsetsZero() {
	(NSEdgeInsetsMake(0.0, 0.0, 0.0, 0.0))
}

func MTGraphicsGetCurrentContext() -> UnsafeMutableRawPointer? {
	NSGraphicsContext.current?.graphicsPort
}
#endif
