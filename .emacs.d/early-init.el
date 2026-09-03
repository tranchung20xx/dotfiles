;;; early-init.el --- Early initialization  -*- lexical-binding: t; -*-
;;  This config based-on Tsoding emacs config
;;  https://github.com/rexim/dotfiles

;; Defer GC during startup

(defvar sane--file-name-handler-alist file-name-handler-alist)
(setq gc-cons-threshold (* 128 1024 1024)
      gc-cons-percentage 1
      file-name-handler-alist nil)

(setq-default user-emacs-directory "~/.emacs.d/user")
(setq custom-file (expand-file-name "~/.emacs.d/custom.el"))

(setq inhibit-splash-screen t
      redisplay-dont-pause t
      inhibit-startup-message t
      frame-inhibit-implied-resize t
      read-process-output-max (* 1024 1024)
      frame-resize-pixelwise t
      window-resize-pixelwise t
      redisplay-skip-fontification-on-input t
      inhibit-compacting-font-caches t
      bidi-inhibit-bpa t
      pgtk-wait-for-event-timeout 0
      auto-window-vscroll nil
      process-adaptive-read-buffering nil)

;; Strip UI chrome before the first frame is drawn to avoid startup
;; flicker/resize (this is the main reason these three belong in
;; early-init.el rather than init.el).
(add-to-list 'default-frame-alist '(background-color . "#000000"))
(add-to-list 'default-frame-alist '(foreground-color . "#ffffff"))
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; package.el bootstrap — needs to happen before init.el's use-package
;; declarations run.
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(load custom-file 'noerror)

(provide 'early-init)
;;; early-init.el ends here
