(defvar wl-file
  "Location of the work log file. Daily headings are added on top level")

(defun wl-add-entry ()
  (interactive)
  (let* ((lnk (org-store-link nil t))
         (id-part (car lnk))
         (title-part (cadr lnk))
         (text (format "[[%s][%s]]" id-part title-part)))
    (let* ((result (add-new-entry wl-file text))
           (text (car result))
           (lnk (car (cdr result)))
           (is-new (car (last result))))
      (when is-new
        (add-worklog-link text lnk)))))

(defun add-new-entry (file text)
  (save-current-buffer
    (setq modified-heading nil)
    (setq is-new nil)
    (let* ((buff (find-file-noselect file))
           (_ (set-buffer buff))
           (result (goto-today-heading)))
      (if result
          (let ((headings (get-level-2-headings)))
            (setq modified-heading result)
            (when (not (equal text (car (member text headings))))
              (progn
                (org-insert-subheading "")
                (insert text)
                (setq is-new t)))
            (goto-new-entry buff text))
        (progn
          (goto-char (point-min))
          (org-goto-first-child)
          (beginning-of-line)
          (newline)
          (forward-line -1)
          (org-insert-heading)
          (insert (format-time-string "%Y-%m-%d %H:%M"))
          (setq modified-heading (format-time-string "%Y-%m-%d %H:%M"))
          (progn
            (org-insert-subheading "")
            (insert text)
            (setq is-new t)
            (goto-new-entry buff text))))
      (save-buffer buff)
      (list modified-heading (org-id-store-link-maybe t) is-new) )))

(defun add-worklog-link (today lnk)
  (let ((has-log
         (save-excursion
           (progn (org-goto-first-child)
                  (equal "Work Log" (org-entry-get (point) "ITEM"))))))
    
    (when (not has-log)
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
        (org-insert-subheading "")
        (insert "Work Log"))))
  (org-goto-first-child)
  (org-insert-subheading "")
  (let* ((text (format "[[%s][%s]]" lnk today )))
    (insert text)))

(defun goto-new-entry (buff text)
  (let ((w (get-buffer-window buff t)))
    (when w (select-window w)))
  (goto-today-entry-with-text text))

(defun goto-today-entry-with-text (text)
  (goto-today-heading)
  (setq done nil)
  (org-goto-first-child)
  (while (not done)
    (let ((text2 (org-entry-get (point) "ITEM")))
      (if (equal text text2)
          (setq done t)
        (org-goto-sibling)))))

(defun goto-today-heading ()
  (progn
    (goto-char (point-min))
    (when (not (org-entry-get (point) "ITEM"))
      (org-goto-first-child))
    (setq done nil)
    (setq result nil)
    (while (not done)
      (let ((text (org-entry-get (point) "ITEM")))
        (when (and text (is-inside-today text))
          (progn (setq done t)
                 (setq result text) ))
        (when
            (and (not done)
                 (not (org-goto-sibling))) (setq done t))))

    result))

(defun is-inside-today (timestamp)
  (let ((time1 (parse-time-string timestamp))
        (now (decode-time (current-time)))) 
    (= (nth 3 time1) (nth 3 now))))

(defun get-level-2-headings ()
  (let ((result
         (org-map-entries
          (lambda ()
            (org-element-property :title (org-element-at-point)))
          "LEVEL=2"
          'tree)))
    result))

(provide 'org-wl)
