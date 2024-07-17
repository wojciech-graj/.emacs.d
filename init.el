;; -*- coding: utf-8; lexical-binding: t -*-

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initial setup
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setq
 gc-cons-threshold (* 16 (* 1024 1024))
 ring-bell-function 'ignore
 inhibit-startup-screen t
 initial-scratch-message nil
 sentence-end-double-space nil
 save-interprogram-paste-before-kill t
 use-dialog-box nil
 mark-even-if-inactive nil
 kill-whole-line t
 case-fold-search nil
 compilation-read-command nil
 compilation-scroll-output 'first-error
 use-short-answers t
 fast-but-imprecise-scrolling t
 load-prefer-newer t
 confirm-kill-processes nil
 native-comp-async-report-warnings-errors 'silent
 display-line-numbers-type 'absolute
 make-backup-files nil
 auto-save-default nil
 create-lockfiles nil
 custom-file (make-temp-name "/tmp/")
 custom-safe-themes t
 max-mini-window-height 8
 use-package-always-ensure t)

;; Mac-specific config
(when (eq system-type 'darwin)
  (progn
    (setq mac-command-modifier 'super)
    (setenv "CONDA_PREFIX" "/opt/homebrew/Caskroom/miniconda/base")))

(fset 'yes-or-no-p 'y-or-n-p)

(cond
 ((file-directory-p "~/Documents/code/")
  (setq default-directory "~/Documents/code/"))
 ((file-directory-p "~/Documents/")
  (setq default-directory "~/Documents/")))

(dolist (mode '(tool-bar-mode menu-bar-mode scroll-bar-mode))
  (when (fboundp mode)
    (apply mode '(-1))))

(dolist (mode '(column-number-mode global-display-line-numbers-mode))
  (when (fboundp mode)
    (apply mode '(1))))

(set-charset-priority 'unicode)
(prefer-coding-system 'utf-8-unix)
(delete-selection-mode t)
(global-hl-line-mode t)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Visuals
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(load-theme 'manoj-dark t)

(defun font-exists-p (font)
  (if (null (x-list-fonts font))
      nil
    t))

(when (window-system)
  (cond
   ((font-exists-p "Courier Prime")
    (set-frame-font "Courier Prime:spacing=100:size=20" nil t))
   ((font-exists-p "Courier New")
    (set-frame-font "Courier New:spacing=100:size=20" nil t))))

(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Modeline
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Modified from: http://amitp.blogspot.se/2011/08/emacs-custom-mode-line.html
(defun shorten-directory (dir max-length)
  "Show up to `max-length' characters of a directory name `dir'."
  (let ((path (reverse (split-string (abbreviate-file-name dir) "/")))
        (output ""))
    (when (and path (equal "" (car path)))
      (setq path (cdr path)))
    (while (and path
                (< (+ (length output) (length (car path)))
                   (- max-length 4)))
      (setq output (concat (car path) "/" output))
      (setq path (cdr path)))
    (when path
      (setq output (concat ".../" output)))
    output))

(setq-default mode-line-format
              '("%e"
                mode-line-front-space
                mode-line-modified
                " "
                (:eval
                 '((line-number-mode
                    ("%4l" (column-number-mode (":" (3 "%c")))))))
                " "
                (:propertize
                 (:eval
                  (format "%24s"
                          (if (buffer-file-name)
                              (shorten-directory default-directory 24)
                            "")))
                 face font-lock-preprocessor-face)
                mode-line-buffer-identification
                "  "
                mode-line-modes
                mode-line-misc-info
                mode-line-end-spaces))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize package.el and use-package
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'package)
(add-to-list
 'package-archives '("melpa" . "http://melpa.org/packages/")
 t)
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

;; Bootstrap 'use-package'
(eval-after-load
    'gnutls '(add-to-list 'gnutls-trustfiles "/etc/ssl/cert.pem"))
(unless (package-installed-p 'use-package)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Misc.
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Diminish
(use-package
 diminish
 :config (diminish 'eldoc-mode) (diminish 'visual-line-mode))

;; Miscellaneous keybindings
(require 'bind-key)
(bind-key "C-s" #'isearch-forward-regexp)
(bind-key "C-S-s" #'rgrep)
(bind-key "C-c s" #'isearch-forward-symbol)

;; Wrap
(setq-default truncate-lines t)
(global-visual-line-mode t)

;; From: https://blog.sumtypeofway.com/posts/emacs-config.html
;; Reduce quantity of dired buffers
(defun dired-up-directory-same-buffer ()
  "Go up in the same buffer."
  (find-alternate-file ".."))

(defun my-dired-mode-hook ()
  (put 'dired-find-alternate-file 'disabled nil) ; Disables the warning.
  (define-key dired-mode-map (kbd "RET") 'dired-find-alternate-file)
  (define-key
   dired-mode-map (kbd "^") 'dired-up-directory-same-buffer))

(add-hook 'dired-mode-hook #'my-dired-mode-hook)

(setq dired-use-ls-dired nil)

(defun display-startup-echo-area-message ()
  (message "Welcome back."))

;; Shebang line in scripts
(setq executable-prefix-env t)

;; Bind comment-dwim
(bind-key* "C-c /" #'comment-dwim)

;; Closing brackets
(electric-pair-mode)

;; Unicode char
(bind-key "C-c U" #'insert-char)

;; Bind init file
(defun open-init-file ()
  (interactive)
  (find-file "~/.emacs.d/init.el"))
(bind-key "C-c e" #'open-init-file)

;; Bind notes file
(defun open-notes-file ()
  (interactive)
  (find-file "~/.emacs.d/notes.org"))
(bind-key "C-c n" #'open-notes-file)

;; Bind undo
(global-unset-key "\C-z")
(global-set-key "\C-z" 'advertised-undo)

;; Bind copy/paste
(cua-mode t)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Packages
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Org
(use-package
 org
 :mode ("\\.org\\'" . org-mode)
 :custom
 (org-hide-leading-stars t)
 (org-hide-emphasis-markers t)
 (org-startup-with-inline-images t)
 (org-image-actual-width nil)
 :config
 (org-babel-do-load-languages
  'org-babel-load-languages '((shell . t))))

;; parenthesis highlighting
(use-package
 paren
 :custom
 (show-paren-delay 0)
 (show-paren-style 'parenthesis)
 :config (show-paren-mode 1))

;; Completion
(use-package
 dabbrev
 :bind (("C-/" . #'dabbrev-completion))
 :custom (dabbrev-case-replace nil))

;; Dim un-selected windows
(use-package
 dimmer
 :custom (dimmer-fraction 0.2)
 :config (dimmer-mode))

(use-package
 centered-window
 :diminish
 :custom (cwm-centered-window-width 120) (centered-window-mode t))

(use-package
 which-key
 :diminish
 :custom (which-key-enable-extended-define-key t)
 :config
 (which-key-mode)
 (which-key-setup-minibuffer))

(use-package
 undo-tree
 :diminish
 :bind (("C-c _" . undo-tree-visualize))
 :custom
 (undo-tree-auto-save-history t)
 (undo-tree-history-directory-alist '(("." . "~/.emacs.d/undo")))
 (undo-tree-enable-undo-in-region nil)
 (undo-limit 320000)
 (undo-strong-limit 480000)
 (undo-tree-visualizer-timestamps t)
 (undo-tree-visualizer-diff t)
 :config (global-undo-tree-mode 1))

;; Recent buffers in a new Emacs session
(use-package
 recentf
 :diminish
 :custom
 (recentf-auto-cleanup 'never)
 (recentf-max-saved-items 1000)
 (recentf-save-file (concat user-emacs-directory ".recentf"))
 :config (recentf-mode t))

(use-package wgrep :custom wgrep-auto-save-buffer t)

(use-package
 dashboard
 :custom
 (dashboard-center-content t)
 (dashboard-startup-banner `logo)
 (dashboard-items '((recents . 16)))
 :config (dashboard-setup-startup-hook))

;; PDF
(use-package
 pdf-tools
 :mode ("\\.pdf\\'" . pdf-view-mode)
 :hook
 (pdf-view-mode . (lambda () (display-line-numbers-mode -1)))
 :config
 (setq-default pdf-view-display-size 'fit-page)
 (pdf-tools-install :no-query))

(use-package
 company
 :diminish
 :config
 (global-company-mode t)
 (define-key company-active-map (kbd "<return>") nil)
 (define-key company-active-map (kbd "RET") nil)
 (define-key
  company-active-map (kbd "TAB") #'company-complete-selection)
 (define-key
  company-active-map (kbd "<tab>") #'company-complete-selection)
 (define-key company-active-map (kbd "SPC") nil))

(use-package citeproc)

(use-package flycheck :hook (java-mode . flycheck-mode) :defer t)

;; indentation markers
(use-package
 highlight-indent-guides
 :diminish
 :hook
 (prog-mode
  .
  (lambda ()
    (unless (derived-mode-p 'emacs-lisp-mode)
      (highlight-indent-guides-mode))))
 :custom
 (highlight-indent-guides-method 'character)
 (highlight-indent-guides-character ?|))

(use-package lsp-java :after lsp)

;; lsp
(use-package
 lsp-mode
 :hook ((java-mode c-mode rust-mode) . lsp-deferred)
 :commands lsp
 :custom
 (lsp-auto-guess-root t)
 (lsp-log-io nil)
 (lsp-restart 'auto-restart)
 (lsp-enable-symbol-highlighting nil)
 (lsp-enable-on-type-formatting nil)
 (lsp-signature-auto-activate nil)
 (lsp-signature-render-documentation nil)
 (lsp-modeline-code-actions-enable nil)
 (lsp-modeline-diagnostics-enable nil)
 (lsp-headerline-breadcrumb-enable nil)
 (lsp-semantic-tokens-enable nil)
 (lsp-enable-folding nil)
 (lsp-enable-imenu nil)
 (read-process-output-max (* 1024 1024)) ;; 1MB
 (lsp-idle-delay 0.5)
 (lsp-lens-enable nil)
 (lsp-inlay-hint-enable t)

 ;; C
 (lsp-clients-clangd-args '("--compile-commands-dir=./builddir"))

 ;; Java
 (lsp-java-vmargs
  `("-noverify" "-Xmx1G" "-XX:+UseG1GC" "-XX:+UseStringDeduplication"
    ,(concat
      "-javaagent:"
      (expand-file-name ".local/share/java/lombok.jar"
                        (getenv "HOME")))
    ,(concat
      "-Xbootclasspath/a:"
      (expand-file-name ".local/share/java/lombok.jar"
                        (getenv "HOME")))))

 ;; Rust
 (lsp-rust-analyzer-display-lifetime-elision-hints-enable
  "skip_trivial")
 (lsp-rust-analyzer-display-chaining-hints t)
 (lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names
  nil)
 (lsp-rust-analyzer-display-closure-return-type-hints t)
 (lsp-rust-analyzer-display-parameter-hints nil)
 (lsp-rust-analyzer-display-reborrow-hints nil)

 ;; Python
 (lsp-pylsp-plugins-yapf-enabled t)
 (lsp-pylsp-plugins-mypy-enabled t)
 (lsp-pylsp-plugins-pycodestyle-enabled nil)
 (lsp-pylsp-plugins-mccabe-enabled nil)
 (lsp-pylsp-plugins-isort-enabled t)
 (lsp-pylsp-plugins-rope-autoimport-code-actions-enabled t)
 (lsp-pylsp-plugins-rope-autoimport-completions-enabled nil)
 (lsp-pylsp-plugins-rope-autoimport-enabled t)
 (lsp-pylsp-plugins-rope-completion-enabled nil))

;; Custom LSP modeline print function without process id
;; From: https://github.com/emacs-lsp/lsp-mode/discussions/3729
(defun aj8/lsp--workspace-print (workspace)
  "Visual representation WORKSPACE."
  (let* ((proc (lsp--workspace-cmd-proc workspace))
         (status (lsp--workspace-status workspace))
         (server-id
          (->
           workspace
           lsp--workspace-client
           lsp--client-server-id
           symbol-name)))
    (if (eq 'initialized status)
        (format "%s" server-id)
      (format "%s/%s" server-id status))))

;; Don't show process id in modeline
(advice-add
 #'lsp--workspace-print
 :override #'aj8/lsp--workspace-print)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Whitespace
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(add-hook 'before-save-hook #'delete-trailing-whitespace)
(setq require-final-newline t)

(defun disable-tabs ()
  (setq indent-tabs-mode nil))
(defun enable-tabs ()
  (local-set-key (kbd "TAB") 'tab-to-tab-stop))

(add-hook 'prog-mode-hook 'enable-tabs)

;; Making electric-indent behave sanely
(setq-default electric-indent-inhibit t)

(setq backward-delete-char-untabify-method 'hungry)

;; From: https://lists.gnu.org/r/help-gnu-emacs/2003-06/msg00372.html
(defun backward-delete-char-tablevel ()
  "Delete space backward to prev level of indentation."
  (interactive)
  (if (or (bolp)
          (save-excursion
            (skip-chars-backward " \t")
            (not (bolp))))
      ;; If we're not inside indentation, behave as usual.
      (call-interactively 'backward-delete-char-untabify)
    ;; We're inside indentation.
    (let* ((col (current-column))
           (destcol
            (save-excursion
              ;; Skip previous lines that are more indented than us.
              (while (and (not (bobp))
                          (zerop (forward-line -1))
                          (skip-chars-forward " \t")
                          (>= (current-column) col)))
              (current-column))))
      (delete-region
       (point)
       (progn
         (move-to-column destcol)
         (point))))))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Languages
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; C
(defun hook-c ()
  (setq indent-tabs-mode t)
  (enable-tabs)
  (setq tab-width 8))
(use-package
 cc-mode
 :hook (c-mode . hook-c)
 :custom
 (c-default-style "linux")
 (c-indent-level 8)
 (c-basic-offset 8)
 :config (c-set-offset 'arglist-cont-nonempty '+))

;; Python
(use-package
 pyvenv
 :config
 (setenv "WORKON_HOME"
         (concat (getenv "CONDA_PREFIX") "/envs"))
 (pyvenv-mode t))
(defun hook-py ()
  (setq indent-tabs-mode nil)
  (enable-tabs)
  (setq tab-width 4)
  (add-hook 'before-save-hook #'lsp-format-buffer t t)
  (unless (getenv "VIRTUAL_ENV")
    (call-interactively #'pyvenv-workon))
  (setq lsp-pylsp-plugins-jedi-environment (getenv "VIRTUAL_ENV"))
  (lsp-deferred))
(add-hook 'python-mode-hook 'hook-py)
(setq-default python-indent-offset 4)

;; Lua
(defun hook-lua ()
  (setq indent-tabs-mode nil)
  (enable-tabs)
  (setq tab-width 3))
(use-package
 lua-mode
 :hook (lua-mode . hook-lua)
 :custom
 (lua-indent-nested-block-content-align nil)
 (lua-indent-close-paren-align nil)
 (lua-indent-offset 3))

;; Elisp
(use-package
 elisp-autofmt
 :commands (elisp-autofmt-mode elisp-autofmt-buffer)
 :hook (emacs-lisp-mode . elisp-autofmt-mode))
(add-hook 'emacs-lisp-mode-hook 'disable-tabs)

;; SQL
(use-package
 sqlformat
 :hook (sql-mode . sqlformat-on-save-mode)
 :custom (sqlformat-command 'pgformatter)
 (sqlformat-args
  '("--type-case=2" "--function-case=1" "--no-space-function"
    "--placeholder=%\\([a-zA-Z_]+\\)s" ;; Psycopg parameters: %(...)s
    )))

;; Java
(defun hook-java ()
  (setq indent-tabs-mode nil)
  (enable-tabs)
  (setq tab-width 4)
  (setq c-basic-offset 4))
(add-hook 'java-mode-hook 'hook-java)

;; Rust
(use-package cargo :diminish :hook (rust-mode . cargo-minor-mode))
(use-package
 rust-mode
 :hook (rust-mode . hook-rust)
 :bind
 (:map
  rust-mode-map
  (("DEL" . backward-delete-char-tablevel)
   ([?\t] . company-indent-or-complete-common)))
 :custom
 (rust-format-on-save t)
 (rust-format-show-buffer nil)
 (rust-format-goto-problem nil))
(defun hook-rust ()
  (setq indent-tabs-mode nil)
  (disable-tabs)
  (setq tab-width 4)
  (setq c-basic-offset 4))

;; https://github.com/scturtle/dotfiles/blob/f1e087e247876dbae20d56f944a1e96ad6f31e0b/doom_emacs/.doom.d/config.el#L74-L85
(cl-defmethod lsp-clients-extract-signature-on-hover
    (contents (_server-id (eql rust-analyzer)))
  (-let* (((&hash "value") contents)
          (groups
           (--partition-by (s-blank? it) (s-lines (s-trim value))))
          (sig_group
           (if (s-equals? "```rust" (car (-third-item groups)))
               (-third-item groups)
             (car groups)))
          (sig
           (-->
            sig_group
            (--drop-while (s-equals? "```rust" it) it)
            (--take-while (not (s-equals? "```" it)) it)
            (--map (s-trim it) it)
            (s-join " " it))))
    (lsp--render-element (concat "```rust\n" sig "\n```"))))