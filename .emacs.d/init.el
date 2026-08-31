;;; init.el --- Main initialization  -*- lexical-binding: t; -*-
;;  This config based-on Tsoding emacs config
;;  https://github.com/rexim/dotfiles

(eval-when-compile (require 'use-package))
(require 'use-package)

(setq use-package-always-ensure t
      package-install-upgrade-built-in t)

(when (native-comp-available-p)
  (setq-default native-comp-async-report-warnings-errors 'silent
                native-comp-compiler-options '("-O2" "-mtune=znver4" "-march=znver4" "-g0"
                                               "-fno-omit-frame-pointer" "-fno-finite-math-only")
                native-comp-driver-options   '("-Wl,-z,pack-relative-relocs" "-Wl,-O2" "-Wl,--as-needed")
                package-native-compile t))

(use-package emacs
  :ensure nil
  :custom
  (custom-file (expand-file-name "~/.emacs.d/custom.el"))
  (c-default-style '((java-mode . "java")
                     (awk-mode . "awk")
                     (other . "bsd")))
  :config
  (when (find-font (font-spec :name "Iosevka"))
    (add-to-list 'default-frame-alist '(font . "Iosevka 26")))

  (add-hook 'before-save-hook #'delete-trailing-whitespace)

  (when (file-exists-p custom-file)
    (load custom-file 'noerror 'nomessage))

  :bind
  (("C-," . duplicate-dwim)
   ("C-x C-g" . find-file-at-point)))

(use-package autorevert
  :ensure nil
  :hook (after-init . global-auto-revert-mode))

(use-package so-long
  :ensure nil
  :hook (after-init . global-so-long-mode))

(use-package dired
  :ensure nil
  :custom
  (dired-dwim-target t)
  (dired-listing-switches "-alhv")
  (dired-mouse-drag-files t))

(use-package dired-x
  :ensure nil
  :config
  (setq dired-omit-files (concat dired-omit-files "\\|^\\..+$")))

(use-package compile
  :ensure nil
  :bind ("M-C-g" . recompile)
  :config
  ;; (add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)
  (add-to-list 'compilation-error-regexp-alist
               '("\\([^()\n]+\\)(\\([0-9]+\\)\\(,\\([0-9]+\\)\\)?) \\(Warning:\\)?" 1 2 (4) (5))))

(use-package xterm-color
  :after compile
  :config
  (define-advice compilation-filter (:around (f proc string) xterm-color)
    (funcall f proc (xterm-color-filter string)))
  :custom
  (compilation-environment '("TERM=xterm-256color")))

(use-package whitespace
  :ensure nil
  :hook ((prog-mode text-mode) . whitespace-mode)
  :custom
  (whitespace-style '(face tabs spaces trailing space-before-tab newline
                           indentation empty space-after-tab space-mark tab-mark)))

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
  :defer t
  :hook (after-init . global-company-mode))

(use-package company-shell
  :config
  (add-to-list 'company-backends '(company-shell company-shell-env company-fish-shell)))

(use-package yasnippet
  :hook (after-init . yas-global-mode))

(use-package transient :defer t)
(use-package magit :defer t)

(use-package editorconfig
  :ensure nil
  :hook (after-init . editorconfig-mode))

(use-package gtags-mode
  :defer t
  :custom (gtags-mode-lighter " gtags")
  :hook (prog-mode . gtags-mode)
  :config
  (setenv "GTAGSLABEL" "native-pygments")
  (setenv "GTAGSCONF" "/usr/share/gtags/gtags.conf"))

(use-package dtrt-indent
  :defer t
  :custom (dtrt-indent-lighter "")
  :hook (prog-mode . dtrt-indent-global-mode))

;; (use-package d-mode          :defer t)
;; (use-package go-mode         :defer t)
;; (use-package lua-mode        :defer t)
;; (use-package rust-mode       :defer t)
;; (use-package cmake-mode      :defer t)
;; (use-package meson-mode      :defer t)
;; (use-package markdown-mode   :defer t)
;; (use-package yaml-mode       :defer t)
;; (use-package qml-mode        :defer t)
;; (use-package json-mode       :defer t)
;; (use-package ninja-mode      :defer t)
;; (use-package typescript-mode :defer t)

(when (file-directory-p "~/.emacs.d/misc")
  (use-package my-misc
    :ensure nil
    :load-path "~/.emacs.d/misc"))

(provide 'init)
;;; init.el ends here
