(advice-remove 'refile-advice 'org-refile)
(defadvice org-refile (after refile-advice activate)
    (save-window-excursion
        (org-refile-goto-last-stored)
        (when (has-someday-maybe-parent)
            (org-todo "MAYBE")
        )
    )
)

(defun has-someday-maybe-parent () 
    (save-excursion
        (org-up-heading-safe)
        (message "Heading: %s" (nth 4 (org-heading-components)))
        (matches-someday-maybe (nth 4 (org-heading-components)))
        )
    )

(defun matches-someday-maybe (str)
    (not (eq nil (string-match-p (regexp-quote "Someday") str))))
