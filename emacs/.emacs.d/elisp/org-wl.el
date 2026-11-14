;; -*- lexical-binding: t; -*-
(defvar wl-file
  "Location of the work log file. Daily headings are added on top level")

(defvar wl-worklog-subheading 
  "Whether to only use a subheading for entry links under the task")

(defun wl-add-entry ()
  (interactive)
  (let* ((lnk (org-store-link nil t))
         (id-part (car lnk))
         (title-part (cadr lnk))
         (text (format "[[%s][%s]]" id-part title-part)))
    (let* ((result (add-new-entry-new wl-file text))
           (text (car result))
           (lnk (car (cdr result)))
           (is-new (car (last result))))
      (when is-new
        (progn
          (when wl-worklog-subheading (save-excursion (add-worklog-link text lnk)))
          (wl--add-worklog-item (format "[[%s][%s]]" lnk text ) ))))))

(setq wl-file-temp "~/sandbox/scratch.org")

(defun add-new-entry (file text)
  (let* ((time (decode-time (current-time)))
         (date (list (decoded-time-month time )
                     (decoded-time-day time )
                     (decoded-time-year time ))))
    

    (save-current-buffer
      (let* ((buff (find-file-noselect file))
             (_ (set-buffer buff))
             (lines (car (buffer-line-statistics buff))))

        (let* ((_ (org-datetree-find-create-entry '(year month day) date))
               (level (org-element-property :level (org-element-at-point)))
               (children (get-level-n-headings (+ 1 level)))
               (day-headline (format-time-string "%Y-%m-%d" (current-time)))
               (is-new (not (equal text (car (member text children))))))
          (if is-new
              (progn
                (end-of-line)
                (org-insert-subheading "")
                (insert text))
            (goto-today-child-text text))
          (list day-headline (org-id-store-link-maybe t) is-new))))))

(defun get-level-n-headings (n)
  (let ((result
         (org-map-entries
          (lambda ()
            (org-element-property :title (org-element-at-point)))
          (format "LEVEL=%d" n)
          'tree)))
    result))

(defun goto-today-child-text (text)
  (setq done nil)
  (org-goto-first-child)
  (while (not done)
    (let ((text2 (org-entry-get (point) "ITEM")))
      (if (equal text text2)
          (setq done t)
        (org-goto-sibling)))))

(defun add-worklog-link (today lnk)
  (let ((has-log
         (save-excursion
           (progn (org-goto-first-child)
                  (equal "Work Log" (org-entry-get (point) "ITEM"))))))
    
    (when (not has-log)
      (progn
        (org-back-to-heading)
        (org-end-of-meta-data t)
        (newline)
        (previous-line)
        (org-insert-subheading "")
        (insert "Work Log"))))
  (org-goto-first-child)
  (org-insert-subheading "")
  (let* ((text (format "[[%s][%s]]" lnk today )))
    (insert text)))

(defun wl--add-worklog-item (item)
  (wl--add-worklog-drawer)
  (wl--goto-worklog-drawer)
  (newline)
  (insert item))

(defun wl--add-worklog-drawer ()
  (when (not (wl--goto-worklog-drawer))
    (wl--skip-properties)
    (end-of-line)
    (newline)
    (insert ":WORKLOG:\n")
    (insert ":END:\n")))

(defun wl--goto-worklog-drawer ()
  (org-back-to-heading)
  (let ((end (save-excursion (outline-next-heading) (point))))
    (re-search-forward "^[ \t]*:WORKLOG:[ \t]*$" end t)))

(defun wl--skip-properties ()
  (org-back-to-heading)
  (let* ((end (save-excursion (outline-next-heading) (point)))
         (props (re-search-forward "^[ \t]*:PROPERTIES:[ \t]*$" end t)))
    (when props
      (re-search-forward "^[ \t]*:END:[ \t]*$" end t))))

(provide 'org-wl)
