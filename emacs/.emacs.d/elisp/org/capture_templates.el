(load "util")

(setq org-capture-templates
      `(("t" "Todo" entry (file+headline ,(org-file "inbox.org") "Inbox") "* TODO %?\n")
	    ("l" "Personal Log" entry (file+datetree ,(denote-file "20240824T163844--personal-log__journal.org")) "* %U %?  %i\n")
        ("d" "Dev Log" entry (file+datetree ,(denote-file "20241208T184247--dev-log__dev.org")) "* %U %?  %i\n")
	    ("c" "[ ] under clocked" checkitem (clock) "[ ]  %?\n")
	    ("o" "TODO under Clocked" entry (clock) "* TODO  %?\n")
	    ("s" "Todo (Shared)" entry (file+headline ,(org-shared-file "inbox_shared.org") "Inbox") "* TODO %?\n")))
