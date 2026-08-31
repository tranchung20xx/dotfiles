;;; early-init.el --- Early initialization  -*- lexical-binding: t; -*-
;;  This config based-on Tsoding emacs config
;;  https://github.com/rexim/dotfiles

;; Defer GC during startup, restore sane values once we're up.
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
              read-process-output-max (* 1024 1024)
              frame-resize-pixelwise t
              window-resize-pixelwise t
              redisplay-dont-pause t
              redisplay-skip-fontification-on-input t
              inhibit-compacting-font-caches t
              bidi-inhibit-bpa t
              process-adaptive-read-buffering nil
              pgtk-wait-for-event-timeout 0)

;; Strip UI chrome before the first frame is drawn to avoid startup
;; flicker/resize (this is the main reason these three belong in
;; early-init.el rather than init.el).
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; package.el bootstrap — needs to happen before init.el's use-package
;; declarations run.
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless package-archive-contents
  (condition-case err
      (package-refresh-contents)
    (error (message "package-refresh-contents failed: %s" err))))

(setq-default user-emacs-directory "~/.emacs.d/user")

(provide 'early-init)
;;; early-init.el ends here
