;;; early-init.el --- Early initialization  -*- lexical-binding: t; -*-
;;  This config based-on Tsoding emacs config
;;  https://github.com/rexim/dotfiles

;; Defer GC during startup

(defvar sane--file-name-handler-alist file-name-handler-alist)
(setq gc-cons-threshold (* 128 1024 1024)
      gc-cons-percentage 1
      file-name-handler-alist nil)

(setq user-emacs-directory "~/.emacs.d/user")
(when (boundp 'native-comp-eln-load-path)
  (add-to-list 'native-comp-eln-load-path
               (expand-file-name "eln-cache/" user-emacs-directory)))

(setq inhibit-splash-screen t
      redisplay-dont-pause t
      inhibit-startup-message t
      read-process-output-max (* 1024 1024)
      inhibit-compacting-font-caches t
      pgtk-wait-for-event-timeout 0)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(setq custom-file (expand-file-name "~/.emacs.d/custom.el"))
(setq use-package-always-ensure t)

(add-to-list 'default-frame-alist '(background-color . "#181818"))
(add-to-list 'default-frame-alist '(foreground-color . "#e4e4ef"))
(add-to-list 'default-frame-alist '(font . "Iosevka 26"))

(provide 'early-init)
;;; early-init.el ends here
