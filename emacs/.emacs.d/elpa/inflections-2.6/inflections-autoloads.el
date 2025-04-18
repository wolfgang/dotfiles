;;; inflections-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from inflections.el

(autoload 'inflection-singularize-string "inflections" "\
Return the singularized version of STR.

(fn STR)")
(define-obsolete-function-alias 'singularize-string 'inflection-singularize-string "2.6")
(autoload 'inflection-pluralize-string "inflections" "\
Return the pluralized version of STR.

(fn STR)")
(define-obsolete-function-alias 'pluralize-string 'inflection-pluralize-string "2.6")

;;; End of scraped data

(provide 'inflections-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; inflections-autoloads.el ends here
