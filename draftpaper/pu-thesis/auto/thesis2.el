(TeX-add-style-hook
 "thesis2"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("puthesis" "12pt" "lot" "lof")))
   (TeX-run-style-hooks
    "latex2e"
    "abstract"
    "acknowledgements"
    "ch-intro/chapter-intro"
    "ch-pastwork/chapter-pastwork"
    "ch-usage/chapter-usage"
    "ch-conclusion/chapter-conclusion"
    "ch-appendicies/implementation"
    "ch-appendicies/printing"
    "puthesis"
    "puthesis12"
    "graphicx"
    "verbatim"
    "multirow"
    "longtable"
    "booktabs"
    "url"
    "hyperref")
   (TeX-add-symbols
    "proquestmode")
   (LaTeX-add-environments
    "indenttext"
    "indentlist")
   (LaTeX-add-bibliographies
    "thesis"))
 :latex)

