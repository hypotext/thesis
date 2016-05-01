(TeX-add-style-hook
 "thesis"
 (lambda ()
   (TeX-add-to-alist 'LaTeX-provided-class-options
                     '(("puthesis" "12pt" "lot" "lof")))
   (TeX-add-to-alist 'LaTeX-provided-package-options
                     '(("xcolor" "dvipsnames") ("sfmath" "cm")))
   (add-to-list 'LaTeX-verbatim-environments-local "lstlisting")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperref")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperimage")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "hyperbaseurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "nolinkurl")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "url")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-braces-local "lstinline")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "path")
   (add-to-list 'LaTeX-verbatim-macros-with-delims-local "lstinline")
   (TeX-run-style-hooks
    "latex2e"
    "puthesis"
    "puthesis12"
    "mathpazo"
    "enumitem"
    "xcolor"
    "graphicx"
    "verbatim"
    "multirow"
    "longtable"
    "booktabs"
    "sfmath"
    "listings"
    "amssymb"
    "amsmath"
    "amsthm"
    "dcolumn"
    "hyperref"
    "url")
   (TeX-add-symbols
    '("ct" 2)
    '("eqn" 1)
    "proquestmode"
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
    "sec:introduction"
    "sec:related_work"
    "sec:background"
    "sec:summary_of_hmac_drbg"
    "sec:security_properties"
    "sec:overview_of_the_foundational_cryptography_framework"
    "sec:a_simple_example_of_reasoning_about_programs_in_prpl"
    "sec:proofs"
    "sec:paper_proofs_vs_machine_checked_proofs"
    "sec:indistinguishability_proof_for_one_call"
    "lem:prf_advantage_one"
    "intermediate2"
    "thm:pr_collisions"
    "lem:collision_bound"
    "sec:indistinguishability_proof_for_a_simplified_hmac_drbg"
    "sec:definitions"
    "def:indist"
    "sec:proof_outline"
    "ex:hybrid_notation"
    "thm:adjacent_hybrids"
    "lem:hybrid_triangle"
    "ex:hybrid_intermediate"
    "lem:prf_advantage_max"
    "thm:hybrids"
    "sec:proof_of_backtracking_resistance"
    "thm:br"
    "sec:on_proving_prediction_resistance"
    "sec:comments_on_the_machine_checked_proofs"
    "sec:proof_tree"
    "sec:coq_specific_reasoning"
    "sec:whats_left_to_prove_in_the_coq_development"
    "sec:how_verification_helped"
    "sec:comments_on_hmac_drbgs_design"
    "sec:future_work"
    "sec:linking_our_crypto_spec_with_the_functional_spec"
    "fig:project_diagram"
    "sec:extending_our_work_to_other_drbgs"
    "sec:conclusion"
    "sec:code"
    "sec:main_definitions_in_the_coq_development"
    "sec:prf_drbg_definitions"
    "sec:hmac_drbg_definitions"
    "sec:proof_of_indistinguishability"
    "sec:main_games"
    "sec:explanations_of_each_lemma_in_the_coq_development"
    "sec:adjacent_hybrids_are_close"
    "sec:identical_until_bad")
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
    "pauli2015"
    "petcher2015"
    "petcherthesis2015"
    "sanguansin2016"
    "schneier2008"
    "ye2014")
   (LaTeX-add-environments
    "game"
    "indenttext"
    "indentlist")
   (LaTeX-add-enumitem-newlists
    '("longenum" "enumerate"))
   (LaTeX-add-amsthm-newtheorems
    "thm"
    "dfn"
    "cor"
    "lem"
    "ex"
    "rem"))
 :latex)

