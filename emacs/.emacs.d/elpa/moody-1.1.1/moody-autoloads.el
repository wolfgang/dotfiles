;;; moody-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from moody.el

(autoload 'moody-replace-mode-line-buffer-identification "moody" "\
Use moody's variant of `mode-line-buffer-identification'.

If optional RESTORE is true, then go back to the default.
If called interactively, then toggle between the variants.

(fn &optional RESTORE)" t)
(autoload 'moody-replace-sml/mode-line-buffer-identification "moody" "\
Use moody's variant of `mode-line-buffer-identification'.

If optional RESTORE is true, then go back to the default.
If called interactively, then toggle between the variants.

Use instead of `moody-replace-mode-line-buffer-identification'
if you use the `smart-mode-line' package, after `sml/setup' has
already been called.

(fn &optional RESTORE)" t)
(autoload 'moody-replace-vc-mode "moody" "\
Use moody's variant of `vc-mode' mode-line element.

If optional RESTORE is true, then go back to the default.
If called interactively, then toggle between the variants.

(fn &optional RESTORE)" t)
(autoload 'moody-replace-eldoc-minibuffer-message-function "moody" "\
Use moody's variant of `eldoc-minibuffer-message'.

If optional RESTORE is true, then go back to the default.
If called interactively, then toggle between the variants.

(fn &optional RESTORE)" t)
(autoload 'moody-replace-mode-line-front-space "moody" "\
Use moody's variant of `mode-line-front-space'.

If optional RESTORE is true, then go back to the default.
If called interactively, then toggle between the variants.

Adjust the display width so that subsequent character in the
mode-line are aligned with those in the buffer.  Unlike other
moody variants do not use any tab or ribbon.

(fn &optional RESTORE)" t)
(register-definition-prefixes "moody" '("moody-"))

;;; End of scraped data

(provide 'moody-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; moody-autoloads.el ends here