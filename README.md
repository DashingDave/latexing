# latexing
### Swift/UI code to present LaTeX-typeset text within iOS/MacOS apps


I've used Swiftify to batch convert the Objective-C files from the iosMath project into Swift in hopes of figuring out how to code the presentation of LaTeX-formatted text within authored iOS/MacOS applications *using only Swift code*.

The ultimate goal is to figure out how to create textfields in SwiftUI views that auto-wrap like this:

<img width="284" alt="Screen Shot 2022-10-06 at 6 08 46 PM" src="https://user-images.githubusercontent.com/40405534/194428883-6c772df3-0604-4888-99fa-90dc857833e3.png">


Neither [iosMath](https://github.com/kostub/iosMath) nor [MathRender](https://github.com/mgriebling/MathRender) appear able to display inline LaTeX that wraps to the screen (as a regular SwiftUI Text view would do).

But, first, the code needs to be cleaned up a lot, and I'm not great with `class` objects. This code is *all* `class` objects--not a single `struct` in sight. Here is a list of every class in the project, with their file locations in bold following the arrow. I've also included every enum and where they can be found as well.

##  List of Classes

- MTAccent --> 						**MTMathList**
- MTAccentDisplay -->					**MTMathListDisplay, MTMathListDisplayInternal**
- MTCTLineDisplay -->					**MTMathListDisplay, MTMathListDisplayInternal**
- MTDisplay -->						**MTMathListDisplay, MTMathListDisplayInternal**
- MTEnvProperties -->					**MTMathListBuilder**
- MTFont -->						**MTFont**
- MTFontManager -->						**MTFontManager**
- MTFontMathTable -->					**MTFontMathTable**
- MTFraction -->						**MTMathList**
- MTFractionDisplay -->					**MTMathListDisplay, MTMathListDisplayInternal**
- MTGlyphConstructionDisplay -->				**MTMathListDisplay, MTMathListDisplayInternal**
- MTGlyphDisplay -->					**MTMathListDisplay, MTMathListDisplayInternal**
- MTGlyphPart -->						**MTFontMathTable**
- MTInner -->						**MTMathList**
- MTInnerDisplay -->					**MTMathListDisplay, MTMathListDisplayInternal**
- MTLargeOperator -->					**MTMathList**
- MTLargeOpLimitsDisplay -->				**MTMathListDisplay, MTMathListDisplayInternal**
- MTLineDisplay -->						**MTMathListDisplay, MTMathListDisplayInternal**
- MTMathAtom -->						**MTMathList**
- MTMathAtomFactory -->					**MTMathAtomFactory**
- MTMathColor -->						**MTMathList**
- MTMathColorbox -->					**MTMathList**
- MTMathList -->						**MTMathList**
- MTMathListBuilder -->					**MTMathListBuilder**
- MTMathListDisplay -->					**MTMathListDisplay, MTMathListDisplayInternal**
- MTMathListIndex -->					**MTMathListIndex**
- MTMathListRange -->					**MTMathListIndex**
- MTMathSpace -->						**MTMathList**
- MTMathStyle -->						**MTMathList**
- MTMathTable -->						**MTMathList**
- MTMathUILabel -->					**MTMathUILabel**
- MTOverLine -->						**MTMathList**
- MTRadical -->						**MTMathList**
- MTRadicalDisplay -->					**MTMathListDisplay, MTMathListDisplayInternal**
- MTTypesetter -->						**MTTypesetter**
- MTUnderLine -->						**MTMathList**


## List of Enums

- MTMathListSubIndexType -->				**MTMathListIndex**
- MTMathAtomType -->					**MTMathList**
- MTFontStyle -->						**MTMathList**
- MTLineStyle -->						**MTMathList**
- MTColumnAlignment -->					**MTMathList**
- MTParseErrors -->						**MTMathListBuilder**
- MTLinePosition -->					**MTMathListDisplay**
- MTMathListSubIndexType -->				**MTMathListIndex**
- MTMathUILabelMode -->					**MTMathUILabel**
- MTTextAlignment -->					**MTMathUILabel**
- MTInterElementSpaceType -->				**MTTypesetter**


In addition to the converted code files, I've added some "front-end" SwiftUI files to present a `MathView` on the screen. The code there is what would work to display properly typeset text when combined with the iosMath Cocoapod or the MathRender Swift package.

Finally, in the folder `Original C`, you can find the original Objective-C code that was used.
