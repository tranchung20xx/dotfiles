;;; -*- lexical-binding: t; -*-

(keymap-global-unset "C-x p") ;; Fck project.el
(keymap-global-unset "C-x C-z")
(keymap-global-unset "C-x C-d") ;; We have C-x d, you know
(keymap-global-unset "C-z")
;; (keymap-global-set "C-x p g" #'grep)
(keymap-global-set "C-x p g" #'grep-find)
(keymap-global-set "C-x p f" #'my/fd-find-file)
(keymap-global-set "M-u" #'upcase-dwim)
(keymap-global-set "M-l" #'downcase-dwim)
(keymap-global-set "M-c" #'capitalize-dwim)

;;; Highlight current working dir in fido buffer
(require 'cl-lib)
(defun my/mb-setup ()
  (when (memq (completion-metadata-get
               (completion-metadata (minibuffer-contents)
                                    minibuffer-completion-table
                                    minibuffer-completion-predicate)
               'category)
              '(file buffer))
    (let* ((ov (make-overlay 1 1 nil t t))
           (up (lambda (&rest _)
                 (let* ((beg (minibuffer-prompt-end))
                        (s (minibuffer-contents))
                        (slash (cl-position ?/ s :from-end t)))
                   (if slash
                       (move-overlay ov beg (+ beg slash 1))
                     (move-overlay ov beg beg))))))
      (overlay-put ov 'face 'icomplete-dir)
      (overlay-put ov 'priority 100)
      (add-hook 'after-change-functions up nil t)
      (add-hook 'minibuffer-exit-hook
                (lambda () (delete-overlay ov))
                nil t)
      (funcall up))))
(add-hook 'minibuffer-setup-hook #'my/mb-setup)

;;; Custom face for fido-mode
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
(advice-add 'icomplete-completions :filter-return
            (lambda (s)
              (let* ((comps (completion-all-sorted-completions))
                     (cat (completion-metadata-get
                           (completion-metadata (minibuffer-contents)
                                                minibuffer-completion-table
                                                minibuffer-completion-predicate)
                           'category))
                     (is-buf (eq cat 'buffer)))
                (when (memq cat '(file buffer))
                  (let ((pos 0)
                        (lst comps))
                    (while (and (consp lst) (stringp (car lst))
                                (< pos (length s)))
                      (let* ((cand (car lst))
                             (m (string-search cand s pos)))
                        (if (not m)
                            (setq lst nil)          ; past what's displayed; stop
                          (let* ((len (length cand))
                                 (tag-start (and is-buf
                                                 (> len 2)
                                                 (eq (aref cand (1- len)) ?>)
                                                 (string-match "<[^>]+>\\'" cand)
                                                 (match-beginning 0)))
                                 (dir (file-name-directory
                                       (if tag-start (substring cand 0 tag-start) cand)))
                                 (dir-len (if dir (length dir) 0)))
                            (when (> dir-len 0)
                              (add-face-text-property m (+ m dir-len) 'icomplete-dir t s))
                            (when tag-start
                              (add-face-text-property (+ m tag-start) (+ m len) 'icomplete-dir t s))
                            (setq pos (+ m len))
                            (setq lst (cdr lst))))))))
                (let ((s-len (length s)))
                  (when (> s-len 0)
                    (let ((first-char (aref s 0)))
                      (when (or (eq first-char ?\[) (eq first-char ?\())
                        (let* ((close-str (if (eq first-char ?\[) "]" ")"))
                               (end-pos (string-search close-str s 1)))
                          (when end-pos
                            (add-face-text-property 1 end-pos 'icomplete-determined nil s)))))))
                s)))

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
  (let ((choice
         (completing-read
          "Find file: "
          (process-lines "fd" "--type" "f" "--hidden" "--exclude" ".git" "--color=never" "--strip-cwd-prefix")
          nil t)))
    (unless (string-empty-p choice)
      (find-file (expand-file-name choice default-directory)))))

(define-advice compilation-filter (:around (f proc string) xterm-color)
  (funcall f proc (xterm-color-filter string)))

(provide 'my-misc)
