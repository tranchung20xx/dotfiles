;;; This config based-on Tsoding emacs config  -*- lexical-binding: t; -*-
;;  https://github.com/rexim/dotfiles

(defvar default-file-name-handler-alist file-name-handler-alist)
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 1
      file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.2
                  file-name-handler-alist default-file-name-handler-alist)))

(setq load-prefer-newer t)
(setq confirm-kill-processes nil)

(setq-default inhibit-splash-screen t
              frame-inhibit-implied-resize t
              frame-resize-pixelwise t
              window-resize-pixelwise t
              redisplay-dont-pause t
              redisplay-skip-fontification-on-input t
              inhibit-compacting-font-caches t
              bidi-inhibit-bpa t
              ;; read-process-output-max (* 1024 1024)
              process-adaptive-read-buffering nil
              pgtk-wait-for-event-timeout 0)

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless package-archive-contents
  (condition-case err
      (package-refresh-contents)
    (error (message "package-refresh-contents failed: %s" err))))

(eval-when-compile (require 'use-package))
(require 'use-package)

(setq use-package-always-ensure t
      package-install-upgrade-built-in t)

(when (native-comp-available-p)
  (setq-default native-comp-async-report-warnings-errors 'silent
                native-comp-compiler-options '("-O3" "-mtune=znver4" "-march=znver4" "-g0"
                                               "-fno-omit-frame-pointer" "-fno-finite-math-only")
                native-comp-driver-options '("-Wl,-z,pack-relative-relocs" "-Wl,-O2" "-Wl,--as-needed")
                package-native-compile t))

(use-package emacs
  :ensure nil
  :custom
  (custom-file (expand-file-name "~/.emacs.custom.el"))
  (c-default-style '((java-mode . "java")
                     (awk-mode . "awk")
                     (other . "bsd")))
  :config
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
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

(use-package savehist
  :ensure nil
  :hook (after-init . savehist-mode)
  :custom (savehist-additional-variables '(kill-ring search-ring regexp-search-ring)))

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
  (add-to-list 'compilation-error-regexp-alist
               '("\\([^()\n]+\\)(\\([0-9]+\\)\\(,\\([0-9]+\\)\\)?) \\(Warning:\\)?" 1 2 (4) (5)))
  (add-hook 'compilation-filter-hook #'ansi-color-compilation-filter))

(use-package whitespace
  :ensure nil
  :hook ((prog-mode text-mode) . whitespace-mode)
  :custom
  (whitespace-style '(face tabs spaces trailing space-before-tab newline
                           indentation empty space-after-tab space-mark tab-mark)))

(use-package icomplete
  :ensure nil
  :hook (after-init . fido-mode)
  :config
  (add-hook 'icomplete-minibuffer-setup-hook
            (lambda ()
              (setq-local completion-styles '(substring partial-completion)))))

(when (file-directory-p "~/.emacs.local/")
  (use-package gruber-darker-theme
    :ensure nil
    :load-path "~/.emacs.local/"
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

(use-package paxedit
  :hook ((emacs-lisp-mode lisp-mode common-lisp-mode clojure-mode scheme-mode racket-mode)
         . paxedit-mode))

(use-package company
  :hook (after-init . global-company-mode))

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
  :hook (prog-mode . gtags-mode))

(use-package dtrt-indent
  :defer t
  :custom (dtrt-indent-lighter "")
  :hook (prog-mode . dtrt-indent-global-mode))

(use-package d-mode        :defer t)
(use-package lua-mode      :defer t)
(use-package rust-mode     :defer t)
(use-package cmake-mode    :defer t)
(use-package meson-mode    :defer t)
(use-package markdown-mode :defer t)
(use-package yaml-mode     :defer t)
(use-package qml-mode      :defer t)
(use-package json-mode     :defer t)

(when (file-directory-p "~/.emacs.local/")
  (use-package my-misc
    :ensure nil
    :load-path "~/.emacs.local/"))

(provide '.emacs)
;;; .emacs.el ends here
