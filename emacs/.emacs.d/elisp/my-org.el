;(assq-delete-all 'org package--builtins)
;(assq-delete-all 'org package--builtin-versions)


(use-package org-journal
  :ensure t
  :init
  (add-to-list 'linum-disabled-modes-list 'org-journal-mode)
  (global-set-key (kbd "C-x C-j") 'org-journal-new-entry)
  (setq org-journal-file-type 'monthly)
  (setq org-journal-file-format "%Y-%m.org")
  (setq org-journal-date-format "%A, %d.%m.%Y")
  :hook (org-journal-mode . flyspell-mode))

(use-package org
  :ensure t
  :defer t
  :init
  ;; Replace S-<cursor keys> used by windmove
  (setq org-replace-disputed-keys t
        org-complete-tags-always-offer-all-agenda-tags t
        org-hide-emphasis-markers t
        org-special-ctrl-a/e t
        org-pretty-entities t
        org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id
        org-pretty-entities-include-sub-superscripts nil
        org-agenda-include-diary t
        org-src-window-setup 'split-window-below)
  :bind (:map org-mode-map
              (( "C-M-<return>" . org-insert-heading-respect-content)
               ("C-c r" . avy-org-refile-as-child)
               ("C-z b" . my-org-insert-bullet-item)
               ("C-c l" . org-store-link)))
  :config
  ;; This enables windmove keys to work in org mode
  ;; See https://orgmode.org/manual/Conflicts.html
  (add-hook 'org-shiftup-final-hook 'windmove-up)
  (add-hook 'org-shiftleft-final-hook 'windmove-left)
  (add-hook 'org-shiftdown-final-hook 'windmove-down)
  (add-hook 'org-shiftright-final-hook 'windmove-right)
  (global-set-key (kbd "<f9>") 'org-pomodoro)
  (add-to-list 'safe-local-variable-values '(org-confirm-babel-evaluate))
  (add-hook 'org-after-todo-state-change-hook
	        (lambda ()
              (if (string= "WAIT" org-state)
                  (progn
	                (message (concat "TODO state changed: " org-state))
                    (insert "(<REASON>) ")))))
  
  (load "org/config.el"))

(defun my-org-insert-bullet-item ()
  (interactive)
  (progn
    (org-back-to-heading)
    (setq header-line-num (line-number-at-pos))
    (forward-line 1)
    (setq left-to-move 0)
    (while (and (= 0 left-to-move)
                (not (looking-at org-complex-heading-regexp)))
      (setq left-to-move (forward-line 1)))
    (beginning-of-line)
    (while
        (and
         (> (line-number-at-pos) header-line-num)
         (or (is-current-line-empty-p)
             (looking-at org-complex-heading-regexp)))
      (forward-line -1))
    (end-of-line)
    (insert "\n")
    (insert "- [ ] ")
    (save-excursion
      (progn
       (org-back-to-heading)
       (outline-show-subtree)))))

(defun is-current-line-empty-p ()
    (let ((str (buffer-substring-no-properties
                (line-beginning-position)
                (line-end-position))))
      (seq-empty-p (s-trim str))))
    

(provide 'my-org)

