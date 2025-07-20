;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "lispy" "0.27.0"
  "Vi-like Paredit."
  '((emacs      "24.3")
    (ace-window "0.9.0")
    (iedit      "0.9.9")
    (swiper     "0.11.0")
    (hydra      "0.14.0")
    (zoutline   "0.1.0"))
  :url "https://github.com/abo-abo/lispy"
  :commit "9c41bc011ae570283cb286659f75d12d38d437ea"
  :revdesc "9c41bc011ae5"
  :keywords '("lisp")
  :authors '(("Oleh Krehel" . "ohwoeowho@gmail.com"))
  :maintainers '(("Oleh Krehel" . "ohwoeowho@gmail.com")))
