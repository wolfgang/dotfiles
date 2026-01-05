(require 'ert)
(eval-buffer (find-file-noselect "./org-wl.el"))


(defmacro with-temp-org-buffer ( file &rest body)
  `(with-temp-buffer
    (insert-file ,file)
    (org-mode)
    (progn ,@body )))

(defun insert-file-header ()
  (insert "#+title:      Work Log\n")
  (insert "#+date:       [2025-12-07 Sun 17:44]\n")
  (insert "#+filetags:   :devlog\n")
  (insert "#+identifier: 20251207T174435\n"))

(defun insert-sub-headers ()
  (insert "** Sub 1\n")
  (insert "*** Sub 1.2\n")
  (insert "** Sub 2\n"))

(defun add-entry-from (task-file &optional target-file)
  (with-temp-org-buffer task-file
    (write-file task-file)
    (make-local-variable 'wl-file)
    (setq wl-file (or target-file (make-temp-org-file "wl-test-file")))
    (goto-char (point-min))
    (wl-add-entry)
    (save-buffer)
    wl-file))

(defun add-two-entries-from (task-file)
  (with-temp-org-buffer task-file
    (write-file task-file)
    (make-local-variable 'wl-file)
    (setq wl-file (make-temp-org-file "wl-test-file"))
    (goto-char (point-min))
    (wl-add-entry)
    (wl-add-entry)
    (save-buffer)
    wl-file))

(defun make-temp-org-file-with-single-heading ()
  (let ((file (make-temp-org-file "wl-test-task-file")))
    (with-temp-file file (insert "* Some Task"))
    file))

(defun make-temp-org-file (name) (make-temp-file name nil ".org"))

(defun assert-wl-file-entry (wl-file task-file header-text sub-header-text)
  (let ((task-id (goto-first-heading-with-text task-file sub-header-text)))
    (with-temp-org-buffer wl-file
      (should (goto-today-heading))
      (save-excursion
        (let ((headings (get-level-2-headings)))
          ;; heading is a link to the given task id
          (should (one-contains-str (format "[[id:%s][%s]]" task-id sub-header-text) headings))
          ;; headings are still unique
          (should (equal headings (seq-uniq headings)))))
      (should (equal header-text (org-entry-get (point) "ITEM"))))))

(defun goto-first-heading-with-text (file text)
  (with-temp-org-buffer file
    (goto-char (point-min))
    (when (not (get-heading-text)) (org-goto-first-child))
    (should (equal text (get-heading-text)))
    (let ((id (org-entry-get (point) "ID") ))
      (should id)
      (should (assoc (format "id:%s" id) org-stored-links))
      id)))

(defun assert-worklog-under-task (file task-string time-string worklog-size)
  (with-temp-org-buffer file
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
    (setq wl-without-today (make-temp-org-file "wl-test-without-today"))
    (setq wl-with-today (make-temp-org-file "wl-test-with-today"))
    (setq wl-with-today-and-existing-heading (make-temp-org-file "wl-test-with-today-and-existing-heading"))
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
  
  (defun kill-test-buffers ()
    (seq-each
     (lambda (b) (with-current-buffer b (save-buffer) (kill-buffer)))
     (seq-filter (lambda (b) (s-starts-with-p "wl-test-" (buffer-name b))) (buffer-list))))
  
  (ert-deftest is-inside-today-works ()
    (let* ((time (decode-time (current-time)))
           (day (nth 3 time))
           (month (nth 4 time)))
      (should (is-inside-today (format-time-string "%Y-%m-%d %H:%M" (current-time))))
      (should-not (is-inside-today (format "2025-%.2d-%.2d 0:01" month day)))
      (should-not (is-inside-today "2025-12-11 0:01"))
      (should-not (is-inside-today "2140-12-11 0:01"))
      (should-not (is-inside-today "2025-12-12 10:45"))))

  (ert-deftest wl-add-entry-creates-new-today-entry ()
    (let ((task-file (make-temp-org-file-with-single-heading)))
      (add-entry-from task-file wl-without-today)
      (assert-wl-file-entry wl-without-today task-file current-time "Some Task")))

  (ert-deftest wl-add-entry-creates-heading-under-existing-today-entry ()
    (let ((task-file (make-temp-org-file-with-single-heading)))
      (add-entry-from task-file wl-with-today)
      (assert-wl-file-entry wl-with-today task-file current-time-prev "Some Task")))

  (ert-deftest wl-add-entry-does-not-create-same-heading-twice-under-today ()
    (let ((task-file (make-temp-org-file-with-single-heading)))
      (add-entry-from task-file wl-with-today-and-existing-heading)
      (assert-wl-file-entry wl-with-today-and-existing-heading
                            task-file
                            current-time-prev
                            "Some Task")))
  
  (ert-deftest wl-add-entry-adds-new-today-entry-to-empty-file ()
    (let ((wl-empty (make-temp-org-file "wl-test-empty"))
          (task-file (make-temp-org-file-with-single-heading)))
      (add-entry-from task-file  wl-empty)
      (assert-wl-file-entry wl-empty task-file current-time "Some Task")))

  (ert-deftest wl-add-entry-adds-work-log-unter-task-with-no-worklog-yet ()
    (let* ((task-file (make-temp-org-file-with-single-heading))
           (wl-file (add-entry-from task-file)))
      (assert-wl-file-entry wl-file task-file current-time "Some Task")
      (assert-worklog-under-task task-file "Some Task" current-time 1)))

  (ert-deftest wl-add-entry-adds-work-log-unter-task-with-existing-worklog ()
    (setq task-file (make-temp-org-file "wl-test-task-file"))
    (with-temp-file task-file
      (insert "* Some Task\n")
      (insert "** Work Log\n")
      (insert "*** 2025-12-05 11:06\n"))

    (let ((wl-file (add-entry-from task-file)))
      (assert-wl-file-entry wl-file task-file current-time "Some Task")
      (assert-worklog-under-task task-file "Some Task" current-time 2)
      (assert-worklog-under-task task-file "Some Task" "2025-12-05 11:06" 2)))

  (ert-deftest wl-add-entry-adds-work-log-only-once-a-day ()
    (setq task-file (make-temp-org-file "wl-test-task-file"))
    (with-temp-file task-file
      (insert "* Some Task\n"))

    (let ((wl-file (add-two-entries-from task-file)))
      (assert-worklog-under-task task-file "Some Task" current-time 1)))

  (ert-deftest wl-add-entry-adds-link-to-task ()
    (let* ((task-file (make-temp-org-file-with-single-heading))
           (wl-file (add-entry-from task-file)))
      (assert-worklog-under-task task-file "Some Task" current-time 1)
      (assert-wl-file-entry wl-file task-file current-time "Some Task")))

  '(ert-deftest wl-add-entry-adds-worklog-before-other-subheadings ()
     (let* ((task-file "/tmp/wl-test-task-file.org")
            ( _ (with-temp-file task-file
                  (insert "* Some Task\n")
                  (insert "** Some subheading\n")))
            (wl-file (add-entry-from task-file))
            )
       (assert-worklog-under-task task-file "Some Task" current-time 2)))
  
  (ert t)
  (kill-test-buffers))
