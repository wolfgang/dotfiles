;;; beframe-autoloads.el --- automatically extracted autoloads  -*- lexical-binding: t -*-
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "beframe" "beframe.el" (0 0 0 0))
;;; Generated autoloads from beframe.el

(autoload 'beframe-read-buffer "beframe" "\
The `read-buffer-function' that limits buffers to frames.
PROMPT, DEF, REQUIRE-MATCH, and PREDICATE are the same as
`read-buffer'.  The PREDICATE is ignored, however, to apply the
per-frame filter.

\(fn PROMPT &optional DEF REQUIRE-MATCH PREDICATE)" nil nil)

(autoload 'beframe-switch-buffer "beframe" "\
Switch to BUFFER in the current frame using completion.

Either bind this command to a key as an alternative to
`switch-to-buffer', or enable the minor mode
`beframe-mode' which makes all buffer prompts limit the
candidates to those that belong to the selected frame.

Also see the other Beframe commands:

\\{beframe-prefix-map}

\(fn BUFFER)" t nil)

(autoload 'beframe-switch-buffer-in-frame "beframe" "\
Switch to BUFFER that belongs to FRAME.

BUFFER is selected with completion among a list of buffers that
belong to FRAME.

Either bind this command to a key as an alternative to
`switch-to-buffer', or enable the minor mode
`beframe-mode' which makes all buffer prompts limit the
candidates to those that belong to the selected frame.

Also see `beframe-switch-buffer'.

Raising and then selecting FRAME does not depend solely on Emacs.
The window manager must permit such an operation.  See bug#61319:
<https://debbugs.gnu.org/cgi/bugreport.cgi?bug=61319>.

\(fn FRAME BUFFER)" t nil)

(autoload 'beframe-buffer-menu "beframe" "\
Produce a `buffer-menu' for the current FRAME.
With FRAME as a prefix argument, prompt for a frame.  When called
from Lisp, FRAME satisfies `framep'.  With key SORT, apply this
sorting function—see `beframe-buffer-list' for more information.

The bespoke buffer menu is displayed in a window using
`display-buffer'.  Configure `display-buffer-alist' to control
its placement and other parameters.

Also see the other Beframe commands:

\\{beframe-prefix-map}

\(fn &optional FRAME &key SORT)" t nil)

(autoload 'beframe-assume-frame-buffers "beframe" "\
Assume FRAME buffer list, copying it into current buffer list.
When called interactively, prompt for FRAME using completion.
Else FRAME must satisfy `framep'.

Also see the other Beframe commands:

\\{beframe-prefix-map}

\(fn FRAME)" t nil)

(autoload 'beframe-unassume-frame-buffers "beframe" "\
Unassume FRAME buffer list, removing it from current buffer list.
When called interactively, prompt for FRAME using completion.
Else FRAME must satisfy `framep'.

Also see the other Beframe commands:

\\{beframe-prefix-map}

\(fn FRAME)" t nil)

(autoload 'beframe-assume-frame-buffers-selectively "beframe" "\
Assume BUFFERS from a selected frame into the current buffer list.

In interactive use, select a frame and then use
`completing-read-multiple' to pick the list of BUFFERS.  Multiple
candidates can be selected, each separated by the
`crm-separator' (typically a comma).

Also see the other Beframe commands:

\\{beframe-prefix-map}

\(fn BUFFERS)" t nil)

(autoload 'beframe-assume-buffers-selectively-all-frames "beframe" "\
Like `beframe-assume-frame-buffers-selectively' but for all frames." t nil)

(function-put 'beframe-assume-buffers-selectively-all-frames 'interactive-only 't)

(autoload 'beframe-unassume-current-frame-buffers-selectively "beframe" "\
Unassume BUFFERS from the current frame's buffer list.

In interactive use, call `completing-read-multiple' to pick the
list of BUFFERS.  Multiple candidates can be selected, each
separated by the `crm-separator' (typically a comma).

Also see the other Beframe commands:

\\{beframe-prefix-map}

\(fn BUFFERS)" t nil)

(autoload 'beframe-assume-all-buffers-no-prompts "beframe" "\
Assume the consolidated buffer list (all frames)." t nil)

(function-put 'beframe-assume-all-buffers-no-prompts 'interactive-only 't)

(autoload 'beframe-unassume-all-buffers-no-prompts "beframe" "\
Unassume the consolidated buffer list (all frames).
Keep only the `beframe-global-buffers'.

Also see the other Beframe commands:

\\{beframe-prefix-map}" t nil)

(function-put 'beframe-unassume-all-buffers-no-prompts 'interactive-only 't)

(defvar beframe-mode nil "\
Non-nil if Beframe mode is enabled.
See the `beframe-mode' command
for a description of this minor mode.
Setting this variable directly does not take effect;
either customize it (see the info node `Easy Customization')
or call the function `beframe-mode'.")

(custom-autoload 'beframe-mode "beframe" nil)

(autoload 'beframe-mode "beframe" "\
Make all buffer prompts limit candidates per frame.
Also see the `beframe-prefix-map'.

This is a minor mode.  If called interactively, toggle the
`Beframe mode' mode.  If the prefix argument is positive, enable
the mode, and if it is zero or negative, disable the mode.

If called from Lisp, toggle the mode if ARG is `toggle'.  Enable
the mode if ARG is nil, omitted, or is a positive number.
Disable the mode if ARG is a negative number.

To check whether the minor mode is enabled in the current buffer,
evaluate `(default-value \\='beframe-mode)'.

The mode's hook is called both when the mode is enabled and when
it is disabled.

\(fn &optional ARG)" t nil)

(autoload 'beframe-rename-frame "beframe" "\
Rename FRAME per `beframe-rename-function'.

When called interactively, prompt for FRAME.  Else accept FRAME
if it is an object that satisfies `framep'.

With optional NAME as a string, use it to name the given FRAME.
When called interactively, prompt for NAME when a prefix argument
is given.

With no NAME argument try to infer a name based on the following:

- If the current window has a buffer that visits a file, name the
  FRAME after the file's name and its `default-directory'.

- If the current window has a non-file-visiting buffer, use the
  `buffer-name' as the FRAME name.

- Else use the `default-directory'.

Remember that this function doubles as an example for
`beframe-rename-function': copy it and modify it accordingly.

\(fn FRAME &optional NAME)" t nil)

(register-definition-prefixes "beframe" '("beframe-"))

;;;***

;;;### (autoloads nil nil ("beframe-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; beframe-autoloads.el ends here
