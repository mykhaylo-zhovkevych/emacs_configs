;;; early-init.el --- Early startup configuration -*- lexical-binding: t; -*-

(setq package-enable-at-startup nil
      frame-inhibit-implied-resize t
      inhibit-startup-screen t
      inhibit-splash-screen t
      inhibit-startup-message t
      initial-scratch-message nil)

;; Set frame parameters before the first graphical frame is drawn.  Keep the
;; menu bar visible while preventing the tool and scroll bars from flashing.
(add-to-list 'default-frame-alist '(menu-bar-lines . 1))
(add-to-list 'default-frame-alist '(tool-bar-lines . 0))
(add-to-list 'default-frame-alist '(vertical-scroll-bars . nil))

;; Explicit arguments make repeated evaluation idempotent instead of toggling.
(menu-bar-mode 1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;;; early-init.el ends here
