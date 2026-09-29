;;; init.el --- Main initialization  -*- lexical-binding: t; -*-
;;  This config based-on Tsoding emacs config
;;  https://github.com/rexim/dotfiles

(setq native-comp-async-report-warnings-errors 'silent
        native-comp-compiler-options '("-O3" "-mtune=znver4" "-march=znver4" "-g0" "-fno-omit-frame-pointer")
        native-comp-driver-options   '("-Wl,-z,pack-relative-relocs" "-Wl,-O2" "-Wl,--as-needed")
        package-native-compile t)

(use-package emacs
  :ensure nil
  :config
  (load custom-file 'noerror 'nomessage)

  :bind
  (("C-," . duplicate-dwim)
   ("C-x C-g" . find-file-at-point))

  :hook
  (before-save . delete-trailing-whitespace)
  (emacs-startup . (lambda ()
                     (setq gc-cons-threshold (* 32 1024 1024)
                           gc-cons-percentage 0.1
                           file-name-handler-alist (delete-dups (append file-name-handler-alist sane--file-name-handler-alist))))))

(use-package compile
  :ensure nil
  :bind ("M-C-g" . recompile)
  :config
  (add-to-list 'compilation-error-regexp-alist
               '("\\([^()\n]+\\)(\\([0-9]+\\)\\(,\\([0-9]+\\)\\)?) \\(Warning:\\)?" 1 2 (4) (5))))

(use-package xterm-color
  :after compile
  :custom
  (compilation-environment '("TERM=xterm-256color")))

(use-package icomplete
  :ensure nil
  :hook (after-init . fido-mode))

(when (file-directory-p "~/.emacs.d/misc")
  (use-package gruber-darker-theme
    :ensure nil
    :load-path "~/.emacs.d/misc"
    :config
    (load-theme 'gruber-darker t)))

(use-package move-text
  :bind (("M-p" . move-text-up)
         ("M-n" . move-text-down)))

(use-package multiple-cursors
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->"         . mc/mark-next-like-this)
         ("C-<"         . mc/mark-previous-like-this)
         ("C-c C-<"     . mc/mark-all-like-this)
         ("C-\""        . mc/skip-to-next-like-this)
         ("C-:"         . mc/skip-to-previous-like-this)))

(use-package paredit
  :defer t
  :hook ((emacs-lisp-mode lisp-mode common-lisp-mode clojure-mode scheme-mode racket-mode)
         . paredit-mode))

(use-package company
  :hook (after-init . global-company-mode))

(use-package company-shell
  :after company
  :config
  (add-to-list 'company-backends '(company-shell company-shell-env company-fish-shell)))

(use-package yasnippet
  :hook (after-init . yas-global-mode)
  :custom
  (yas-snippet-dirs `(,(expand-file-name "~/.emacs.d/snippets"))))

(use-package transient :defer t)
(use-package magit :defer t)

(use-package editorconfig
  :ensure nil
  :config (editorconfig-mode 1))

(use-package gtags-mode
  :defer t
  :custom (gtags-mode-lighter " gtags")
  :hook (prog-mode . gtags-mode)
  :init
  (setenv "GTAGSLABEL" "native-pygments")
  (setenv "GTAGSCONF" "/etc/gtags.conf"))

(use-package dtrt-indent
  :defer t
  :custom (dtrt-indent-lighter "")
  :hook (prog-mode . dtrt-indent-mode))

(use-package d-mode          :defer t)
(use-package go-mode         :defer t)
(use-package lua-mode        :defer t)
(use-package qml-mode        :defer t)
(use-package yaml-mode       :defer t)
(use-package json-mode       :defer t)
(use-package rust-mode       :defer t)
(use-package cmake-mode      :defer t)
(use-package meson-mode      :defer t)
(use-package ninja-mode      :defer t)
(use-package markdown-mode   :defer t)
(use-package typescript-mode :defer t)

(when (file-directory-p "~/.emacs.d/misc")
  (use-package my-misc
    :ensure nil
    :load-path "~/.emacs.d/misc"))

(provide 'init)
;;; init.el ends here
