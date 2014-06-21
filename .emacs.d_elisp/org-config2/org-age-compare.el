(defun org-age-set-to-today-if-missing ()
  (interactive)
  (or (org-entry-get (point) org-age-property)
      (let ((d (format-time-string "%Y-%m-%d" (current-time))))
        (org-entry-put (point) org-age-property d)
        d)))

(defconst org-date-regexp "\\b[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\b")

(defun org-age-set-from-vc-if-missing ()
  (interactive)
  (or (org-entry-get (point) org-age-property)
      (let ((current-line (count-lines (point-min) (point)))
            date-string)
        (save-window-excursion
          (vc-annotate buffer-file-name (vc-workfile-version buffer-file-name))
          (if (search-forward-regexp org-date-regexp
                                     (point-at-eol) t)
              (setq date-string (match-string 0)))
          (kill-buffer nil)) ;; otherwise next annotation may be wrong
        (when date-string
          (org-entry-put (point) org-age-property date-string)
          (basic-save-buffer)) ;; otherwise next annotation may be wrong
        date-string)))


(defun org-age-compare (a b)
  (let* ((ma (get-text-property 1 'org-marker a))
         (mb (get-text-property 1 'org-marker b))
         (da (with-current-buffer (marker-buffer ma)
               (goto-char (marker-position ma))
               (org-age-set-to-today-if-missing)))
         (db (with-current-buffer (marker-buffer mb)
               (goto-char (marker-position mb))
               (org-age-set-to-today-if-missing))))
    (cond
     ((string< da db) -1)
     ((string= da db) nil)
     (t +1))))

(defun recent-entry-matcher ()  "STYLE<>\"habit\"&TIMESTAMP_IA>=\"<-7d>\"")
