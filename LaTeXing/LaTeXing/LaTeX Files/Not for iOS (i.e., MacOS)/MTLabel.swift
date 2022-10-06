//
//	MTLabel.swift
//	ObjC -> Swift conversion of
//
//  MTLabel.h/.m
//  MacOSMath
//  Created by 安志钢 on 17-01-09.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import AppKit

#if !TARGET_OS_IPHONE

class MTLabel: NSTextField {
	var text: String? {
	    get {
			return super.stringValue
	    }
	    set(text) {
			super.stringValue = text ?? ""
	    }
	}

	override init() {
		super.init()

		super.isBezeled = false
		
		super.drawsBackground = false
		
		super.isEditable = false
		
		super.isSelectable = false
	}

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

#endif
