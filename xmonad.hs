import XMonad
import XMonad.Util.EZConfig
import XMonad.Util.Ungrab
import XMonad.Hooks.SetWMName
import XMonad.Hooks.StatusBar



main :: IO ()
main = xmonad $ def
       	{ startupHook = setWMName "LG3D"}
	{ modMask = mod4Mask 
	}
	`additionalKeysP`
	[ ("M-e" , spawn "emacs")
	,  ("M-s" , spawn "slack")
	, ("M-b" , spawn "brave")
	, ("M-S-l", spawn "xscreensaver-command -lock")
	]
