(save-current-buffer
  (progn
    (set-buffer (find-file-noselect "~/sandbox/wl-test.org"))
    (goto-char (point-min))
    (org-goto-first-child)
    (setq done nil)
    (while (not done)
      (print (org-entry-get (point) "ITEM"))
      (when (not (org-goto-sibling)) (setq done t)))))

(save-current-buffer
  (let* ((buff (find-file-noselect "~/sandbox/wl-test.org"))
         (_ (set-buffer buff))
         (result (get-today-headline)))
    (if result
        (progn
          (org-insert-subheading "")
          (insert "HELLO2"))
        (progn
          (goto-char (point-min))
          (org-goto-first-child)
          (beginning-of-line)
          (newline)
          (forward-line -1)
          (org-insert-heading)
          (insert (format-time-string "%Y-%m-%d %H:%M"))))))

(defun get-today-headline ()
  (progn
    (goto-char (point-min))
    (org-goto-first-child)
    (setq done nil)
    (setq result nil)
    (while (not done)
      (let ((text (org-entry-get (point) "ITEM")))
        (when (is-inside-today text)
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

(require 'test-simple)

(test-simple-start)
(assert-t (is-inside-today (format-time-string "%Y-%m-%d %H:%M" (current-time))))
(assert-nil (is-inside-today "2025-12-11 0:01"))
(assert-nil (is-inside-today "2140-12-11 0:01"))
(assert-nil (is-inside-today "2025-12-12 10:45"))

(end-tests)


