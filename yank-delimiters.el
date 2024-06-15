;;; yank-delimiters.el --- Delimiters-aware yanking -*- lexical-binding: t -*-

;; Copyright (C) 2024  Tony Zorman
;;
;; Author: Tony Zorman <soliditsallgood@mailbox.org>
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "29.1") (dash "2.18.0"))
;; Homepage: https://github.com/slotThe/yank-delimiters

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A version of `yank' that is aware of delimiters, and deletes
;; extraneous ones before putting the string into the buffer.
;;
;; To use, simply bind `yank-delimiters-yank' to a key:
;;
;;     (bind-key "C-y" #'yank-delimiters-yank)
;;
;; See [1] for a more extensive overview.
;;
;; [1]: https://tony-zorman.com/posts/yanking.html

;;; Code:

(require 'dash)

(defun yank-delimiters--count ()
  "Return delimiter count in current buffer.
Returns a list, each element being of the form (OPEN CLOSE AMNT),
where OPEN and CLOSE are the respective opening and closing
delimiters, and AMNT is an integer; a positive (negative) number
signalling that there are that many extraneous opening (closing)
delimiters.  Thus, a value of 0 signifies a balanced buffer.

Do not count a delimiter towards the global total if it is
escaped (prefixed by a backslash), part of a string, or part of a
comment."
  (goto-char (point-min))
  (let-alist '((paren . 0) (bracket . 0) (curly . 0))
    (while-let ((char (char-after)))
      (unless (or (-intersection (text-properties-at (point))
                                 '(font-lock-string-face
                                   font-lock-comment-face))
                  (eq ?\\ (char-before)))
        (pcase char
          (?\( (cl-incf .paren)) (?\[ (cl-incf .bracket)) (?\{ (cl-incf .curly))
          (?\) (cl-decf .paren)) (?\] (cl-decf .bracket)) (?\} (cl-decf .curly))))
      (forward-char))
    `(("(" ")" ,.paren)
      ("[" "]" ,.bracket)
      ("{" "}" ,.curly))))

(defun yank-delimiters--trim (open close n)
  "Trim delimiter in current buffer.
OPEN and CLOSE are the respective opening and closing delimiters.
The number N indicates how many—and which—delimiters to trim.  If
it is positive, trim CLOSE; otherwise, trim OPEN."
  (-let (((pt del) (if (< n 0)          ; More closing than opening?
                       `(point-max (when (search-backward ,close (point-min) t)
                                     (delete-forward-char 1)))
                     `(point-min (when (search-forward ,open (point-max) t)
                                   (delete-backward-char 1))))))
    (goto-char (funcall pt))
    (dotimes (_ (abs n))
      (eval del))))

(defun yank-delimiters--trim-all (str)
  "Trim delimiters in string STR.
See `yank-delimiters--count' for a list of all relevant
delimiters, and `yank-delimiters--trim' for how delimiters are
actually trimmed."
  (with-temp-buffer
    (insert str)
    (--each (yank-delimiters--count)
      (apply #'yank-delimiters--trim it))
    (buffer-string)))

;;;###autoload
(defun yank-delimiters-yank (&optional arg)
  "Delimiter-aware yanking.
Like `yank' (which see), but trim non-matching delimiters from
the string before actually yanking it into the current buffer.
The kill-ring itself remains untouched.

Implementation copied verbatim from `yank', except for the
insertion of `yank-delimiters--trim-all' before yanking."
  (interactive "*P")
  (setq yank-window-start (window-start))
  ;; If we don't get all the way through, make `last-command' indicate
  ;; that for the following command.
  (setq this-command t)
  (push-mark)
  (insert-for-yank (yank-delimiters--trim-all
                    (current-kill
                     (cond
                      ((listp arg) 0)
                      ((eq arg '-) -2)
                      (t (1- arg))))))
  (when (consp arg)
    ;; This is like `exchange-point-and-mark', but doesn't activate the
    ;; mark.  It is cleaner to avoid activation, even though the command
    ;; loop would deactivate the mark because we inserted text.
    (goto-char (prog1 (mark t)
                 (set-marker (mark-marker) (point) (current-buffer)))))
  ;; If we do get all the way through, make `this-command' indicate that.
  (when (eq this-command t)
    (setq this-command 'yank))
  nil)

;; Play nice with `delsel.el'
(put 'yank-delimiters-yank 'delete-selection 'yank)

(provide 'yank-delimiters)
;;; yank-delimiters.el ends here
