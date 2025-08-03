;; -*- lexical-binding: t; -*-

(defun make-new-day ()
  (interactive)
  (progn
    (org-back-to-heading)
    (beginning-of-line)
    (setq date (org-read-date))
    (org-insert-heading)
    (insert date)
    (setq marker (point-marker))
    (forward-line)
    (while (not (eq nil (refile-not-done-first-level-children marker date))))))

(defun refile-not-done-first-level-children (marker refile-target)
  (seq-filter
   (lambda (x) (not (eq nil x)))
   (org-map-entries
    (lambda ()
      (if (and (= 2 (org-current-level))
               (has-any-child-with-todo-state))
          (progn
            (org-refile nil nil (list refile-target (buffer-file-name) nil marker))
            t)
        nil))
    "TODO!=\"DONE\"" 'tree)))

(defun has-any-child-with-todo-state ()
  (let ((result
         (seq-filter
          (lambda (x) (eq 'todo x))
          (org-map-entries
           (lambda ()
             (org-element-property :todo-type (org-element-at-point)))
           t 'tree))))
    (not (seq-empty-p result))))

(provide 'new-day)
