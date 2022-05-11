(if (eq system-type 'darwin)
    (setq alert-user-configuration '((nil notifier nil)))
  (progn
    ;;(setq alert-growl-command "growlnotify.com")
    (setq alert-user-configuration '((nil growl nil)))
    )
 )
