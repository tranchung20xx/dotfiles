;;; my-misc.el --- Personal keybindings and utilities  -*- lexical-binding: t; -*-

(keymap-global-unset "C-x p") ;; Fck project.el
(keymap-global-unset "C-x C-z")
(keymap-global-unset "C-z")
;; (keymap-global-set "C-x p g" #'grep)
(keymap-global-set "C-x C-d" #'ffap) ;; We have C-x d, you know
(keymap-global-set "C-x p g" #'grep-find)
(keymap-global-set "C-x p f" #'my/fd-find-file)
(keymap-global-set "M-u" #'upcase-dwim)
(keymap-global-set "M-l" #'downcase-dwim)
(keymap-global-set "M-c" #'capitalize-dwim)

;;; Fido/icomplete enhancement — directory & match highlighting

(defgroup my-icomplete-faces nil
  "Faces for custom icomplete/fido highlighting."
  :group 'icomplete)

(defface icomplete-dir
  '((t :inherit font-lock-keyword-face))
  "Face for directory entries in icomplete."
  :group 'my-icomplete-faces)

(defface icomplete-determined
  '((t :inherit shadow))
  "Face for the determined (sole/bracketed) match in icomplete."
  :group 'my-icomplete-faces)

(defconst my/icomplete--buf-tag-re "<[^>]+>\\'"
  "Regexp matching buffer uniquification tags like <dir>.")

;; Cache the completion category for the duration of each minibuffer session.
(defvar-local my/icomplete--cached-category 'unset
  "Cached completion category; `unset' means not yet computed.")

(defun my/icomplete--category ()
  "Return the completion category for the current minibuffer session.
Result is cached in `my/icomplete--cached-category' for the lifetime of
the minibuffer so that `completion-metadata' is only called once."
  (if (eq my/icomplete--cached-category 'unset)
      (setq my/icomplete--cached-category
            (completion-metadata-get
             (completion-metadata (minibuffer-contents)
                                  minibuffer-completion-table
                                  minibuffer-completion-predicate)
             'category))
    my/icomplete--cached-category))

;; Minibuffer input: highlight the directory prefix typed so far

(defun my/mb-setup ()
  "Overlay the directory prefix in minibuffer input with `icomplete-dir' face."
  ;; Always reset the cache at session start -- minibuffer buffers are reused,
  ;; so a stale value from the previous session would contaminate this one.
  (setq-local my/icomplete--cached-category 'unset)
  (when (memq (my/icomplete--category) '(file buffer))
    (let* ((ov (make-overlay 1 1 nil t t))
           (update (lambda (&rest _)
                     (let* ((beg (minibuffer-prompt-end))
                            (end (save-excursion
                                   (goto-char (point-max))
                                   (if (search-backward "/" beg t)
                                       (1+ (point))
                                     beg))))
                       ;; Skip move-overlay when bounds are unchanged.
                       (unless (and (= (overlay-start ov) beg)
                                    (= (overlay-end ov) end))
                         (move-overlay ov beg end)))))
           ;; Declare cleanup as a variable so it can remove itself.
           cleanup)
      (setq cleanup
            (lambda ()
              (delete-overlay ov)
              ;; Remove both hooks so they don't accumulate across sessions
              ;; in the reused minibuffer buffer.
              (remove-hook 'after-change-functions update t)
              (remove-hook 'minibuffer-exit-hook cleanup t)))
      (overlay-put ov 'face 'icomplete-dir)
      (overlay-put ov 'priority 100)
      (add-hook 'after-change-functions update nil t)
      (add-hook 'minibuffer-exit-hook cleanup nil t)
      (funcall update))))

(add-hook 'minibuffer-setup-hook #'my/mb-setup)

;; Completion candidates: highlight directory prefixes & determined match

(defun my/icomplete--highlight-candidate (s pos cand is-buf)
  "Highlight directory part of CAND found at POS in string S.
If IS-BUF is non-nil, also highlight <dir> uniquification tags.
Return position past the candidate, or nil if CAND is not found."
  (when-let* ((m (string-search cand s pos)))
    (let* ((len (length cand))
           (tag-beg (and is-buf (> len 2)
                         (eq (aref cand (1- len)) ?>)
                         (string-match my/icomplete--buf-tag-re cand)
                         (match-beginning 0)))
           (base (if tag-beg (substring cand 0 tag-beg) cand))
           (dir-len (length (or (file-name-directory base) ""))))
      (when (> dir-len 0)
        (add-face-text-property m (+ m dir-len) 'icomplete-dir t s))
      (when tag-beg
        (add-face-text-property (+ m tag-beg) (+ m len) 'icomplete-dir t s))
      (+ m len))))

(defun my/icomplete-dir-annotate (s)
  "Highlight directory parts and determined matches in icomplete output S."
  (when (> (length s) 0)
    (let* ((cat (my/icomplete--category))
           (is-buf (eq cat 'buffer)))
      (when (memq cat '(file buffer))
        (let ((pos 0)
              (len (length s))
              (comps (completion-all-sorted-completions)))
          (while (and (consp comps) (stringp (car comps)) (< pos len))
            (if-let* ((new-pos (my/icomplete--highlight-candidate
                               s pos (car comps) is-buf)))
                (setq pos new-pos comps (cdr comps))
              (setq comps nil)))))
      (let ((ch (aref s 0)))
        (when (memq ch '(?\[ ?\())
          (let ((end (string-search (if (eq ch ?\[) "]" ")") s 1)))
            (when end
              (add-face-text-property 1 end 'icomplete-determined nil s)))))))
  s)

(advice-add 'icomplete-completions :filter-return #'my/icomplete-dir-annotate)

;; Add / to dired buffer name
(add-hook 'dired-mode-hook
          (lambda ()
            (unless (string-suffix-p "/" (buffer-name))
              (rename-buffer (concat (buffer-name) "/") t))))


(defun my/smart-electric-indent (_)
  (let ((ppss (syntax-ppss)))
    (when (or (nth 3 ppss)
              (nth 4 ppss))
      'no-indent)))
(add-hook 'electric-indent-functions #'my/smart-electric-indent)

(defun my/fd-find-file ()
  "Find a file beneath `default-directory' using fd."
  (interactive)
  (unless (executable-find "fd")
    (user-error "fd not found on PATH"))
  (let* ((default-directory (or (and (fboundp 'project-root)
                                     (when-let* ((proj (project-current)))
                                       (project-root proj)))
                                default-directory))
         (choice (completing-read
                  (format "Find file in %s: " default-directory)
                  (process-lines "fd" "--type" "f" "--hidden" "--exclude" ".git"
                                 "--color=never" "--strip-cwd-prefix")
                  nil t)))
    (unless (string-empty-p choice)
      (find-file (expand-file-name choice default-directory)))))

(defun my/compilation-filter-xterm-color (f proc string)
  (funcall f proc (if (fboundp 'xterm-color-filter)
                      (xterm-color-filter string)
                    string)))

(with-eval-after-load 'compile
  (advice-add 'compilation-filter :around #'my/compilation-filter-xterm-color))

(provide 'my-misc)
;;; my-misc.el ends here
