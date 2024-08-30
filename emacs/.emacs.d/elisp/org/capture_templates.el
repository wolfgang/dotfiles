(load "util")

(setq org-capture-templates
      `(("t" "Todo" entry (file+headline ,(org-file "inbox.org") "Inbox") "* TODO %?\n")
	    ("l" "Log" entry (file+datetree ,(denote-file "20240824T163844--the-log__log.org")) "* %U %?  %i\n")
	    ("d" "Todo Today" entry (file+headline ,(org-file  "inbox.org") "Inbox") "* SCHD  %?\nSCHEDULED: %t")
	    ("c" "[ ] under clocked" checkitem (clock) "[ ]  %?\n")
	    ("o" "TODO under Clocked" entry (clock) "* TODO  %?\n")
	    ("s" "Todo (Shared)" entry (file+headline ,(org-shared-file "inbox_shared.org") "Inbox") "* TODO %?\n")))
