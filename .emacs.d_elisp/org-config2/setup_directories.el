(load "util")

(if (not (eq system-type 'darwin))
  (progn
    (setq org-directory "e:/Library/Dropbox/org")
    (setq org-mobile-directory "e:/Library/Dropbox/OrgMobile")
    (setq org-mobile-inbox-for-pull (org-file "inbox_r.org")))
  (progn
    (setq org-directory "~/Dropbox/org")
    (setq org-mobile-directory "")
  )
)

(setq org-agenda-files (list org-directory))
