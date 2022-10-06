//
//	MTMathUILabel.swift
//	ObjC -> Swift conversion of
//
//  MathUILabel.h/.m
//  iosMath
//  Created by Kostub Deshmukh on 8/26/13.
//  Copyright (C) 2013 MathChat
//
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

import CoreText

/* Different display styles supported by the `MTMathUILabel`. The only significant difference between the two modes is how fractions and limits on large operators are displayed. */
enum MTMathUILabelMode: Int {
	case display	// Display mode; equivalent to $$ in TeX
	case text		// Text mode; equivalent to $ in TeX.
}

/* Horizontal text alignment for `MTMathUILabel`. */
enum MTTextAlignment: Int {
	case left
	case center
	case right
}

/* The main view for rendering math, `MTMathLabel` accepts either a string in LaTeX or an `MTMathList` to display. Use `MTMathList` directly only if you are building it programmatically (e.g. using an editor), otherwise using LaTeX is the preferable method. */
/* The math display is centered vertically in the label. The default horizontal alignment is `left` (this can be changed by setting `MTTextAlignment`), and the default mode is `display` (this can be changed by setting `MTmathUIlabelMode`). */
/* When created it uses `[MTFontManager defaultFont]` as its font. This can be changed using the `font` parameter. */
@IBDesignable
class MTMathUILabel: MTView {
	private var errorLabel: MTLabel?

	/* The `MTMathList` to render. Setting this will remove any `latex` that has already been set. If `latex` has been set, this will return the parsed `MTMathList` if the `latex` parses successfully. Use this setting if the `MTMathList` has been programmatically constructed, otherwise it is preferred to use `latex`. */
	private var _mathList: MTMathList?

	var mathList: MTMathList? {
	    get {
			_mathList
	    }
	    set(mathList) {
			_mathList = mathList
			
			error = nil
			
			latex = MTMathListBuilder.mathList(toString: mathList)
			
			invalidateIntrinsicContentSize()
			
			setNeedsLayout()
	    }
	}
	
	/* The latex string to be displayed. Setting this will remove any `mathList` that has been set. If latex has not been set, this will return the latex output for the `mathList` that is set. */
	@IBInspectable private var _latex: String?
	
	@IBInspectable var latex: String? {
	    get {
			_latex
	    }
	    set(latex) {
			_latex = latex
			
			self.error = nil
			
			var error: Error? = nil
			
			mathList = MTMathListBuilder.build(from: latex, error: &error)
			
			if let error = error {
				mathList = nil
				
				self.error = error
				
				errorLabel?.text = error.localizedDescription
				
				errorLabel?.frame = bounds
				
				errorLabel?.hidden = !displayErrorInline
			} else {
				errorLabel?.hidden = true
			}
			
			invalidateIntrinsicContentSize()
			
			setNeedsLayout()
	    }
	}
	
	/* This contains any error that occurred when parsing the latex. */
	private(set) var error: Error?
	
	/* If true, it displays the error message inline; default is `true`. */
	var displayErrorInline = false

	/* The MTFont to use for rendering. */
	private var _font: MTFont?
	
	var font: MTFont {
	    get {
			_font
	    }
	    set(font) {
			assert(font != nil, "Invalid parameter not satisfying: font != nil")
			
			_font = font
			
			invalidateIntrinsicContentSize()
			
			setNeedsLayout()
	    }
	}
	
	/* Convenience method to just set the size of the font without changing the fontface. */
	@IBInspectable private var _fontSize: CGFloat = 0.0
	
	@IBInspectable var fontSize: CGFloat {
	    get {
			_fontSize
	    }
	    set(fontSize) {
			_fontSize = fontSize
			
			let font = self.font.copy(withSize: _fontSize)
			
			if let font = font {
				self.font = font
			}
	    }
	}
	
	/* This sets the text color of the rendered math formula; default is black. */
	@IBInspectable private var _textColor: MTColor?
	
	@IBInspectable var textColor: MTColor {
		get {
			_textColor
	    }
	    set(textColor) {
			assert(textColor != nil, "Invalid parameter not satisfying: textColor != nil")
			
			_textColor = textColor
			
			displayList?.textColor = textColor
			
			setNeedsDisplay()
	    }
	}
	
	/* The minimum distance from the margin of the view to the rendered math. This value is `UIEdgeInsetsZero` by default. This is useful if you need some padding between the math and the border/background color. `sizeThatFits` will have its returned size increased by these insets. */
	@IBInspectable private var _contentInsets: MTEdgeInsets?

	@IBInspectable var contentInsets: MTEdgeInsets {
	    get {
			_contentInsets
	    }
	    set(contentInsets) {
			_contentInsets = contentInsets
			
			invalidateIntrinsicContentSize()
			
			setNeedsLayout()
	    }
	}
	
	/* The Label mode for the label; default is Display. */
	private var _labelMode: MTMathUILabelMode!
	
	var labelMode: MTMathUILabelMode! {
	    get {
			_labelMode
	    }
	    set(labelMode) {
			_labelMode = labelMode
			
			invalidateIntrinsicContentSize()
			
			setNeedsLayout()
	    }
	}
	
	/* Horizontal alignment for the text; default is align left. */
	private var _textAlignment: MTTextAlignment!
	
	var textAlignment: MTTextAlignment! {
	    get {
			_textAlignment
	    }
	    set(textAlignment) {
			_textAlignment = textAlignment
			
			invalidateIntrinsicContentSize()
			
			setNeedsLayout()
	    }
	}
	
	/* The internal display of the MTMathUILabel. (**For advanced use only.**) */
	private(set) var displayList: MTMathListDisplay?

	init(frame: CGRect) {
		super.init(frame: frame)
		initCommon()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		initCommon()
	}

	func initCommon() {
		layer.isGeometryFlipped = true 		// For ease of interaction with the CoreText coordinate system

		fontSize = 20						// Default font size

		contentInsets = MTEdgeInsetsZero

		labelMode = MTMathUILabelMode.display

		let font = MTFontManager().defaultFont

		if let font = font {
			self.font = font
		}

		textAlignment = MTTextAlignment.left

		displayList = nil

		displayErrorInline = true

		backgroundColor = MTColor.clear()

		textColor = .black()

		errorLabel = MTLabel()

		errorLabel?.hidden = true

		errorLabel?.layer.isGeometryFlipped = true

		errorLabel?.textColor = MTColor.red()

		addSubview(errorLabel)
	}

	#if !TARGET_OS_IPHONE

	func setNeedsLayout() {
		self.setNeedsLayout(true)
	}

	func setNeedsDisplay() {
		self.setNeedsDisplay(true)
	}

	func isFlipped() -> Bool {
		return false
	}

	#endif
	
	func currentStyle() -> MTLineStyle {
		switch labelMode {
			case MTMathUILabelMode.display:
				return kMTLineStyleDisplay
		
			case MTMathUILabelMode.text:
				return kMTLineStyleText
		}
	}

	/* Only override drawRect if you perform custom drawing. An empty implementation adversely affects performance during animation. */
	func draw(_ rect: MTRect) {
		super.draw(rect)

		if mathList == nil {
			return
		}

		/* Drawing code */
		let context = MTGraphicsGetCurrentContext()
		
		context?.saveGState()

		displayList?.draw(context)

		context?.restoreGState()
	}

	func layoutSubviews() {
		if mathList != nil {
			displayList = MTTypesetter.createLine(for: mathList, font: font, style: currentStyle())
			
			displayList?.textColor = textColor

			/* Determine x position based on alignment. */
			var textX: CGFloat = 0
			
			switch textAlignment {
				case MTTextAlignment.left:
					textX = contentInsets.left
			
				case MTTextAlignment.center:
					textX = (bounds.size.width - contentInsets.left - contentInsets.right - (displayList?.width ?? 0)) / 2 + contentInsets.left
			
				case MTTextAlignment.right:
					textX = bounds.size.width - displayList?.width - contentInsets.right
			}

			let availableHeight: CGFloat = bounds.size.height - contentInsets.bottom - contentInsets.top
			
			/* Center things vertically. */
			var height = displayList?.ascent + displayList?.descent
			
			if height < fontSize / 2 {
				height = fontSize / 2		// Set the height to half the size of the font.
			}
			
			let textY = (availableHeight - height) / 2 + (displayList?.descent ?? 0.0) + contentInsets.bottom
			
			displayList?.position = CGPoint(x: textX, y: textY)
		} else {
			displayList = nil
		}
		
		errorLabel?.frame = bounds
		
		setNeedsDisplay()
	}

	#if !TARGET_OS_IPHONE

	func layout() {
		layoutSubviews()
		super.layout()
	}

	#endif

	func sizeThatFits(_ size: CGSize) -> CGSize {
		var size = size
		
		var displayList: MTMathListDisplay? = nil
		
		if mathList != nil {
			displayList = MTTypesetter.createLine(for: mathList, font: font, style: currentStyle())
		}

		size.width = displayList?.width + contentInsets.left + contentInsets.right
		
		size.height = displayList?.ascent + displayList?.descent + contentInsets.top + contentInsets.bottom
		
		return size
	}

	func intrinsicContentSize() -> CGSize {
		return sizeThatFits(.zero)
	}
}
