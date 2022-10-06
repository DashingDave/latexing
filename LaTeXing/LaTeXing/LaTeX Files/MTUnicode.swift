//
//	MTUnicode.swift
//	ObjC -> Swift conversion of
//
//  MTUnicode.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 8/16/14.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import SwiftUI

extension String {
	func unicodeLength() -> Int {
		/* Each unicode char is represented as 4 bytes in utf-32. */
		return lengthOfBytes(using: .utf32) / 4
	}
}
