;;; org-drill.el --- Self-testing using spaced repetition -*- lexical-binding: t -*-

;;; Header:

;; Maintainer: Phillip Lord <phillip.lord@russet.org.uk>
;; Author: Paul Sexton <eeeickythump@gmail.com>
;; Package-Version: 2.7.0
;; Package-Revision: 4c114489e682
;; Package-Requires: ((emacs "25.3") (seq "2.14") (org "9.2.4") (persist "0.3"))
;; Keywords: games, outlines, multimedia

;; URL: https://gitlab.com/phillord/org-drill/issues
;;
;; This file is not part of GNU Emacs.
;;
;; Copyright (C) 2018-2019 Phillip Lord
;; Copyright (C) 2010-2015 Paul Sexton
;;
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;

;;; Commentary:
;;
;; Within an Org mode outline or outlines, headings and associated content are
;; treated as "flashcards".  Spaced repetition algorithms are used to conduct
;; interactive "drill sessions", where a selection of these flashcards is
;; presented to the student in random order.  The student rates his or her
;; recall of each item, and this information is used to schedule the item for
;; later revision.
;;
;; Each drill session can be restricted to topics in the current buffer
;; (default), one or several files, all agenda files, or a subtree.  A single
;; topic can also be tested.
;;
;; Different "card types" can be defined, which present their information to
;; the student in different ways.
;;
;; See the file README.org for more detailed documentation.

;;; Code:

(require 'cl-lib)
(require 'eieio)
(require 'org)
(require 'org-agenda)
(require 'org-id)
(require 'persist)
(require 'seq)

(defgroup org-drill nil
  "Options concerning interactive drill sessions in Org mode (org-drill)."
  :tag "Org-Drill"
  :group 'org-link)

(defcustom org-drill-question-tag
  "drill"
  "Tag for topics which are review topics."
  :group 'org-drill
  :type 'string)

(defcustom org-drill-maximum-items-per-session
  30
  "Each drill session will present at most this many topics for review.
Nil means unlimited."
  :group 'org-drill
  :type '(choice integer (const nil)))

(defcustom org-drill-maximum-duration
  20
  "Maximum duration of a drill session, in minutes.
Nil means unlimited."
  :group 'org-drill
  :type '(choice integer (const nil)))

(defcustom org-drill-item-count-includes-failed-items-p
  nil
  "If non-nil, count failed items in overall count.

If nil (default), only successful items count towards this
total."
  :group 'org-drill
  :type 'boolean)

(defcustom org-drill-failure-quality
  2
  "Lower bound for an recall to be marked as failure.

If the quality of recall for an item is this number or lower,
it is regarded as an unambiguous failure, and the repetition
interval for the card is reset to 0 days.  If the quality is higher
than this number, it is regarded as successfully recalled, but the
time interval to the next repetition will be lowered if the quality
was near to a fail.

By default this is 2, for SuperMemo-like behaviour.  For
Mnemosyne-like behaviour, set it to 1.  Other values are not
really sensible."
  :group 'org-drill
  :type '(choice (const 2) (const 1)))

(defcustom org-drill-forgetting-index
  10
  "The maximum percentage of items that can be forgotten before a warning.

What percentage of items do you consider it is 'acceptable' to
forget each drill session? The default is 10%.  A warning message
is displayed at the end of the session if the percentage forgotten
climbs above this number."
  :group 'org-drill
  :type 'integer)

(defcustom org-drill-leech-failure-threshold
  15
  "Threshold before a item is defined as a leech.

If an item is forgotten more than this many times, it is tagged
as a 'leech' item."
  :group 'org-drill
  :type '(choice integer (const nil)))

(defcustom org-drill-leech-method
  'skip
  "How should 'leech items' be handled during drill sessions?
Possible values:
- nil :: Leech items are treated the same as normal items.
- skip :: Leech items are not included in drill sessions.
- warn :: Leech items are still included in drill sessions,
  but a warning message is printed when each leech item is
  presented."
  :group 'org-drill
  :type '(choice (const warn) (const skip) (const nil)))

(defface org-drill-visible-cloze-face
  '((t (:foreground "darkseagreen")))
  "The face used to hide the contents of cloze phrases."
  :group 'org-drill)

(defface org-drill-visible-cloze-hint-face
  '((t (:foreground "dark slate blue")))
  "The face used to hide the contents of cloze phrases."
  :group 'org-drill)

(defface org-drill-hidden-cloze-face
  '((t (:foreground "deep sky blue" :background "blue")))
  "The face used to hide the contents of cloze phrases."
  :group 'org-drill)

(defcustom org-drill-use-visible-cloze-face-p
  nil
  "Highlight cloze-deleted text."
  :group 'org-drill
  :type 'boolean)

(defcustom org-drill-hide-item-headings-p
  nil
  "If non-nil, conceal headings during a drill session.

You may want to enable this behaviour if item headings or tags
contain information that could 'give away' the answer."
  :group 'org-drill
  :type 'boolean)

(defcustom org-drill-new-count-color
  "royal blue"
  "Foreground colour for remaining new items."
  :group 'org-drill
  :type 'color)

(defcustom org-drill-mature-count-color
  "green"
  "Foreground colour for remaining mature items.

Mature items are due for review, but are not new."
  :group 'org-drill
  :type 'color)

(defcustom org-drill-failed-count-color
  "red"
  "Foreground colour for remaining failed items."
  :group 'org-drill
  :type 'color)

(defcustom org-drill-done-count-color
  "sienna"
  "Foreground colour for reviewed items."
  :group 'org-drill
  :type 'color)

(defcustom org-drill-left-cloze-delimiter
  "["
  "String used within org buffers to delimit cloze deletions."
  :group 'org-drill
  :type 'string)

(defcustom org-drill-right-cloze-delimiter
  "]"
  "String used within org buffers to delimit cloze deletions."
  :group 'org-drill
  :type 'string)

(setplist 'org-drill-cloze-overlay-defaults
          `(display ,(format "%s...%s"
                             org-drill-left-cloze-delimiter
                             org-drill-right-cloze-delimiter)
                    face org-drill-hidden-cloze-face
                    window t))

(setplist 'org-drill-hidden-text-overlay
          '(invisible t))

(setplist 'org-drill-replaced-text-overlay
          '(display "Replaced text"
                    face default
                    window t))

(add-hook 'org-font-lock-set-keywords-hook 'org-drill-add-cloze-fontification)

(defvar org-drill-hint-separator "||"
  "Delimiter in cloze expression for hints.")

(defun org-drill--compute-cloze-regexp ()
  "Return a regexp that detects clozes."
  (concat "\\("
          (regexp-quote org-drill-left-cloze-delimiter)
          "[[:cntrl:][:graph:][:space:]]+?\\)\\(\\|"
          (regexp-quote org-drill-hint-separator)
          ".+?\\)\\("
          (regexp-quote org-drill-right-cloze-delimiter)
          "\\)"))

(defun org-drill--compute-cloze-keywords ()
  "Return a fontification spec that detects cloze keywords."
  (list (list (org-drill--compute-cloze-regexp)
              (cl-copy-list '(1 'org-drill-visible-cloze-face nil))
              (cl-copy-list '(2 'org-drill-visible-cloze-hint-face t))
              (cl-copy-list '(3 'org-drill-visible-cloze-face nil)))))

(defvar-local org-drill-cloze-regexp
  (org-drill--compute-cloze-regexp)
  "Regexp that detects cloze.

This is buffer-local variable.")

(defvar-local org-drill-cloze-keywords
  (org-drill--compute-cloze-keywords)
  "Fontification form for cloze.

This is a buffer-local variable.")

;; Variables defining what keys can be pressed during drill sessions to quit the
;; session, edit the item, etc.
(defvar org-drill--quit-key ?q
  "Character to quit the session.")
(defvar org-drill--edit-key ?e
  "Character to suspend the session.")
(defvar org-drill--help-key ??
  "Character to show help.")
(defvar org-drill--skip-key ?s
  "Character to skip to the next item.")
(defvar org-drill--tags-key ?t
  "Character to edit the tags.")

(defcustom org-drill-card-type-alist
  '((nil org-drill-present-simple-card)
    ("simple" org-drill-present-simple-card)
    ("simpletyped" org-drill-present-simple-card-with-typed-answer)
    ("twosided" org-drill-present-two-sided-card nil t)
    ("multisided" org-drill-present-multi-sided-card nil t)
    ("hide1cloze" org-drill-present-multicloze-hide1)
    ("hide2cloze" org-drill-present-multicloze-hide2)
    ("show1cloze" org-drill-present-multicloze-show1)
    ("show2cloze" org-drill-present-multicloze-show2)
    ("multicloze" org-drill-present-multicloze-hide1)
    ("hidefirst" org-drill-present-multicloze-hide-first)
    ("hidelast" org-drill-present-multicloze-hide-last)
    ("hide1_firstmore" org-drill-present-multicloze-hide1-firstmore)
    ("show1_lastmore" org-drill-present-multicloze-show1-lastmore)
    ("show1_firstless" org-drill-present-multicloze-show1-firstless)
    ("conjugate"
     org-drill-present-verb-conjugation
     org-drill-show-answer-verb-conjugation)
    ("decline_noun"
     org-drill-present-noun-declension
     org-drill-show-answer-noun-declension)
    ("spanish_verb" org-drill-present-spanish-verb)
    ("translate_number" org-drill-present-translate-number))
  "Alist associating card types with presentation functions.

Each entry in the alist takes the form:

;;; (CARDTYPE QUESTION-FN [ANSWER-FN DRILL-EMPTY-P])

Where CARDTYPE is a string or nil (for default), and QUESTION-FN
is a function which takes no arguments and returns a boolean
value.

When supplied, ANSWER-FN is a function that takes one argument --
that argument is a function of no arguments, which when called,
prompts the user to rate their recall and performs rescheduling
of the drill item.  ANSWER-FN is called with the point on the
active item's heading, just prior to displaying the item's
'answer'.  It can therefore be used to modify the appearance of
the answer.  ANSWER-FN must call its argument before returning.

When supplied, DRILL-EMPTY-P is a boolean value, default nil.
When non-nil, cards of this type will be presented during tests
even if their bodies are empty."
  :group 'org-drill
  :type '(alist :key-type (choice string (const nil))
                :value-type function))

(defcustom org-drill-card-tags-alist
  '(("explain" nil org-drill-explain-answer-presenter
     org-drill-explain-cleaner))
  "Alist associating tags with presentation functions.

The alist is of the form (TAG QUESTION-PRESENTER ANSWER-PRESENTER CLEANER).

When a card with the relevant TAG is tested, QUESTION-PRESENTER
will be called when the card is displayed to the user,
ANSWER-PRESENTER will be called with point in the entry when the
answer is displayed to the user and CLEANER will be called when
the answer is accepted.  In all cases, point will be in the card
in question when the function is called.  All values may be nil in
which case no function will be called."
  :group 'org-drill
  :type '(alist :key-type (choice string (const nil))
                :value-type function))

(defcustom org-drill-scope
  'file
  "The scope to search for drill items in a session.

This can be any of:

file                 The current buffer, respecting the restriction if any.
                     This is the default.
tree                 The subtree started with the entry at point
file-no-restriction  The current buffer, without restriction
file-with-archives   The current buffer, and any archives associated with it.
agenda               All agenda files
agenda-with-archives All agenda files with any archive files associated
                     with them.
directory            All files with the extension '.org' in the same
                     directory as the current file (includes the current
                     file if it is an .org file.)
 (FILE1 FILE2 ...)   If this is a list, all files in the list will be scanned."
  ;; Note -- meanings differ slightly from the argument to org-map-entries:
  ;; 'file' means current file/buffer, respecting any restriction
  ;; 'file-no-restriction' means current file/buffer, ignoring restrictions
  ;; 'directory' means all *.org files in current directory
  :group 'org-drill
  :type '(choice (const :tag "The current buffer, respecting the restriction if any." file)
                 (const :tag "The subtree started with the entry at point" tree)
                 (const :tag "The current buffer, without restriction" file-no-restriction)
                 (const :tag "The current buffer, and any archives associated with it." file-with-archives)
                 (const :tag "All agenda files" agenda)
                 (const :tag "All agenda files with any archive files associated with them." agenda-with-archives)
                 (const :tag "All files with the extension '.org' in the same directory as the current file (includes the current file if it is an .org file.)"  directory)
                 (repeat :tag "List of files to scan for drill items." file)))

(defcustom org-drill-match
  nil
  "If non-nil, a string specifying a tags/property/TODO query.

During drill sessions, only items that match this query will be
considered."
  :group 'org-drill
  :type '(choice (const nil) string))

(defcustom org-drill-save-buffers-after-drill-sessions-p
  t
  "If non-nil, prompt to save all modified buffers when a session ends."
  :group 'org-drill
  :type 'boolean)

(defcustom org-drill-spaced-repetition-algorithm
  'sm5
  "Which SuperMemo spaced repetition algorithm to use for scheduling items.
Available choices are:
- SM2 :: the SM2 algorithm, used in SuperMemo 2.0
- SM5 :: the SM5 algorithm, used in SuperMemo 5.0
- Simple8 :: a modified version of the SM8 algorithm.  SM8 is used in
  SuperMemo 98. The version implemented here is simplified in that while it
  'learns' the difficulty of each item using quality grades and number of
  failures, it does not modify the matrix of values that
  governs how fast the inter-repetition intervals increase.  A method for
  adjusting intervals when items are reviewed early or late has been taken
  from SM11, a later version of the algorithm, and included in Simple8."
  :group 'org-drill
  :type '(choice (const sm2) (const sm5) (const simple8)))

(persist-defvar org-drill-sm5-optimal-factor-matrix
  nil
  "DO NOT CHANGE THE VALUE OF THIS VARIABLE.

Persistent matrix of optimal factors, used by the SuperMemo SM5
algorithm. The matrix is saved at the end of each drill session.

Over time, values in the matrix will adapt to the individual user's
pace of learning.")

(defcustom org-drill-sm5-initial-interval
  4.0
  "In the SM5 algorithm, the initial interval after the first
successful presentation of an item is always 4 days. If you wish to change
this, you can do so here."
  :group 'org-drill
  :type 'float)

(defcustom org-drill-add-random-noise-to-intervals-p
  nil
  "If true, the number of days until an item's next repetition
will vary slightly from the interval calculated by the SM2
algorithm. The variation is very small when the interval is
small, but scales up with the interval."
  :group 'org-drill
  :type 'boolean)

(defcustom org-drill-adjust-intervals-for-early-and-late-repetitions-p
  nil
  "If true, when the student successfully reviews an item 1 or more days
before or after the scheduled review date, this will affect that date of
the item's next scheduled review, according to the algorithm presented at
 [[http://www.supermemo.com/english/algsm11.htm#Advanced%20repetitions]].

Items that were reviewed early will have their next review date brought
forward. Those that were reviewed late will have their next review
date postponed further.

Note that this option currently has no effect if the SM2 algorithm
is used."
  :group 'org-drill
  :type 'boolean)

(defcustom org-drill-cloze-text-weight
  4
  "For card types 'hide1_firstmore', 'show1_lastmore' and 'show1_firstless',
this number determines how often the 'less favoured' situation
should arise. It will occur 1 in every N trials, where N is the
value of the variable.

For example, with the hide1_firstmore card type, the first piece
of clozed text should be hidden more often than the other
pieces. If this variable is set to 4 (default), the first item
will only be shown 25% of the time (1 in 4 trials). Similarly for
show1_lastmore, the last item will be shown 75% of the time, and
for show1_firstless, the first item would only be shown 25% of the
time.

If the value of this variable is NIL, then weighting is disabled, and
all weighted card types are treated as their unweighted equivalents."
  :group 'org-drill
  :type '(choice integer (const nil)))

(defcustom org-drill-cram-hours
  12
  "When in cram mode, items are considered due for review if
they were reviewed at least this many hours ago."
  :group 'org-drill
  :type 'integer)

;;; NEW items have never been presented in a drill session before.
;;; MATURE items HAVE been presented at least once before.
;;; - YOUNG mature items were scheduled no more than
;;;   ORG-DRILL-DAYS-BEFORE-OLD days after their last
;;;   repetition. These items will have been learned 'recently' and will have a
;;;   low repetition count.
;;; - OLD mature items have intervals greater than
;;;   ORG-DRILL-DAYS-BEFORE-OLD.
;;; - OVERDUE items are past their scheduled review date by more than
;;;   LAST-INTERVAL * (ORG-DRILL-OVERDUE-INTERVAL-FACTOR - 1) days,
;;;   regardless of young/old status.

(defcustom org-drill-days-before-old
  10
  "When an item's inter-repetition interval rises above this value in days,
it is no longer considered a 'young' (recently learned) item."
  :group 'org-drill
  :type 'integer)

(defcustom org-drill-overdue-interval-factor
  1.2
  "An item is considered overdue if its scheduled review date is
more than (ORG-DRILL-OVERDUE-INTERVAL-FACTOR - 1) * LAST-INTERVAL
days in the past. For example, a value of 1.2 means an additional
20% of the last scheduled interval is allowed to elapse before
the item is overdue. A value of 1.0 means no extra time is
allowed at all - items are immediately considered overdue if
there is even one day's delay in reviewing them. This variable
should never be less than 1.0."
  :group 'org-drill
  :type 'float)

(defcustom org-drill-learn-fraction
  0.5
  "Fraction between 0 and 1 that governs how quickly the spaces
between successive repetitions increase, for all items. The
default value is 0.5. Higher values make spaces increase more
quickly with each successful repetition. You should only change
this in small increments (for example 0.05-0.1) as it has an
exponential effect on inter-repetition spacing."
  :group 'org-drill
  :type 'float)

(defcustom org-drill-presentation-prompt-with-typing nil
  "Non-nil indicates that answers should be given in a buffer."
  :group 'org-drill
  :type 'boolean)

(defcustom org-drill-cloze-length-matches-hidden-text-p
  nil
  "If non-nil, when concealing cloze deletions, force the length of
the ellipsis to match the length of the missing text. This may be useful
to preserve the formatting in a displayed table, for example."
  :group 'org-drill
  :type 'boolean)

(defvar org-drill-display-answer-hook nil
  "Hook called when `org-drill' answers are displayed.")

(defclass org-drill-session ()
  ((qualities :initform nil)
   (start-time
    :initform 0.0
    :documentation "Time at which the session started"
    :type float)
   (new-entries :initform nil)
   (dormant-entry-count :initform 0)
   (due-entry-count :initform 0)
   (overdue-entry-count :initform 0)
   (due-tomorrow-count :initform 0)
   (overdue-entries
    :initform nil
    :documentation
    "List of markers for items that are
considered 'overdue', based on the value of
ORG-DRILL-OVERDUE-INTERVAL-FACTOR.")
   (young-mature-entries
    :initform nil
    :documentation "List of markers for mature entries whose last inter-repetition
interval was <= ORG-DRILL-DAYS-BEFORE-OLD days.")
   (old-mature-entries
    :initform nil
    :documentation "List of markers for mature entries whose last inter-repetition
interval was greater than ORG-DRILL-DAYS-BEFORE-OLD days.")
   (failed-entries :initform nil)
   (again-entries :initform nil)
   (done-entries :initform nil)
   (current-item
    :initform nil
    :documentation "Set to the marker for the item currently being tested.")
   (cram-mode
    :initform nil
    :documementation "Are we in 'cram mode', where all items are considered due
for review unless they were already reviewed in the recent past?")
   (warned-about-id-creation
    :initform nil
    :documentation "Have we warned the user about ID creation this session?")
   (overdue-data :initform nil)
   (cnt :initform 0)
   (exit-kind
    :initform nil
    :documentation "Return value from typed answers which use recursive edit.")
   (typed-answer
    :initform nil
    :documentation "The last answer typed by the user.")
   (drill-answer
    :initform nil
    :documentation "The correct answer when an item is being
presented. If this variable is non-nil, the default presentation
function will show its value instead of the default behaviour of
revealing the contents of the drilled item.

This variable is useful for card types that compute their answers
-- for example, a card type that asks the student to translate a
random number to another language.")
   (end-pos :initform nil))
  :documentation "An org-drill session object carries data about
  the current state of a particular org-drill session." )

(defvar org-drill-current-session nil
  "If non-nil, the current session.

The current session is an `org-drill-session' object.")

(defvar org-drill-last-session nil
  "If non-nil, the last session.

This can be used to resume the last session.")

(defvar org-drill-cards-in-this-emacs 0
  "The total number of cards displayed in this Emacs invocation.

This variable is not functionally important, but is used for
  debugging.")

(defvar org-drill-scheduling-properties
  '("LEARN_DATA" "DRILL_LAST_INTERVAL" "DRILL_REPEATS_SINCE_FAIL"
    "DRILL_TOTAL_REPEATS" "DRILL_FAILURE_COUNT" "DRILL_AVERAGE_QUALITY"
    "DRILL_EASE" "DRILL_LAST_QUALITY" "DRILL_LAST_REVIEWED"))

(defvar org-drill--lapse-very-overdue-entries-p nil
  "If non-nil, entries more than 90 days overdue are regarded as 'lapsed'.
This means that when the item is eventually re-tested it will be
treated as 'failed' (quality 2) for rescheduling purposes,
regardless of whether the test was successful.")


;;; Make the above settings safe as file-local variables.
(put 'org-drill-question-tag 'safe-local-variable 'stringp)
(put 'org-drill-maximum-items-per-session 'safe-local-variable
     '(lambda (val) (or (integerp val) (null val))))
(put 'org-drill-maximum-duration 'safe-local-variable
     '(lambda (val) (or (integerp val) (null val))))
(put 'org-drill-failure-quality 'safe-local-variable 'integerp)
(put 'org-drill-forgetting-index 'safe-local-variable 'integerp)
(put 'org-drill-leech-failure-threshold 'safe-local-variable 'integerp)
(put 'org-drill-leech-method 'safe-local-variable
     '(lambda (val) (memq val '(nil skip warn))))
(put 'org-drill-use-visible-cloze-face-p 'safe-local-variable 'booleanp)
(put 'org-drill-hide-item-headings-p 'safe-local-variable 'booleanp)
(put 'org-drill-spaced-repetition-algorithm 'safe-local-variable
     '(lambda (val) (memq val '(simple8 sm5 sm2))))
(put 'org-drill-sm5-initial-interval 'safe-local-variable 'floatp)
(put 'org-drill-add-random-noise-to-intervals-p 'safe-local-variable 'booleanp)
(put 'org-drill-adjust-intervals-for-early-and-late-repetitions-p
     'safe-local-variable 'booleanp)
(put 'org-drill-cram-hours 'safe-local-variable 'integerp)
(put 'org-drill-learn-fraction 'safe-local-variable 'floatp)
(put 'org-drill-days-before-old 'safe-local-variable 'integerp)
(put 'org-drill-overdue-interval-factor 'safe-local-variable 'floatp)
(put 'org-drill-scope 'safe-local-variable
     '(lambda (val) (or (symbolp val) (listp val))))
(put 'org-drill-match 'safe-local-variable
     '(lambda (val) (or (stringp val) (null val))))
(put 'org-drill-save-buffers-after-drill-sessions-p 'safe-local-variable 'booleanp)
(put 'org-drill-cloze-text-weight 'safe-local-variable
     '(lambda (val) (or (null val) (integerp val))))
(put 'org-drill-left-cloze-delimiter 'safe-local-variable 'stringp)
(put 'org-drill-right-cloze-delimiter 'safe-local-variable 'stringp)

;;; Org compatability hacks
(when (version< org-version "9.2")
  (advice-add 'org-get-tags :around #'org-drill-get-tags-advice))

(defun org-drill-get-tags-advice (orig-fun &rest args)
  ;; the two arg call obsoletes get-local-tags
  (if (= 2 (length args))
      ;; and we don't want any byte compile errors
      (if (fboundp 'org-get-local-tags) (org-get-local-tags))
    ;; the non-arg version doesn't return inherited tags, but
    ;; get-tags-at does.
    (org-get-tags-at)))

(when (= 8 (car (version-to-list org-version)))
  ;; Shut up package-lint
  (defalias 'org-drill-defun 'defun)
  (org-drill-defun org-toggle-latex-fragment (&rest args)
    (apply 'org-preview-latex-fragment args)))

;;;; Utilities ================================================================
(defmacro org-drill-pop-random (place)
  "Remove an item randomly from PLACE."
  (let ((idx (cl-gensym)))
    `(if (null ,place)
         nil
       (let ((,idx (cl-random (length ,place))))
         (prog1 (nth ,idx ,place)
           (setf ,place (append (cl-subseq ,place 0 ,idx)
                                (cl-subseq ,place (1+ ,idx)))))))))

(defmacro org-drill-push-end (val place)
  "Add VAL to the end of the sequence stored in PLACE. Return the new
value."
  `(setf ,place (append ,place (list ,val))))

(defun org-drill-round-float (floatnum fix)
  "Round the floating point number FLOATNUM to FIX decimal places.
Example: (round-float 3.56755765 3) -> 3.568"
  (let ((n (expt 10 fix)))
    (/ (float (round (* floatnum n))) n)))

(defun org-drill-command-keybinding-to-string (cmd)
  "Return a human-readable description of the key/keys to which the command
CMD is bound, or nil if it is not bound to a key."
  (let ((key (where-is-internal cmd overriding-local-map t)))
    (if key (key-description key))))

(defun org-drill-time-to-inactive-org-timestamp (time)
  "Convert TIME into org-mode timestamp."
  (format-time-string
   (concat "[" (substring (cdr org-time-stamp-formats) 1 -1) "]")
   time))

(defun org-drill-map-entries (func &optional scope drill-match &rest skip)
  "Like `org-map-entries', but only drill entries are processed."
  (let ((org-drill-match (or drill-match org-drill-match)))
    (apply 'org-map-entries func
           (concat "+" org-drill-question-tag
                   (if (and (stringp org-drill-match)
                            (not (member (elt org-drill-match 0) '(?+ ?- ?|))))
                       "+" "")
                   (or org-drill-match ""))
           (org-drill-current-scope scope)
           skip)))

(defun org-drill-current-scope (scope)
  "Translate SCOPE into an scope suitable for `org-map-entries'.

If scope is NIL, then use `org-drill-scope'.

Returns scope as defined by `org-map-entries'"
  (let ((scope (or scope org-drill-scope)))
    (cl-case scope
      (file nil)
      (file-no-restriction 'file)
      (directory
       (directory-files
        (file-name-directory (buffer-file-name))
        t "^[^.].*\\.org$"))
      (t scope))))

(defmacro org-drill-with-hidden-cloze-text (&rest body)
  "Eval BODY with clozed text hidden."
  (declare (debug t))
  `(progn
     (org-drill-hide-clozed-text)
     (unwind-protect
         (progn
           ,@body)
       (org-drill-unhide-clozed-text))))

(defmacro org-drill-with-hidden-cloze-hints (&rest body)
  "Eval BODY with cloze hints hidden."
  (declare (debug t))
  `(progn
     (org-drill-hide-cloze-hints)
     (unwind-protect
         (progn
           ,@body)
       (org-drill-unhide-text))))

(defmacro org-drill-with-hidden-comments (&rest body)
  "Eval BODY with comments hidden."
  (declare (debug t))
  `(progn
     (if org-drill-hide-item-headings-p
         (org-drill-hide-heading-at-point))
     (org-drill-hide-comments)
     (unwind-protect
         (progn
           ,@body)
       (org-drill-unhide-text))))

(defun org-drill-days-since-last-review ()
  "Nil means a last review date has not yet been stored for
the item.
Zero means it was reviewed today.
A positive number means it was reviewed that many days ago.
A negative number means the date of last review is in the future --
this should never happen."
  (let ((datestr (org-entry-get (point) "DRILL_LAST_REVIEWED")))
    (when datestr
      (- (time-to-days (current-time))
         (time-to-days (apply 'encode-time
                              (org-parse-time-string datestr)))))))

(defun org-drill-hours-since-last-review ()
  "Like `org-drill-days-since-last-review', but return value is
in hours rather than days."
  (let ((datestr (org-entry-get (point) "DRILL_LAST_REVIEWED")))
    (when datestr
      (floor
       (/ (- (time-to-seconds (current-time))
             (time-to-seconds (apply 'encode-time
                                     (org-parse-time-string datestr))))
          (* 60 60))))))

(defun org-drill-entry-p (&optional marker)
  "Is MARKER, or the point, in a 'drill item'? This will return nil if
the point is inside a subheading of a drill item -- to handle that
situation use `org-part-of-drill-entry-p'."
  (save-excursion
    (when marker
      (org-drill-goto-entry marker))
    (member org-drill-question-tag (org-get-tags nil t))))

(defun org-drill-goto-entry (marker)
  "Switch to the buffer and position of MARKER."
  (switch-to-buffer (marker-buffer marker))
  (goto-char marker))

(defun org-drill-part-of-drill-entry-p ()
  "Is the current entry either the main heading of a 'drill item',
or a subheading within a drill item?"
  (or (org-drill-entry-p)
      ;; Does this heading INHERIT the drill tag
      (member org-drill-question-tag (org-get-tags))))

(defun org-drill-goto-drill-entry-heading ()
  "Move the point to the heading which holds the :drill: tag for this
drill entry."
  (unless (org-at-heading-p)
    (org-back-to-heading))
  (unless (org-drill-part-of-drill-entry-p)
    (error "Point is not inside a drill entry"))
  (while (not (org-drill-entry-p))
    (unless (org-up-heading-safe)
      (error "Cannot find a parent heading that is marked as a drill entry"))))

(defun org-drill-entry-leech-p ()
  "Is the current entry a 'leech item'?"
  (and (org-drill-entry-p)
       (member "leech" (org-get-tags nil t))))

;; (defun org-drill-entry-due-p ()
;;   (cond
;;    (*org-drill-cram-mode*
;;     (let ((hours (org-drill-hours-since-last-review)))
;;       (and (org-drill-entry-p)
;;            (or (null hours)
;;                (>= hours org-drill-cram-hours)))))
;;    (t
;;     (let ((item-time (org-get-scheduled-time (point))))
;;       (and (org-drill-entry-p)
;;            (or (not (eql 'skip org-drill-leech-method))
;;                (not (org-drill-entry-leech-p)))
;;            (or (null item-time)         ; not scheduled
;;                (not (cl-minusp             ; scheduled for today/in past
;;                      (- (time-to-days (current-time))
;;                         (time-to-days item-time))))))))))

(defun org-drill-entry-days-overdue (session)
  "Returns:
- NIL if the item is not to be regarded as scheduled for review at all.
  This is the case if it is not a drill item, or if it is a leech item
  that we wish to skip, or if we are in cram mode and have already reviewed
  the item within the last few hours.
- 0 if the item is new, or if it scheduled for review today.
- A negative integer - item is scheduled that many days in the future.
- A positive integer - item is scheduled that many days in the past."
  (cond
   ((oref session cram-mode)
    (let ((hours (org-drill-hours-since-last-review)))
      (and (org-drill-entry-p)
           (or (null hours)
               (>= hours org-drill-cram-hours))
           0)))
   (t
    (let ((item-time (org-get-scheduled-time (point))))
      (cond
       ((or (not (org-drill-entry-p))
            (and (eql 'skip org-drill-leech-method)
                 (org-drill-entry-leech-p)))
        nil)
       ((null item-time)                ; not scheduled -> due now
        0)
       (t
        (- (time-to-days (current-time))
           (time-to-days item-time))))))))

(defun org-drill-entry-overdue-p (session &optional days-overdue last-interval)
  "Returns true if entry that is scheduled DAYS-OVERDUE dasy in the past,
and whose last inter-repetition interval was LAST-INTERVAL, should be
considered 'overdue'. If the arguments are not given they are extracted
from the entry at point."
  (unless days-overdue
    (setq days-overdue (org-drill-entry-days-overdue session)))
  (unless last-interval
    (setq last-interval (org-drill-entry-last-interval 1)))
  (and (numberp days-overdue)
       (> days-overdue 1)               ; enforce a sane minimum 'overdue' gap
       ;;(> due org-drill-days-before-overdue)
       (> (/ (+ days-overdue last-interval 1.0) last-interval)
          org-drill-overdue-interval-factor)))

(defun org-drill-entry-due-p (session)
  "Return non-nil if the entry at point is overdue.

The SESSION can affect the definition of overdue."
  (let ((due (org-drill-entry-days-overdue session)))
    (and (not (null due))
         (not (cl-minusp due)))))

(defun org-drill-entry-new-p ()
  "Return non-nil if the entry at point is new."
  (and (org-drill-entry-p)
       (let ((item-time (org-get-scheduled-time (point))))
         (null item-time))))

(defun org-drill-entry-last-quality (&optional default)
  "Return the SM quality score for entry at point, or DEFAULT."
  (let ((quality (org-entry-get (point) "DRILL_LAST_QUALITY")))
    (if quality
        (string-to-number quality)
      default)))

(defun org-drill-entry-failure-count ()
  "Return the SM failure count for entry at point."
  (let ((quality (org-entry-get (point) "DRILL_FAILURE_COUNT")))
    (if quality
        (string-to-number quality)
      0)))

(defun org-drill-entry-average-quality (&optional default)
  "Return the SM average quality for entry at point."
  (let ((val (org-entry-get (point) "DRILL_AVERAGE_QUALITY")))
    (if val
        (string-to-number val)
      (or default nil))))

(defun org-drill-entry-last-interval (&optional default)
  "Return the SM last interval for entry at point."
  (let ((val (org-entry-get (point) "DRILL_LAST_INTERVAL")))
    (if val
        (string-to-number val)
      (or default 0))))

(defun org-drill-entry-repeats-since-fail (&optional default)
  "Return the SM repeats since fail for entry at point."
  (let ((val (org-entry-get (point) "DRILL_REPEATS_SINCE_FAIL")))
    (if val
        (string-to-number val)
      (or default 0))))

(defun org-drill-entry-total-repeats (&optional default)
  "Return the SM total number of repeats for the entry at point."
  (let ((val (org-entry-get (point) "DRILL_TOTAL_REPEATS")))
    (if val
        (string-to-number val)
      (or default 0))))

(defun org-drill-entry-ease (&optional default)
  "Return the SM ease for the entry at point."
  (let ((val (org-entry-get (point) "DRILL_EASE")))
    (if val
        (string-to-number val)
      default)))

(defun org-drill-random-dispersal-factor ()
  "Returns a random number between 0.5 and 1.5.

This returns a strange random number distribution. See
http://www.supermemo.com/english/ol/sm5.htm for details."
  (let ((a 0.047)
        (b 0.092)
        (p (- (cl-random 1.0) 0.5)))
    (cl-flet ((sign (n)
                    (cond ((zerop n) 0)
                          ((cl-plusp n) 1)
                          (t -1))))
      (/ (+ 100 (* (* (/ -1 b) (log (- 1 (* (/ b a ) (abs p)))))
                   (sign p)))
         100.0))))

(defun org-drill-early-interval-factor (optimal-factor
                                                optimal-interval
                                                days-ahead)
  "Arguments:
- OPTIMAL-FACTOR: interval-factor if the item had been tested
exactly when it was supposed to be.
- OPTIMAL-INTERVAL: interval for next repetition (days) if the item had been
tested exactly when it was supposed to be.
- DAYS-AHEAD: how many days ahead of time the item was reviewed.

Returns an adjusted optimal factor which should be used to
calculate the next interval, instead of the optimal factor found
in the matrix."
  (let ((delta-ofmax (* (1- optimal-factor)
                    (/ (+ optimal-interval
                          (* 0.6 optimal-interval) -1) (1- optimal-interval)))))
    (- optimal-factor
       (* delta-ofmax (/ days-ahead (+ days-ahead (* 0.6 optimal-interval)))))))

(defun org-drill-get-item-data ()
  "Returns a list of 6 items, containing all the stored recall
  data for the item at point:
- LAST-INTERVAL is the interval in days that was used to schedule the item's
  current review date.
- REPEATS is the number of items the item has been successfully recalled without
  without any failures. It is reset to 0 upon failure to recall the item.
- FAILURES is the total number of times the user has failed to recall the item.
- TOTAL-REPEATS includes both successful and unsuccessful repetitions.
- AVERAGE-QUALITY is the mean quality of recall of the item over
  all its repetitions, successful and unsuccessful.
- EASE is a number reflecting how easy the item is to learn. Higher is easier.
"
  (let ((learn-str (org-entry-get (point) "LEARN_DATA"))
        (repeats (org-drill-entry-total-repeats :missing)))
    (cond
     (learn-str
      (let ((learn-data (and learn-str
                             (read learn-str))))
        (list (nth 0 learn-data)        ; last interval
              (nth 1 learn-data)        ; repetitions
              (org-drill-entry-failure-count)
              (nth 1 learn-data)
              (org-drill-entry-last-quality)
              (nth 2 learn-data)        ; EF
              )))
     ((not (eql :missing repeats))
      (list (org-drill-entry-last-interval)
            (org-drill-entry-repeats-since-fail)
            (org-drill-entry-failure-count)
            (org-drill-entry-total-repeats)
            (org-drill-entry-average-quality)
            (org-drill-entry-ease)))
     (t  ; virgin item
      (list 0 0 0 0 nil nil)))))

(defun org-drill-store-item-data (last-interval repeats failures
                                                total-repeats meanq
                                                ease)
  "Stores the given data in the item at point."
  (org-entry-delete (point) "LEARN_DATA")
  (org-set-property "DRILL_LAST_INTERVAL"
                    (number-to-string (org-drill-round-float last-interval 4)))
  (org-set-property "DRILL_REPEATS_SINCE_FAIL" (number-to-string repeats))
  (org-set-property "DRILL_TOTAL_REPEATS" (number-to-string total-repeats))
  (org-set-property "DRILL_FAILURE_COUNT" (number-to-string failures))
  (org-set-property "DRILL_AVERAGE_QUALITY"
                    (number-to-string (org-drill-round-float meanq 3)))
  (org-set-property "DRILL_EASE"
                    (number-to-string (org-drill-round-float ease 3))))

;;; SM2 Algorithm =============================================================
(defun org-drill-determine-next-interval-sm2 (last-interval n ef quality
                                                  failures meanq total-repeats)
  "Arguments:
- LAST-INTERVAL -- the number of days since the item was last reviewed.
- REPEATS -- the number of times the item has been successfully reviewed
- EF -- the 'easiness factor'
- QUALITY -- 0 to 5

Returns a list: (INTERVAL REPEATS EF FAILURES MEAN TOTAL-REPEATS OFMATRIX), where:
- INTERVAL is the number of days until the item should next be reviewed
- REPEATS is incremented by 1.
- EF is modified based on the recall quality for the item.
- OF-MATRIX is not modified."
  (if (zerop n) (setq n 1))
  (if (null ef) (setq ef 2.5))
  (setq meanq (if meanq
                  (/ (+ quality (* meanq total-repeats 1.0))
                     (1+ total-repeats))
                quality))
  (cl-assert (> n 0))
  (cl-assert (and (>= quality 0) (<= quality 5)))
  (if (<= quality org-drill-failure-quality)
      ;; When an item is failed, its interval is reset to 0,
      ;; but its EF is unchanged
      (list -1 1 ef (1+ failures) meanq (1+ total-repeats)
            org-drill-sm5-optimal-factor-matrix)
    ;; else:
    (let* ((next-ef (org-drill-modify-e-factor ef quality))
           (interval
            (cond
             ((<= n 1) 1)
             ((= n 2)
              (cond
               (org-drill-add-random-noise-to-intervals-p
                (cl-case quality
                  (5 6)
                  (4 4)
                  (3 3)
                  (2 1)
                  (t -1)))
               (t 6)))
             (t (* last-interval next-ef)))))
      (list (if org-drill-add-random-noise-to-intervals-p
                (+ last-interval (* (- interval last-interval)
                                    (org-drill-random-dispersal-factor)))
              interval)
            (1+ n)
            next-ef
            failures meanq (1+ total-repeats)
            org-drill-sm5-optimal-factor-matrix))))

;;; SM5 Algorithm =============================================================
(defun org-drill-modify-e-factor (ef quality)
  "Return new e-factor given existing EF and QUALITY."
  (if (< ef 1.3)
      1.3
    (+ ef (- 0.1 (* (- 5 quality) (+ 0.08 (* (- 5 quality) 0.02)))))))

(defun org-drill-modify-of (of q fraction)
  "Return modify of."
  (let ((temp (* of (+ 0.72 (* q 0.07)))))
    (+ (* (- 1 fraction) of) (* fraction temp))))

(defun org-drill-set-optimal-factor (n ef of-matrix of)
  "Set the optimal factor."
  (let ((factors (assoc n of-matrix)))
    (if factors
	(let ((ef-of (assoc ef (cdr factors))))
	  (if ef-of
	      (setcdr ef-of of)
	    (push (cons ef of) (cdr factors))))
      (push (cons n (list (cons ef of))) of-matrix)))
  of-matrix)

(defun org-drill-initial-optimal-factor-sm5 (n ef)
  "Return initial optimal factor."
  (if (= 1 n)
      org-drill-sm5-initial-interval
    ef))

(defun org-drill-get-optimal-factor-sm5 (n ef of-matrix)
  "Return optimal factor."
  (let ((factors (assoc n of-matrix)))
    (or (and factors
             (let ((ef-of (assoc ef (cdr factors))))
               (and ef-of (cdr ef-of))))
        (org-drill-initial-optimal-factor-sm5 n ef))))

(defun org-drill-inter-repetition-interval-sm5 (last-interval n ef &optional of-matrix)
  "Return repetition interval."
  (let ((of (org-drill-get-optimal-factor-sm5 n ef (or of-matrix
                                             org-drill-sm5-optimal-factor-matrix))))
    (if (= 1 n)
        of
      (* of last-interval))))

(defun org-drill-determine-next-interval-sm5 (last-interval n ef quality
                                                  failures meanq total-repeats
                                                  of-matrix &optional delta-days)
  "Return next interval."
  (if (zerop n) (setq n 1))
  (if (null ef) (setq ef 2.5))
  (cl-assert (> n 0))
  (cl-assert (and (>= quality 0) (<= quality 5)))
  (unless of-matrix
    (setq of-matrix org-drill-sm5-optimal-factor-matrix))
  (setq of-matrix (copy-tree of-matrix))

  (setq meanq (if meanq
                  (/ (+ quality (* meanq total-repeats 1.0))
                     (1+ total-repeats))
                quality))

  (let ((next-ef (org-drill-modify-e-factor ef quality))
        (old-ef ef)
        (new-of (org-drill-modify-of (org-drill-get-optimal-factor-sm5 n ef of-matrix)
                           quality org-drill-learn-fraction))
        (interval nil))
    (when (and org-drill-adjust-intervals-for-early-and-late-repetitions-p
               delta-days (cl-minusp delta-days))
      (setq new-of (org-drill-early-interval-factor
                    (org-drill-get-optimal-factor-sm5 n ef of-matrix)
                    (org-drill-inter-repetition-interval-sm5
                     last-interval n ef of-matrix)
                    delta-days)))
    (setq of-matrix
          (org-drill-set-optimal-factor n next-ef of-matrix
                              (org-drill-round-float new-of 3))) ; round OF to 3 d.p.
    (setq ef next-ef)
    (cond
     ;; "Failed" -- reset repetitions to 0,
     ((<= quality org-drill-failure-quality)
      (list -1 1 old-ef (1+ failures) meanq (1+ total-repeats)
            of-matrix))     ; Not clear if OF matrix is supposed to be
                                        ; preserved
     ;; For a zero-based quality of 4 or 5, don't repeat
     ;; ((and (>= quality 4)
     ;;       (not org-learn-always-reschedule))
     ;;  (list 0 (1+ n) ef failures meanq
     ;;        (1+ total-repeats) of-matrix))     ; 0 interval = unschedule
     (t
      (setq interval (org-drill-inter-repetition-interval-sm5
                      last-interval n ef of-matrix))
      (if org-drill-add-random-noise-to-intervals-p
          (setq interval (* interval (org-drill-random-dispersal-factor))))
      (list interval
            (1+ n)
            ef
            failures
            meanq
            (1+ total-repeats)
            of-matrix)))))

;;; Simple8 Algorithm =========================================================
(defun org-drill-simple8-first-interval (failures)
  "Arguments:
- FAILURES: integer >= 0. The total number of times the item has
  been forgotten, ever.

Returns the optimal FIRST interval for an item which has previously been
forgotten on FAILURES occasions."
  (* 2.4849 (exp (* -0.057 failures))))

(defun org-drill-simple8-interval-factor (ease repetition)
  "Arguments:
- EASE: floating point number >= 1.2. Corresponds to `AF' in SM8 algorithm.
- REPETITION: the number of times the item has been tested.
1 is the first repetition (ie the second trial).
Returns:
The factor by which the last interval should be
multiplied to give the next interval. Corresponds to `RF' or `OF'."
  (+ 1.2 (* (- ease 1.2) (expt org-drill-learn-fraction (log repetition 2)))))

(defun org-drill-simple8-quality->ease (quality)
  "Returns the ease (`AF' in the SM8 algorithm) which corresponds
to a mean item quality of QUALITY."
  (+ (* 0.0542 (expt quality 4))
     (* -0.4848 (expt quality 3))
     (* 1.4916 (expt quality 2))
     (* -1.2403 quality)
     1.4515))

(defun org-drill-determine-next-interval-simple8 (last-interval repeats quality
                                                      failures meanq totaln
                                                      &optional delta-days)
  "Arguments:
- LAST-INTERVAL -- the number of days since the item was last reviewed.
- REPEATS -- the number of times the item has been successfully reviewed
- EASE -- the 'easiness factor'
- QUALITY -- 0 to 5
- DELTA-DAYS -- how many days overdue was the item when it was reviewed.
  0 = reviewed on the scheduled day. +N = N days overdue.
  -N = reviewed N days early.

Returns the new item data, as a list of 6 values:
- NEXT-INTERVAL
- REPEATS
- EASE
- FAILURES
- AVERAGE-QUALITY
- TOTAL-REPEATS.
See the documentation for `org-drill-get-item-data' for a description of these."
  (cl-assert (>= repeats 0))
  (cl-assert (and (>= quality 0) (<= quality 5)))
  (cl-assert (or (null meanq) (and (>= meanq 0) (<= meanq 5))))
  (let ((next-interval nil))
    (setf meanq (if meanq
                    (/ (+ quality (* meanq totaln 1.0)) (1+ totaln))
                  quality))
    (cond
     ((<= quality org-drill-failure-quality)
      (cl-incf failures)
      (setf repeats 0
            next-interval -1))
     ((or (zerop repeats)
          (zerop last-interval))
      (setf next-interval (org-drill-simple8-first-interval failures))
      (cl-incf repeats)
      (cl-incf totaln))
     (t
      (let* ((use-n
              (if (and
                   org-drill-adjust-intervals-for-early-and-late-repetitions-p
                   (numberp delta-days) (cl-plusp delta-days)
                   (cl-plusp last-interval))
                  (+ repeats (min 1 (/ delta-days last-interval 1.0)))
                repeats))
             (factor (org-drill-simple8-interval-factor
                      (org-drill-simple8-quality->ease meanq) use-n))
             (next-int (* last-interval factor)))
        (when (and org-drill-adjust-intervals-for-early-and-late-repetitions-p
                   (numberp delta-days) (cl-minusp delta-days))
          ;; The item was reviewed earlier than scheduled.
          (setf factor (org-drill-early-interval-factor
                        factor next-int (abs delta-days))
                next-int (* last-interval factor)))
        (setf next-interval next-int)
        (cl-incf repeats)
        (cl-incf totaln))))
    (list
     (if (and org-drill-add-random-noise-to-intervals-p
              (cl-plusp next-interval))
         (* next-interval (org-drill-random-dispersal-factor))
       next-interval)
     repeats
     (org-drill-simple8-quality->ease meanq)
     failures
     meanq
     totaln
     )))

;;; Essentially copied from `org-learn.el', but modified to
;;; optionally call the SM2 or simple8 functions.
(defun org-drill-smart-reschedule (quality &optional days-ahead)
  "If DAYS-AHEAD is supplied it must be a positive integer. The
item will be scheduled exactly this many days into the future."
  (let ((delta-days (- (time-to-days (current-time))
                       (time-to-days (or (org-get-scheduled-time (point))
                                         (current-time)))))
        (ofmatrix org-drill-sm5-optimal-factor-matrix)
        ;; Entries can have weights, 1 by default. Intervals are divided by the
        ;; item's weight, so an item with a weight of 2 will have all intervals
        ;; halved, meaning you will end up reviewing it twice as often.
        ;; Useful for entries which randomly present any of several facts.
        (weight (org-entry-get (point) "DRILL_CARD_WEIGHT")))
    (if (stringp weight)
        (setq weight (read weight)))
    (cl-destructuring-bind (last-interval repetitions failures
                                       total-repeats meanq ease)
        (org-drill-get-item-data)
      (cl-destructuring-bind (next-interval repetitions ease
                                         failures meanq total-repeats
                                         &optional new-ofmatrix)
          (cl-case org-drill-spaced-repetition-algorithm
            (sm5 (org-drill-determine-next-interval-sm5 last-interval repetitions
                                              ease quality failures
                                              meanq total-repeats ofmatrix))
            (sm2 (org-drill-determine-next-interval-sm2 last-interval repetitions
                                              ease quality failures
                                              meanq total-repeats))
            (simple8 (org-drill-determine-next-interval-simple8 last-interval repetitions
                                                      quality failures meanq
                                                      total-repeats
                                                      delta-days)))
        (if (numberp days-ahead)
            (setq next-interval days-ahead))

        (if (and (null days-ahead)
                 (numberp weight) (cl-plusp weight)
                 (not (cl-minusp next-interval)))
            (setq next-interval
                  (max 1.0 (+ last-interval
                              (/ (- next-interval last-interval) weight)))))

        (org-drill-store-item-data next-interval repetitions failures
                                   total-repeats meanq ease)

        (if (eql 'sm5 org-drill-spaced-repetition-algorithm)
            (setq org-drill-sm5-optimal-factor-matrix new-ofmatrix))

        (cond
         ((= 0 days-ahead)
          (org-schedule '(4)))
         ((cl-minusp days-ahead)
          (org-schedule nil (current-time)))
         (t
          (org-schedule nil (time-add (current-time)
                                      (days-to-time
                                       (round next-interval))))))))))

(defun org-drill-hypothetical-next-review-date (quality)
  "Returns an integer representing the number of days into the future
that the current item would be scheduled, based on a recall quality
of QUALITY."
  (let ((weight (org-entry-get (point) "DRILL_CARD_WEIGHT")))
    (cl-destructuring-bind (last-interval repetitions failures
                                       total-repeats meanq ease)
        (org-drill-get-item-data)
      (if (stringp weight)
          (setq weight (read weight)))
      (cl-destructuring-bind (next-interval _repetitions _ease
                                         _failures _meanq _total-repeats
                                         &optional _ofmatrix)
          (cl-case org-drill-spaced-repetition-algorithm
            (sm5 (org-drill-determine-next-interval-sm5 last-interval repetitions
                                              ease quality failures
                                              meanq total-repeats
                                              org-drill-sm5-optimal-factor-matrix))
            (sm2 (org-drill-determine-next-interval-sm2 last-interval repetitions
                                              ease quality failures
                                              meanq total-repeats))
            (simple8 (org-drill-determine-next-interval-simple8 last-interval repetitions
                                                      quality failures meanq
                                                      total-repeats)))
        (cond
         ((not (cl-plusp next-interval))
          0)
         ((and (numberp weight) (cl-plusp weight))
          (+ last-interval
             (max 1.0 (/ (- next-interval last-interval) weight))))
         (t
          next-interval))))))

(defun org-drill-hypothetical-next-review-dates ()
  "Return hypothetical next review dates."
  (let ((intervals nil))
    (dotimes (q 6)
      (push (max (or (car intervals) 0)
                 (org-drill-hypothetical-next-review-date q))
            intervals))
    (reverse intervals)))

(defun org-drill--read-key-sequence (prompt)
  "Just like `read-key-sequence' but with input method turned off."
  (let ((old-input-method current-input-method))
    (unwind-protect
        (progn
          (set-input-method nil)
          (read-key-sequence prompt))
      (set-input-method old-input-method))))

(defun org-drill-reschedule (session)
  "Returns quality rating (0-5), or nil if the user quit."
  (let ((ch nil)
        (input nil)
        (next-review-dates (org-drill-hypothetical-next-review-dates))
        (typed-answer-statement (if (oref session typed-answer)
                                    (format "Your answer: %s\n"
                                            (oref session typed-answer))
                                  ""))
        (key-prompt (format "(0-5, %c=help, %c=edit, %c=tags, %c=quit)"
                            org-drill--help-key
                            org-drill--edit-key
                            org-drill--tags-key
                            org-drill--quit-key)))
    (save-excursion
      (while (not (memq ch (list org-drill--quit-key
                                 org-drill--edit-key
                                 7          ; C-g
                                 ?0 ?1 ?2 ?3 ?4 ?5)))
        (run-hooks 'org-drill-display-answer-hook)
        (setq input (org-drill--read-key-sequence
                     (if (eq ch org-drill--help-key)
                         (format "0-2 Means you have forgotten the item.
3-5 Means you have remembered the item.

0 - Completely forgot.
1 - Even after seeing the answer, it still took a bit to sink in.
2 - After seeing the answer, you remembered it.
3 - It took you awhile, but you finally remembered. (+%s days)
4 - After a little bit of thought you remembered. (+%s days)
5 - You remembered the item really easily. (+%s days)

%sHow well did you do? %s"
                                 (round (nth 3 next-review-dates))
                                 (round (nth 4 next-review-dates))
                                 (round (nth 5 next-review-dates))
                                 typed-answer-statement
                                 key-prompt)
                       (format "%sHow well did you do? %s"
                               typed-answer-statement key-prompt))))
        (cond
         ((stringp input)
          (setq ch (elt input 0)))
         ((and (vectorp input) (symbolp (elt input 0)))
          (cl-case (elt input 0)
            (up (ignore-errors (forward-line -1)))
            (down (ignore-errors (forward-line 1)))
            (left (ignore-errors (backward-char)))
            (right (ignore-errors (forward-char)))
            (prior (ignore-errors (scroll-down))) ; pgup
            (next (ignore-errors (scroll-up)))))  ; pgdn
         ((and (vectorp input) (listp (elt input 0))
               (eventp (elt input 0)))
          (cl-case (car (elt input 0))
            (wheel-up (ignore-errors (mwheel-scroll (elt input 0))))
            (wheel-down (ignore-errors (mwheel-scroll (elt input 0)))))))
        (if (eql ch org-drill--tags-key)
            (org-set-tags-command))))
    (cond
     ((and (>= ch ?0) (<= ch ?5))
      (let ((quality (- ch ?0))
            (failures (org-drill-entry-failure-count)))
        (unless (oref session cram-mode)
          (save-excursion
            (let ((quality (if (org-drill--entry-lapsed-p session) 2 quality)))
              (org-drill-smart-reschedule quality
                                          (nth quality next-review-dates))))
          (push quality (oref session qualities))
          (cond
           ((<= quality org-drill-failure-quality)
            (when org-drill-leech-failure-threshold
              ;;(setq failures (if failures (string-to-number failures) 0))
              ;; (org-set-property "DRILL_FAILURE_COUNT"
              ;;                   (format "%d" (1+ failures)))
              (if (> (1+ failures) org-drill-leech-failure-threshold)
                  (org-toggle-tag "leech" 'on))))
           (t
            (let ((scheduled-time (org-get-scheduled-time (point))))
              (when scheduled-time
                (message "Next review in %d days"
                         (- (time-to-days scheduled-time)
                            (time-to-days (current-time))))
                (sit-for 0.5)))))
          (org-set-property "DRILL_LAST_QUALITY" (format "%d" quality))
          (org-set-property "DRILL_LAST_REVIEWED"
                            (org-drill-time-to-inactive-org-timestamp (current-time))))
        quality))
     ((= ch org-drill--edit-key)
      'edit)
     (t
      nil))))

;; (defun org-drill-hide-all-subheadings-except (heading-list)
;;   "Returns a list containing the position of each immediate subheading of
;; the current topic."
;;   (let ((drill-entry-level (org-current-level))
;;         (drill-sections nil)
;;         (drill-heading nil))
;;     (org-show-subtree)
;;     (save-excursion
;;       (org-map-entries
;;        (lambda ()
;;          (when (and (not (outline-invisible-p))
;;                     (> (org-current-level) drill-entry-level))
;;            (setq drill-heading (org-get-heading t))
;;            (unless (and (= (org-current-level) (1+ drill-entry-level))
;;                         (member drill-heading heading-list))
;;              (hide-subtree))
;;            (push (point) drill-sections)))
;;        "" 'tree))
;;     (reverse drill-sections)))

(defun org-drill-hide-subheadings-if (test)
  "TEST is a function taking no arguments. TEST will be called for each
of the immediate subheadings of the current drill item, with the point
on the relevant subheading. TEST should return nil if the subheading is
to be revealed, non-nil if it is to be hidden.
Returns a list containing the position of each immediate subheading of
the current topic."
  (let ((drill-entry-level (org-current-level))
        (drill-sections nil))
    (org-show-subtree)
    (save-excursion
      (org-map-entries
       (lambda ()
         (when (and (not (outline-invisible-p))
                    (> (org-current-level) drill-entry-level))
           (when (or (/= (org-current-level) (1+ drill-entry-level))
                        (funcall test))
             (outline-hide-subtree))
           (push (point) drill-sections)))
       t 'tree))
    (reverse drill-sections)))

(defun org-drill-hide-all-subheadings-except (heading-list)
  "Hide all subheadings except HEADING-LIST."
  (org-drill-hide-subheadings-if
   (lambda () (let ((drill-heading (org-get-heading t)))
           (not (member drill-heading heading-list))))))

(defun org-drill--make-minibuffer-prompt (session prompt)
  "Make a mini-buffer for the SESSION, with PROMPT."
  (let ((status (cl-first (org-drill-entry-status session)))
        (mature-entry-count (+ (length (oref session young-mature-entries))
                               (length (oref session old-mature-entries))
                               (length (oref session overdue-entries)))))
    (format "%s %s %s %s %s %s"
            (propertize
             (char-to-string
              (cond
               ((eql status :failed) ?F)
               ((oref session cram-mode) ?C)
               (t
                (cl-case status
                  (:new ?N) (:young ?Y) (:old ?o) (:overdue ?!)
                  (t ??)))))
             'face `(:foreground
                     ,(cl-case status
                        (:new org-drill-new-count-color)
                        ((:young :old) org-drill-mature-count-color)
                        ((:overdue :failed) org-drill-failed-count-color)
                        (t org-drill-done-count-color))))
            (propertize
             (number-to-string (length (oref session done-entries)))
             'face `(:foreground ,org-drill-done-count-color)
             'help-echo "The number of items you have reviewed this session.")
            (propertize
             (number-to-string (+ (length (oref session again-entries))
                                  (length (oref session failed-entries))))
             'face `(:foreground ,org-drill-failed-count-color)
             'help-echo (concat "The number of items that you failed, "
                                "and need to review again."))
            (propertize
             (number-to-string mature-entry-count)
             'face `(:foreground ,org-drill-mature-count-color)
             'help-echo "The number of old items due for review.")
            (propertize
             (number-to-string (length (oref session new-entries)))
             'face `(:foreground ,org-drill-new-count-color)
             'help-echo (concat "The number of new items that you "
                                "have never reviewed."))
            prompt)))

(defun org-drill-presentation-prompt  (session &optional prompt)
  "Create a card prompt with a timer and user-specified menu.

Arguments:

PROMPT: A string that overrides the standard prompt.

RETURNS: An alist of the form ((<char> . <symbol>)...) where
         <char> is the character pressed and <symbol> is the
         returned value, which will normally be either a symbol,
         `t' or `nil'.

START-TIME: The time the card started to be displayed.  This
            defaults to (current-time), however, if the function
            is called multiple times from one card then it might
            be convenient to override this default.
"
  (if org-drill-presentation-prompt-with-typing
    (org-drill-presentation-prompt-in-buffer session prompt)
    (org-drill-presentation-prompt-in-mini-buffer session prompt)))

(defun org-drill-presentation-prompt-in-mini-buffer (session &optional prompt)
  "Create a card prompt with a timer and user-specified    if returns
    (or (cdr (assoc ch returns)))
 menu.

Arguments:

PROMPT: A string that overrides the standard prompt.
"
  (let* ((item-start-time (current-time))
         (input nil)
         (ch nil)
         (prompt
          (or prompt
              (format (concat "Press key for answer, "
                              "%c=edit, %c=tags, %c=skip, %c=quit.")
                      org-drill--edit-key
                      org-drill--tags-key
                      org-drill--skip-key
                      org-drill--quit-key)))
         (full-prompt
          (org-drill--make-minibuffer-prompt session prompt)))
    (if (and (eql 'warn org-drill-leech-method)
             (org-drill-entry-leech-p))
        (setq full-prompt (concat
                           (propertize "!!! LEECH ITEM !!!
You seem to be having a lot of trouble memorising this item.
Consider reformulating the item to make it easier to remember.\n"
                                       'face '(:foreground "red"))
                           full-prompt)))
    (while (memq ch '(nil org-drill--tags-key))
      (setq ch nil)
      (while (not (input-pending-p))
        (let ((elapsed (time-subtract (current-time) item-start-time)))
          (message (concat (if (>= (time-to-seconds elapsed) (* 60 60))
                               "++:++ "
                             (format-time-string "%M:%S " elapsed))
                           full-prompt))
          (sit-for 1)))
      (setq input (org-drill--read-key-sequence nil))
      (if (stringp input) (setq ch (elt input 0)))
      (if (eql ch org-drill--tags-key)
          (org-set-tags-command)))
    (cond
     ((eql ch org-drill--quit-key) nil)
     ((eql ch org-drill--edit-key) 'edit)
     ((eql ch org-drill--skip-key) 'skip)
     (t t))))

(defvar org-drill-presentation-timer nil
  "Timer for buffer-entry of answers")

(defvar org-drill-presentation-timer-calls 0
  "How many times the presentation timer has been called")

(defun org-drill-presentation-timer-cancel ()
  "Cancel the presentation timer."
  (when org-drill-presentation-timer
    (cancel-timer org-drill-presentation-timer))
  (setq org-drill-presentation-timer nil)
  (setq org-drill-presentation-timer-calls 0))

(defun org-drill-presentation-minibuffer-timer-function
    (item-start-time full-prompt)
  "Return prompt for mini-buffer in `org-drill-response-mode'."
  (let ((elapsed (time-subtract (current-time) item-start-time)))
    (message (concat (if (>= (time-to-seconds elapsed) (* 60 60))
                         "++:++ "
                       (format-time-string "%M:%S " elapsed))
                     full-prompt)))
  ;; if we have done it this many times, we probably want to stop
  (when (< 10 (cl-incf org-drill-presentation-timer-calls))
    (org-drill-presentation-timer-cancel)))

(define-derived-mode org-drill-response-mode nil "Org-Drill")
(define-key org-drill-response-mode-map [return] 'org-drill-response-rtn)
(define-key org-drill-response-mode-map (kbd "C-c C-q") 'org-drill-response-quit)
(define-key org-drill-response-mode-map (kbd "C-c C-e") 'org-drill-response-edit)
(define-key org-drill-response-mode-map (kbd "C-c C-s") 'org-drill-response-skip)
(define-key org-drill-response-mode-map (kbd "C-c C-t") 'org-drill-response-tags)

(defun org-drill-response-complete ()
  "Complete org-drill response mode."
  (kill-buffer (current-buffer))
  (exit-recursive-edit))

(defun org-drill-response-rtn ()
  "Exit response mode with return value."
  (interactive)
  (let ((session org-drill-current-session))
    (setf (oref session typed-answer) (buffer-string))
    (oset session exit-kind t)
    (org-drill-response-complete)))

(defun org-drill-response-quit ()
  "Exit response mode with quit."
  (interactive)
  (oset org-drill-current-session exit-kind 'quit)
  (org-drill-response-complete))

(defun org-drill-response-edit ()
  "Exit response mode with edit."
  (interactive)
  (oset org-drill-current-session exit-kind 'edit)
  (org-drill-response-complete))

(defun org-drill-response-skip ()
  "Exit response mode with skip."
  (interactive)
  (oset org-drill-current-session exit-kind 'skip)
  (org-drill-response-complete))

(defun org-drill-response-tags ()
  "Exit response mode with tags."
  (interactive)
  (oset org-drill-current-session exit-kind 'tags)
  (org-drill-response-complete))

(defun org-drill-response-get-buffer-create ()
  "Create a response buffer."
  (let ((local-current-input-method
         current-input-method)
        (cb (current-buffer)))
    (with-current-buffer
        (get-buffer-create "*Org-Drill*")
      (erase-buffer)
      (org-drill-response-mode)
      (set-input-method local-current-input-method)
      (current-buffer))))

(defun org-drill-presentation-prompt-in-buffer (session &optional prompt)
  "Display drill for SESSION with PROMPT."
  (let* ((item-start-time (current-time))
         (prompt
          (or prompt
              (format (concat "Type answer then return, "
                              "C-c C-e=edit, C-c C-t=tags, C-c C-s=skip, C-c C-q=quit."))))
         (full-prompt
          (org-drill--make-minibuffer-prompt session prompt)))
    (setf (oref session drill-answer) nil)
    (if (and (eql 'warn org-drill-leech-method)
             (org-drill-entry-leech-p))
        (setq full-prompt (concat
                           (propertize "!!! LEECH ITEM !!!
You seem to be having a lot of trouble memorising this item.
Consider reformulating the item to make it easier to remember.\n"
                                       'face '(:foreground "red"))
                           full-prompt)))
    (org-drill-presentation-timer-cancel)
    (setq org-drill-presentation-timer
          (run-with-idle-timer 1 t
                               #'org-drill-presentation-minibuffer-timer-function
                               item-start-time full-prompt)
          org-drill-presentation-timer-calls 0)
    (save-window-excursion
      (let ((buf
             (org-drill-response-get-buffer-create)))
        (select-window
         (display-buffer-below-selected buf nil))
        ;; Store the current session in a variable, so that it can
        ;; be picked up by the when we leave the buffer
        (setq-local org-drill-current-session session)
        (recursive-edit)
        (org-drill-presentation-timer-cancel)
        (oref session exit-kind)))))

(cl-defun org-drill-presentation-prompt-for-string (session prompt)
  "Create a card prompt with a timer and user-specified menu.

Arguments:

PROMPT: A string that overrides the standard prompt.

START-TIME: The time the card started to be displayed.  This
            defaults to (current-time), however, if the function
            is called multiple times from one card then it might
            be convenient to override this default.
"
  (let* ((prompt
          (or prompt
              "Type your answer and press <Enter>: "))
         (full-prompt
          (org-drill--make-minibuffer-prompt session prompt)))
    (if (and (eql 'warn org-drill-leech-method)
             (org-drill-entry-leech-p))
        (setq full-prompt (concat
                           (propertize "!!! LEECH ITEM !!!
You seem to be having a lot of trouble memorising this item.
Consider reformulating the item to make it easier to remember.\n"
                                       'face '(:foreground "red"))
                           full-prompt)))
    (setf (oref session drill-answer)
          (read-string full-prompt nil nil nil t))))

(defun org-drill-pos-in-regexp (pos regexp &optional nlines)
  "Return non-nil if POS is within REGEXP.

Normally only the current line is checked but NLINES can be checked instead.

If non-nil, returns (BEG . END) where beginning and end of the match are."
  (save-excursion
    (goto-char pos)
    (org-in-regexp regexp nlines)))

(defun org-drill-hide-region (beg end &optional text)
  "Hide the buffer region between BEG and END with an 'invisible text'
visual overlay, or with the string TEXT if it is supplied."
  (let ((ovl (make-overlay beg end)))
    (overlay-put ovl 'category
                 'org-drill-hidden-text-overlay)
    (overlay-put ovl 'priority 9999)
    (when (stringp text)
      (overlay-put ovl 'invisible nil)
      (overlay-put ovl 'face 'default)
      (overlay-put ovl 'display text))))

(defun org-drill-hide-heading-at-point (&optional text)
  "Hide the heading at point."
  (unless (org-at-heading-p)
    (error "Point is not on a heading"))
  (save-excursion
    (let ((beg (point)))
      (end-of-line)
      (org-drill-hide-region beg (point) text))))

(defun org-drill-hide-comments ()
  "Hide comments."
  (save-excursion
    (while (re-search-forward "^#.*$" nil t)
      (org-drill-hide-region (match-beginning 0) (match-end 0)))))

(defun org-drill-unhide-text ()
  "Unhide text."
  (save-excursion
    (dolist (ovl (overlays-in (point-min) (point-max)))
      (when (eql 'org-drill-hidden-text-overlay (overlay-get ovl 'category))
        (delete-overlay ovl)))))

(defun org-drill-hide-clozed-text ()
  "Hide clozed text."
  (save-excursion
    (while (re-search-forward org-drill-cloze-regexp nil t)
      ;; Don't hide:
      ;; - org links, partly because they might contain inline
      ;;   images which we want to keep visible.
      ;; - LaTeX math fragments
      ;; - the contents of SRC blocks
      (unless (save-match-data
                (or (org-drill-pos-in-regexp (match-beginning 0)
                                       org-bracket-link-regexp 1)
                    (org-in-src-block-p)
                    (org-inside-LaTeX-fragment-p)))
        (org-drill-hide-matched-cloze-text)))))

(defun org-drill-hide-matched-cloze-text ()
  "Hide the current match with a 'cloze' visual overlay."
  (let ((ovl (make-overlay (match-beginning 0) (match-end 0)))
        (hint-sep-pos (string-match-p (regexp-quote org-drill-hint-separator)
                                      (match-string 0))))
    (overlay-put ovl 'category
                 'org-drill-cloze-overlay-defaults)
    (overlay-put ovl 'priority 9999)
    (if org-drill-cloze-length-matches-hidden-text-p
        (overlay-put ovl 'display
                     (concat "[" (make-string (max 1 (- (length (match-string 0)) 2)) ?.) "]")))
    (when (and hint-sep-pos
               (> hint-sep-pos 1))
      (let ((hint (substring-no-properties
                   (match-string 0)
                   (+ hint-sep-pos (length org-drill-hint-separator))
                   (1- (length (match-string 0))))))
        (overlay-put
         ovl 'display
         ;; If hint is like `X...' then display [X...]
         ;; otherwise display [...X]
         (format "[%s%s%s]"
                 hint
                 (if (string-match-p (regexp-quote "...") hint) "" "...")
                 (if org-drill-cloze-length-matches-hidden-text-p
                     (make-string (max 0 (- (length (match-string 0))
                                            (length hint)
                                            (if (string-match-p (regexp-quote "...") hint) 0 3)
                                            2))
                                  ?.)
                   "")))))))

(defun org-drill-hide-cloze-hints ()
  "Hide cloze hints."
  (save-excursion
    (while (re-search-forward org-drill-cloze-regexp nil t)
      (unless (or (save-match-data
                    (org-drill-pos-in-regexp (match-beginning 0)
                                       org-bracket-link-regexp 1))
                  (null (match-beginning 2))) ; hint subexpression matched
        (org-drill-hide-region (match-beginning 2) (match-end 2))))))

(defmacro org-drill-with-replaced-entry-text (text &rest body)
  "During the execution of BODY, the entire text of the current entry is
concealed by an overlay that displays the string TEXT."
  `(progn
     (org-drill-replace-entry-text ,text)
     (unwind-protect
         (progn
           ,@body)
       (org-drill-unreplace-entry-text))))

(defmacro org-drill-with-replaced-entry-text-multi (replacements &rest body)
  "During the execution of BODY, the entire text of the current entry is
concealed by an overlay that displays the overlays in REPLACEMENTS."
  `(progn
     (org-drill-replace-entry-text ,replacements t)
     (unwind-protect
         (progn
           ,@body)
       (org-drill-unreplace-entry-text))))

(defun org-drill-replace-entry-text (text &optional multi-p)
  "Make an overlay that conceals the entire text of the item, not
including properties or the contents of subheadings. The overlay shows
the string TEXT.
If MULTI-P is non-nil, TEXT must be a list of values which are legal
for the `display' text property. The text of the item will be temporarily
replaced by all of these items, in the order in which they appear in
the list.
Note: does not actually alter the item."
  (cond
   ((and multi-p
         (listp text))
    (org-drill-replace-entry-text-multi text))
   (t
    (let ((ovl (make-overlay (point-min)
                             (save-excursion
                               (outline-next-heading)
                               (point)))))
      (overlay-put ovl 'priority 9999)
      (overlay-put ovl 'category
                   'org-drill-replaced-text-overlay)
      (overlay-put ovl 'display text)))))

(defun org-drill-unreplace-entry-text ()
  "Unreplace entry text."
  (save-excursion
    (dolist (ovl (overlays-in (point-min) (point-max)))
      (when (eql 'org-drill-replaced-text-overlay (overlay-get ovl 'category))
        (delete-overlay ovl)))))

(defun org-drill-replace-entry-text-multi (replacements)
  "Make overlays that conceal the entire text of the item, not
including properties or the contents of subheadings. The overlay shows
the string TEXT.
Note: does not actually alter the item."
  (let ((ovl nil)
        (p-min (point-min))
        (p-max (save-excursion
                 (outline-next-heading)
                 (point))))
    (cl-assert (>= (- p-max p-min) (length replacements)))
    (dotimes (i (length replacements))
      (setq ovl (make-overlay (+ p-min (* 2 i))
                              (if (= i (1- (length replacements)))
                                  p-max
                                (+ p-min (* 2 i) 1))))
      (overlay-put ovl 'priority 9999)
      (overlay-put ovl 'category
                   'org-drill-replaced-text-overlay)
      (overlay-put ovl 'display (nth i replacements)))))

(defmacro org-drill-with-replaced-entry-heading (heading &rest body)
  "Display HEADING in place of current entry heading, and execute BODY."
  `(progn
     (org-drill-replace-entry-heading ,heading)
     (unwind-protect
         (progn
           ,@body)
       (org-drill-unhide-text))))

(defun org-drill-replace-entry-heading (heading)
  "Make an overlay that conceals the heading of the item. The overlay shows
the string TEXT.
Note: does not actually alter the item."
  (org-drill-hide-heading-at-point heading))

(defun org-drill-unhide-clozed-text ()
  "Show clozed text."
  (save-excursion
    (dolist (ovl (overlays-in (point-min) (point-max)))
      (when (eql 'org-drill-cloze-overlay-defaults (overlay-get ovl 'category))
        (delete-overlay ovl)))))

(defun org-drill-get-entry-text (&optional keep-properties-p)
  "Return the text of the current entry."
  (let ((text (org-agenda-get-some-entry-text (point-marker) 100)))
    (if keep-properties-p
        text
      (substring-no-properties text))))

;; (defun org-entry-empty-p ()
;;   (zerop (length (org-drill-get-entry-text))))

;; This version is about 5x faster than the old version, above.
(defun org-drill-entry-empty-p ()
  "Return non-nil if the current entry is empty."
  (save-excursion
    (org-back-to-heading t)
    (let ((lim (save-excursion
                 (outline-next-heading) (point))))
      (if (fboundp 'org-end-of-meta-data-and-drawers)
          (org-end-of-meta-data-and-drawers) ; function removed Feb 2015
        (org-end-of-meta-data t))
      (or (>= (point) lim)
          (null (re-search-forward "[[:graph:]]" lim t))))))

;;; Presentation functions ====================================================
;;
;; Each of these is called with point on topic heading.  Each needs to show the
;; topic in the form of a 'question' or with some information 'hidden', as
;; appropriate for the card type. The user should then be prompted to press a
;; key. The function should then reveal either the 'answer' or the entire
;; topic, and should return t if the user chose to see the answer and rate their
;; recall, nil if they chose to quit.
(defun org-drill-present-simple-card (session)
  "Present a simple card."
  (org-drill-with-hidden-comments
   (org-drill-with-hidden-cloze-hints
    (org-drill-with-hidden-cloze-text
     (org-drill-hide-all-subheadings-except nil)
     (org-drill--show-latex-fragments)  ; overlay all LaTeX fragments with images
     (ignore-errors
       (org-display-inline-images t))
     (org-cycle-hide-drawers 'all)
     (prog1 (org-drill-presentation-prompt session)
       (org-drill-hide-subheadings-if 'org-drill-entry-p))))))

(defun org-drill-present-default-answer (session reschedule-fn)
  "Present a default answer.

SESSION is the current session.
RESCHEDULE-FN is the function to reschedule."
  (prog1 (cond
          ((oref session drill-answer)
           (org-drill-with-replaced-entry-text
            (format "\nAnswer:\n\n  %s\n" (oref session drill-answer))
            (funcall reschedule-fn session)
            ))
          (t
           (org-drill-hide-subheadings-if 'org-drill-entry-p)
           (org-drill-unhide-clozed-text)
           (org-drill--show-latex-fragments)
           (ignore-errors
             (org-display-inline-images t))
           (org-cycle-hide-drawers 'all)
           (org-remove-latex-fragment-image-overlays)
           (save-excursion
             (org-mark-subtree)
             (let ((beg (region-beginning))
                   (end (region-end)))
               (org--latex-preview-region beg end))
             (deactivate-mark))
           (org-drill-with-hidden-cloze-hints
            (funcall reschedule-fn session))))))

(defun org-drill-present-simple-card-with-typed-answer (session)
  "Present a simple card with a typed answer."
  (org-drill-with-hidden-comments
   (org-drill-with-hidden-cloze-hints
    (org-drill-with-hidden-cloze-text
     (org-drill-hide-all-subheadings-except nil)
     (org-drill--show-latex-fragments)  ; overlay all LaTeX fragments with images
     (ignore-errors
       (org-display-inline-images t))
     (org-cycle-hide-drawers 'all)
     (prog1 (org-drill-presentation-prompt-for-string session nil)
       (org-drill-hide-subheadings-if 'org-drill-entry-p))))))

(defun org-drill--show-latex-fragments ()
  "Show latex fragment."
  (org-remove-latex-fragment-image-overlays)
  (org-toggle-latex-fragment '(16)))

(defun org-drill-present-two-sided-card (session)
  (org-drill-with-hidden-comments
   (org-drill-with-hidden-cloze-hints
    (org-drill-with-hidden-cloze-text
     (let ((drill-sections (org-drill-hide-all-subheadings-except nil)))
       (when drill-sections
         (save-excursion
           (goto-char (nth (cl-random (min 2 (length drill-sections)))
                           drill-sections))
           (org-show-subtree)))
       (org-drill--show-latex-fragments)
       (ignore-errors
         (org-display-inline-images t))
       (org-cycle-hide-drawers 'all)
       (prog1 (org-drill-presentation-prompt session)
         (org-drill-hide-subheadings-if 'org-drill-entry-p)))))))

(defun org-drill-present-multi-sided-card (session)
  (org-drill-with-hidden-comments
   (org-drill-with-hidden-cloze-hints
    (org-drill-with-hidden-cloze-text
     (let ((drill-sections (org-drill-hide-all-subheadings-except nil)))
       (when drill-sections
         (save-excursion
           (goto-char (nth (cl-random (length drill-sections)) drill-sections))
           (org-show-subtree)))
       (org-drill--show-latex-fragments)
       (ignore-errors
         (org-display-inline-images t))
       (org-cycle-hide-drawers 'all)
       (prog1 (org-drill-presentation-prompt session)
         (org-drill-hide-subheadings-if 'org-drill-entry-p)))))))

(defun org-drill-present-multicloze-hide-n (session
                                            number-to-hide
                                            &optional
                                            force-show-first
                                            force-show-last
                                            force-hide-first)
  "Hides NUMBER-TO-HIDE pieces of text that are marked for cloze deletion,
chosen at random.
If NUMBER-TO-HIDE is negative, show only (ABS NUMBER-TO-HIDE) pieces,
hiding all the rest.
If FORCE-HIDE-FIRST is non-nil, force the first piece of text to be one of
the hidden items.
If FORCE-SHOW-FIRST is non-nil, never hide the first piece of text.
If FORCE-SHOW-LAST is non-nil, never hide the last piece of text.
If the number of text pieces in the item is less than
NUMBER-TO-HIDE, then all text pieces will be hidden (except the first or last
items if FORCE-SHOW-FIRST or FORCE-SHOW-LAST is non-nil)."
  (org-drill-with-hidden-comments
   (org-drill-with-hidden-cloze-hints
    (let ((item-end nil)
          (match-count 0)
          (body-start (or (cdr (org-get-property-block))
                          (point))))
      (if (and force-hide-first force-show-first)
          (error "FORCE-HIDE-FIRST and FORCE-SHOW-FIRST are mutually exclusive"))
      (org-drill-hide-all-subheadings-except nil)
      (save-excursion
        (outline-next-heading)
        (setq item-end (point)))
      (save-excursion
        (goto-char body-start)
        (while (re-search-forward org-drill-cloze-regexp item-end t)
          (let ((in-regexp? (save-match-data
                              (org-drill-pos-in-regexp (match-beginning 0)
                                                 org-bracket-link-regexp 1))))
            (unless (or in-regexp?
                        (org-inside-LaTeX-fragment-p))
              (cl-incf match-count)))))
      (if (cl-minusp number-to-hide)
          (setq number-to-hide (+ match-count number-to-hide)))
      (when (cl-plusp match-count)
        (let* ((positions (org-drill-shuffle
                           (cl-loop for i from 1
                                 to match-count
                                 collect i)))
               (match-nums nil)
               (cnt nil))
          (if force-hide-first
              ;; Force '1' to be in the list, and to be the first item
              ;; in the list.
              (setq positions (cons 1 (remove 1 positions))))
          (if force-show-first
              (setq positions (remove 1 positions)))
          (if force-show-last
              (setq positions (remove match-count positions)))
          (setq match-nums
                (cl-subseq positions
                        0 (min number-to-hide (length positions))))
          ;; (dolist (pos-to-hide match-nums)
          (save-excursion
            (goto-char body-start)
            (setq cnt 0)
            (while (re-search-forward org-drill-cloze-regexp item-end t)
              (unless (save-match-data
                        (or (org-drill-pos-in-regexp (match-beginning 0)
                                               org-bracket-link-regexp 1)
                            (org-inside-LaTeX-fragment-p)))
                (cl-incf cnt)
                (if (memq cnt match-nums)
                    (org-drill-hide-matched-cloze-text)))))))
      ;; (loop
      ;;  do (re-search-forward org-drill-cloze-regexp
      ;;                        item-end t pos-to-hide)
      ;;  while (org-drill-pos-in-regexp (match-beginning 0)
      ;;                           org-bracket-link-regexp 1))
      ;; (org-drill-hide-matched-cloze-text)))))
      (org-drill--show-latex-fragments)
      (ignore-errors
        (org-display-inline-images t))
      (org-cycle-hide-drawers 'all)
      (prog1 (org-drill-presentation-prompt session)
        (org-drill-hide-subheadings-if 'org-drill-entry-p)
        (org-drill-unhide-clozed-text))))))

(defun org-drill-present-multicloze-hide-nth (session to-hide)
  "Hide the TO-HIDE'th piece of clozed text. 1 is the first piece. If
TO-HIDE is negative, count backwards, so -1 means the last item, -2
the second to last, etc."
  (org-drill-with-hidden-comments
   (org-drill-with-hidden-cloze-hints
    (let ((item-end nil)
          (match-count 0)
          (body-start (or (cdr (org-get-property-block))
                          (point)))
          (cnt 0))
      (org-drill-hide-all-subheadings-except nil)
      (save-excursion
        (outline-next-heading)
        (setq item-end (point)))
      (save-excursion
        (goto-char body-start)
        (while (re-search-forward org-drill-cloze-regexp item-end t)
          (let ((in-regexp? (save-match-data
                              (org-drill-pos-in-regexp (match-beginning 0)
                                                 org-bracket-link-regexp 1))))
            (unless (or in-regexp?
                        (org-inside-LaTeX-fragment-p))
              (cl-incf match-count)))))
      (if (cl-minusp to-hide)
          (setq to-hide (+ 1 to-hide match-count)))
      (cond
       ((or (not (cl-plusp match-count))
            (> to-hide match-count))
        nil)
       (t
        (save-excursion
          (goto-char body-start)
          (setq cnt 0)
          (while (re-search-forward org-drill-cloze-regexp item-end t)
            (unless (save-match-data
                      ;; Don't consider this a cloze region if it is part of an
                      ;; org link, or if it occurs inside a LaTeX math
                      ;; fragment
                      (or (org-drill-pos-in-regexp (match-beginning 0)
                                             org-bracket-link-regexp 1)
                          (org-inside-LaTeX-fragment-p)))
              (cl-incf cnt)
              (if (= cnt to-hide)
                  (org-drill-hide-matched-cloze-text)))))))
      (org-drill--show-latex-fragments)
      (ignore-errors
        (org-display-inline-images t))
      (org-cycle-hide-drawers 'all)
      (prog1 (org-drill-presentation-prompt session)
        (org-drill-hide-subheadings-if 'org-drill-entry-p)
        (org-drill-unhide-clozed-text))))))

(defun org-drill-present-multicloze-hide1 (session)
  "Hides one of the pieces of text that are marked for cloze deletion,
chosen at random."
  (org-drill-present-multicloze-hide-n session 1))

(defun org-drill-present-multicloze-hide2 (session)
  "Hides two of the pieces of text that are marked for cloze deletion,
chosen at random."
  (org-drill-present-multicloze-hide-n session 2))

(defun org-drill-present-multicloze-hide-first (session)
  "Hides the first piece of text that is marked for cloze deletion."
  (org-drill-present-multicloze-hide-nth session 1))

(defun org-drill-present-multicloze-hide-last (session)
  "Hides the last piece of text that is marked for cloze deletion."
  (org-drill-present-multicloze-hide-nth session -1))

(defun org-drill-present-multicloze-hide1-firstmore (session)
  "Commonly, hides the FIRST piece of text that is marked for
cloze deletion. Uncommonly, hide one of the other pieces of text,
chosen at random.

The definitions of 'commonly' and 'uncommonly' are determined by
the value of `org-drill-cloze-text-weight'."
  ;; The 'firstmore' and 'lastmore' functions used to randomly choose whether
  ;; to hide the 'favoured' piece of text. However even when the chance of
  ;; hiding it was set quite high (80%), the outcome was too unpredictable over
  ;; the small number of repetitions where most learning takes place for each
  ;; item. In other words, the actual frequency during the first 10 repetitions
  ;; was often very different from 80%. Hence we use modulo instead.
  (cond
   ((null org-drill-cloze-text-weight)
    ;; Behave as hide1cloze
    (org-drill-present-multicloze-hide1 session))
   ((not (and (integerp org-drill-cloze-text-weight)
              (cl-plusp org-drill-cloze-text-weight)))
    (error "Illegal value for org-drill-cloze-text-weight: %S"
           org-drill-cloze-text-weight))
   ((zerop (mod (1+ (org-drill-entry-total-repeats 0))
                org-drill-cloze-text-weight))
    ;; Uncommonly, hide any item except the first
    (org-drill-present-multicloze-hide-n session 1 t))
   (t
    ;; Commonly, hide first item
    (org-drill-present-multicloze-hide-first session))))

(defun org-drill-present-multicloze-show1-lastmore (session)
  "Commonly, hides all pieces except the last. Uncommonly, shows
any random piece. The effect is similar to 'show1cloze' except
that the last item is much less likely to be the item that is
visible.

The definitions of 'commonly' and 'uncommonly' are determined by
the value of `org-drill-cloze-text-weight'."
  (cond
   ((null org-drill-cloze-text-weight)
    ;; Behave as show1cloze
    (org-drill-present-multicloze-show1 session))
   ((not (and (integerp org-drill-cloze-text-weight)
              (cl-plusp org-drill-cloze-text-weight)))
    (error "Illegal value for org-drill-cloze-text-weight: %S"
           org-drill-cloze-text-weight))
   ((zerop (mod (1+ (org-drill-entry-total-repeats 0))
                org-drill-cloze-text-weight))
    ;; Uncommonly, show any item except the last
    (org-drill-present-multicloze-hide-n session -1 nil nil t))
   (t
    ;; Commonly, show the LAST item
    (org-drill-present-multicloze-hide-n session -1 nil t))))

(defun org-drill-present-multicloze-show1-firstless (session)
  "Commonly, hides all pieces except one, where the shown piece
is guaranteed NOT to be the first piece. Uncommonly, shows any
random piece. The effect is similar to 'show1cloze' except that
the first item is much less likely to be the item that is
visible.

The definitions of 'commonly' and 'uncommonly' are determined by
the value of `org-drill-cloze-text-weight'."
  (cond
   ((null org-drill-cloze-text-weight)
    ;; Behave as show1cloze
    (org-drill-present-multicloze-show1 session))
   ((not (and (integerp org-drill-cloze-text-weight)
              (cl-plusp org-drill-cloze-text-weight)))
    (error "Illegal value for org-drill-cloze-text-weight: %S"
           org-drill-cloze-text-weight))
   ((zerop (mod (1+ (org-drill-entry-total-repeats 0))
                org-drill-cloze-text-weight))
    ;; Uncommonly, show the first item
    (org-drill-present-multicloze-hide-n session -1 t))
   (t
    ;; Commonly, show any item, except the first
    (org-drill-present-multicloze-hide-n session -1 nil nil t))))

(defun org-drill-present-multicloze-show1 (session)
  "Similar to `org-drill-present-multicloze-hide1', but hides all
the pieces of text that are marked for cloze deletion, except for one
piece which is chosen at random."
  (org-drill-present-multicloze-hide-n session -1))

(defun org-drill-present-multicloze-show2 (session)
  "Similar to `org-drill-present-multicloze-show1', but reveals two
pieces rather than one."
  (org-drill-present-multicloze-hide-n session -2))

(defun org-drill-present-card-using-text (session question &optional answer)
  "Present the string QUESTION as the only visible content of the card.
If ANSWER is supplied, set the session slot `drill-answer' to its value."
  (if answer (setf (oref session drill-answer) answer))
  (org-drill-with-hidden-comments
   (org-drill-with-replaced-entry-text
    (concat "\n" question)
    (org-drill-hide-all-subheadings-except nil)
    (org-cycle-hide-drawers 'all)
    (ignore-errors
      (org-display-inline-images t))
    (prog1 (org-drill-presentation-prompt session)
      (org-drill-hide-subheadings-if 'org-drill-entry-p)))))

(defun org-drill-entry (session)
  "Present the current topic for interactive review, as in `org-drill'.
Review will occur regardless of whether the topic is due for review or whether
it meets the definition of a 'review topic' used by `org-drill'.

Returns a quality rating from 0 to 5, or nil if the user quit, or the symbol
EDIT if the user chose to exit the drill and edit the current item. Choosing
the latter option leaves the drill session suspended; it can be resumed
later using `org-drill-resume'.

See `org-drill' for more details."
  (org-drill-entry-f session 'org-drill-reschedule))

(defun org-drill-card-tag-caller (item tag)
  (funcall
   (or (nth item (assoc tag org-drill-card-tags-alist))
       'ignore)))

(defun org-drill-entry-f (session complete-func)
  (org-drill-goto-drill-entry-heading)
  ;;(unless (org-drill-part-of-drill-entry-p)
  ;;  (error "Point is not inside a drill entry"))
  ;;(unless (org-at-heading-p)
  ;;  (org-back-to-heading))
  (let ((card-type (org-entry-get (point) "DRILL_CARD_TYPE" t))
        (answer-fn 'org-drill-present-default-answer)
        (cont nil)
        ;; fontification functions in `outline-view-change-hook' can cause big
        ;; slowdowns, so we temporarily bind this variable to nil here.
        (outline-view-change-hook nil))
    (setf (oref session drill-answer) nil)
    (org-save-outline-visibility t
      (save-restriction
        (org-narrow-to-subtree)
        (org-show-subtree)
        (org-cycle-hide-drawers 'all)

        (let ((presentation-fn
               (cdr (assoc card-type org-drill-card-type-alist))))
          (if (listp presentation-fn)
              (cl-psetq answer-fn (or (cl-second presentation-fn)
                                   'org-drill-present-default-answer)
                     presentation-fn (cl-first presentation-fn)))
          (let* ((tags (org-get-tags))
                 (rtn
                  (cond
                   ((null presentation-fn)
                    (message "%s:%d: Unrecognised card type '%s', skipping..."
                             (buffer-name) (point) card-type)
                    (sit-for 0.5)
                    'skip)
                   (t
                    (mapc
                     (apply-partially 'org-drill-card-tag-caller 1)
                     tags)
                    (setq cont (funcall presentation-fn session))
                    (cond
                     ((not cont)
                      (message "Quit")
                      nil)
                     ((eql cont 'edit)
                      'edit)
                     ((eql cont 'skip)
                      'skip)
                     (t
                      (save-excursion
                        (mapc
                         (apply-partially 'org-drill-card-tag-caller 2)
                         tags)
                        (funcall answer-fn session complete-func))))))))
            (mapc
             (apply-partially 'org-drill-card-tag-caller 3)
             tags)
            (cl-incf org-drill-cards-in-this-emacs)
            rtn))))))

(defun org-drill-entries-pending-p (session)
  (or (oref session again-entries)
      (oref session current-item)
      (and (not (org-drill-maximum-item-count-reached-p session))
           (not (org-drill-maximum-duration-reached-p session))
           (or (oref session new-entries)
               (oref session failed-entries)
               (oref session young-mature-entries)
               (oref session old-mature-entries)
               (oref session overdue-entries)
               (oref session again-entries)))))

(defun org-drill-pending-entry-count (session)
  (+ (if (markerp (oref session current-item)) 1 0)
     (length (oref session new-entries))
     (length (oref session failed-entries))
     (length (oref session young-mature-entries))
     (length (oref session old-mature-entries))
     (length (oref session overdue-entries))
     (length (oref session again-entries))))

(defun org-drill-maximum-duration-reached-p (session)
  "Returns true if the current drill session has continued past its
maximum duration."
  (and org-drill-maximum-duration
       (not (oref session cram-mode))
       (oref session start-time)
       (> (- (float-time (current-time))
             (oref session start-time))
          (* org-drill-maximum-duration 60))))

(defun org-drill-maximum-item-count-reached-p (session)
  "Returns true if the current drill session has reached the
maximum number of items."
  (and org-drill-maximum-items-per-session
       (not (oref session cram-mode))
       (>= (if org-drill-item-count-includes-failed-items-p
               (+ (length (oref session done-entries))
                  (length (oref session again-entries)))
             (length (oref session done-entries)))
          org-drill-maximum-items-per-session)))

(defun org-drill-pop-next-pending-entry (session)
  (cl-block org-drill-pop-next-pending-entry
    (let ((m nil))
      (while (or (null m)
                 (not (org-drill-entry-p m)))
        (setq
         m
         (cond
          ;; First priority is items we failed in a prior session.
          ((and (oref session failed-entries)
                (not (org-drill-maximum-item-count-reached-p session))
                (not (org-drill-maximum-duration-reached-p session)))
           (org-drill-pop-random (oref session failed-entries)))
          ;; Next priority is overdue items.
          ((and (oref session overdue-entries)
                (not (org-drill-maximum-item-count-reached-p session))
                (not (org-drill-maximum-duration-reached-p session)))
           ;; We use `pop', not `pop-random', because we have already
           ;; sorted overdue items into a random order which takes
           ;; number of days overdue into account.
           (pop (oref session overdue-entries)))
          ;; Next priority is 'young' items.
          ((and (oref session young-mature-entries)
                (not (org-drill-maximum-item-count-reached-p session))
                (not (org-drill-maximum-duration-reached-p session)))
           (org-drill-pop-random (oref session young-mature-entries)))
          ;; Next priority is newly added items, and older entries.
          ;; We pool these into a single group.
          ((and (or (oref session new-entries)
                    (oref session old-mature-entries))
                (not (org-drill-maximum-item-count-reached-p session))
                (not (org-drill-maximum-duration-reached-p session)))
           (cond
            ((< (cl-random (+ (length (oref session new-entries))
                              (length (oref session old-mature-entries))))
                (length (oref session new-entries)))
             (org-drill-pop-random (oref session new-entries)))
            (t
             (org-drill-pop-random (oref session old-mature-entries)))))
          ;; After all the above are done, last priority is items
          ;; that were failed earlier THIS SESSION.
          ((oref session again-entries)
           (pop (oref session again-entries)))
          (t                            ; nothing left -- return nil
           (cl-return-from org-drill-pop-next-pending-entry nil)))))
      m)))

(defun org-drill-entries (session &optional resuming-p)
  "Returns nil, t, or a list of markers representing entries that were
'failed' and need to be presented again before the session ends.

RESUMING-P is true if we are resuming a suspended drill session."
  (cl-block org-drill-entries
    (while (org-drill-entries-pending-p session)
      (let ((m (cond
                ((or (not resuming-p)
                     (null (oref session current-item))
                     (not (org-drill-entry-p (oref session current-item))))
                 (org-drill-pop-next-pending-entry session))
                (t                      ; resuming a suspended session.
                 (setq resuming-p nil)
                 (oref session current-item)))))
        (setf (oref session current-item) m)
        (unless m
          (error "Unexpectedly ran out of pending drill items"))
        (save-excursion
          (org-drill-goto-entry m)
          (message "[debug] org-drill: at marker position %s" (marker-position m))
          (cond
           ((not (org-at-heading-p))
            (error "Not at heading for entry %s" m))
           ((not (org-drill-entry-due-p session))
            ;; The entry is not due anymore. This could arise if the user
            ;; suspends a drill session, then drills an individual entry,
            ;; then resumes the session.
            (message "Entry no longer due, skipping...")
            (sit-for 0.3)
            nil)
           (t
            (org-show-entry)
            (let ((result (org-drill-entry session)))
              (cond
               ((null result)
                (message "Quit")
                (setf (oref session end-pos) :quit)
                (cl-return-from org-drill-entries nil))
               ((eql result 'edit)
                (setf (oref session end-pos) (point-marker))
                (cl-return-from org-drill-entries nil))
               ((eql result 'skip)
                (setf (oref session current-item) nil)
                nil)                      ; skip this item
               (t
                (cond
                 ((<= result org-drill-failure-quality)
                  (if (oref session again-entries)
                      (setf (oref session again-entries)
                            (org-drill-shuffle (oref session again-entries))))
                  (org-drill-push-end m (oref session again-entries)))
                 (t
                  (push m (oref session done-entries))))
                (setf (oref session current-item) nil)))))))))))

(defun org-drill-final-report (session)
  (let* ((qualities (oref session qualities))
         (pass-percent
          (round (* 100 (cl-count-if (lambda (qual)
                                       (> qual org-drill-failure-quality))
                                     qualities))
                 (max 1 (length qualities))))
         (prompt nil)
         (max-mini-window-height 0.6))
    (setq prompt
          (format
           "%d items reviewed. Session duration %s.
Recall of reviewed items:
 Excellent (5):     %3d%%   |   Near miss (2):      %3d%%
 Good (4):          %3d%%   |   Failure (1):        %3d%%
 Hard (3):          %3d%%   |   Abject failure (0): %3d%%

You successfully recalled %d%% of reviewed items (quality > %s)
%d/%d items still await review (%s, %s, %s, %s, %s).
Tomorrow, %d more items will become due for review.
Session finished. Press a key to continue..."
           (length (oref session done-entries))
           (format-seconds "%h:%.2m:%.2s"
                           (- (float-time (current-time))
                              (oref session start-time)))
           (round (* 100 (cl-count 5 qualities))
                  (max 1 (length qualities)))
           (round (* 100 (cl-count 2 qualities))
                  (max 1 (length qualities)))
           (round (* 100 (cl-count 4 qualities))
                  (max 1 (length qualities)))
           (round (* 100 (cl-count 1 qualities))
                  (max 1 (length qualities)))
           (round (* 100 (cl-count 3 qualities))
                  (max 1 (length qualities)))
           (round (* 100 (cl-count 0 qualities))
                  (max 1 (length qualities)))
           pass-percent
           org-drill-failure-quality
           (org-drill-pending-entry-count session)
           (+ (org-drill-pending-entry-count session)
              (oref session dormant-entry-count))
           (propertize
            (format "%d failed"
                    (+ (length (oref session failed-entries))
                       (length (oref session again-entries))))
            'face `(:foreground ,org-drill-failed-count-color))
           (propertize
            (format "%d overdue"
                    (length (oref session overdue-entries)))
            'face `(:foreground ,org-drill-failed-count-color))
           (propertize
            (format "%d new"
                    (length (oref session new-entries)))
            'face `(:foreground ,org-drill-new-count-color))
           (propertize
            (format "%d young"
                    (length (oref session young-mature-entries)))
            'face `(:foreground ,org-drill-mature-count-color))
           (propertize
            (format "%d old"
                    (length (oref session old-mature-entries)))
            'face `(:foreground ,org-drill-mature-count-color))
           (oref session due-tomorrow-count)
           ))

    (while (not (input-pending-p))
      (message "%s" prompt)
      (sit-for 0.5))
    (read-char-exclusive)

    (if (and qualities
             (< pass-percent (- 100 org-drill-forgetting-index)))
        (read-char-exclusive
         (format
          "%s
You failed %d%% of the items you reviewed during this session.
%d (%d%%) of all items scanned were overdue.

Are you keeping up with your items, and reviewing them
when they are scheduled? If so, you may want to consider
lowering the value of `org-drill-learn-fraction' slightly in
order to make items appear more frequently over time."
          (propertize "WARNING!" 'face 'org-warning)
          (- 100 pass-percent)
          (oref session overdue-entry-count)
          (round (* 100 (oref session overdue-entry-count))
                 (+ (oref session dormant-entry-count)
                    (oref session due-entry-count))))
         ))))

(defun org-drill-free-markers (session markers)
  "MARKERS is a list of markers, all of which will be freed (set to
point nowhere). Alternatively, MARKERS can be 't', in which case
all the markers used by Org-Drill will be freed."
  (dolist (m (if (eql t markers)
                 (append  (oref session done-entries)
                          (oref session new-entries)
                          (oref session failed-entries)
                          (oref session again-entries)
                          (oref session overdue-entries)
                          (oref session young-mature-entries)
                          (oref session old-mature-entries))
               markers))
    (set-marker m nil)))

;;; overdue-data is a list of entries, each entry has the form (POS DUE AGE)
;;; where POS is a marker pointing to the start of the entry, and
;;; DUE is a number indicating how many days ago the entry was due.
;;; AGE is the number of days elapsed since item creation (nil if unknown).
;;; if age > lapse threshold (default 90), sort by age (oldest first)
;;; if age < lapse threshold, sort by due (biggest first)
(defun org-drill-order-overdue-entries (session)
  (let* ((lapsed-days (if org-drill--lapse-very-overdue-entries-p
                          90 most-positive-fixnum))
         (not-lapsed (cl-remove-if (lambda (a) (> (or (cl-second a) 0) lapsed-days))
                                   (oref session overdue-data)))
         (lapsed (cl-remove-if-not
                  (lambda (a) (> (or (cl-second a) 0)
                                 lapsed-days))
                  (oref session overdue-data))))
    (setf (oref session overdue-entries)
          (mapcar 'first
                  (append
                   (sort (org-drill-shuffle not-lapsed)
                         (lambda (a b) (> (cl-second a) (cl-second b))))
                   (sort lapsed
                         (lambda (a b) (> (cl-third a) (cl-third b)))))))))

(defun org-drill--entry-lapsed-p (session)
  (let ((lapsed-days 90))
    (and org-drill--lapse-very-overdue-entries-p
         (> (or (org-drill-entry-days-overdue session) 0)
            lapsed-days))))

(defun org-drill-entry-days-since-creation (session &optional use-last-interval-p)
  "If USE-LAST-INTERVAL-P is non-nil, and DATE_ADDED is missing, use the
value of DRILL_LAST_INTERVAL instead (as the item's age must be at least
that many days)."
  (let ((timestamp (org-entry-get (point) "DATE_ADDED")))
    (cond
     (timestamp
      (- (org-time-stamp-to-now timestamp)))
     (use-last-interval-p
      (+ (or (org-drill-entry-days-overdue session) 0)
         (read (or (org-entry-get (point) "DRILL_LAST_INTERVAL") "0"))))
     (t nil))))

(defun org-drill-entry-status (session)
  "Returns a list (STATUS DUE AGE) where DUE is the number of days overdue,
zero being due today, -1 being scheduled 1 day in the future.
AGE is the number of days elapsed since the item was created (nil if unknown).
STATUS is one of the following values:
- nil, if the item is not a drill entry, or has an empty body
- :unscheduled
- :future
- :new
- :failed
- :overdue
- :young
- :old
"
  (save-excursion
    (unless (org-at-heading-p)
      (org-back-to-heading))
    (let ((due (org-drill-entry-days-overdue session))
          (age (org-drill-entry-days-since-creation session t))
          (last-int (org-drill-entry-last-interval 1)))
      (list
       (cond
        ((not (org-drill-entry-p))
         nil)
        ((and (org-drill-entry-empty-p)
              (let* ((card-type (org-entry-get (point) "DRILL_CARD_TYPE" nil))
                    (dat (cdr (assoc card-type org-drill-card-type-alist))))
                (or (null card-type)
                    (not (cl-third dat)))))
         ;; body is empty, and this is not a card type where empty bodies are
         ;; meaningful, so skip it.
         nil)
        ((null due)                     ; unscheduled - usually a skipped leech
         :unscheduled)
        ;; ((eql -1 due)
        ;;  :tomorrow)
        ((cl-minusp due)                   ; scheduled in the future
         :future)
        ;; The rest of the stati all denote 'due' items ==========================
        ((<= (org-drill-entry-last-quality 9999)
             org-drill-failure-quality)
         ;; Mature entries that were failed last time are
         ;; FAILED, regardless of how young, old or overdue
         ;; they are.
         :failed)
        ((org-drill-entry-new-p)
         :new)
        ((org-drill-entry-overdue-p session due last-int)
         ;; Overdue status overrides young versus old
         ;; distinction.
         ;; Store marker + due, for sorting of overdue entries
         :overdue)
        ((<= (org-drill-entry-last-interval 9999)
             org-drill-days-before-old)
         :young)
        (t
         :old))
       due age))))

(defun org-drill-progress-message (collected scanned)
  (when (zerop (% scanned 50))
    (let* ((meter-width 40)
           (sym1 (if (cl-oddp (floor scanned (* 50 meter-width))) ?| ?.))
           (sym2 (if (eql sym1 ?.) ?| ?.)))
      (message "Collecting due drill items:%4d %s%s"
               collected
               (make-string (% (ceiling scanned 50) meter-width)
                            sym2)
               (make-string (- meter-width (% (ceiling scanned 50) meter-width))
                            sym1)))))

(defun org-drill-map-entry-function (session)
  (org-drill-progress-message
   (+ (length (oref session new-entries))
      (length (oref session overdue-entries))
      (length (oref session young-mature-entries))
      (length (oref session old-mature-entries))
      (length (oref session failed-entries)))
   (cl-incf (oref session cnt)))
  (when (org-drill-entry-p)
    (org-drill-id-get-create-with-warning session)
    (cl-destructuring-bind (status due age)
        (org-drill-entry-status session)
      (cl-case status
        (:unscheduled
         (cl-incf (oref session dormant-entry-count)))
        ;; (:tomorrow
        ;;  (cl-incf *org-drill-dormant-entry-count*)
        ;;  (cl-incf *org-drill-due-tomorrow-count*))
        (:future
         (cl-incf (oref session dormant-entry-count))
         (if (eq -1 due)
             (cl-incf (oref session due-tomorrow-count))))
        (:new
         (push (point-marker) (oref session new-entries)))
        (:failed
         (push (point-marker) (oref session failed-entries)))
        (:young
         (push (point-marker) (oref session young-mature-entries)))
        (:overdue
         (push (list (point-marker) due age) (oref session overdue-data)))
        (:old
         (push (point-marker) (oref session old-mature-entries)))
        ))))

(defun org-drill-id-get-create-with-warning(session)
  (when (and (not (oref session warned-about-id-creation))
             (null (org-id-get)))
    (message (concat "Creating unique IDs for items "
                     "(slow, but only happens once)"))
    (sit-for 0.5)
    (setf (oref session warned-about-id-creation) t))
  (org-id-get-create))

(defun org-drill (&optional scope drill-match resume-p)
  "Begin an interactive 'drill session'. The user is asked to
review a series of topics (headers). Each topic is initially
presented as a 'question', often with part of the topic content
hidden. The user attempts to recall the hidden information or
answer the question, then presses a key to reveal the answer. The
user then rates his or her recall or performance on that
topic. This rating information is used to reschedule the topic
for future review.

Org-drill proceeds by:

- Finding all topics (headings) in SCOPE which have either been
  used and rescheduled before, or which have a tag that matches
  `org-drill-question-tag'.

- All matching topics which are either unscheduled, or are
  scheduled for the current date or a date in the past, are
  considered to be candidates for the drill session.

- If `org-drill-maximum-items-per-session' is set, a random
  subset of these topics is presented. Otherwise, all of the
  eligible topics will be presented.

SCOPE determines the scope in which to search for
questions.  It accepts the same values as `org-drill-scope',
which see.

DRILL-MATCH, if supplied, is a string specifying a tags/property/
todo query. Only items matching the query will be considered.
It accepts the same values as `org-drill-match', which see.

If RESUME-P is non-nil, resume a suspended drill session rather
than starting a new one."

  (interactive)
  ;; Check org version. Org 7.9.3f introduced a backwards-incompatible change
  ;; to the arguments accepted by `org-schedule'. At the time of writing there
  ;; are still lots of people using versions of org older than this.
  (let ((majorv (cl-first (mapcar 'string-to-number (split-string (org-release) "[.]")))))
    (if (and (< majorv 8)
             (not (string-match-p "universal prefix argument" (documentation 'org-schedule))))
        (read-char-exclusive
         (format "Warning: org-drill requires org mode 7.9.3f or newer. Scheduling of failed cards will not
work correctly with older versions of org mode. Your org mode version (%s) appears to be older than
7.9.3f. Please consider installing a more recent version of org mode." (org-release)))))
  (let ((session
         (if resume-p
             org-drill-last-session
           (setq org-drill-last-session
                 (org-drill-session)))))
    (cl-block org-drill
      (unless resume-p
        (org-drill-free-markers session t)
        (setf (oref session current-item) nil
              (oref session done-entries) nil
              (oref session dormant-entry-count) 0
              (oref session due-entry-count) 0
              (oref session due-tomorrow-count) 0
              (oref session overdue-entry-count) 0
              (oref session new-entries) nil
              (oref session overdue-entries) nil
              (oref session young-mature-entries) nil
              (oref session old-mature-entries) nil
              (oref session failed-entries) nil
              (oref session again-entries) nil
              (oref session start-time) (float-time (current-time))))
      (unwind-protect
          (save-excursion
            (unless resume-p
              (let ((org-trust-scanner-tags t))
                (org-drill-map-entries
                 (apply-partially #'org-drill-map-entry-function session)
                 scope drill-match)
                (org-drill-order-overdue-entries session)
                (setf (oref session overdue-entry-count)
                      (length (oref session overdue-entries)))))
            (setf (oref session due-entry-count)
                  (org-drill-pending-entry-count session))
            (cond
             ((and (null (oref session current-item))
                   (null (oref session new-entries))
                   (null (oref session failed-entries))
                   (null (oref session overdue-entries))
                   (null (oref session young-mature-entries))
                   (null (oref session old-mature-entries)))
              (message "I did not find any pending drill items."))
             (t
              (org-drill-entries session resume-p)
              (message "Drill session finished!")
              (sit-for 1)
              (message nil)
              )))
        (progn
          (unless (oref session end-pos)
            (setf (oref session cram-mode) nil)
            (org-drill-free-markers session (oref session done-entries))))))
    (cond
     ((oref session end-pos)
      (when (markerp (oref session end-pos))
        (org-drill-goto-entry (oref session end-pos))
        (org-reveal)
        (org-show-entry))
      (let ((keystr (org-drill-command-keybinding-to-string 'org-drill-resume)))
        (message
         "You can continue the drill session with the command `org-drill-resume'.%s"
         (if keystr (format "\nYou can run this command by pressing %s." keystr)
           ""))))
     (t
      (org-drill-final-report session)
      (if (eql 'sm5 org-drill-spaced-repetition-algorithm)
          (persist-save 'org-drill-sm5-optimal-factor-matrix))
      (if org-drill-save-buffers-after-drill-sessions-p
          (save-some-buffers))
      (message "Drill session finished!")
      (sit-for 1)
      (message nil)
      ))))

(defun org-drill-cram (&optional scope drill-match)
  "Run an interactive drill session in 'cram mode'. In cram mode,
all drill items are considered to be due for review, unless they
have been reviewed within the last `org-drill-cram-hours'
hours."
  (interactive)
  (setq (oref session cram-mode) t)
  (org-drill scope drill-match))

(defun org-drill-cram-tree ()
  "Run  an interactive drill session in 'cram mode' using subtree at point.

See also, `org-drill-cram' and `org-drill-tree'."
  (interactive)
  (org-drill-cram 'tree))

(defun org-drill-tree ()
  "Run an interactive drill session using drill items within the
subtree at point."
  (interactive)
  (org-drill 'tree))

(defun org-drill-directory ()
  "Run an interactive drill session using drill items from all org
files in the same directory as the current file."
  (interactive)
  (org-drill 'directory))

(defun org-drill-again (&optional scope drill-match)
  "Run a new drill session, but try to use leftover due items that
were not reviewed during the last session, rather than scanning for
unreviewed items. If there are no leftover items in memory, a full
scan will be performed."
  (interactive)
  (let ((session org-drill-last-session))
    (setf (oref session cram-mode) nil)
    (cond
     ((cl-plusp (org-drill-pending-entry-count session))
      (org-drill-free-markers session (oref session done-entries))
      (if (markerp (oref session current-item))
          (set-marker (oref session current-item) nil))
      (setf (oref session start-time) (float-time (current-time)))
      (setf (oref session done-entries) nil
            (oref session current-item) nil)
      (org-drill scope drill-match t))
     (t
      (org-drill scope drill-match)))))

(defun org-drill-resume ()
  "Resume a suspended drill session. Sessions are suspended by
exiting them with the `edit' or `quit' options."
  (interactive)
  (let ((session org-drill-last-session))
    (cond
     ((org-drill-entries-pending-p session)
      (org-drill nil nil t))
     ((and (cl-plusp (org-drill-pending-entry-count session))
           ;; Current drill session is finished, but there are still
           ;; more items which need to be reviewed.
           (y-or-n-p (format
                      "You have finished the drill session.  However, %d items still
need reviewing.  Start a new drill session? "
                      (org-drill-pending-entry-count session))))
      (org-drill-again))
     (t
      (message "You have finished the drill session.")))))


(defun org-drill-relearn-item ()
  "Make the current item due for revision, and set its last interval to 0.
Makes the item behave as if it has been failed, without actually recording a
failure. This command can be used to 'reset' repetitions for an item."
  (interactive)
  (org-drill-smart-reschedule 4 0))


(defun org-drill-strip-entry-data ()
  (dolist (prop org-drill-scheduling-properties)
    (org-delete-property prop))
  (org-schedule '(4)))


(defun org-drill-strip-all-data (&optional scope)
  "Delete scheduling data from every drill entry in scope. This
function may be useful if you want to give your collection of
entries to someone else.  Scope defaults to the current buffer,
and is specified by the argument SCOPE, which accepts the same
values as `org-drill-scope'."
  (interactive)
  (when (yes-or-no-p
         "Delete scheduling data from ALL items in scope: are you sure?")
    (cond
     ((null scope)
      ;; Scope is the current buffer. This means we can use
      ;; `org-delete-property-globally', which is faster.
      (dolist (prop org-drill-scheduling-properties)
        (org-delete-property-globally prop))
      (org-drill-map-entries (lambda () (org-schedule '(4))) scope))
     (t
      (org-drill-map-entries 'org-drill-strip-entry-data scope)))
    (message "Done.")))


(defun org-drill-add-cloze-fontification ()
  ;; Compute local versions of the regexp for cloze deletions, in case
  ;; the left and right delimiters are redefined locally.
  (setq-local org-drill-cloze-regexp (org-drill--compute-cloze-regexp))
  (setq-local org-drill-cloze-keywords (org-drill--compute-cloze-keywords))
  (when org-drill-use-visible-cloze-face-p
    (add-to-list 'org-font-lock-extra-keywords
                 (cl-first org-drill-cloze-keywords))))


;; Can't add to org-mode-hook, because local variables won't have been loaded
;; yet.

;; (defun org-drill-add-cloze-fontification ()
;;   (when (eql major-mode 'org-mode)
;;     ;; Compute local versions of the regexp for cloze deletions, in case
;;     ;; the left and right delimiters are redefined locally.
;;     (setq-local org-drill-cloze-regexp (org-drill--compute-cloze-regexp))
;;     (setq-local org-drill-cloze-keywords (org-drill--compute-cloze-keywords))
;;     (when org-drill-use-visible-cloze-face-p
;;       (font-lock-add-keywords nil       ;'org-mode
;;                               org-drill-cloze-keywords
;;                               nil))))

;; XXX
;; (add-hook 'hack-local-variables-hook
;;           'org-drill-add-cloze-fontification)
;;
;; (org-drill-add-cloze-fontification)


;;; Synching card collections =================================================
(defvar org-drill-dest-id-table (make-hash-table :test 'equal))

(defun org-drill-copy-entry-to-other-buffer (dest &optional path)
  "Copy the subtree at point to the buffer DEST. The copy will receive
the tag 'imported'."
  (cl-block org-drill-copy-entry-to-other-buffer
    (save-excursion
      (let ((m nil))
        (cl-flet ((paste-tree-here (&optional level)
                                   (org-paste-subtree level)
                                   (org-drill-strip-entry-data)
                                   (org-toggle-tag "imported" 'on)
                                   (org-drill-map-entries
                                    (lambda ()
                                      (let ((id (org-id-get)))
                                        (org-drill-strip-entry-data)
                                        (unless (gethash id org-drill-dest-id-table)
                                          (puthash id (point-marker)
                                                   org-drill-dest-id-table))))
                                    'tree)))
          (unless path
            (setq path (org-get-outline-path)))
          (org-copy-subtree)
          (switch-to-buffer dest)
          (setq m
                (condition-case nil
                    (org-find-olp path t)
                  (error                ; path does not exist in DEST
                   (cl-return-from org-drill-copy-entry-to-other-buffer
                     (cond
                      ((cdr path)
                       (org-drill-copy-entry-to-other-buffer
                        dest (butlast path)))
                      (t
                       ;; We've looked all the way up the path
                       ;; Default to appending to the end of DEST
                       (goto-char (point-max))
                       (newline)
                       (paste-tree-here)))))))
          (goto-char m)
          (outline-next-heading)
          (newline)
          (forward-line -1)
          (paste-tree-here (1+ (or (org-current-level) 0)))
          )))))

(defun org-drill-merge-buffers (src &optional dest ignore-new-items-p)
  "SRC and DEST are two org mode buffers containing drill items.
For each drill item in DEST that shares an ID with an item in SRC,
overwrite scheduling data in DEST with data taken from the item in SRC.
This is intended for use when two people are sharing a set of drill items,
one person has made some updates to the item set, and the other person
wants to migrate to the updated set without losing their scheduling data.

By default, any drill items in SRC which do not exist in DEST are
copied into DEST. We attempt to place the copied item in the
equivalent location in DEST to its location in SRC, by matching
the heading hierarchy. However if IGNORE-NEW-ITEMS-P is non-nil,
we simply ignore any items that do not exist in DEST, and do not
copy them across."
  (interactive "bImport scheduling info from which buffer?")
  (unless dest
    (setq dest (current-buffer)))
  (setq src (get-buffer src)
        dest (get-buffer dest))
  (when (yes-or-no-p
         (format
          (concat "About to overwrite all scheduling data for drill items in `%s' "
                  "with information taken from matching items in `%s'. Proceed? ")
          (buffer-name dest) (buffer-name src)))
    ;; Compile list of all IDs in the destination buffer.
    (clrhash org-drill-dest-id-table)
    (with-current-buffer dest
      (org-drill-map-entries
       (lambda ()
         (let ((this-id (org-id-get)))
           (when this-id
             (puthash this-id (point-marker) org-drill-dest-id-table))))
       'file))
    ;; Look through all entries in source buffer.
    (with-current-buffer src
      (org-drill-map-entries
       (lambda ()
         (let ((id (org-id-get))
               (last-quality nil) (last-reviewed nil)
               (scheduled-time nil))
           (cond
            ((or (null id)
                 (not (org-drill-entry-p)))
             nil)
            ((gethash id org-drill-dest-id-table)
             ;; This entry matches an entry in dest. Retrieve all its
             ;; scheduling data, then go to the matching location in dest
             ;; and write the data.
             (let ((marker (gethash id org-drill-dest-id-table)))
               (cl-destructuring-bind (last-interval repetitions failures
                                                  total-repeats meanq ease)
                   (org-drill-get-item-data)
                 (setq last-reviewed (org-entry-get (point) "DRILL_LAST_REVIEWED")
                       last-quality (org-entry-get (point) "DRILL_LAST_QUALITY")
                       scheduled-time (org-get-scheduled-time (point)))
                 (save-excursion
                   ;; go to matching entry in destination buffer
                   (switch-to-buffer (marker-buffer marker))
                   (goto-char marker)
                   (org-drill-strip-entry-data)
                   (unless (zerop total-repeats)
                     (org-drill-store-item-data last-interval repetitions failures
                                                total-repeats meanq ease)
                     (if last-quality
                         (org-set-property "LAST_QUALITY" last-quality)
                       (org-delete-property "LAST_QUALITY"))
                     (if last-reviewed
                         (org-set-property "LAST_REVIEWED" last-reviewed)
                       (org-delete-property "LAST_REVIEWED"))
                     (if scheduled-time
                         (org-schedule nil scheduled-time)))))
               (remhash id org-drill-dest-id-table)
               (set-marker marker nil)))
            (t
             ;; item in SRC has ID, but no matching ID in DEST.
             ;; It must be a new item that does not exist in DEST.
             ;; Copy the entire item to the *end* of DEST.
             (unless ignore-new-items-p
               (org-drill-copy-entry-to-other-buffer dest))))))
       'file))
    ;; Finally: there may be some items in DEST which are not in SRC, and
    ;; which have been scheduled by another user of DEST. Clear out the
    ;; scheduling info from all the unmatched items in DEST.
    (with-current-buffer dest
      (maphash (lambda (_id m)
                 (goto-char m)
                 (org-drill-strip-entry-data)
                 (set-marker m nil))
               org-drill-dest-id-table))))



;;; Card types for learning languages =========================================

;;; `conjugate' card type =====================================================
;;; See spanish.org for usage

(defvar org-drill-verb-tense-alist
  '(("present" "tomato")
    ("simple present" "tomato")
    ("present indicative" "tomato")
    ;; past tenses
    ("past" "purple")
    ("simple past" "purple")
    ("preterite" "purple")
    ("imperfect" "darkturquoise")
    ("present perfect" "royalblue")
    ;; future tenses
    ("future" "green")
    ;; moods (backgrounds).
    ("indicative" nil)                  ; default
    ("subjunctive" "medium blue")
    ("conditional" "grey30")
    ("negative imperative" "red4")
    ("positive imperative" "darkgreen")
    )
  "Alist where each entry has the form (TENSE COLOUR), where
TENSE is a string naming a tense in which verbs can be
conjugated, and COLOUR is a string specifying a foreground colour
which will be used by `org-drill-present-verb-conjugation' and
`org-drill-show-answer-verb-conjugation' to fontify the verb and
the name of the tense.")

(defun org-drill-get-verb-conjugation-info ()
  "Auxiliary function used by `org-drill-present-verb-conjugation' and
`org-drill-show-answer-verb-conjugation'."
  (let ((infinitive (org-entry-get (point) "VERB_INFINITIVE" t))
        (inf-hint (org-entry-get (point) "VERB_INFINITIVE_HINT" t))
        (translation (org-entry-get (point) "VERB_TRANSLATION" t))
        (tense (org-entry-get (point) "VERB_TENSE" nil))
        (mood (org-entry-get (point) "VERB_MOOD" nil))
        (highlight-face nil))
    (unless (and infinitive translation (or tense mood))
      (error "Missing information for verb conjugation card (%s, %s, %s, %s) at %s"
             infinitive translation tense mood (point)))
    (setq tense (if tense (downcase (car (read-from-string tense))))
          mood (if mood (downcase (car (read-from-string mood))))
          infinitive (car (read-from-string infinitive))
          inf-hint (if inf-hint (car (read-from-string inf-hint)))
          translation (car (read-from-string translation)))
    (setq highlight-face
          (list :foreground
                (or (cl-second (assoc-string tense org-drill-verb-tense-alist t))
                    "hotpink")
                :background
                (or
                 (cl-second (assoc-string mood org-drill-verb-tense-alist t))
                 "black")))
    (setq infinitive (propertize infinitive 'face highlight-face))
    (setq translation (propertize translation 'face highlight-face))
    (if tense (setq tense (propertize tense 'face highlight-face)))
    (if mood (setq mood (propertize mood 'face highlight-face)))
    (list infinitive inf-hint translation tense mood)))

(defun org-drill-present-verb-conjugation (session)
  "Present a drill entry whose card type is 'conjugate'."
  (cl-flet ((tense-and-mood-to-string
             (tense mood)
             (cond
              ((and tense mood)
               (format "%s tense, %s mood" tense mood))
              (tense
               (format "%s tense" tense))
              (mood
               (format "%s mood" mood)))))
    (cl-destructuring-bind (infinitive inf-hint translation tense mood)
        (org-drill-get-verb-conjugation-info)
      (org-drill-present-card-using-text
       session
       (cond
        ((zerop (cl-random 2))
         (format "\nTranslate the verb\n\n%s\n\nand conjugate for the %s.\n\n"
                 infinitive (tense-and-mood-to-string tense mood)))

        (t
         (format "\nGive the verb that means\n\n%s %s\n
and conjugate for the %s.\n\n"
                 translation
                 (if inf-hint (format "  [HINT: %s]" inf-hint) "")
                 (tense-and-mood-to-string tense mood))))))))

(defun org-drill-show-answer-verb-conjugation (session reschedule-fn)
 "Show the answer for a drill item whose card type is 'conjugate'.
RESCHEDULE-FN must be a function that calls `org-drill-reschedule' and
returns its return value."
  (cl-destructuring-bind (infinitive _inf-hint translation tense mood)
      (org-drill-get-verb-conjugation-info)
    (org-drill-with-replaced-entry-heading
     (format "%s of %s ==> %s\n\n"
             (capitalize
              (cond
               ((and tense mood)
                (format "%s tense, %s mood" tense mood))
               (tense
                (format "%s tense" tense))
               (mood
                (format "%s mood" mood))))
             infinitive translation)
     (org-cycle-hide-drawers 'all)
     (funcall reschedule-fn session))))


;;; `decline_noun' card type ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defvar org-drill-noun-gender-alist
  '(("masculine" "dodgerblue")
    ("masc" "dodgerblue")
    ("male" "dodgerblue")
    ("m" "dodgerblue")
    ("feminine" "orchid")
    ("fem" "orchid")
    ("female" "orchid")
    ("f" "orchid")
    ("neuter" "green")
    ("neutral" "green")
    ("neut" "green")
    ("n" "green")
    ))

(defun org-drill-get-noun-info ()
  "Auxiliary function used by `org-drill-present-noun-declension' and
`org-drill-show-answer-noun-declension'."
  (let ((noun (org-entry-get (point) "NOUN" t))
        (noun-hint (org-entry-get (point) "NOUN_HINT" t))
        (noun-root (org-entry-get (point) "NOUN_ROOT" t))
        (noun-gender (org-entry-get (point) "NOUN_GENDER" t))
        (translation (org-entry-get (point) "NOUN_TRANSLATION" t))
        (highlight-face nil))
    (unless (and noun translation)
      (error "Missing information for `decline_noun' card (%s, %s, %s, %s) at %s"
             noun translation noun-hint noun-root (point)))
    (setq noun-root (if noun-root (car (read-from-string noun-root)))
          noun (car (read-from-string noun))
          noun-gender (downcase (car (read-from-string noun-gender)))
          noun-hint (if noun-hint (car (read-from-string noun-hint)))
          translation (car (read-from-string translation)))
    (setq highlight-face
          (list :foreground
                (or (cl-second (assoc-string noun-gender
                                          org-drill-noun-gender-alist t))
                    "red")))
    (setq noun (propertize noun 'face highlight-face))
    (setq translation (propertize translation 'face highlight-face))
    (list noun noun-root noun-gender noun-hint translation)))

(defun org-drill-present-noun-declension (session)
  "Present a drill entry whose card type is 'decline_noun'."
  (cl-destructuring-bind (noun _noun-root noun-gender noun-hint translation)
      (org-drill-get-noun-info)
    (let* ((props (org-entry-properties (point)))
           (definite
             (cond
              ((assoc "DECLINE_DEFINITE" props)
               (propertize (if (org-entry-get (point) "DECLINE_DEFINITE")
                               "definite" "indefinite")
                           'face 'warning))
              (t nil)))
           (plural
            (cond
             ((assoc "DECLINE_PLURAL" props)
              (propertize (if (org-entry-get (point) "DECLINE_PLURAL")
                              "plural" "singular")
                          'face 'warning))
             (t nil))))
      (org-drill-present-card-using-text
       session
       (cond
        ((zerop (cl-random 2))
         (format "\nTranslate the noun\n\n%s (%s)\n\nand list its declensions%s.\n\n"
                 noun noun-gender
                 (if (or plural definite)
                     (format " for the %s %s form" definite plural)
                   "")))
        (t
         (format "\nGive the noun that means\n\n%s %s\n
and list its declensions%s.\n\n"
                 translation
                 (if noun-hint (format "  [HINT: %s]" noun-hint) "")
                 (if (or plural definite)
                     (format " for the %s %s form" definite plural)
                   ""))))))))

(defun org-drill-show-answer-noun-declension (session reschedule-fn)
  "Show the answer for a drill item whose card type is 'decline_noun'.
RESCHEDULE-FN must be a function that calls `org-drill-reschedule' and
returns its return value."
  (cl-destructuring-bind (noun _noun-root noun-gender _noun-hint translation)
      (org-drill-get-noun-info)
    (org-drill-with-replaced-entry-heading
     (format "Declensions of %s (%s) ==> %s\n\n"
             noun noun-gender translation)
     (org-cycle-hide-drawers 'all)
     (funcall reschedule-fn session))))

;;; `spanish_verb' card type ==================================================
;;; Not very interesting, but included to demonstrate how a presentation
;;; function can manipulate which subheading are hidden versus shown.

(defun org-drill-present-spanish-verb (session)
  (let ((prompt nil))
    (org-drill-with-hidden-comments
     (org-drill-with-hidden-cloze-hints
      (org-drill-with-hidden-cloze-text
       (cl-case (cl-random 6)
         ;; PWL 2018-06-22
         ;; As far as I can tell, neither prompt nor reveal-headings
         ;; do anything here. They never seem to appear anyway. But
         ;; this might be because I broke things when cleaning up the
         ;; dynamic binding.
         (0
          (org-drill-hide-all-subheadings-except '("Infinitive"))
          (setq prompt
                (concat "Translate this Spanish verb, and conjugate it "
                        "for the *present* tense.")
                ;;reveal-headings '("English" "Present Tense" "Notes")
                ))
         (1
          (org-drill-hide-all-subheadings-except '("English"))
          (setq prompt (concat "For the *present* tense, conjugate the "
                               "Spanish translation of this English verb.")
                ;;reveal-headings '("Infinitive" "Present Tense" "Notes")
                ))
         (2
          (org-drill-hide-all-subheadings-except '("Infinitive"))
          (setq prompt (concat "Translate this Spanish verb, and "
                               "conjugate it for the *past* tense.")
                ;;reveal-headings '("English" "Past Tense" "Notes")
                ))
         (3
          (org-drill-hide-all-subheadings-except '("English"))
          (setq prompt (concat "For the *past* tense, conjugate the "
                               "Spanish translation of this English verb.")
                ;;reveal-headings '("Infinitive" "Past Tense" "Notes")
                ))
         (4
          (org-drill-hide-all-subheadings-except '("Infinitive"))
          (setq prompt (concat "Translate this Spanish verb, and "
                               "conjugate it for the *future perfect* tense.")
                ;;reveal-headings '("English" "Future Perfect Tense" "Notes")
                ))
         (5
          (org-drill-hide-all-subheadings-except '("English"))
          (setq prompt (concat "For the *future perfect* tense, conjugate the "
                               "Spanish translation of this English verb.")
                ;;reveal-headings '("Infinitive" "Future Perfect Tense" "Notes")
                )))
       (org-cycle-hide-drawers 'all)
       (prog1 (org-drill-presentation-prompt session prompt)
         (org-drill-hide-subheadings-if 'org-drill-entry-p)))))))

;; org-drill :explain: implementations
(defun org-drill-get-explain-text (&optional existing-text)
  "Fetch the explaination texts for this entry.

Explaination text is found in parent entries with an :explain:
tag. If there are multiple parents entries with such a tag, all
of them are returned.

Returns a list of strings."
  (save-excursion
    (save-restriction
      (widen)
      (if (>= 1 (funcall outline-level))
          existing-text
        (outline-up-heading 1 t)
        (if (org-drill-explain-entry-p t)
            (org-drill-get-explain-text
             (cons
              (org-drill-get-entry-text)
              existing-text))
          existing-text)))))

(defvar org-drill-explain-overlay nil)

(defun org-drill-explain-entry-p (&optional no-inherit)
  "Returns non-nil if an entry is associated with explanation"
  (member "explain" (org-get-tags nil no-inherit)))

(defun org-drill-end-of-entry-pos ()
  (save-excursion
    (org-end-of-subtree)
    (point)))

(defun org-drill-explain-answer-presenter ()
  (save-excursion
    (when org-drill-explain-overlay
      (delete-overlay org-drill-explain-overlay))
    (let* ((end (org-drill-end-of-entry-pos))
           (ov (make-overlay
                end end
                (current-buffer))))
      (overlay-put ov 'after-string
                   (format "\n\nExplanation:\n\n%s"
                           (mapconcat 'identity
                                      (org-drill-get-explain-text) "\n\n")))
      (setq org-drill-explain-overlay ov))))

(defun org-drill-explain-cleaner ()
  (when org-drill-explain-overlay
      (delete-overlay org-drill-explain-overlay)))

;;; Leitner Learning
(defvar org-drill-leitner-boxed-entries nil
  "All leitner entries that are currently in an active box.")

(defvar org-drill-leitner-unboxed-entries nil
  "All leitner entries that are not in a box.")

(defvar org-drill-leitner-promote-to-drill-p t)

(defvar org-drill-leitner-completed 0
  "The number of entries that have been completed this time.")

(defvar org-drill-leitner-tag "leitner")

(defun org-drill-sm-or-leitner ()
  (interactive)
  ;; org-drill-again uses org-drill-pending-entry-count to decide
  ;; whether it needs to scan or not.
  (let* ((session
          (or org-drill-last-session (org-drill-session)))
         (pending
          (org-drill-pending-entry-count session)))
    (unless (cl-plusp pending)
      (org-drill-map-entries
       (apply-partially 'org-drill-map-entry-function session)
       nil nil))
    ;; if the overdue entries are not ones we have just created
    (if (> (org-drill-pending-entry-count session) org-drill-leitner-completed)
        ;; we should have scanned previously if we need to
        (progn
          (message "Org Drill: Starting SM learning")
          (sit-for 0.5)
          (setq org-drill-last-session session)
          (org-drill-again))
      (message "Org Drill: Starting leitner learning")
      (sit-for 0.5)
      (org-drill-leitner session))))

(defun org-drill-leitner (&optional session)
  "Perform Leitner learning"
  (interactive)
  (let ((org-drill-leitner-boxed-entries nil)
        (org-drill-leitner-unboxed-entries nil)
        (session (setq org-drill-last-session
                       (or session
                           (org-drill-session))))
        (count 0))
    (org-drill-all-leitner-capture)
    ;; make sure we have enough (or at least the maximum number we
    ;; can) of boxed entities
    (when (<
           (length org-drill-leitner-boxed-entries)
           (- org-drill-maximum-items-per-session count))
      (org-drill-leitner-start-box
       (- org-drill-maximum-items-per-session
          (length org-drill-leitner-boxed-entries)
          count))
      (setq org-drill-leitner-boxed-entries nil)
      (setq org-drill-leitner-unboxed-entries nil)
      (org-drill-all-leitner-capture))
    (pcase
        (catch 'user-exit
          (seq-map
           (lambda (loc)
             (org-drill-goto-entry loc)
             (let ((r (org-drill-leitner-entry session)))
               ;; short circuit if necessary
               (unless (eq t r)
                 (throw 'user-exit (list r loc)))))
           (org-drill-shuffle
            (seq-take org-drill-leitner-boxed-entries
                      org-drill-maximum-items-per-session))))
      (`(quit ,_)  t)
      (`(edit ,loc)
       (org-drill-goto-entry loc)
       (org-reveal)
       (org-show-entry))
      (`,_
       (message "Finished Leitner Learning: %s complete today, %s in process, %s to start"
                org-drill-leitner-completed
                (length org-drill-leitner-boxed-entries)
                (length org-drill-leitner-unboxed-entries))))))

;; take from John Kitchen
(defun org-drill-swap (LIST el1 el2)
  "in LIST swap indices EL1 and EL2 in place"
  (let ((tmp (elt LIST el1)))
    (setf (elt LIST el1) (elt LIST el2))
    (setf (elt LIST el2) tmp)))

(defun org-drill-shuffle (LIST)
  "Shuffle the elements in LIST.
shuffling is done in place."
  (cl-loop for i in (reverse (number-sequence 1 (1- (length LIST))))
        do (let ((j (random (+ i 1))))
             (org-drill-swap LIST i j)))
  LIST)

(defun org-drill-leitner-start-box (number)
  "Box some items for the first time."
  (message "Starting %s new items" number)
  (sit-for 0.25)
  (seq-map
   (lambda (loc)
     (org-drill-goto-entry loc)
     (message "New leitner entry: %s" (org-drill-get-entry-text))
     (sit-for 0.5)
     (org-set-property "DRILL_LEITNER_BOX" "1"))
   (seq-take
    (org-drill-shuffle (seq-copy org-drill-leitner-unboxed-entries))
    number)))

(defun org-drill-map-leitner (func &optional scope)
  "Return all entries marked with leitner tag."
  (org-map-entries
   func (concat "+" "leitner")
   (org-drill-current-scope scope)))

(defun org-drill-all-leitner-capture (&optional scope)
  "Capture all items marked with a leitner tag"
  (let ((org-drill-question-tag org-drill-leitner-tag))
    (org-drill-map-leitner
     (apply-partially #'org-drill-map-leitner-capture (org-drill-session))
     scope)
    (setq org-drill-leitner-boxed-entries
          (nreverse org-drill-leitner-boxed-entries)
          org-drill-leitner-unboxed-entries
          (nreverse org-drill-leitner-unboxed-entries))))

(defun org-drill-map-leitner-capture (session)
  "Capture this entry if it is a valid leitner entry"
  ;; This bit is all rather shared with org-drill-map-entry-function
  (org-drill-progress-message
   (+ (length org-drill-leitner-unboxed-entries)
      (length org-drill-leitner-boxed-entries))
   (cl-incf (oref session cnt)))
  (when (org-drill-entry-p)
    (org-drill-id-get-create-with-warning session)
    (let ((leitner-box (org-entry-get (point) "DRILL_LEITNER_BOX" nil)))
      (cond
       ;; Entries we have not looked at yet
       ((null leitner-box)
        (push (point-marker) org-drill-leitner-unboxed-entries))
       ;; Entries we have finished with
       ((> (string-to-number leitner-box) 5) nil)
       ((and
         (>= (string-to-number leitner-box) 0)
         (<= (string-to-number leitner-box) 5))
        (push (point-marker)
              org-drill-leitner-boxed-entries))))))

(defun org-drill-leitner-entry (session)
  "Interactive drill for the current entry."
  (let ((org-drill-question-tag org-drill-leitner-tag))
    (org-drill-entry-f session #'org-drill-leitner-rebox)))

(defun org-drill-leitner-rebox (session)
  "Returns quality rating (0-5), or nil if the user quit."
  (let ((ch nil)
        (input nil)
        (typed-answer-statement (if (oref session typed-answer)
                                    (format "Your answer: %s\n"
                                            (oref session typed-answer))
                                  ""))
        (key-prompt (format "(0-5, %c=help, %c=edit, %c=tags, %c=quit)"
                            org-drill--help-key
                            org-drill--edit-key
                            org-drill--tags-key
                            org-drill--quit-key)))
    (save-excursion
      (while (not (memq ch (list org-drill--quit-key
                                 org-drill--edit-key
                                 7          ; C-g
                                 ?0 ?1 ?2 ?3 ?4 ?5)))
        (run-hooks 'org-drill-display-answer-hook)
        (setq input (org-drill--read-key-sequence
                     (if (eq ch org-drill--help-key)
                         (format "0-2 Means you have forgotten the item.
3-5 Means you have remembered the item.

0 - Completely forgot. (Back to Zero)
1 - Even after seeing the answer, it still took a bit to sink in (Back to one)
2 - After seeing the answer, you remembered it (Remain in current Box)
3 - It took you awhile, but you finally remembered. (Forward One)
4 - After a little bit of thought you remembered. (Forward One)
5 - You remembered the item really easily. (Forward One)

%sHow well did you do? %s"
                                 typed-answer-statement
                                 key-prompt)
                       (format "%sHow well did you do? %s"
                               typed-answer-statement key-prompt))))
        ;; All this is shared with drill-reschedule. And what does it do?
        (cond
         ((stringp input)
          (setq ch (elt input 0)))
         ((and (vectorp input) (symbolp (elt input 0)))
          (cl-case (elt input 0)
            (up (ignore-errors (forward-line -1)))
            (down (ignore-errors (forward-line 1)))
            (left (ignore-errors (backward-char)))
            (right (ignore-errors (forward-char)))
            (prior (ignore-errors (scroll-down))) ; pgup
            (next (ignore-errors (scroll-up)))))  ; pgdn
         ((and (vectorp input) (listp (elt input 0))
               (eventp (elt input 0)))
          (cl-case (car (elt input 0))
            (wheel-up (ignore-errors (mwheel-scroll (elt input 0))))
            (wheel-down (ignore-errors (mwheel-scroll (elt input 0)))))))
        (if (eql ch org-drill--tags-key)
            (org-set-tags-command))))
    (cond
     ((and (>= ch ?0) (<= ch ?5))
      (let ((current-box
             (string-to-number
              (org-entry-get (point) "DRILL_LEITNER_BOX" nil))))
        (cond
         ((or (= ch ?0))
          (message "Refiled down to box: 1")
          (org-set-property "DRILL_LEITNER_BOX" "1"))
         ((or (= ch ?1))
          (let ((box
                 (format
                  "%s"
                  (if (eq current-box 1)
                      1
                    (- current-box 1)))))
            (message "Refiled down to box: %s" box)
            (sit-for 0.3)
            (org-set-property
             "DRILL_LEITNER_BOX" box)))
         ((= ch ?2)
          ;; neither promote nor demote
          (message "Remaining in box: %s" current-box)
          (sit-for 0.3))
         ((or (= ch ?3) (= ch ?4)(= ch ?5))
          (org-drill-leitner-promote current-box)))
        t))
     ((= ch org-drill--edit-key)
      'edit)
     ((= ch org-drill--quit-key)
      'quit)
     (t nil))))

(defun org-drill-leitner-promote (current-box)
  "Promote the current entry to drill or otherwise"
  (when (eq current-box 5)
    (org-toggle-tag "leitner" 'off)
    (when org-drill-leitner-promote-to-drill-p
      (org-toggle-tag "drill" 'on))
    (cl-incf org-drill-leitner-completed))
  (org-set-property
   "DRILL_LEITNER_BOX"
   (format
    "%s"
    (+ current-box 1)))
  (message "Refiled to box: %s" (+ current-box 1))
  (sit-for 0.3))

;;; Test functions
(defun org-drill-test-display ()
  (interactive)
  ;; set tag to anything
  (org-toggle-tag "zysygy")
  (unwind-protect
      (let ((org-drill-question-tag "zysygy"))
        (org-drill-entry-f (org-drill-session)
                           #'org-drill-test-display-rescheduler))
    (org-toggle-tag "zysygy")))

(defun org-drill-test-display-rescheduler (session)
  (run-hooks 'org-drill-display-answer-hook)
  ;; Normally, the rescheduler waits for input at this point
  (read-key-sequence "Press anything to continue"))

(defun org-drill-leitner-vs-drill-entries ()
  (interactive)
  (let
      ((number-drill-entries 0)
       (org-drill-leitner-unboxed-entries nil)
       (org-drill-leitner-boxed-entries nil))
    (org-drill-all-leitner-capture)
    (org-drill-map-entries
     (lambda ()
       (setq number-drill-entries (+ 1 number-drill-entries)))
     nil nil)
    (message "There are %s drill entries\nThere are %s leitner entries\nA total of %s entries."
             number-drill-entries
             (+ (length org-drill-leitner-boxed-entries)
                (length org-drill-leitner-unboxed-entries))
             (+ number-drill-entries
                (+ (length org-drill-leitner-boxed-entries)
                   (length org-drill-leitner-unboxed-entries))))))

(provide 'org-drill)
;;; org-drill.el ends here
