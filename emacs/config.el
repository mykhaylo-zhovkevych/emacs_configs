(defvar elpaca-installer-version 0.12)
  (defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
  (defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
  (defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
  (defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                                :ref nil :depth 1 :inherit ignore
                                :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                                :build (:not elpaca-activate)))
  (let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
         (build (expand-file-name "elpaca/" elpaca-builds-directory))
         (order (cdr elpaca-order))
         (default-directory repo))
    (add-to-list 'load-path (if (file-exists-p build) build repo))
    (unless (file-exists-p repo)
      (make-directory repo t)
      (when (<= emacs-major-version 28) (require 'subr-x))
      (condition-case-unless-debug err
          (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                    ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                    ,@(when-let* ((depth (plist-get order :depth)))
                                                        (list (format "--depth=%d" depth) "--no-single-branch"))
                                                    ,(plist-get order :repo) ,repo))))
                    ((zerop (call-process "git" nil buffer t "checkout"
                                          (or (plist-get order :ref) "--"))))
                    (emacs (concat invocation-directory invocation-name))
                    ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                          "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                    ((require 'elpaca))
                    ((elpaca-generate-autoloads "elpaca" repo)))
              (progn (message "%s" (buffer-string)) (kill-buffer buffer))
            (error "%s" (with-current-buffer buffer (buffer-string))))
        ((error) (warn "%s" err) (delete-directory repo 'recursive))))
    (unless (require 'elpaca-autoloads nil t)
      (require 'elpaca)
      (elpaca-generate-autoloads "elpaca" repo)
      (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
  (add-hook 'after-init-hook #'elpaca-process-queues)
  (elpaca `(,@elpaca-order))

  ;; Install a package via the elpaca macro
  ;; See the "recipes" section of the manual for more details.

  ;; (elpaca example-package)

  ;; Install use-package support
  (elpaca elpaca-use-package
    ;; Enable use-package :ensure support for Elpaca.
    (elpaca-use-package-mode))

  (elpaca-wait)

  ;;When installing a package used in the init file itself,
  ;;e.g. a package which adds a use-package key word,
  ;;use the :wait recipe keyword to block until that package is installed/configured.
  ;;For example:
  ;;(use-package general :ensure (:wait t) :demand t)

  (elpaca (general :wait t)
    (require 'general)
    (general-evil-setup)

    ;; set up 'SPC' as the global leader key
    (general-create-definer dt/leader-keys
  			  :states '(normal insert visual emacs)
  			  :keymaps 'override
  			  :prefix "SPC" ;; set leader
  			  :global-prefix "M-SPC") ;; access leader in insert mode

    (dt/leader-keys
     "b" '(:ignore t :wk "buffer")
     "bb" '(switch-to-buffer :wk "Switch buffer")
     "bk" '(kill-this-buffer :wk "Kill this buffer")
     "bn" '(next-buffer :wk "Next buffer")
     "bp" '(previous-buffer :wk "Previous buffer")
     "br" '(revert-buffer :wk "Reload buffer"))

    )

  ;; Expands to: (elpaca evil (use-package evil :demand t))
  (use-package evil
    :ensure (:wait t)
    :demand t
    :config
    (evil-mode 1))

  (require 'server)
  (unless (server-running-p)
    (condition-case err
        (server-start)
      (file-error
       (warn "Could not start Emacs server: %s" (error-message-string err)))))

  ;;Turns off elpaca-use-package-mode current declaration
  ;;Note this will evaluate the declaration immediately. It is not deferred.
  ;;Useful for configuring built-in emacs features.
  (use-package emacs
    :ensure nil
    :config
    (setq ring-bell-function #'ignore
          inhibit-startup-screen t
          inhibit-splash-screen t
          inhibit-startup-message t
          initial-buffer-choice t))

  (set-face-attribute 'default nil
  :font "JetBrains Mono"
  :height 110
  :weight 'medium)
(set-face-attribute 'variable-pitch nil
  :font "Ubuntu"
  :height 120
  :weight 'medium)
(set-face-attribute 'fixed-pitch nil
  :font "JetBrains Mono"
  :height 110
  :weight 'medium)
;; Makes commented text and keywords italics.
;; This is working in emacsclient but not emacs.
;; Your font must have an italic face available.
(set-face-attribute 'font-lock-comment-face nil
  :slant 'italic)
(set-face-attribute 'font-lock-keyword-face nil
  :slant 'italic)

;; This sets the default font on all graphical frames created after restarting Emacs.
;; Does the same thing as 'set-face-attribute default' above, but emacsclient fonts
;; are not right unless I also add this method of setting the default font.
(add-to-list 'default-frame-alist '(font . "JetBrains Mono-11"))

;; Uncomment the following line if line spacing needs adjusting.
(setq-default line-spacing 0.12)

(menu-bar-mode)
(tool-bar-mode -1)
(scroll-bar-mode -1)
