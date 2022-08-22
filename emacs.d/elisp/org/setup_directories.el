(load "util")

(if (eq system-type 'windows-nt)
  (progn
    (setq org-directory "e:/Library/Dropbox/org")
    (setq org-shared-directory "e:/Library/Dropbox/org-shared")
    (setq org-mobile-directory "e:/Library/Dropbox/OrgMobile")
    (setq org-mobile-inbox-for-pull (org-file "inbox_r.org")))
  (progn
    (setq org-directory (getenv "ORG_DIRECTORY"))
    (setq org-shared-directory (getenv "ORG_SHARED_DIRECTORY"))))

(setq org-agenda-files (remove-if (lambda (d) (eq nil d )) (list org-directory org-shared-directory)))
(setq org-journal-dir (concat org-directory "/journal"))
