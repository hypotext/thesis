(TeX-add-style-hook
 "test"
 (lambda ()
   (TeX-run-style-hooks
    "latex2e"
    "article"
    "art10")
   (LaTeX-add-labels
    "documentclasses"
    "article"
    "book"
    "report"
    "letter"
    "conclusions")
   (LaTeX-add-bibitems
    "doe"))
 :latex)

