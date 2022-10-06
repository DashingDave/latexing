//
//  ContentView.swift
//  LaTeXing
//
//  Created by Dashing Dave on 5/31/22.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		MathView(equation: "\\sqrt{2x^{2}}")
	}
}


struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
