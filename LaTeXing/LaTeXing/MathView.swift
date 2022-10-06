//
//  MathView.swift
//  LaTeXing
//
//  Created by Dashing Dave on 5/31/22.
//

import SwiftUI

struct MathView: UIViewRepresentable {
	@Environment(\.colorScheme) var colorScheme
	var equation: String = ""
	
	func makeUIView(context: Context) -> MTMathUILabel {
		MTMathUILabel()
	}
	
	func updateUIView(_ uiView: MTMathUILabel, context: Context) {
		uiView.latex = equation
		uiView.textColor = colorScheme == .dark ? UIColor.white : UIColor.black
		uiView.font = MTFontManager().xitsFont(withSize: CGFloat(24))
		uiView.textAlignment = .center
		uiView.labelMode = .text
	}
}

struct MathView_Previews: PreviewProvider {
    static var previews: some View {
		MathView(equation: "2y + x")
    }
}
