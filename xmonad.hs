import XMonad
import XMonad.Util.EZConfig
import XMonad.Util.Ungrab
import XMonad.Util.Loggers

import XMonad.Hooks.SetWMName
import XMonad.Hooks.StatusBar
import XMonad.Layout.NoBorders (noBorders, smartBorders)
import XMonad.Layout.TwoPane
import XMonad.Layout.Spacing


import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP

import XMonad.Hooks.EwmhDesktops



main :: IO ()
main = xmonad 
    . withEasySB (statusBarProp "xmobar" (pure myXmobarPP)) defToggleStrutsKey
    $ myConfig

myConfig = def
    { startupHook = setWMName "LG3D"}
    { modMask = mod4Mask
    , layoutHook = myLayoutHook 
    }
    `additionalKeysP`
    [ ("M-e" , spawn "emacs")
    , ("M-s" , spawn "slack")
    , ("M-b" , spawn "brave")
    , ("M-S-l", spawn "xscreensaver-command -lock")
    , ("M-S-d", sendMessage $ JumpToLayout "Tall")
    , ("M-S-f", sendMessage $ JumpToLayout "Full")
    , ("M-S-t", sendMessage $ JumpToLayout "TwoPane")
    ] 

myLayoutHook =
    smartBorders $ 
    tiled 
    ||| Mirror tiled 
    ||| noBorders Full
    ||| twoPane
    ||| Mirror twoPane
    
  where
    twoPane  = TwoPane delta smaster
    tiled    = Tall nmaster delta ratio
    smaster  = 50/100
    nmaster  = 1      -- Default number of windows in the master pane
    ratio    = 1/2    -- Default proportion of screen occupied by master pane
    delta    = 3/100  -- Percent of screen to increment by when resizing panes

myXmobarPP :: PP
myXmobarPP = def
    { ppSep             = magenta " • "
    , ppTitleSanitize   = xmobarStrip
    , ppCurrent         = wrap " " "" . xmobarBorder "Top" "#8be9fd" 2
    , ppHidden          = white . wrap " " ""
    , ppHiddenNoWindows = lowWhite . wrap " " ""
    , ppUrgent          = red . wrap (yellow "!") (yellow "!")
    , ppOrder           = \[ws, l, _, wins] -> [ws, l, wins]
    , ppExtras          = [logTitles formatFocused formatUnfocused]
    }
  where
    formatFocused   = wrap (white    "[") (white    "]") . magenta . ppWindow
    formatUnfocused = wrap (lowWhite "[") (lowWhite "]") . blue    . ppWindow

    -- | Windows should have *some* title, which should not not exceed a
    -- sane length.
    ppWindow :: String -> String
    ppWindow = xmobarRaw . (\w -> if null w then "untitled" else w) . shorten 30

    blue, lowWhite, magenta, red, white, yellow :: String -> String
    magenta  = xmobarColor "#ff79c6" ""
    blue     = xmobarColor "#bd93f9" ""
    white    = xmobarColor "#f8f8f2" ""
    yellow   = xmobarColor "#f1fa8c" ""
    red      = xmobarColor "#ff5555" ""
    lowWhite = xmobarColor "#bbbbbb" ""