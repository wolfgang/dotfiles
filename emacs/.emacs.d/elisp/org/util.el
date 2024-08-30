(defun org-file (name)
  (concat org-directory "/" name))

(defun denote-file (name)
  (concat denote-directory "/" name))

(defun org-shared-file (name)
  (concat org-shared-directory "/" name))
