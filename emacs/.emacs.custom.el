;; -*- lexical-binding: t; -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(auto-revert-avoid-polling t)
 '(auto-revert-verbose nil)
 '(backup-directory-alist '(("." . "~/.emacs.d/backups/")))
 '(c-basic-offset 4)
 '(column-number-mode t)
 '(company-backends
   '(company-semantic company-cmake company-capf company-files
                      (company-dabbrev-code company-gtags
                                            company-etags
                                            company-keywords)
                      company-dabbrev))
 '(company-dabbrev-code-ignore-case t)
 '(company-dabbrev-downcase nil)
 '(compilation-always-kill t)
 '(confirm-kill-emacs 'y-or-n-p)
 '(create-lockfiles nil)
 '(custom-safe-themes
   '("09276f492e8e604d9a0821ef82f27ce58b831f90f49f986b4d93a006c12dbcdb"
     default))
 '(delete-selection-mode t)
 '(dired-auto-revert-buffer t)
 '(dired-clean-confirm-killing-deleted-buffers nil)
 '(dired-copy-dereference t)
 '(dired-do-revert-buffer t)
 '(dired-kill-when-opening-new-dired-buffer t)
 '(dired-recursive-copies 'always)
 '(dired-recursive-deletes 'top)
 '(disabled-command-function 'ignore t)
 '(display-line-numbers-type 'relative)
 '(duplicate-line-final-position -1)
 '(eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider))
 '(electric-pair-mode t)
 '(fast-but-imprecise-scrolling t)
 '(font-lock-maximum-decoration 2)
 '(global-auto-revert-mode t)
 '(global-display-line-numbers-mode t)
 '(global-eldoc-mode nil)
 '(grep-find-command '("rg --no-heading --color=never -nSe ''" . 37))
 '(icomplete-compute-delay 0)
 '(indent-tabs-mode nil)
 '(make-backup-files nil)
 '(package-selected-packages
   '(cmake-mode company d-mode dtrt-indent gtags-mode json-mode lua-mode
                magit markdown-mode meson-mode move-text
                multiple-cursors naysayer-theme paxedit qml-mode
                rust-mode yaml-mode yasnippet))
 '(ring-bell-function 'ignore)
 '(show-paren-mode t)
 '(tab-width 4)
 '(truncate-lines t)
 '(use-short-answers t)
 '(yas-snippet-dirs '("~/.emacs.snippets/")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
