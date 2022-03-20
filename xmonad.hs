import XMonad
import XMonad.Util.EZConfig
import XMonad.Util.Ungrab
import XMonad.Hooks.SetWMName
import XMonad.Hooks.StatusBar
import XMonad.Layout.NoBorders (noBorders, smartBorders)
import XMonad.Layout.TwoPane
import XMonad.Layout.Spacing


main :: IO ()
main = xmonad $ myConfig

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