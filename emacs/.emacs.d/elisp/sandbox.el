(setq lnk '("id:425002e7-6306-465e-b28c-c882d11766d5" #("Research emacs fu" 1 2 3 )))

(setq foo #("Research emacs fu" 1 2 3))

(aref foo 1)

(setq id-part (car lnk))
(setq title-part (car (cdr lnk)))

(insert (format "[[%s][%s]]" id-part title-part))

(aref #("foo" 1 2) 0)
