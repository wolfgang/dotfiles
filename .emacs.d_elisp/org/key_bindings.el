(if (eq system-type 'darwin) 
    (progn 
      (setq mac-command-modifier 'control) 
      (define-key global-map (kbd "C-M-<return>") 'org-insert-heading-respect-content) 
      (global-unset-key "\C-z")))

(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key (kbd "<f12>") 'org-agenda)
(global-set-key (kbd "<f11>") 'org-columns)
(global-set-key (kbd "<f10>") 'org-refile-goto-last-stored)
(global-set-key (kbd "<f9>") 'org-pomodoro)
(global-set-key (kbd "<f8>") 'org-clock-in)
(global-set-key (kbd "<f7>") 'org-clock-out)

(define-key global-map "\C-cc" 'org-capture)

(global-set-key (kbd "C->") 'show-children)
(global-set-key (kbd "C-<") 'hide-subtree)
