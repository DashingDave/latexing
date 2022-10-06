//
//	NSColorHexString.swift
//	ObjC -> Swift conversion of
//
//  NSColor+HexString.h/.m
//  iosMath
//  Created by Markus Sähn on 21/03/2017.
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import Cocoa

#if !TARGET_OS_IPHONE

extension NSColor {
	convenience init?(fromHexString hexString: String?) {
		if hexString == "" {
			return nil
		}

		if hexString?[hexString?.index(hexString?.startIndex, offsetBy: 0)] != "#" {
			return nil
		}

		var rgbValue: UInt = 0

		let scanner = Scanner(string: hexString ?? "")

		if hexString?[hexString?.index(hexString?.startIndex, offsetBy: 0)] == "#" {
			scanner.scanLocation = 1
		}

		scanner.scanHexInt32(UnsafeMutablePointer<UInt32>(mutating: &rgbValue))

		/* red:green:blue:alpha: in AppKit/NSColor.h is NS_AVAILABLE_MAC(10_9), unavailable for macOS 10.8. Older method name colorWithSRGBRed::green:blue:alpha: works. */
		self.init(srgbRed: Double(((rgbValue & 0xff0000) >> 16)) / 255.0, green: Double(((rgbValue & 0xff00) >> 8)) / 255.0, blue: Double((rgbValue & 0xff)) / 255.0, alpha: 1.0)
	}
}

#endif
