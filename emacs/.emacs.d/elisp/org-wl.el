(defvar wl-file
  "Location of the work log file. Daily headings are added on top level")

(defun wl-add-entry ()
  (interactive)
  (let* ((lnk (org-store-link nil t))
         (id-part (car lnk))
         (title-part (cadr lnk))
         (text (format "[[%s][%s]]" id-part title-part)))
    (add-new-entry wl-file text)))

(defun add-new-entry ( file text)
  (save-current-buffer
    (let* ((buff (find-file-noselect file))
           (_ (set-buffer buff))
           (result (goto-today-heading)))
      (if result
          (let ((headings (get-level-2-headings)))
            (when (not (equal text (car (member text headings))))
              (progn
                (org-insert-subheading "")
                (insert text)))
            (goto-new-entry buff text))
        (progn
          (goto-char (point-min))
          (org-goto-first-child)
          (beginning-of-line)
          (newline)
          (forward-line -1)
          (org-insert-heading)
          (insert (format-time-string "%Y-%m-%d %H:%M"))
          (progn
            (org-insert-subheading "")
            (insert text)
            (goto-new-entry buff text)))))
    (save-buffer buff)))

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
    (org-goto-first-child)
    (setq done nil)
    (setq result nil)
    (while (not done)
      (let ((text (org-entry-get (point) "ITEM")))
        (when (is-inside-today text)
          (progn (setq done t)
                 (setq result t) ))
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
