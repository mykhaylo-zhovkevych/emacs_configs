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
    (setq ring-bell-function #'ignore))

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

;; doom-themes-treemacs-config and treemacs's own icon theme both hard-require
;; nerd-icons; without an explicit package declaration it's never actually
;; loaded, which throws mid dired-mode-hook and leaves Dired buffers
;; permanently uninitialized (see treemacs--follow crash notes below).
(use-package nerd-icons
  :ensure t)

(use-package treemacs
  :ensure t
  :defer t
  :init
  (with-eval-after-load 'winum
    (define-key winum-keymap (kbd "M-0") #'treemacs-select-window))
  :config
  (progn
    (setq treemacs-buffer-name-function            #'treemacs-default-buffer-name
          treemacs-buffer-name-prefix              " *Treemacs-Buffer-"
          treemacs-collapse-dirs                   (if treemacs-python-executable 3 0)
          treemacs-deferred-git-apply-delay        0.5
          treemacs-directory-name-transformer      #'identity
          treemacs-display-in-side-window          t
          treemacs-eldoc-display                   'simple
          treemacs-file-event-delay                2000
          treemacs-file-extension-regex            treemacs-last-period-regex-value
          treemacs-file-follow-delay               0.2
          treemacs-file-name-transformer           #'identity
          treemacs-follow-after-init               t
          treemacs-expand-after-init               t
          treemacs-find-workspace-method           'find-for-file-or-pick-first
          treemacs-git-command-pipe                ""
          treemacs-goto-tag-strategy               'refetch-index
          treemacs-header-scroll-indicators        '(nil . "^^^^^^")
          treemacs-hide-dot-git-directory          t
          treemacs-hide-dot-jj-directory           t
          treemacs-indentation                     2
          treemacs-indentation-string              " "
          treemacs-is-never-other-window           nil
          treemacs-max-git-entries                 5000
          treemacs-missing-project-action          'ask
          treemacs-move-files-by-mouse-dragging    t
          treemacs-move-forward-on-expand          nil
          treemacs-no-png-images                   nil
          treemacs-no-delete-other-windows         t
          treemacs-project-follow-cleanup          nil
          treemacs-persist-file                    (expand-file-name ".cache/treemacs-persist" user-emacs-directory)
          treemacs-position                        'left
          treemacs-read-string-input               'from-child-frame
          treemacs-recenter-distance               0.1
          treemacs-recenter-after-file-follow      nil
          treemacs-recenter-after-tag-follow       nil
          treemacs-recenter-after-project-jump     'always
          treemacs-recenter-after-project-expand   'on-distance
          treemacs-litter-directories              '("/node_modules" "/.venv" "/.cask")
          treemacs-project-follow-into-home        nil
          treemacs-show-cursor                     nil
          treemacs-show-hidden-files               t
          treemacs-silent-filewatch                nil
          treemacs-silent-refresh                  nil
          treemacs-sorting                         'alphabetic-asc
          treemacs-select-when-already-in-treemacs 'move-back
          treemacs-space-between-root-nodes        t
          treemacs-tag-follow-cleanup              t
          treemacs-tag-follow-delay                1.5
          treemacs-text-scale                      nil
          treemacs-user-mode-line-format           nil
          treemacs-user-header-line-format         nil
          treemacs-wide-toggle-width               70
          treemacs-width                           35
          treemacs-width-increment                 1
          treemacs-width-is-initially-locked       t
          treemacs-workspace-switch-cleanup        nil)

    ;; The default width and height of the icons is 22 pixels. If you are
    ;; using a Hi-DPI display, uncomment this to double the icon size.
    ;;(treemacs-resize-icons 44)

    (treemacs-follow-mode t)
    ;; treemacs-follow-mode's idle timer calls `dired-current-directory' on
    ;; any buffer whose major-mode is dired-mode; if that buffer's
    ;; `dired-subdir-alist' hasn't been populated yet (e.g. a Dired buffer on
    ;; "~" still mid-readin), dired signals "No subdir-alist in %s" instead
    ;; of returning a directory. Fall back to `default-directory' instead of
    ;; erroring.
    (with-eval-after-load 'dired
      (advice-add 'dired-current-directory :around
                  (lambda (orig-fn &rest args)
                    (if dired-subdir-alist
                        (apply orig-fn args)
                      default-directory))))
    (treemacs-filewatch-mode t)
    (treemacs-fringe-indicator-mode 'always)
    (when treemacs-python-executable
      (treemacs-git-commit-diff-mode t))

    (pcase (cons (not (null (executable-find "git")))
                 (not (null treemacs-python-executable)))
      (`(t . t)
       (treemacs-git-mode 'deferred))
      (`(t . _)
       (treemacs-git-mode 'simple)))

    (treemacs-hide-gitignored-files-mode nil)
    (unless noninteractive
      (treemacs-start-on-boot)))
  :bind
  (:map global-map
        ("M-0"       . treemacs-select-window)
        ("C-x t 1"   . treemacs-delete-other-windows)
        ("C-x t t"   . treemacs)
        ("C-x t d"   . treemacs-select-directory)
        ("C-x t B"   . treemacs-bookmark)
        ("C-x t C-t" . treemacs-find-file)
        ("C-x t M-t" . treemacs-find-tag)))

(use-package treemacs-evil
  :after (treemacs evil)
  :ensure t)

(use-package treemacs-projectile
  :after (treemacs projectile)
  :ensure t)

(use-package treemacs-icons-dired
  :hook (dired-mode . treemacs-icons-dired-enable-once)
  :ensure t)

(use-package transient
  :ensure (:wait t))

(use-package magit
  :ensure (:wait t)
  :commands magit-status
  :bind ("C-x g" . magit-status))

(use-package treemacs-magit
  :after (treemacs magit)
  :ensure t)

(use-package treemacs-persp ;;treemacs-perspective if you use perspective.el vs. persp-mode
  :after (treemacs persp-mode) ;;or perspective vs. persp-mode
  :ensure t
  :config (treemacs-set-scope-type 'Perspectives))

(use-package treemacs-tab-bar ;;treemacs-tab-bar if you use tab-bar-mode
  :after (treemacs)
  :ensure t
  :config (treemacs-set-scope-type 'Tabs))

(use-package doom-themes
  :ensure t
  :custom
  ;; Global settings (defaults)
  (doom-themes-enable-bold t)   ; if nil, bold is universally disabled
  (doom-themes-enable-italic t) ; if nil, italics is universally disabled
  ;; for treemacs users
  (doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  :config
  (load-theme 'doom-one t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (nerd-icons must be installed!)
  (doom-themes-neotree-config)
  ;; or for treemacs users
  (doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(use-package solaire-mode
    :ensure t
    :config
    (solaire-global-mode +1))

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

 (use-package spacious-padding
    :ensure (:wait t)
    :config
    (setq spacious-padding-widths
          '(:internal-border-width 15
            :header-line-width 4
            :mode-line-width 6
            :tab-width 4
            :right-divider-width 10
            :scroll-bar-width 8))
    (spacious-padding-mode 1))

(use-package tab-bar
  :ensure nil
  :config
  (tab-bar-mode 1)
  (tab-bar-history-mode 1)
  (setq tab-bar-show 1
        tab-bar-close-button-show t
        tab-bar-new-button-show t))

(use-package dashboard
  :elpaca t
  :config
  (setq dashboard-banner-logo-title "Welcome to Emacs"
        dashboard-startup-banner 'official
        dashboard-center-content t
        dashboard-vertically-center-content t
        dashboard-display-icons-p t
        dashboard-icon-type 'nerd-icons
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-items '((recents   . 8)
                          (bookmarks . 5)
                          (projects  . 5)
                          (agenda    . 5)))

  (add-hook 'elpaca-after-init-hook
            #'dashboard-insert-startupify-lists)
  (add-hook 'elpaca-after-init-hook
            #'dashboard-initialize)

  (dashboard-setup-startup-hook)

  ;; Show Dashboard in new frames created by emacsclient.
  (when (daemonp)
    (setq initial-buffer-choice #'dashboard-open)
    (add-hook 'server-after-make-frame-hook #'dashboard-open)))

(use-package golden-ratio
  :ensure t
  :config
  (golden-ratio-mode 1))
