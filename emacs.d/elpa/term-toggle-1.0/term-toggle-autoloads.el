;;; term-toggle-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "term-toggle" "term-toggle.el" (0 0 0 0))
;;; Generated autoloads from term-toggle.el

(autoload 'term-toggle-term "term-toggle" "\
Toggle `term'." t nil)

(autoload 'term-toggle-shell "term-toggle" "\
Toggle `shell'." t nil)

(autoload 'term-toggle-ansi "term-toggle" "\
Toggle `ansi-term'." t nil)

(autoload 'term-toggle-eshell "term-toggle" "\
Toggle `eshell'." t nil)

(autoload 'term-toggle-ielm "term-toggle" "\
Toggle `ielm'." t nil)

(register-definition-prefixes "term-toggle" '("term-toggle" "tt--"))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; term-toggle-autoloads.el ends here
