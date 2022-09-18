(load "util")

(setq org-capture-templates `(
	("t" "Todo" entry (file+headline ,(org-file "inbox.org") "Inbox") "* TODO %?\n")
	("d" "Todo Today" entry (file+headline ,(org-file  "inbox.org") "Inbox") "* SCHD  %?\nSCHEDULED: %t")
	("c" "[ ] under clocked" checkitem (clock) "[ ]  %?\n")
	("o" "TODO under Clocked" entry (clock) "* TODO  %?\n")
	("n" "Notebook" entry (file+headline ,(org-file  "notebook.org") "Notebook") "* [%<%Y-%d-%m %H:%M:%S>] %? %i\n")
	("k" "Notebook (KB)" entry (file+headline ,(org-file  "notebook.org") "Notebook") "* [%<%Y-%d-%m %H:%M:%S>] %? :KB: %i\n")
	("j" "Notebook (Journal)" entry (file+headline ,(org-file  "notebook.org") "Notebook") "* [%<%Y-%d-%m %H:%M:%S>] %? :JOURNAL: %i\n")
	("s" "Todo (Shared)" entry (file+headline ,(org-shared-file "inbox_shared.org") "Inbox") "* TODO %?\n")
	("i" "Interruption" entry (file ,(org-file "interruptions.org")) "* %? %i\n" :clock-in :clock-resume)
))
