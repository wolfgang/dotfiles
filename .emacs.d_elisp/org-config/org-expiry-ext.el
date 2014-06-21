;;
;; Allow automatically handing of created/expired meta data.
;;
(require 'org-expiry)
;; Configure it a bit to my liking
(setq org-expiry-created-property-name "CREATED" ; Name of property when an item is created
      org-expiry-inactive-timestamps   t ; Don't have everything in the agenda view
      )

(defun mrb/insert-created-timestamp(&optional offset) 
  (when (eq (org-expiry-insert-created) 1) 
    (org-back-to-heading) 
    (org-end-of-line) 
    (when offset (insert " "))))


(defun mrb/should-insert-timestamp()
    (<= (car (org-heading-components))
	org-created-timestamp-max-level))

(defun mrb/insert-created-timestamp-ext(&optional offset)
    (when (mrb/should-insert-timestamp)
      (mrb/insert-created-timestamp offset)))

(defadvice org-insert-todo-heading (after mrb/created-timestamp-advice activate) 
  "Insert a CREATED property using org-expiry.el for TODO entries"
  (mrb/insert-created-timestamp-ext))

(ad-activate 'org-insert-todo-heading)

(defadvice org-insert-heading (after mrb/created-timestamp-advice activate) 
  (if (eq org-created-timestamp-for-headings t)
      (mrb/insert-created-timestamp-ext)))

(ad-activate 'org-insert-heading)

(require 'org-capture)

(defadvice org-capture (after mrb/created-timestamp-advice activate) 
  (mrb/insert-created-timestamp-ext))

(ad-activate 'org-capture)

;; Add feature to allow easy adding of tags in a capture window
(defun mrb/add-tags-in-capture() 
  (interactive)
  "Insert tags in a capture window without losing the point" 
  (save-excursion 
    (org-back-to-heading) 
    (org-set-tags)))
;; Bind this to a reasonable key
(define-key org-capture-mode-map "\C-c\C-t" 'mrb/add-tags-in-capture)
