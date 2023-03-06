(load "util")

(if (eq system-type 'windows-nt)
  (progn
    (setq org-directory "e:/Library/Dropbox/org")
    (setq org-shared-directory "e:/Library/Dropbox/org-shared")
    (setq org-mobile-directory "e:/Library/Dropbox/OrgMobile")
    (setq org-mobile-inbox-for-pull (org-file "inbox_r.org"))))

(defun make-org-roam-daily-dir ()
  (if (eq nil org-roam-directory) nil
    (concat org-roam-directory "/daily" )))

(setq org-agenda-files (remove-if (lambda (d) (eq nil d )) (list org-directory org-shared-directory org-roam-directory (make-org-roam-daily-dir))))
(setq org-journal-dir (concat org-directory "/journal"))


