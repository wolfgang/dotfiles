;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "ob-async" "1.0.0"
  "Asynchronous org-babel src block execution."
  '((async "1.9")
    (org   "9.0.1")
    (emacs "24.4")
    (dash  "2.14.1"))
  :url "https://github.com/astahlman/ob-async"
  :commit "5984d6172c179528adf9aeba414598604dfb5c9a"
  :revdesc "5984d6172c17"
  :keywords '("tools")
  :authors '(("Andrew Stahlman" . "andrewstahlman@gmail.com"))
  :maintainers '(("Andrew Stahlman" . "andrewstahlman@gmail.com")))
