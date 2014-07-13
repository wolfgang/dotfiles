(load "util")

(if (eq system-type 'windows-nt)
  (progn
    (setq org-directory "e:/Library/Dropbox/org")
    (setq org-shared-directory "e:/Library/Dropbox/org-shared")
    (setq org-mobile-directory "e:/Library/Dropbox/OrgMobile")
    (setq org-mobile-inbox-for-pull (org-file "inbox_r.org")))
  (progn
    (setq org-directory "~/Dropbox/org")
    (setq org-shared-directory "~/Dropbox/org-shared")
    (setq org-mobile-directory "")
  )
)

(setq org-agenda-files (list org-directory org-shared-directory))
