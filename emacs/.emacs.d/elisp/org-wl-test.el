(eval-buffer (find-file-noselect "./org-wl.el"))

(defun insert-file-header ()
  (insert "#+title:      Work Log\n")
  (insert "#+date:       [2025-12-07 Sun 17:44]\n")
  (insert "#+filetags:   :devlog\n")
  (insert "#+identifier: 20251207T174435\n"))

(defun insert-sub-headers ()
  (insert "** Sub 1\n")
  (insert "*** Sub 1.2\n")
  (insert "** Sub 2\n"))

(defun add-entry-from (task-file)
  (save-current-buffer
    (let* ((buff (find-file-noselect task-file)))
      (with-current-buffer buff
        (make-local-variable 'wl-file)
        (setq wl-file (make-temp-org-file "wl-file"))
        (goto-char (point-min))
        (wl-add-entry)
        wl-file))))

(defun add-two-entries-from (task-file)
  (save-current-buffer
    (let* ((buff (find-file-noselect task-file)))
      (with-current-buffer buff
        (make-local-variable 'wl-file)
        (setq wl-file (make-temp-org-file "wl-file"))
        (goto-char (point-min))
        (wl-add-entry)
        (wl-add-entry)
        wl-file))))

(defun make-temp-org-file (name) (make-temp-file name nil ".org"))

(defun assert-new-today-entry (file header-text sub-header-text)
    (save-current-buffer
      (set-buffer (find-file-noselect file))
      (should (goto-today-heading))
      (save-excursion
        (let ((headings (get-level-2-headings)))
          ;; headings contain given text
          (should (one-contains-str sub-header-text headings))
          ;; headings are still unique
          (should (equal headings (seq-uniq headings)))))
      (should (equal header-text (org-entry-get (point) "ITEM")))))

(defun assert-new-today-entry2 (wl-file task-file header-text sub-header-text)
  (let ((task-id (goto-first-heading-with-text task-file sub-header-text)))
    (save-current-buffer
      (set-buffer (find-file-noselect wl-file))
      (should (goto-today-heading))
      (save-excursion
        (let ((headings (get-level-2-headings)))
          ;; heading is a link to the given task id
          (should (one-contains-str (format "[[id:%s][%s]]" task-id sub-header-text) headings))
          ;; headings are still unique
          (should (equal headings (seq-uniq headings)))))
      (should (equal header-text (org-entry-get (point) "ITEM"))))))

(defun goto-first-heading-with-text (file text)
  (with-current-buffer (find-file-noselect task-file)
    (goto-char (point-min))
    (when (not (get-heading-text)) (org-goto-first-child))
    (should (equal text (get-heading-text)))
    (let ((id (org-entry-get (point) "ID") ))
      (should id)
      (should (assoc (format "id:%s" id) org-stored-links))
      id)))

(defun assert-worklog-entry (file task-string time-string worklog-size)
  (with-current-buffer (find-file-noselect task-file)
    (let ((id (goto-first-heading-with-text file task-string)))
      (should id)
      (should (assoc (format "id:%s" id) org-stored-links))
      (org-goto-first-child)
      (should (equal "Work Log" (get-heading-text)))
      (let ((children (get-sub-headings-at-level (+ 1 (org-current-level)))))
        (should (equal worklog-size (length children)))
        (should (one-contains-str time-string children))))))

(defun get-sub-headings-at-level (level)
  (let ((result
         (org-map-entries
          (lambda ()
            (org-element-property :title (org-element-at-point)))
          (format "LEVEL=%d" level)
          'tree)))
    result))

(defun one-contains-str ( str strings)
  (let ((result (seq-filter (lambda (s) (string-search str s)) strings )))
    (= 1 (length result))))

(defun get-heading-text ()
    (org-entry-get (point) "ITEM"))

(progn
  (ert-delete-all-tests)

  (let ((now (current-time)))
    (setq wl-without-today (make-temp-org-file "wl-without-today"))
    (setq wl-with-today (make-temp-org-file "wl-with-today"))
    (setq wl-with-today-and-existing-heading (make-temp-org-file "wl-with-today-and-existing-heading"))
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
  
  (ert-deftest is-inside-today ()
    (should (is-inside-today (format-time-string "%Y-%m-%d %H:%M" (current-time))))
    (should-not (is-inside-today "2025-12-11 0:01"))
    (should-not (is-inside-today "2140-12-11 0:01"))
    (should-not (is-inside-today "2025-12-12 10:45")))

  (ert-deftest creates-new-today-entry ()
    (add-new-entry wl-without-today "text under today")
    (assert-new-today-entry wl-without-today current-time "text under today"))

  (ert-deftest create-heading-under-existing-today-entry ()
    (add-new-entry wl-with-today "text under today")
    (assert-new-today-entry wl-with-today current-time-prev "text under today"))

  (ert-deftest does-not-create-same-heading-twice-under-today ()
    (add-new-entry wl-with-today-and-existing-heading "Entry 1")
    (assert-new-today-entry wl-with-today-and-existing-heading current-time-prev "Entry 1"))
  
  (ert-deftest adds-new-today-entry-to-empty-file ()
    (let ((wl-empty (make-temp-org-file "wl-empty")))
      (add-new-entry wl-empty "text under today")
      (assert-new-today-entry wl-empty current-time "text under today")))

  (ert-deftest wl-add-entry-adds-work-log-unter-task-with-no-worklog-yet ()
    (setq task-file (make-temp-org-file "wl-task-file"))
    (with-temp-file task-file (insert "* Some Task"))

    (let ((wl-file (add-entry-from task-file)))
      (assert-new-today-entry2 wl-file task-file current-time "Some Task")
      (assert-worklog-entry task-file "Some Task" current-time 1)))

  (ert-deftest wl-add-entry-adds-work-log-unter-task-with-existing-worklog ()
    (setq task-file (make-temp-org-file "wl-task-file"))
    (with-temp-file task-file
      (insert "* Some Task\n")
      (insert "** Work Log\n")
      (insert "*** 2025-12-05 11:06\n"))

    (let ((wl-file (add-entry-from task-file)))
      (assert-new-today-entry2 wl-file task-file current-time "Some Task")
      (assert-worklog-entry task-file "Some Task" current-time 2)
      (assert-worklog-entry task-file "Some Task" "2025-12-05 11:06" 2)))

  (ert-deftest wl-add-entry-adds-work-log-only-once-a-day ()
    (setq task-file (make-temp-org-file "wl-task-file"))
    (with-temp-file task-file
      (insert "* Some Task\n"))

    (add-two-entries-from task-file)
    (assert-worklog-entry task-file "Some Task" current-time 1))

  (ert-deftest wl-add-entry-adds-link-to-task ()
    (setq task-file (make-temp-org-file "wl-task-file"))
    (with-temp-file task-file (insert "* Some Task"))

    (let ((wl-file (add-entry-from task-file)))
      (assert-worklog-entry task-file "Some Task" current-time 1)
      (assert-new-today-entry2 wl-file task-file current-time "Some Task")))
  
  (ert t))
