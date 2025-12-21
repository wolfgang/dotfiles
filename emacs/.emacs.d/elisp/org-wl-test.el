(require 'org-wl)
(require 'test-simple)

(defun assert-new-today-entry (file header-text sub-header-text)
  (save-current-buffer
    (set-buffer (find-file-noselect file))
    (goto-today-heading)
    (save-excursion
      (let ((headings (get-level-2-headings)))
        ;; headings contain given text
        (assert-equal sub-header-text (car (member sub-header-text headings)))
        ;; headings are still unique
        (assert-equal headings (seq-uniq headings))))
    
    (let ((text (org-entry-get (point) "ITEM")))
      (assert-equal header-text text))))

(defun insert-file-header ()
  (insert "#+title:      Work Log\n")
  (insert "#+date:       [2025-12-07 Sun 17:44]\n")
  (insert "#+filetags:   :devlog\n")
  (insert "#+identifier: 20251207T174435\n"))
(defun insert-sub-headers ()
  (insert "** Sub 1\n")
  (insert "*** Sub 1.2\n")
  (insert "** Sub 2\n"))

(test-simple-start)

(assert-t (is-inside-today (format-time-string "%Y-%m-%d %H:%M" (current-time))))
(assert-nil (is-inside-today "2025-12-11 0:01"))
(assert-nil (is-inside-today "2140-12-11 0:01"))
(assert-nil (is-inside-today "2025-12-12 10:45"))

(let ((now (current-time)))
  (setq wl-without-today "/tmp/wl-without-today.org")
  (setq wl-with-today "/tmp/wl-with-today.org")
  (setq wl-with-today-and-existing-heading "/tmp/wl-with-today-and-existing-heading.org")
  (setq today (format-time-string "%Y-%m-%d" now))
  (setq current-time (format-time-string "%Y-%m-%d %H:%M" now))
  (setq current-time-prev (format "%s 15:32" today)))

(with-temp-file wl-without-today
  (insert-file-header)
  (insert "* 2025-12-10 15:32\n")
  (insert-sub-headers)
  (insert "* 2025-12-05 11:06\n"))

(with-temp-file wl-with-today
  (insert-file-header)
  (insert (format "* %s\n" current-time-prev))
  (insert-sub-headers)
  (insert "* 2025-12-9 11:54\n")
  (insert "* 2025-12-10 15:32\n")
  (insert-sub-headers))

(with-temp-file wl-with-today-and-existing-heading
  (insert-file-header)
  (insert (format "* %s\n" current-time-prev))
  (insert "** Entry 1"))

(add-new-entry wl-without-today "text under today")
(add-new-entry wl-with-today "text under today")
(add-new-entry wl-with-today-and-existing-heading "Entry 1")
(assert-new-today-entry wl-without-today current-time "text under today")
(assert-new-today-entry wl-with-today current-time-prev "text under today")
(assert-new-today-entry wl-with-today-and-existing-heading current-time-prev "Entry 1")

(end-tests)
