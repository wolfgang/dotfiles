(load "org-age-compare.el")
(load "util")

(defun age-sorted (Header Property &rest Direction)
  `(
    (org-agenda-overriding-header ,Header)
    (org-age-property ,Property) 
    (org-agenda-cmp-user-defined 'org-age-compare)
    (org-agenda-sorting-strategy ',Direction))
  )

(defun with-org-file (name)
  `((org-agenda-files '(,(org-file name)))))

(defun recently-completed (days header)
  (let ((match (format "TODO=\"DONE\"&CLOSED>=\"<-%dd>\"" days)))
	`(tags ,match ,(age-sorted header "CLOSED" 'user-defined-down))))

(defun scheduled-today ()
	`(tags "TODO=\"SCHD\"&SCHEDULED=\"<-0d>\""
	       ((org-agenda-overriding-header "Scheduled Today"))))

(setq agenda-day-sort '(org-agenda-sorting-strategy '(habit-down time-up priority-down todo-state-down)))

(setq next-actions `(tags-todo "TODO=\"NEXT\"" ((org-agenda-overriding-header "Next Actions" ))))
(setq scratch `(tags "+SCRATCH+LEVEL=1" ,(append '((org-agenda-overriding-header "Scratch")) (with-org-file "scratchpad.org"))))

(setq inbox-match  "+TODO=\"TODO\"-HABIT+INBOX")

(setq inbox
      `(tags-todo ,inbox-match
		  (
		   (org-agenda-overriding-header "Inbox")
		   (org-agenda-skip-function
		    '(oh/agenda-skip :headline-if '(subtask)
		   )
                    ))))

(setq groceries `(tags-todo "+GROCERIES/+TODO" ((org-agenda-overriding-header "Groceries"))))

(setq someday `(tags "+TODO=\"MAYBE\"" ((org-agenda-overriding-header "Someday/Maybe"))))

(setq available-tasks
      `(tags-todo "-INBOX-GROCERIES/!+TODO"
                     ((org-agenda-overriding-header "Available Tasks")
                      (org-agenda-skip-function
                       '(oh/agenda-skip :headline-if '(project)
                                        :subtree-if '(inactive habit scheduled deadline)
                                        :subtree-if-restricted-and '(single-task)))
                      (org-agenda-sorting-strategy '(category-keep)))))

(setq active-projects `(tags-todo "+TODO=\"PROJ\"-INACTIVE" ((org-agenda-overriding-header  "Active Projects"))))
(setq inactive-projects `(tags-todo "+TODO=\"PROJ\"+INACTIVE" ((org-agenda-overriding-header  "Inactive Projects"))))
                       

(setq skip-used-timeslots
     '(org-agenda-skip-function '(org-agenda-skip-entry-if 'todo '("USED"))))

(setq org-agenda-custom-commands `(
                                   ("t" "Tasks" (,next-actions
                                                 ,(scheduled-today)
                                                 ,available-tasks))
                                   ("d" "Today" ((agenda "" (,agenda-day-sort (org-agenda-span 'day) ,skip-used-timeslots))))

                                   ("p" "Projects" (,active-projects, inactive-projects))
				   ("i" "Inbox" (,inbox))
                                   ("y" "Someday/Maybe" (,someday))
                                   ("g" "Groceries" (,groceries))

                                   ("o" "Overview" ((agenda "" (,agenda-day-sort (org-agenda-span 'week) ,skip-used-timeslots))
                                                    ,next-actions
                                                    ,available-tasks
                                                    ,active-projects
						    ,inactive-projects                          
						    ,inbox
                                                    ,(recently-completed 2 "Recently Completed")
                                                    ,scratch
                                                    ,someday))
                                   
                                   ("e" "Completed" (,(recently-completed 365 "Completed Tasks")))
                                   ("k" "Knowledge Base" tags  "KB" ,(with-org-file "notebook.org"))
                                   ("b" "Notebook" tags  "NOTEBOOK" ,(with-org-file "notebook.org"))
                                   ))


      
