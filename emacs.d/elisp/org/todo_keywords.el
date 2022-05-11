
(setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
        (sequence "PROJ(p)" "|")
        (sequence "MAYBE(m)" "|")
        (sequence "SCHD" "|")
        (sequence "WAIT" "|")
        )
      )


(setq org-todo-keyword-faces '(("TODO" :foreground "red" 
				                :weight bold) 
			                   ("NEXT" :foreground "#8f3f71" 
				                :weight bold) 
			                   ("FREE" :foreground "black" 
				                :weight bold) 
			                   ("USED" :foreground "grey" 
				                :weight bold) 
			                   ("DONE" :foreground "forest green" 
				                :weight bold) 
			                   ("MAYBE" :foreground "orange" 
				                :weight bold) 
			                   ("SCHD" :foreground "#a8a8a8" 
				                :weight bold)
                               ("WAIT" :foreground "#949494") 
                               ("PROJ" :background "blue"
                                :foreground "#bcbcbc"
				                :weight bold)))

(defadvice org-schedule (after org-schedule-change-state) 
  (if (org-get-scheduled-time (point)) 
      (org-todo "SCHD")))

(defadvice org-deadline (after org-deadline-change-state) 
  (if (org-get-deadline-time (point)) 
      (org-todo "SCHD")))

(defadvice org-todo (after org-todo-remove-times) 
  (if (and
       (not (string= (org-get-todo-state) "TODO"))
       (not (string= (org-get-todo-state) "DONE"))
       (not (string= (org-get-todo-state) "SCHD")))
      (progn 
	(org-schedule '(4)) 
	(org-deadline '(4)))))

(ad-activate 'org-schedule)
(ad-activate 'org-deadline)
(ad-activate 'org-todo)
