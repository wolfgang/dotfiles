;;; denote-org.el --- Denote extensions for Org mode -*- lexical-binding: t -*-

;; Copyright (C) 2024-2025  Free Software Foundation, Inc.

;; Author: Protesilaos Stavrou <info@protesilaos.com>
;; Maintainer: Protesilaos Stavrou <info@protesilaos.com>
;; URL: https://github.com/protesilaos/denote-org
;; Version: 0.1.1
;; Package-Requires: ((emacs "28.1") (denote "4.0.0"))

;; This file is NOT part of GNU Emacs.

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Optional extensions to Denote that work specifically with Org mode.

;;; Code:

(require 'denote)
(require 'org)

(defgroup denote-org ()
  "Optional extensions to Denote that work specifically with Org mode."
  :group 'denote
  :link '(info-link "(denote) top")
  :link '(info-link "(denote-org) top")
  :link '(url-link :tag "Denote homepage" "https://protesilaos.com/emacs/denote")
  :link '(url-link :tag "Denote Org homepage" "https://protesilaos.com/emacs/denote-org"))

;;;; Link to file and heading

(defun denote-org--get-outline (file)
  "Return `outline-regexp' headings and line numbers of FILE."
  (with-current-buffer (find-file-noselect file)
    (let ((outline-regexp (format "^\\(?:%s\\)" (or (bound-and-true-p outline-regexp) "\\*+ ")))
          candidates)
      (save-excursion
        (goto-char (point-min))
        (while (if (bound-and-true-p outline-search-function)
                   (funcall outline-search-function)
                 (re-search-forward outline-regexp nil t))
          (push
           ;; NOTE 2024-01-20: The -5 (minimum width) is a
           ;; sufficiently high number to keep the alignment
           ;; consistent in most cases.  Larger files will simply
           ;; shift the heading text in minibuffer, but this is not an
           ;; issue anymore.
           (format "%-5s %s"
                   (line-number-at-pos (point))
                   (buffer-substring-no-properties (line-beginning-position) (line-end-position)))
           candidates)
          (goto-char (1+ (line-end-position)))))
      (if candidates
          (nreverse candidates)
        (user-error "No outline")))))

(define-obsolete-function-alias
  'denote-org--outline-prompt
  'denote-org-outline-prompt
  "3.1.0")

(defun denote-org-outline-prompt (&optional file)
  "Prompt for outline among headings retrieved by `denote-org--get-outline'.
With optional FILE use the outline of it, otherwise use that of
the current file."
  (let ((current-file (or file buffer-file-name)))
    (completing-read
     (format "Select heading inside `%s': "
             (propertize (file-name-nondirectory current-file) 'face 'denote-faces-prompt-current-name))
     (denote--completion-table-no-sort 'imenu (denote-org--get-outline current-file))
     nil :require-match)))

(defun denote-org--get-heading-and-id-from-line (line file)
  "Return heading text and CUSTOM_ID from the given LINE in FILE."
  (with-current-buffer (find-file-noselect file)
    (save-excursion
      (goto-char (point-min))
      (forward-line (1- line))
      (cons (denote-link-ol-get-heading)
            (if (eq denote-org-store-link-to-heading 'context)
                (org-entry-get (point) "CUSTOM_ID")
              (denote-link-ol-get-id))))))

(defun denote-org-format-link-with-heading (file heading-id description &optional format)
  "Prepare link to FILE with HEADING-ID using DESCRIPTION.
Optional FORMAT is the exact link pattern to use."
  (when (region-active-p)
    (setq description (buffer-substring-no-properties (region-beginning) (region-end)))
    (denote--delete-active-region-content))
  (format
   (or format "[[denote:%s::#%s][%s]]")
   (denote-retrieve-filename-identifier file)
   heading-id
   description))

(define-obsolete-function-alias
  'denote-org-extras-link-to-heading
  'denote-org-link-to-heading
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-link-to-heading ()
  "Link to file and then specify a heading to extend the link to.

The resulting link has the following pattern:

[[denote:IDENTIFIER::#ORG-HEADING-CUSTOM-ID]][Description::Heading text]].

Because only Org files can have links to individual headings,
limit the list of possible files to those which include the .org
file extension (remember that Denote works with many file types,
per the user option `denote-file-type').

The user option `denote-org-store-link-to-heading'
determined whether the `org-store-link' function can save a link
to the current heading.  Such links look the same as those of
this command, though the functionality defined herein is
independent of it.

To only link to a file, use the `denote-link' command.

Also see `denote-org-backlinks-for-heading'."
  (declare (interactive-only t))
  (interactive nil org-mode)
  (unless (derived-mode-p 'org-mode)
    (user-error "Links to headings only work between Org files"))
  (let ((context-p (eq denote-org-store-link-to-heading 'context)))
    (when-let* ((file (denote-file-prompt ".*\\.org"))
                (file-text (denote-get-link-description file))
                (heading (denote-org-outline-prompt file))
                (line (string-to-number (car (split-string heading "\t"))))
                (heading-data (denote-org--get-heading-and-id-from-line line file))
                (heading-text (car heading-data))
                (heading-id (if (and context-p (null (cdr heading-data)))
                                heading-text
                              (cdr heading-data)))
                (description (denote-link-format-heading-description file-text heading-text)))
      (insert
       (denote-org-format-link-with-heading
        file
        heading-id
        description
        (when (equal heading-text heading-id)
          "[[denote:%s::*%s][%s]]"))))))

;;;; Heading backlinks

(defun denote-org--get-file-id-and-heading-id-or-context ()
  "Return link to current file and heading.
If a CUSTOM_ID is present and the value of the user option
`denote-org-store-link-to-heading' is set to `context', then return a
regexp that matches both the CUSTOM_ID and the context of the current
heading.  This looks like:

    \\(ID::*HEADING-TEXT\\|ID::#HEADING-ID\\)

If CUSTOM_ID is present but `denote-org-store-link-to-heading' is not
set to `context', then return a patternf of the following form:

    ID::#HEADING-ID"
  (when-let* ((id (denote-retrieve-filename-identifier-with-error buffer-file-name)))
    (let ((context-p (eq denote-org-store-link-to-heading 'context))
          (heading-id (org-entry-get (point) "CUSTOM_ID")))
      (cond
       ((and context-p heading-id)
        (format "\\(%s::%s%s\\|#%s\\)" id (shell-quote-argument "*") (denote-link-ol-get-heading) heading-id))
       (context-p
        (concat id "::" (shell-quote-argument "*") (denote-link-ol-get-heading)))
       (heading-id
        (concat id "::#" heading-id))
       (t
        (error "No way to get link to a heading at point in file `%s'" buffer-file-name))))))

(defun denote-org--get-backlinks-buffer-name (text)
  "Format a buffer name for `denote-org-backlinks-for-heading' with TEXT."
  (format "*Denote HEADING backlinks for %S*" text))

(defun denote-org--get-backlinks-for-heading (file-and-heading-id)
  "Get backlinks to FILE-AND-HEADING-ID as a list of strings."
  (when-let* ((files (denote-directory-files nil :omit-current :text-only))
              (xref-file-name-display 'abs)
              (matches-in-files (xref-matches-in-files file-and-heading-id files))
              (xref-alist (xref--analyze matches-in-files)))
    (mapcar
     (lambda (x)
       (denote-get-file-name-relative-to-denote-directory (car x)))
     xref-alist)))

(define-obsolete-function-alias
  'denote-org-extras-backlinks-for-heading
  'denote-org-backlinks-for-heading
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-backlinks-for-heading ()
  "Produce backlinks for the current heading.
This otherwise has the same behaviour as `denote-backlinks'---refer to
that for the details.

Also see `denote-org-link-to-heading'."
  (interactive)
  (when-let* ((heading-id (denote-org--get-file-id-and-heading-id-or-context))
              (heading-text (substring-no-properties (denote-link-ol-get-heading))))
    (denote-link--prepare-backlinks heading-id ".*\\.org" (denote-org--get-backlinks-buffer-name heading-text))))

;;;; Extract subtree into its own note

(defun denote-org--get-heading-date ()
  "Try to return a timestamp for the current Org heading.
This can be used as the value for the DATE argument of the
`denote' command."
  (when-let* ((pos (point))
              (timestamp (or (org-entry-get pos "DATE")
                             (org-entry-get pos "CREATED")
                             (org-entry-get pos "CLOSED"))))
    (date-to-time timestamp)))

(define-obsolete-function-alias
  'denote-org-extras-extract-org-subtree
  'denote-org-extract-org-subtree
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-extract-org-subtree ()
  "Create new Denote note using the current Org subtree as input.
Remove the subtree from its current file and move its contents into a
new Denote file (a subtree is a heading with all of its contents,
including subheadings).

Take the text of the subtree's top level heading and use it as the title
of the new note.

If the heading has any tags, use them as the keywords of the new note.
If the Org file has any #+filetags use them as well (Org's filetags are
inherited by the headings).  If none of these are true and the user
option `denote-prompts' includes an entry for keywords, then prompt for
keywords.  Else do not include any keywords.

If the heading has a PROPERTIES drawer, retain it for further review.

If the heading's PROPERTIES drawer includes a DATE or CREATED property,
or there exists a CLOSED statement with a timestamp value, use that to
derive the date (or date and time) of the new note (if there is only a
date, the time is taken as 00:00).  If more than one of these is
present, the order of preference is DATE, then CREATED, then CLOSED.  If
none of these is present, use the current time.  If the `denote-prompts'
includes an entry for a date, then prompt for a date at this stage (also
see `denote-date-prompt-use-org-read-date').

For the rest, consult the value of the user option `denote-prompts' in
the following scenaria:

- Optionally prompt for a subdirectory, otherwise produce the new note
  in the variable `denote-directory'.

- Optionally prompt for a file signature, otherwise do not use one.

Make the new note an Org file regardless of the value of the user option
`denote-file-type'."
  (interactive nil org-mode)
  (unless (derived-mode-p 'org-mode)
    (user-error "Headings can only be extracted from Org files"))
  (if-let* ((text (org-get-entry))
            (heading (denote-link-ol-get-heading)))
      (let ((tags (org-get-tags))
            (date (denote-org--get-heading-date))
            subdirectory
            signature)
        (dolist (prompt denote-prompts)
          (pcase prompt
            ('keywords (when (not tags) (setq tags (denote-keywords-prompt))))
            ('subdirectory (setq subdirectory (denote-subdirectory-prompt)))
            ('date (when (not date) (setq date (denote-date-prompt))))
            ('signature (setq signature (denote-signature-prompt)))))
        (delete-region (org-entry-beginning-position)
                       (save-excursion (org-end-of-subtree t) (point)))
        (denote heading tags 'org subdirectory date text signature))
    (user-error "No subtree to extract; aborting")))

;;;; Convert links from `:denote' to `:file' and vice versa

(defun denote-org--get-link-type-regexp (type)
  "Return regexp for Org link TYPE.
TYPE is a symbol of either `file' or `denote'.

The regexp consists of four groups.  Group 1 is the link type, 2
is the target, 3 is the target's search terms, and 4 is the
description."
  (let ((group-1))
    (pcase type
      ('denote (setq group-1 "denote"))
      ('file (setq group-1 "file"))
      (_ (error "`%s' is an unknown link type" type)))
    (format "\\[\\[\\(?1:%s:\\)\\(?:\\(?2:.*?\\)\\(?3:::.*\\)?\\]\\|\\]\\)\\(?4:\\[\\(?:.*?\\)\\]\\)?\\]" group-1)))

(defun denote-org--get-path (id)
  "Return file path to ID according to `org-link-file-path-type'."
  (if (or (eq org-link-file-path-type 'adaptive)
          (eq org-link-file-path-type 'relative))
      (denote-get-relative-path-by-id id)
    (denote-get-path-by-id id)))

(define-obsolete-function-alias
  'denote-org-extras-convert-links-to-file-type
  'denote-org-convert-links-to-file-type
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-convert-links-to-file-type ()
  "Convert denote: links to file: links in the current Org buffer.
Ignore all other link types.  Also ignore links that do not
resolve to a file in the variable `denote-directory'."
  (interactive nil org-mode)
  (if (derived-mode-p 'org-mode)
      (save-excursion
        (let ((count 0))
          (goto-char (point-min))
          (while (re-search-forward (denote-org--get-link-type-regexp 'denote) nil :no-error)
            (let* ((id (match-string-no-properties 2))
                   (search (or (match-string-no-properties 3) ""))
                   (desc (or (match-string-no-properties 4) ""))
                   (file (save-match-data (denote-org--get-path id))))
              (when file
                (let ((new-text (if desc
                                    (format "[[file:%s%s]%s]" file search desc)
                                  (format "[[file:%s%s]]" file search))))
                  (replace-match new-text :fixed-case :literal)
                  (setq count (1+ count))))))
          (message "Converted %d `denote:' links to `file:' links" count)))
    (user-error "The current file is not using Org mode")))

(define-obsolete-function-alias
  'denote-org-extras-convert-links-to-denote-type
  'denote-org-convert-links-to-denote-type
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-convert-links-to-denote-type ()
  "Convert file: links to denote: links in the current Org buffer.
Ignore all other link types.  Also ignore file: links that do not
point to a file with a Denote file name."
  (interactive nil org-mode)
  (if (derived-mode-p 'org-mode)
      (save-excursion
        (let ((count 0))
          (goto-char (point-min))
          (while (re-search-forward (denote-org--get-link-type-regexp 'file) nil :no-error)
            (let* ((file (match-string-no-properties 2))
                   (search (or (match-string-no-properties 3) ""))
                   (desc (or (match-string-no-properties 4) ""))
                   (id (save-match-data (denote-retrieve-filename-identifier file))))
              (when id
                (let ((new-text (if desc
                                    (format "[[denote:%s%s]%s]" id search desc)
                                  (format "[[denote:%s%s]]" id search))))
                  (replace-match new-text :fixed-case :literal)
                  (setq count (1+ count))))))
          (message "Converted %d `file:' links to `denote:' links" count)))
    (user-error "The current file is not using Org mode")))

;;;; Org dynamic blocks

;; NOTE 2024-01-22 12:26:13 +0200: The following is copied from the
;; now-deleted denote-org-dblock.el.  Its original author was Elias
;; Storms <elias.storms@gmail.com>, with substantial contributions and
;; further developments by me (Protesilaos).

;; This section defines Org dynamic blocks using the facility described
;; in the Org manual.  Evaluate this:
;;
;;    (info "(org) Dynamic Blocks")
;;
;; The dynamic blocks defined herein are documented at length in the
;; Denote manual.  See the following node and its subsections:
;;
;;    (info "(denote) Use Org dynamic blocks")

;;;;; Common helper functions

(defun denote-org-dblock--files (files-matching-regexp &optional sort-by-component reverse exclude-regexp)
  "Return list of FILES-MATCHING-REGEXP in variable `denote-directory'.
SORT-BY-COMPONENT, REVERSE, EXCLUDE-REGEXP have the same meaning as
`denote-sort-get-directory-files'.  If both are nil, do not try to
perform any sorting.

Also see `denote-org-dblock--files-missing-only'."
  (cond
   ((and sort-by-component reverse)
    (denote-sort-get-directory-files files-matching-regexp sort-by-component reverse :omit-current exclude-regexp))
   (sort-by-component
    (denote-sort-get-directory-files files-matching-regexp sort-by-component nil :omit-current exclude-regexp))
   (reverse
    (denote-sort-get-directory-files files-matching-regexp :no-component-specified reverse :omit-current exclude-regexp))
   (t
    (denote-directory-files files-matching-regexp :omit-current nil exclude-regexp))))

(defun denote-org-dblock--get-missing-links (regexp)
  "Return list of missing links to all notes matching REGEXP.
Missing links are those for which REGEXP does not have a match in
the current buffer."
  (let ((found-files (denote-directory-files regexp :omit-current))
        (linked-files (denote-link--expand-identifiers denote-org-link-in-context-regexp)))
    (if-let* ((final-files (seq-difference found-files linked-files)))
        final-files
      (message "All links matching `%s' are present" regexp)
      '())))

(defun denote-org-dblock--files-missing-only (files-matching-regexp &optional sort-by-component reverse)
  "Return list of missing links to FILES-MATCHING-REGEXP.
SORT-BY-COMPONENT and REVERSE have the same meaning as
`denote-sort-files'.  If both are nil, do not try to perform any
sorting.

Also see `denote-org-dblock--files'."
  (denote-sort-files
   (denote-org-dblock--get-missing-links files-matching-regexp)
   sort-by-component
   reverse))

;;;;; Dynamic block to insert links

(define-obsolete-function-alias
  'denote-org-extras-dblock-insert-links
  'denote-org-dblock-insert-links
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-dblock-insert-links (regexp)
  "Create Org dynamic block to insert Denote links matching REGEXP."
  (interactive
   (list
    (denote-files-matching-regexp-prompt))
   org-mode)
  (org-create-dblock (list :name "denote-links"
                           :regexp regexp
                           :not-regexp nil
                           :excluded-dirs-regexp nil
                           :sort-by-component nil
                           :reverse-sort nil
                           :id-only nil
                           :include-date nil))
  (org-update-dblock))

;; NOTE 2024-03-30: This is how the autoload is done in org.el.
;;;###autoload
(eval-after-load 'org
  '(progn
     (org-dynamic-block-define "denote-links" 'denote-org-dblock-insert-links)))

;; TODO 2024-12-04: Maybe we can do this for anything that deals with
;; regular expressions that users provide?  I prefer not to do the
;; work if nobody wants it, though I am mentioning this here just in
;; case.
(defun denote-org--parse-rx (regexp)
  "Parse REGEXP as an `rx' argument or string and return string."
  (cond
   ((null regexp)
    nil)
   ((listp regexp)
    (rx-to-string regexp))
   ((stringp regexp)
    regexp)
   (t
    (error "Regexp `%s' is neither a list nor a string" regexp))))

;;;###autoload
(defun org-dblock-write:denote-links (params)
  "Function to update `denote-links' Org Dynamic blocks.
Used by `org-dblock-update' with PARAMS provided by the dynamic block."
  (let* ((rx (denote-org--parse-rx (plist-get params :regexp)))
         (not-rx (denote-org--parse-rx (plist-get params :not-regexp)))
         (sort (plist-get params :sort-by-component))
         (reverse (plist-get params :reverse-sort))
         (include-date (plist-get params :include-date))
         (block-name (plist-get params :block-name))
         (denote-excluded-directories-regexp (or (plist-get params :excluded-dirs-regexp)
                                                 denote-excluded-directories-regexp))
         (files (denote-org-dblock--files rx sort reverse not-rx)))
    (when block-name (insert "#+name: " block-name "\n"))
    (denote-link--insert-links files 'org (plist-get params :id-only) :no-other-sorting include-date)
    (join-line))) ; remove trailing empty line

;;;;; Dynamic block to insert missing links

;; TODO 2024-12-03: Do we need the :not-regexp here?  I think yes,
;; though I prefer to have a user of this kind of dblock send me their
;; feedback.

(define-obsolete-function-alias
  'denote-org-extras-dblock-insert-missing-links
  'denote-org-dblock-insert-missing-links
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-dblock-insert-missing-links (regexp)
  "Create Org dynamic block to insert Denote links matching REGEXP."
  (interactive
   (list
    (denote-files-matching-regexp-prompt))
   org-mode)
  (org-create-dblock (list :name "denote-missing-links"
                           :regexp regexp
                           :excluded-dirs-regexp nil
                           :sort-by-component nil
                           :reverse-sort nil
                           :id-only nil
                           :include-date nil))
  (org-update-dblock))

;; NOTE 2024-03-30: This is how the autoload is done in org.el.
;;;###autoload
(eval-after-load 'org
  '(progn
     (org-dynamic-block-define "denote-missing-links" 'denote-org-dblock-insert-missing-links)))

;;;###autoload
(defun org-dblock-write:denote-missing-links (params)
  "Function to update `denote-links' Org Dynamic blocks.
Used by `org-dblock-update' with PARAMS provided by the dynamic block."
  (let* ((rx (denote-org--parse-rx (plist-get params :regexp)))
         (sort (plist-get params :sort-by-component))
         (reverse (plist-get params :reverse-sort))
         (include-date (plist-get params :include-date))
         (block-name (plist-get params :block-name))
         (denote-excluded-directories-regexp (or (plist-get params :excluded-dirs-regexp)
                                                 denote-excluded-directories-regexp))
         (files (denote-org-dblock--files-missing-only rx sort reverse)))
    (when block-name (insert "#+name: " block-name "\n"))
    (denote-link--insert-links files 'org (plist-get params :id-only) :no-other-sorting include-date)
    (join-line))) ; remove trailing empty line

;;;;; Dynamic block to insert backlinks

(defun denote-org-dblock--maybe-sort-backlinks (files sort-by-component reverse)
  "Sort backlink FILES if SORT-BY-COMPONENT and/or REVERSE is non-nil."
  (cond
   ((and sort-by-component reverse)
    (denote-sort-files files sort-by-component reverse))
   (sort-by-component
    (denote-sort-files files sort-by-component))
   (reverse
    (denote-sort-files files :no-component-specified reverse))
   (t
    files)))

;; TODO 2024-12-03: Do we need the :not-regexp here?  I think yes,
;; though I prefer to have a user of this kind of dblock send me their
;; feedback.

(define-obsolete-function-alias
  'denote-org-extras-dblock-insert-backlinks
  'denote-org-dblock-insert-backlinks
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-dblock-insert-backlinks ()
  "Create Org dynamic block to insert Denote backlinks to current file."
  (interactive nil org-mode)
  (org-create-dblock (list :name "denote-backlinks"
                           :excluded-dirs-regexp nil
                           :sort-by-component nil
                           :reverse-sort nil
                           :id-only nil
                           :this-heading-only nil
                           :include-date nil))
  (org-update-dblock))

;; NOTE 2024-03-30: This is how the autoload is done in org.el.
;;;###autoload
(eval-after-load 'org
  '(progn
     (org-dynamic-block-define "denote-backlinks" 'denote-org-dblock-insert-backlinks)))

;;;###autoload
(defun org-dblock-write:denote-backlinks (params)
  "Function to update `denote-backlinks' Org Dynamic blocks.
Used by `org-dblock-update' with PARAMS provided by the dynamic block."
  (when-let* ((files (if (plist-get params :this-heading-only)
                         (denote-org--get-backlinks-for-heading (denote-org--get-file-id-and-heading-id-or-context))
                       (denote-link-return-backlinks))))
    (let* ((sort (plist-get params :sort-by-component))
           (reverse (plist-get params :reverse-sort))
           (include-date (plist-get params :include-date))
           (denote-excluded-directories-regexp (or (plist-get params :excluded-dirs-regexp)
                                                   denote-excluded-directories-regexp))
           (files (denote-org-dblock--maybe-sort-backlinks files sort reverse)))
      (denote-link--insert-links files 'org (plist-get params :id-only) :no-other-sorting include-date)
      (join-line)))) ; remove trailing empty line

;;;;; Dynamic block to insert entire file contents

(defun denote-org-dblock--get-file-contents (file &optional no-front-matter add-links)
  "Insert the contents of FILE.
With optional NO-FRONT-MATTER as non-nil, try to remove the front
matter from the top of the file.  If NO-FRONT-MATTER is a number,
remove that many lines starting from the top.  If it is any other
non-nil value, delete from the top until the first blank line.

With optional ADD-LINKS as non-nil, first insert a link to the
file and then insert its contents.  In this case, format the
contents as a typographic list.  If ADD-LINKS is `id-only', then
insert links as `denote-link' does when supplied with an ID-ONLY
argument."
  (when (denote-file-is-note-p file)
    (with-temp-buffer
      (when add-links
        (insert
         (format "- %s\n\n"
                 (denote-format-link
                  file
                  (denote-get-link-description file)
                  'org
                  (eq add-links 'id-only)))))
      (let ((beginning-of-contents (point)))
        (insert-file-contents file)
        (when no-front-matter
          (delete-region
           (if (natnump no-front-matter)
               (progn (forward-line no-front-matter) (line-beginning-position))
             (1+ (re-search-forward "^$" nil :no-error 1)))
           beginning-of-contents))
        (when add-links
          (indent-region beginning-of-contents (point-max) 2)))
      (buffer-string))))

(defvar denote-org-dblock-file-contents-separator
  (concat "\n\n" (make-string 50 ?-) "\n\n\n")
  "Fallback separator used by `denote-org-dblock-add-files'.")

(defun denote-org-dblock--separator (separator)
  "Return appropriate value of SEPARATOR for `denote-org-dblock-add-files'."
  (cond
   ((null separator) "")
   ((stringp separator) separator)
   (t denote-org-dblock-file-contents-separator)))

(defun denote-org-dblock-add-files (regexp &optional separator no-front-matter add-links sort-by-component reverse excluded-dirs-regexp exclude-regexp)
  "Insert files matching REGEXP.

Seaprate them with the optional SEPARATOR.  If SEPARATOR is nil,
use the `denote-org-dblock-file-contents-separator'.

If optional NO-FRONT-MATTER is non-nil try to remove the front
matter from the top of the file.  Do it by finding the first
blank line, starting from the top of the buffer.

If optional ADD-LINKS is non-nil, first insert a link to the file
and then insert its contents.  In this case, format the contents
as a typographic list.

If optional SORT-BY-COMPONENT is a symbol among `denote-sort-components',
sort files matching REGEXP by the corresponding Denote file name
component.  If the symbol is not among `denote-sort-components',
fall back to the default identifier-based sorting.

If optional REVERSE is non-nil reverse the sort order.

Optional EXCLUDED-DIRS-REGEXP is the `let' bound value of
`denote-excluded-directories-regexp'.  When nil, the original value of
that user option is used.

Optional EXCLUDE-REGEXP is a more general way to exclude files whose
name matches the given regular expression."
  (let* ((denote-excluded-directories-regexp (or excluded-dirs-regexp denote-excluded-directories-regexp))
         (files (denote-org-dblock--files regexp sort-by-component reverse exclude-regexp))
         (files-contents (mapcar
                          (lambda (file) (denote-org-dblock--get-file-contents file no-front-matter add-links))
                          files)))
    (insert (string-join files-contents (denote-org-dblock--separator separator)))))

(define-obsolete-function-alias
  'denote-org-extras-dblock-insert-files
  'denote-org-dblock-insert-files
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-dblock-insert-files (regexp sort-by-component)
  "Create Org dynamic block to insert Denote files matching REGEXP.
Sort the files according to SORT-BY-COMPONENT, which is a symbol
among `denote-sort-components'."
  (interactive
   (list
    (denote-files-matching-regexp-prompt)
    (denote-sort-component-prompt))
   org-mode)
  (org-create-dblock (list :name "denote-files"
                           :regexp regexp
                           :not-regexp nil
                           :excluded-dirs-regexp nil
                           :sort-by-component sort-by-component
                           :reverse-sort nil
                           :no-front-matter nil
                           :file-separator nil
                           :add-links nil))
  (org-update-dblock))

;; NOTE 2024-03-30: This is how the autoload is done in org.el.
;;;###autoload
(eval-after-load 'org
  '(progn
     (org-dynamic-block-define "denote-files" 'denote-org-dblock-insert-files)))

;;;###autoload
(defun org-dblock-write:denote-files (params)
  "Function to update `denote-files' Org Dynamic blocks.
Used by `org-dblock-update' with PARAMS provided by the dynamic block."
  (let* ((rx (denote-org--parse-rx (plist-get params :regexp)))
         (not-rx (denote-org--parse-rx (plist-get params :not-regexp)))
         (sort (plist-get params :sort-by-component))
         (reverse (plist-get params :reverse-sort))
         (block-name (plist-get params :block-name))
         (separator (plist-get params :file-separator))
         (no-f-m (plist-get params :no-front-matter))
         (add-links (plist-get params :add-links))
         (excluded-dirs (plist-get params :excluded-dirs-regexp)))
    (when block-name (insert "#+name: " block-name "\n"))
    (when rx (denote-org-dblock-add-files rx separator no-f-m add-links sort reverse excluded-dirs not-rx)))
  (join-line)) ; remove trailing empty line

;;;; Insert files as headings

(defun denote-org-dblock--extract-regexp (regexp)
  "Extract REGEXP from the buffer and trim it of surrounding spaces."
  (string-trim
   (save-excursion
     (re-search-forward regexp nil :no-error)
     (buffer-substring-no-properties (match-end 0) (line-end-position)))))

(defun denote-org-dblock--get-file-contents-as-heading (file add-links)
  "Insert the contents of Org FILE, formatting the #+title as a heading.
With optional ADD-LINKS, make the title link to the original file."
  (when-let* (((denote-file-is-note-p file))
              (identifier (denote-retrieve-filename-identifier file))
              (file-type (denote-filetype-heuristics file))
              ((eq file-type 'org)))
    (with-temp-buffer
      (let ((beginning-of-contents (point))
            title
            tags)
        (insert-file-contents file)
        (setq title (denote-org-dblock--extract-regexp (denote--title-key-regexp file-type)))
        (setq tags (denote-org-dblock--extract-regexp (denote--keywords-key-regexp file-type)))
        (delete-region (1+ (re-search-forward "^$" nil :no-error 1)) beginning-of-contents)
        (goto-char beginning-of-contents)
        (when (and title tags)
          (if add-links
              (insert (format "* [[denote:%s][%s]] %s\n\n" identifier title tags))
            (insert (format "* %s %s\n\n" title tags)))
          (org-align-tags :all))
        (while (re-search-forward "^\\(*+?\\) " nil :no-error)
          (replace-match (format "*%s " "\\1"))))
      (buffer-string))))

(defun denote-org-dblock-add-files-as-headings (regexp &optional add-links sort-by-component reverse excluded-dirs-regexp exclude-regexp)
  "Insert files matching REGEXP.

If optional ADD-LINKS is non-nil, first insert a link to the file
and then insert its contents.  In this case, format the contents
as a typographic list.

If optional SORT-BY-COMPONENT is a symbol among `denote-sort-components',
sort files matching REGEXP by the corresponding Denote file name
component.  If the symbol is not among `denote-sort-components',
fall back to the default identifier-based sorting.

If optional REVERSE is non-nil reverse the sort order.

Optional EXCLUDED-DIRS-REGEXP is the `let' bound value of
`denote-excluded-directories-regexp'.  When nil, the original value of
that user option is used.

Optional EXCLUDE-REGEXP is a more general way to exclude files whose
name matches the given regular expression."
  (let* ((denote-excluded-directories-regexp (or excluded-dirs-regexp denote-excluded-directories-regexp))
         (files (denote-org-dblock--files regexp sort-by-component reverse exclude-regexp))
         (files-contents (mapcar
                          (lambda (file)
                            (denote-org-dblock--get-file-contents-as-heading file add-links))
                          files)))
    (insert (string-join files-contents))))

(define-obsolete-function-alias
  'denote-org-extras-dblock-insert-files-as-headings
  'denote-org-dblock-insert-files-as-headings
  "As part of making `denote-org' a standalone package")

;;;###autoload
(defun denote-org-dblock-insert-files-as-headings (regexp sort-by-component)
  "Create Org dynamic block to insert Denote Org files matching REGEXP.

Turn the #+title of each file into a top-level heading.  Then increment
all original headings in the file by one, so that they become
subheadings of what once was the #+title.

Use the #+filetags of each file as tags for the top-level heading (what
was the #+title).

Sort the files according to SORT-BY-COMPONENT, which is a symbol
among `denote-sort-components'.

IMPORTANT NOTE: This dynamic block only works with Org files, because it
has to assume the Org notation in order to insert each file's contents
as its own heading."
  (interactive
   (list
    (denote-files-matching-regexp-prompt)
    (denote-sort-component-prompt))
   org-mode)
  (org-create-dblock (list :name "denote-files-as-headings"
                           :regexp regexp
                           :not-regexp nil
                           :excluded-dirs-regexp nil
                           :sort-by-component sort-by-component
                           :reverse-sort nil
                           :add-links nil))
  (org-update-dblock))

;; NOTE 2024-03-30: This is how the autoload is done in org.el.
;;;###autoload
(eval-after-load 'org
  '(progn
     (org-dynamic-block-define "denote-files-as-headings" 'denote-org-dblock-insert-files-as-headings)))

;;;###autoload
(defun org-dblock-write:denote-files-as-headings (params)
  "Function to update `denote-files' Org Dynamic blocks.
Used by `org-dblock-update' with PARAMS provided by the dynamic block."
  (let* ((rx (denote-org--parse-rx (plist-get params :regexp)))
         (not-rx (denote-org--parse-rx (plist-get params :not-regexp)))
         (sort (plist-get params :sort-by-component))
         (reverse (plist-get params :reverse-sort))
         (block-name (plist-get params :block-name))
         (add-links (plist-get params :add-links))
         (excluded-dirs (plist-get params :excluded-dirs-regexp)))
    (when block-name (insert "#+name: " block-name "\n"))
    (when rx (denote-org-dblock-add-files-as-headings rx add-links sort reverse excluded-dirs not-rx)))
  (join-line)) ; remove trailing empty line

(provide 'denote-org)
;;; denote-org.el ends here
