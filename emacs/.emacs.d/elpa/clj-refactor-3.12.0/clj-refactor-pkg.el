(define-package "clj-refactor" "3.12.0" "A collection of commands for refactoring Clojure code"
  '((emacs "26.1")
    (seq "2.19")
    (yasnippet "0.6.1")
    (paredit "24")
    (multiple-cursors "1.2.2")
    (clojure-mode "5.18.0")
    (cider "1.11.1")
    (parseedn "1.2.0")
    (inflections "2.6")
    (hydra "0.13.2"))
  :commit "dc1bbc8cdaa723bdbb6669ea7d280625c370755d" :authors
  '(("Magnar Sveen" . "magnars@gmail.com")
    ("Lars Andersen" . "expez@expez.com")
    ("Benedek Fazekas" . "benedek.fazekas@gmail.com")
    ("Bozhidar Batsov" . "bozhidar@batsov.dev"))
  :maintainers
  '(("Magnar Sveen" . "magnars@gmail.com"))
  :maintainer
  '("Magnar Sveen" . "magnars@gmail.com")
  :keywords
  '("convenience" "clojure" "cider"))
;; Local Variables:
;; no-byte-compile: t
;; End:
