;; -*- no-byte-compile: t; lexical-binding: nil -*-
(define-package "org-web-tools" "1.3"
  "Display and capture web content with Org-mode."
  '((emacs   "27.1")
    (org     "9.0")
    (compat  "29.1.4.2")
    (dash    "2.12")
    (esxml   "0.3.4")
    (s       "1.10.0")
    (plz     "0.7.1")
    (request "0.3.0"))
  :url "http://github.com/alphapapa/org-web-tools"
  :commit "7a6498f442fc7f29504745649948635c7165d847"
  :revdesc "v1.3-0-g7a6498f442fc"
  :keywords '("hypermedia" "outlines" "org" "web")
  :authors '(("Adam Porter" . "adam@alphapapa.net"))
  :maintainers '(("Adam Porter" . "adam@alphapapa.net")))
