;; -*- coding: utf-8; lexical-binding: t -*-

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initial setup
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Use with `use-package-report` for benchmarking init.el
(when nil
  (setq use-package-compute-statistics t))

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
 custom-file "~/.emacs.d/.emacs-custom.el"
 custom-safe-themes t
 max-mini-window-height 8
 use-package-always-ensure t)

;; OS-specific config
(cond
 ((eq system-type 'darwin)
  (setq mac-command-modifier 'super)
  (setenv "CONDA_PREFIX" "/opt/homebrew/Caskroom/miniconda/base"))
 ((eq system-type 'gnu/linux)
  (setenv "CONDA_PREFIX" "~/miniconda3")))

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
(global-so-long-mode t)

(unless (file-exists-p custom-file)
  (with-temp-buffer
    (write-file custom-file)))
(load custom-file)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Visuals
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(load-theme 'manoj-dark t)

(defun font-exists-p (font)
  (if (null (x-list-fonts font))
      nil
    t))

(let* ((font-size
        (if (string-match-p "laptop" (system-name))
            36
          20))
       (font-cmd (format ":spacing=100:size=%d" font-size)))
  (when (window-system)
    (cond
     ((font-exists-p "Courier Prime")
      (set-frame-font (concat "Courier Prime" font-cmd) nil t))
     ((font-exists-p "Courier New")
      (set-frame-font (concat "Courier New" font-cmd) nil t)))))

(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Modeline
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; From (modified): http://amitp.blogspot.se/2011/08/emacs-custom-mode-line.html
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

(use-package exec-path-from-shell
  :custom (exec-path-from-shell-arguments '("-l"))
  :config
  (when (memq window-system '(mac ns x))
    (exec-path-from-shell-initialize)))

;; Diminish
(use-package diminish
  :config
  (diminish 'eldoc-mode)
  (diminish 'visual-line-mode))

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

;; Closing brackets
(electric-pair-mode)

;; Unicode char
(bind-key "C-c U" #'insert-char)

;; Bind init file
(defun open-init-file ()
  (interactive)
  (find-file "~/.emacs.d/init.el"))
(bind-key "C-c e" #'open-init-file)

;; Bind undo
(global-unset-key "\C-z")
(global-set-key "\C-z" 'advertised-undo)

;; Bind copy/paste
(cua-mode t)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'ox-publish)

(setq wgraj/org-publish-base-directory
      (or (getenv "WEBSITE_BASE_DIRECTORY")
          "~/Documents/code/w-graj.net")
      wgraj/org-publish-publishing-directory
      (or (getenv "WEBSITE_PUBLISHING_DIRECTORY")
          "~/Documents/code/out.w-graj.net"))

(use-package org
  :mode ("\\.org\\'" . org-mode)
  :custom
  (org-hide-leading-stars t)
  (org-hide-emphasis-markers t)
  (org-startup-with-inline-images t)
  (org-image-actual-width nil)
  (org-export-allow-bind-keywords t)
  (org-plantuml-jar-path "/usr/share/java/plantuml-1.2025.4.jar")
  (org-confirm-babel-evaluate #'my-org-confirm-babel-evaluate)
  (org-publish-project-alist
   `(("orgfiles"
      :recursive t
      :base-directory ,wgraj/org-publish-base-directory
      :publishing-function org-html-publish-to-html
      :publishing-directory ,wgraj/org-publish-publishing-directory
      :section-numbers nil
      :with-toc nil
      :with-title nil
      :time-stamp-file nil
      :html-head-include-default-style nil
      :html-head "<link rel=\"stylesheet\" href=\"/style.css\" type=\"text/css\"/>")

     ("other"
      :recursive t
      :base-directory ,wgraj/org-publish-base-directory
      :base-extension "svg\\|css\\|asc\\|ico"
      :publishing-directory ,wgraj/org-publish-publishing-directory
      :publishing-function org-publish-attachment)
     ("website" :components ("orgfiles" "other"))))
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages '((shell . t) (sql . t) (plantuml . t)))
  (setq org-plantuml-executable-args
        (append org-plantuml-executable-args '("-theme" "mono")))
  (setq org-format-latex-options
        (plist-put org-format-latex-options :scale 3.0))
  (defun org-confirm-babel-evaluate-nil (lang body)
    nil)
  ;; https://lists.gnu.org/archive/html/emacs-orgmode/2016-07/msg00394.html
  (defun esf/execute-autoexec-block ()
    (interactive)
    (org-babel-goto-named-src-block "autoexec")
    (setq-local org-confirm-babel-evaluate
                #'org-confirm-babel-evaluate-nil)
    (org-babel-execute-src-block)
    (kill-local-variable 'org-confirm-babel-evaluate))
  (defun my-org-confirm-babel-evaluate (lang body)
    (not (string= lang "plantuml")))
  (defun my-org-html-wrap-tables
      (orig-fun table contents info &rest _)
    (format "<div class=\"table-container\">\n%s\n</div>"
            (funcall orig-fun table contents info)))
  (advice-add 'org-html-table :around #'my-org-html-wrap-tables))

(use-package htmlize
  :custom (org-html-htmlize-output-type 'css)
  :config
  ;; From: https://github.com/hniksic/emacs-htmlize/issues/45#issuecomment-1535041865
  (setq-default htmlize-ignore-background t)
  (defadvice htmlize-face-background
      (around htmlize-ignore-background activate)
    (unless htmlize-ignore-background
      ad-do-it)))

;; From: https://www.cyberaesthete.com/blog/00000000.html
(defun org-html-htmlize-generate-css ()
  "Create the CSS for all font definitions in the current Emacs session.
Use this to create face definitions in your CSS style file that can then
be used by code snippets transformed by htmlize.
This command just produces a buffer that contains class definitions for all
faces used in the current Emacs session.  You can copy and paste the ones you
need into your CSS file.

If you then set `org-html-htmlize-output-type' to `css', calls
to the function `org-html-htmlize-region-for-paste' will
produce code that uses these same face definitions."
  (interactive)
  (unless (require 'htmlize nil t)
    (error "htmlize library missing.  Aborting"))
  (and (get-buffer "*html*") (kill-buffer "*html*"))
  (let ((current-buffer (buffer-string)))
    (with-temp-buffer
      (insert current-buffer)
      (let ((fl (face-list))
            (htmlize-css-name-prefix "org-")
            (htmlize-output-type 'css)
            f
            i)
        (while (setq
                f (pop fl)
                i (and f (face-attribute f :inherit)))
          (when (and (symbolp f) (or (not i) (not (listp i))))
            (insert (org-add-props (copy-sequence "1") nil 'face f))))
        (htmlize-region (point-min) (point-max)))))
  (pop-to-buffer-same-window "*html*")
  (goto-char (point-min))
  (when (re-search-forward "<style" nil t)
    (delete-region (point-min) (match-beginning 0)))
  (when (re-search-forward "</style>" nil t)
    (delete-region (1+ (match-end 0)) (point-max)))
  (beginning-of-line 1)
  (when (looking-at " +")
    (replace-match ""))
  (goto-char (point-min)))

(use-package org-roam
  :bind
  (("C-c n l" . org-roam-buffer-toggle)
   ("C-c n f" . org-roam-node-find)
   ("C-c n i" . org-roam-node-insert)
   ("C-c n r" . org-roam-ref-add)
   ("C-c n t" . org-roam-tag-add)
   ("C-c n a" . org-roam-alias-add))
  :config
  (define-key
   minibuffer-local-completion-map (kbd "SPC") 'self-insert-command)
  (org-roam-setup)
  (org-roam-db-autosync-mode))

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Packages
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; parenthesis highlighting
(use-package paren
  :custom
  (show-paren-delay 0)
  (show-paren-style 'parenthesis)
  :config (show-paren-mode 1))

;; Completion
(use-package dabbrev
  :bind (("C-/" . #'dabbrev-completion))
  :custom (dabbrev-case-replace nil))

;; Dim un-selected windows
(use-package dimmer
  :custom (dimmer-fraction 0.2)
  :config (dimmer-mode))

(use-package centered-window
  :diminish
  :custom
  (cwm-centered-window-width 120)
  (centered-window-mode t))

(use-package which-key
  :diminish
  :custom (which-key-enable-extended-define-key t)
  :config
  (which-key-mode)
  (which-key-setup-minibuffer))

(use-package undo-tree
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
(use-package recentf
  :diminish
  :custom
  (recentf-auto-cleanup 'never)
  (recentf-max-saved-items 1000)
  (recentf-save-file (concat user-emacs-directory ".recentf"))
  :config (recentf-mode t))

(use-package wgrep
  :custom (wgrep-auto-save-buffer t))

(use-package dashboard
  :custom
  (dashboard-center-content t)
  (dashboard-startup-banner `logo)
  (dashboard-items '((recents . 16)))
  :config (dashboard-setup-startup-hook))

;; PDF
(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :hook (pdf-view-mode . (lambda () (display-line-numbers-mode -1)))
  :config
  (setq-default pdf-view-display-size 'fit-page)
  (pdf-tools-install :no-query))

(use-package company
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

(use-package flycheck
  :hook (java-mode . flycheck-mode))

(use-package flyspell
  :diminish
  :hook ((text-mode . flyspell-mode) (prog-mode . flyspell-prog-mode)))

;; indentation markers
(use-package highlight-indent-guides
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

(use-package lsp-haskell)

;; lsp
(use-package lsp-mode
  :hook
  ((java-mode
    c-mode c++-mode rust-mode haskell-mode haskell-literate-mode)
   . lsp-deferred)
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
   `("-noverify"
     "-Xmx1G"
     "-XX:+UseG1GC"
     "-XX:+UseStringDeduplication"))

  ;; Rust
  (lsp-rust-analyzer-display-lifetime-elision-hints-enable
   "skip_trivial")
  (lsp-rust-analyzer-display-chaining-hints t)
  (lsp-rust-analyzer-display-closure-return-type-hints t)
  (lsp-rust-analyzer-display-parameter-hints t)

  ;; Python
  (lsp-pylsp-plugins-yapf-enabled t)
  (lsp-pylsp-plugins-mypy-enabled t)
  (lsp-pylsp-plugins-pycodestyle-enabled nil)
  (lsp-pylsp-plugins-mccabe-enabled nil)
  (lsp-pylsp-plugins-isort-enabled t)
  (lsp-pylsp-plugins-rope-autoimport-code-actions-enabled t)
  (lsp-pylsp-plugins-rope-autoimport-completions-enabled nil)
  (lsp-pylsp-plugins-rope-autoimport-enabled t)
  (lsp-pylsp-plugins-rope-completion-enabled nil)
  :config
  ;; Optional config for Java from Sdkman
  (when nil
    (progn
      (setq lsp-java-configuration-runtimes
            '[(:name
               "JavaSE-21"
               :path
               (expand-file-name ".sdkman/candidates/java/21.0.2-open"
                                 (getenv "HOME"))
               :default t)]
            lsp-java-java-path
            (expand-file-name
             ".sdkman/candidates/java/21.0.2-open/bin/java"
             (getenv "HOME")))
      (setenv "JAVA_HOME"
              (expand-file-name ".sdkman/candidates/java/21.0.2-open"
                                (getenv "HOME"))))))

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
(use-package cc-mode
  :hook ((c-mode . hook-c) (c++-mode . hook-c))
  :custom
  (c-default-style "linux")
  (c-indent-level 8)
  (c-basic-offset 8)
  :config (c-set-offset 'arglist-cont-nonempty '+))

;; Python
(use-package pyvenv
  :config
  (setenv "WORKON_HOME" (concat (getenv "CONDA_PREFIX") "/envs"))
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

;; Cython
(use-package cython-mode)

;; Lua
(defun hook-lua ()
  (setq indent-tabs-mode nil)
  (enable-tabs)
  (setq tab-width 3))
(use-package lua-mode
  :hook (lua-mode . hook-lua)
  :custom
  (lua-indent-nested-block-content-align nil)
  (lua-indent-close-paren-align nil)
  (lua-indent-offset 3))

;; Elisp
(use-package elisp-autofmt
  :commands (elisp-autofmt-mode elisp-autofmt-buffer)
  :hook (emacs-lisp-mode . elisp-autofmt-mode))
(add-hook 'emacs-lisp-mode-hook 'disable-tabs)

;; SQL
(use-package sqlformat
  :hook (sql-mode . sqlformat-on-save-mode)
  :custom
  (sqlformat-command 'pgformatter)
  (sqlformat-args
   '("--type-case=2" "--function-case=1" "--no-space-function"
     "--placeholder=%\\([a-zA-Z_]+\\)s" ;; Psycopg parameters: %(...)s
     )))

;; Java
(use-package lsp-java
  :after lsp)
(defun hook-java ()
  (setq indent-tabs-mode nil)
  (enable-tabs)
  (setq tab-width 4)
  (setq c-basic-offset 4))
(add-hook 'java-mode-hook 'hook-java)

;; Rust
(use-package cargo
  :diminish
  :hook (rust-mode . cargo-minor-mode))
(use-package rust-mode
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

;; From: https://github.com/scturtle/dotfiles/blob/f1e087e247876dbae20d56f944a1e96ad6f31e0b/doom_emacs/.doom.d/config.el#L74-L85
(cl-defmethod lsp-clients-extract-signature-on-hover
    (contents (_server-id (eql rust-analyzer)))
  (-let*
   (((&hash "value") contents)
    (groups (--partition-by (s-blank? it) (s-lines (s-trim value))))
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

;; Haskell
(use-package haskell-mode)
(use-package ormolu
  :diminish
  :hook (haskell-mode . ormolu-format-on-save-mode))

;; YAML
(use-package yaml-mode)

;; Docker
(use-package dockerfile-mode)

;; Local variables:
;; elisp-autofmt-load-packages-local: ("use-package")
;; end:
