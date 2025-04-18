;;; eyebrowse-autoloads.el --- automatically extracted autoloads (do not edit)   -*- lexical-binding: t -*-
;; Generated by the `loaddefs-generate' function.

;; This file is part of GNU Emacs.

;;; Code:

(add-to-list 'load-path (or (and load-file-name (directory-file-name (file-name-directory load-file-name))) (car load-path)))



;;; Generated autoloads from eyebrowse.el

(autoload 'eyebrowse-setup-evil-keys "eyebrowse" "\
Set up key bindings specific to Evil.
Currently only gt, gT, gc and zx are supported.")
(autoload 'eyebrowse-setup-opinionated-keys "eyebrowse" "\
Set up more opinionated key bindings for using eyebrowse.

M-0..M-9, C-< / C->, C-'and C-\" are used for switching.  If
IGNORE-EVIL isn't set and Evil is detected, extra key bindings
will be set up with `eyebrowse-setup-evil-keys' as well.

(fn &optional IGNORE-EVIL)")
(defvar eyebrowse-mode nil "\
Non-nil if Eyebrowse mode is enabled.
See the `eyebrowse-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `eyebrowse-mode'.")
(custom-autoload 'eyebrowse-mode "eyebrowse" nil)
(autoload 'eyebrowse-mode "eyebrowse" "\
Toggle `eyebrowse-mode'.

This global minor mode provides a set of keybindings for
switching window configurations.  It tries mimicking the tab
behaviour of `ranger`, a file manager.

This is a global minor mode.  If called interactively, toggle the
`Eyebrowse mode' mode.  If the prefix argument is positive, enable the
mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable the
mode if ARG is nil, omitted, or is a positive number.  Disable the mode
if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='eyebrowse-mode)'.

The mode's hook is called both when the mode is enabled and when it is
disabled.

(fn &optional ARG)" t)
(register-definition-prefixes "eyebrowse" '("eyebrowse-"))

;;; End of scraped data

(provide 'eyebrowse-autoloads)

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; no-native-compile: t
;; coding: utf-8-emacs-unix
;; End:

;;; eyebrowse-autoloads.el ends here
