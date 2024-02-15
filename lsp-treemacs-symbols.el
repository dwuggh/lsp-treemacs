;;; lsp-treemacs-symbols.el --- lsp-treemacs-symbols extension -*- lexical-binding: t; -*-


;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'treemacs)
(require 'treemacs-treelib)

(defvar lsp-treemacs-symbols--follow-timer nil "Signal.")
(defvar lsp-treemacs-symbols-follow-update-time 0.02
  "Time interval for updating symbols.")

;;;###autoload
(defun lsp-treemacs-symbols-look-back ()
  (let ((line (- (line-number-at-pos (point) t) 1)))
    (with-current-buffer lsp-treemacs-symbols-buffer-name
      (treemacs-walk-dom (treemacs-find-in-dom '(lsp-treemacs-generic-root))
        (lambda (node)
          (-when-let ((&plist :range (&hash "start" (&hash "line" l1) "end" (&hash "line" l2)))
                      (ignore-errors
                        (save-excursion
                          (goto-char (treemacs-dom-node->position node))
                          (button-get (treemacs-node-at-point) :item))))
            ;; NOTE `l1' and `l2' start from 0, while `line-number-at-pos' start from 1.
            (when (and (>= line l1) (<= line l2))
              (with-selected-window
                  (get-buffer-window lsp-treemacs-symbols-buffer-name)
                (-when-let (window (get-buffer-window))
                  (set-window-point window (treemacs-dom-node->position node)))
                (hl-line-highlight)))))))))


(defun lsp-treemacs-symbols--follow ()
  (setq lsp-treemacs-symbols--follow-timer nil)
  (lsp-treemacs-symbols-look-back))

(defun lsp-treemacs-symbols--follow-update ()
  (when (and
         (eq (current-buffer) lsp-treemacs--symbols-last-buffer)
         (get-buffer-window lsp-treemacs-symbols-buffer-name))
    (unless lsp-treemacs-symbols--follow-timer
      (setq lsp-treemacs-symbols--follow-timer
            (run-with-idle-timer 0.02 nil #'lsp-treemacs-symbols--follow)))))

;;;###autoload
(define-minor-mode lsp-treemacs-symbols-follow-mode
  "Toggle `lsp-treemacs-symbols-follow-mode'.
Locate to corresponding symbol in buffer."
  :init-value nil
  :global     t
  :lighter    nil
  :group      'lsp-treemacs
  (if lsp-treemacs-symbols-follow-mode
      (add-hook 'post-command-hook #'lsp-treemacs-symbols--follow-update 0 nil)
    (remove-hook 'post-command-hook #'lsp-treemacs-symbols--follow-update nil)))


(provide 'lsp-treemacs-symbols)
