(TeX-add-style-hook
 "puthesis"
 (lambda ()
   (TeX-run-style-hooks
    "setspace"
    "losymbol"
    "report"
    "rep10")
   (TeX-add-symbols
    '("extravspace" 1)
    "frontmatter"
    "mainmatter"
    "makelot"
    "makelof"
    "makelos"
    "maketoc"
    "bodyspacing"
    "tablespacing"
    "makefrontmatter"
    "maketitlepage"
    "makecopyrightpage"
    "makeabstract"
    "submitted"
    "copyrightyear"
    "adviser"
    "departmentprefix"
    "department"
    "acknowledgements"
    "dedication"
    "makeacknowledgements"
    "makededication"
    "abstract")
   (LaTeX-add-counters
    "subyear"))
 :latex)

