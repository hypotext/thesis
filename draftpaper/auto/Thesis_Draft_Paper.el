(TeX-add-style-hook
 "Thesis_Draft_Paper"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("revtex4-1" "twocolumn" "showpacs" "nofootinbib" "aps" "superscriptaddress" "eqsecnum" "prd" "notitlepage" "showkeys" "10pt")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("sfmath" "cm")))
   (add-to-list 'LaTeX-verbatim-environments-local "lstlisting")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperref")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (TeX-run-style-hooks
    "latex2e"
    "revtex4-1"
    "revtex4-110"
    "natbib"
    "sfmath"
    "graphicx"
    "verbatim"
    "listings"
    "amssymb"
    "amsmath"
    "amsthm"
    "dcolumn"
    "hyperref"
    "enumitem")
   (TeX-add-symbols
    '("ct" 2)
    '("eqn" 1)
    "spc"
    "s"
    "bv"
    "ev"
    "el"
    "li"
    "kv"
    "f"
    "cd"
    "ld"
    "xor"
    "oh"
    "adv"
    "ged"
    "D"
    "non"
    "mc"
    "ov"
    "dr"
    "rar"
    "bt"
    "samp"
    "lar")
   (LaTeX-add-labels
    "intermediate2"
    "def:indist"
    "ex:hybrid_notation"
    "thm:adjacent_hybrids"
    "lem:hybrid_triangle"
    "ex:hybrid_intermediate"
    "thm:hybrids"
    "thm:br"
    "fig:project_diagram")
   (LaTeX-add-bibitems
    "affeldt2009"
    "appel2015"
    "barak2005"
    "barker2012"
    "barthe2011"
    "barthe2014"
    "bellare2004"
    "beringer2015"
    "campagna2006"
    "dodis2013"
    "dorre2015"
    "fouque2008"
    "goldreich2005"
    "hirose2008"
    "petcher2015"
    "petcherthesis2015"
    "sanguansin2016"
    "ye2014")
   (LaTeX-add-environments
    "game")
   (LaTeX-add-amsthm-newtheorems
    "thm"
    "dfn"
    "cor"
    "lem"
    "ex"))
 :latex)

