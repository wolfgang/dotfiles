(load "util")

(if (eq system-type 'windows-nt)
  (progn
    (setq org-directory "e:/Library/Dropbox/org")
    (setq org-shared-directory "e:/Library/Dropbox/org-shared")
    (setq org-mobile-directory "e:/Library/Dropbox/OrgMobile")
    (setq org-mobile-inbox-for-pull (org-file "inbox_r.org"))))

(setq org-agenda-files (list org-directory denote-directory))
(when (boundp 'org-shared-directory) (push org-shared-directory org-agenda-files))
(setq org-journal-dir (concat org-directory "/journal"))


