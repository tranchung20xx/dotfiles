;; -*- lexical-binding: t; -*-
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(auto-revert-verbose nil)
 '(backup-directory-alist '(("." . "~/.emacs.d/backups/")))
 '(c-basic-offset 4)
 '(column-number-mode t)
 '(company-dabbrev-code-everywhere t)
 '(company-dabbrev-code-ignore-case t)
 '(company-dabbrev-code-other-buffers 'code)
 '(company-dabbrev-downcase nil)
 '(company-dabbrev-ignore-case nil)
 '(compilation-always-kill t)
 '(compilation-scroll-output t)
 '(completion-styles '(basic emacs22 flex))
 '(confirm-kill-emacs 'y-or-n-p)
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
 '(dired-kill-when-opening-new-dired-buffer t)
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
 '(grep-find-command '("rg --no-heading --color=never -nSe ''" . 37))
 '(icomplete-compute-delay 0)
 '(indent-tabs-mode nil)
 '(make-backup-files nil)
 '(package-selected-packages
   '(clang-format cmake-mode company csharp-mode d-mode dictionary
                  dtrt-indent editorconfig elixir-ts-mode faceup
                  go-mode gtags-mode json-mode less-css-mode lua-mode
                  magit markdown-mode markdown-ts-mode meson-mode
                  move-text multiple-cursors ninja-mode org paxedit
                  peg qml-mode rust-mode timeout tramp typescript-mode
                  verilog-mode wallpaper which-key xterm-color
                  yaml-mode yasnippet))
 '(prog-mode-hook
   '(dtrt-indent-global-mode gtags-mode whitespace-mode
                             delete-trailing-whitespace-mode))
 '(ring-bell-function 'ignore)
 '(savehist-mode t)
 '(show-paren-mode t)
 '(tab-width 4)
 '(treesit-enabled-modes t)
 '(treesit-font-lock-level 2)
 '(truncate-lines t)
 '(use-short-answers t)
 '(windmove-default-keybindings '(nil shift))
 '(yas-snippet-dirs '("~/.emacs.snippets/")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
