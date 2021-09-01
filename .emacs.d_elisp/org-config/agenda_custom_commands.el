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
  `(tags "TODO=\"SCHD\"&SCHEDULED>=\"<+0d>\"&SCHEDULED<\"<+1d>\""
	       ((org-agenda-overriding-header "Scheduled Today"))))

(setq skip-used-timeslots
     '(org-agenda-skip-function '(org-agenda-skip-entry-if 'todo '("USED"))))

(setq agenda-day-sort 
  '(org-agenda-sorting-strategy '(habit-down time-up priority-down todo-state-down)))

(setq next-actions `(tags-todo "TODO=\"NEXT\"" (
  (org-agenda-overriding-header "Next Actions" ))))

(setq week-agenda `(agenda "" (
  ,agenda-day-sort
  (org-agenda-span 'week)
  ,skip-used-timeslots)))

(setq someday `(tags "+TODO=\"MAYBE\"" (
  (org-agenda-overriding-header "Someday/Maybe") 
  (org-agenda-files '(,(org-file "someday.org"))))))

(setq inbox `(tags-todo "-HABIT+TODO=\"TODO\"" (
  (org-agenda-overriding-header "Inbox")
  (org-agenda-files '(,(org-file "inbox.org"))))))

(setq all-todos `(tags-todo "-HABIT+TODO=\"TODO\"" (
  (org-agenda-overriding-header "All Todos")
  (org-agenda-skip-function
    '(oh/agenda-skip :subtree-if '(inactive))
  )
                  
)))

(setq all-somedays `(tags "+TODO=\"MAYBE\"" (
  (org-agenda-overriding-header "All Someday/Maybe") 
)))



(setq active-projects `(tags-todo "+TODO=\"PROJ\"-INACTIVE" (
  (org-agenda-overriding-header  "Active Projects")
  (org-agenda-prefix-format " %i %-16:c%l"))))

(setq inactive-projects `(tags-todo "+TODO=\"PROJ\"+INACTIVE" (
  (org-agenda-overriding-header  "Inactive Projects"))))


(setq org-agenda-custom-commands `(
  ("t" "Tasks" (,next-actions
               ,(scheduled-today)
               ,inbox))

  ("d" "Today" ((agenda "" (,agenda-day-sort
                           (org-agenda-span 'day)
                           ,skip-used-timeslots))
               ,next-actions))

  ("w" "Week" (,week-agenda))

  ("p" "Projects" (
    ,active-projects 
    ,inactive-projects 
  ))

  ("i" "Inbox" (,inbox))

  ("y" "Someday/Maybe" (,someday))

  ; ("j" "Journal" tags-tree "JOURNAL")

  ("o" "Overview"  (
                   ,week-agenda
                   ,next-actions
                   ,active-projects
                   ,all-todos
                   ,(recently-completed 2 "Recently Completed")
                   ,all-somedays))
  ("e" "Completed" (,(recently-completed 365 "Completed Tasks")))

  ("k" "Knowledge Base" tags  "KB" ,(with-org-file "notebook.org"))

  ("b" "Notebook" tags  "NOTEBOOK" ,(with-org-file "notebook.org")))
)
