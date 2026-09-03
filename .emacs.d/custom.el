;;; -*- lexical-binding: t -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(auto-revert-verbose nil)
 '(auto-save-list-file-prefix "~/.emacs.d/user/auto-save-list/.saves-")
 '(backup-directory-alist '(("." . "~/.emacs.d/backups/")))
 '(c-basic-offset 4)
 '(c-ts-indent-offset 4)
 '(c-ts-mode-enable-doxygen t)
 '(column-number-mode t)
 '(company-dabbrev-code-everywhere t)
 '(company-dabbrev-code-ignore-case t)
 '(company-dabbrev-code-other-buffers 'code)
 '(company-dabbrev-downcase nil)
 '(company-dabbrev-ignore-case nil)
 '(compilation-always-kill t)
 '(compilation-scroll-output t)
 '(completion-styles '(flex))
 '(confirm-kill-emacs 'y-or-n-p)
 '(confirm-kill-processes nil)
 '(create-lockfiles nil)
 '(custom-safe-themes
   '("71db67ea6e739968ca6d8a6d16cf86afd7dda23d129c8eeec98077f66a13d637"
     "09276f492e8e604d9a0821ef82f27ce58b831f90f49f986b4d93a006c12dbcdb"
     default))
 '(delete-selection-mode t)
 '(dired-auto-revert-buffer t)
 '(dired-clean-confirm-killing-deleted-buffers nil)
 '(dired-copy-dereference t)
 '(dired-do-revert-buffer t)
 '(dired-dwim-target t)
 '(dired-kill-when-opening-new-dired-buffer t)
 '(dired-listing-switches "-alhv" nil nil "Customized with use-package dired")
 '(dired-omit-files "\\`[.]?#\\|\\`[.][.]?\\'\\|^\\..+$")
 '(dired-recursive-copies 'always)
 '(disabled-command-function 'ignore t)
 '(display-line-numbers-type 'relative)
 '(duplicate-line-final-position -1)
 '(eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider))
 '(electric-pair-mode t)
 '(fast-but-imprecise-scrolling t)
 '(font-lock-maximum-decoration 2)
 '(global-auto-revert-mode t)
 '(global-auto-revert-non-file-buffers t)
 '(global-display-line-numbers-mode t)
 '(global-eldoc-mode nil)
 '(global-so-long-mode t)
 '(grep-find-command '("rg --no-heading --color=never -nSe ''" . 37))
 '(icomplete-compute-delay 0)
 '(indent-tabs-mode nil)
 '(make-backup-files nil)
 '(minibuffer-electric-default-mode t)
 '(package-selected-packages
   '(company company-shell cperl-mode csharp-mode dictionary dtrt-indent
             editorconfig elixir-ts-mode faceup gtags-mode
             less-css-mode lua-mode magit markdown-ts-mode move-text
             multiple-cursors org paredit peg timeout tramp transient
             verilog-mode wallpaper which-key xterm-color yasnippet))
 '(prog-mode-hook '(whitespace-mode delete-trailing-whitespace-mode))
 '(ring-bell-function 'ignore)
 '(show-paren-mode t)
 '(tab-width 4)
 '(text-mode-hook
   '(whitespace-mode text-mode-hook-identify
                     delete-trailing-whitespace-mode))
 '(treesit-enabled-modes t)
 '(treesit-font-lock-level 2)
 '(truncate-lines t)
 '(use-package-always-ensure t)
 '(use-short-answers t)
 '(whitespace-style
   '(face trailing tabs spaces newline empty indentation space-after-tab
          space-before-tab space-mark tab-mark)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
