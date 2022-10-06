//
//	NSViewBackgroundColor.swift
//	ObjC -> Swift conversion of
//
//  NSView+backgroundColor.h/.m
//  MacOSMath
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import Cocoa

#if !TARGET_OS_IPHONE

extension NSView {
	var backgroundColor: NSColor? {
	    get {
			if layer?.backgroundColor == nil {
				return .clear
			}

			if let aBackgroundColor = layer?.backgroundColor {
				return NSColor(cgColor: aBackgroundColor)
			}

			return nil
	    }
	    set(backgroundColor) {
			layer?.backgroundColor = NSColor.clear.cgColor

			wantsLayer = true
	    }
	}
}

#endif
