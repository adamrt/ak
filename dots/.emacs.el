;;; emacs.el --- built-ins plus Evil, Magit, Consult and Eat. -*- lexical-binding: t; -*-

;;;; Identity
(setq user-full-name "Adam Patterson"
      user-mail-address "adam@adamrt.com")

;;;; Packages
(require 'package)
(add-to-list 'package-archives
             '("nongnu-devel" . "https://elpa.nongnu.org/nongnu-devel/") t)
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

(require 'use-package)
(setq use-package-always-ensure t)

;;;; Basics
(setq inhibit-startup-screen t
      ring-bell-function #'ignore
      use-short-answers t
      create-lockfiles nil
      make-backup-files nil
      auto-save-default nil
      load-prefer-newer t
      sentence-end-double-space nil
      custom-file (expand-file-name "custom.el" user-emacs-directory))

(setq-default indent-tabs-mode nil
              fill-column 80)

;; One binding to rule them all! Steve Yegge
(global-set-key (kbd "C-w") #'backward-kill-word)

;;;; macOS
(when (eq system-type 'darwin)
  ;; Emacs.app's bundled GCC derives a nonexistent macOS version (18) from
  ;; Darwin 27, breaking native compilation.  Give it the real one.
  ;; Remove once a fixed Emacs.app build ships.
  (setenv "MACOSX_DEPLOYMENT_TARGET" "27.0")

  (setq mac-command-modifier 'meta
        ns-command-modifier 'meta
        mac-option-modifier 'super
        ns-option-modifier 'super
        mac-right-option-modifier 'none
        ns-right-option-modifier 'none
        delete-by-moving-to-trash t
        trash-directory "~/.Trash")


  ;; Bring Emacs to the front once startup finishes.
  (add-hook 'window-setup-hook
          (lambda ()
            (when (display-graphic-p)
              (select-frame-set-input-focus (selected-frame))))))

;;;; UI
(setq frame-resize-pixelwise t)        ; no gaps when maximized
(setq frame-inhibit-implied-resize t)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(menu-bar-mode -1)
(when (display-graphic-p)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  ;; Required font: fail loudly if missing (GUI only).
  (unless (find-font (font-spec :family "Berkeley Mono"))
    (error "Berkeley Mono not found"))
  (set-face-attribute 'default nil :family "Berkeley Mono" :height 180))

(setopt mode-line-collapse-minor-modes t) ; one button instead of every lighter
(column-number-mode 1)
(which-function-mode 1)
(which-key-mode 1)

;;;; Editing behavior
(setq global-auto-revert-non-file-buffers t ; refresh Dired too
      recentf-max-saved-items 200)

(global-auto-revert-mode 1)
(electric-pair-mode 1)
(recentf-mode 1)
(savehist-mode 1)
(save-place-mode 1)
(winner-mode 1)
(repeat-mode 1)

;; Shared setup for every programming mode.
(defun my/prog-setup ()
  (add-hook 'before-save-hook #'delete-trailing-whitespace nil t)
  (hs-minor-mode 1)                    ; folding; Evil's za/zc/zo use it
  (completion-preview-mode 1))         ; inline completion hints
(add-hook 'prog-mode-hook #'my/prog-setup)

;;;; Completion
(setq completion-styles '(basic flex)
      completion-auto-help nil
      tab-always-indent 'complete)
(fido-vertical-mode 1)
;; TAB in the minibuffer accepts the top candidate (directories get a trailing /).
(define-key icomplete-minibuffer-map (kbd "TAB") #'minibuffer-force-complete)
(global-set-key (kbd "M-/") #'hippie-expand)

;;;; Navigation: project, xref, tags
(when (executable-find "rg")
  (setq xref-search-program 'ripgrep))
(setq xref-prompt-for-identifier nil
      etags-regen-file-extensions '("c" "h" "go" "py")
      etags-regen-program-options '("--declarations")
      project-switch-commands #'magit-project-status)
(etags-regen-mode 1)

;; semantic-symref-filepattern-alist doesn't include c-ts-mode
(with-eval-after-load 'semantic/symref/grep
  (add-to-list 'semantic-symref-filepattern-alist
               '(c-ts-mode "*.[ch]")))

;;;; Compile
(setq compilation-scroll-output 'first-error
      compilation-ask-about-save nil)

;;;; Tree-sitter
;; Use the tree-sitter mode for any language that has one, and offer to
;; install a missing grammar the first time a file of that type is opened.
(setopt treesit-enabled-modes t
        treesit-auto-install-grammar 'ask)

;; Go has no non-tree-sitter mode built in, so map its files directly.
(add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))
(add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))

;;;; C
(setq c-ts-mode-indent-style 'k&r
      c-ts-indent-offset 4)

;;;; Go (gofmt ships with the Go toolchain)
(defun my/gofmt-buffer ()
  "Format the buffer with gofmt, preserving point. Leave it alone on errors."
  (when (executable-find "gofmt")
    (let ((out (generate-new-buffer " *gofmt*")))
      (unwind-protect
          (when (zerop (call-process-region (point-min) (point-max)
                                            "gofmt" nil out nil))
            (replace-buffer-contents out))
        (kill-buffer out)))))

(defun my/go-setup ()
  (setq-local indent-tabs-mode t
              tab-width 4
              compile-command "go build ./... && go vet ./...")
  ;; gofmt owns whitespace; don't also run the generic trimmer.
  (remove-hook 'before-save-hook #'delete-trailing-whitespace t)
  (add-hook 'before-save-hook #'my/gofmt-buffer nil t))
(add-hook 'go-ts-mode-hook #'my/go-setup)

;;;; Diff / VC
(setq ediff-window-setup-function #'ediff-setup-windows-plain
      ediff-split-window-function #'split-window-horizontally)

;; No vc UI or keys (Magit does git). The Git backend stays because
;; project.el uses it to find project roots; restrict it to Git only.
(setq vc-handled-backends '(Git))

;;;; Unix modes / Dired
(add-hook 'sh-mode-hook (lambda () (setq-local sh-basic-offset 2)))
(add-hook 'makefile-mode-hook (lambda () (setq-local indent-tabs-mode t)))

(setq dired-dwim-target t
      dired-listing-switches "-alh"
      dired-kill-when-opening-new-dired-buffer t)

;;;; Helper commands
(defun my/find-init-file ()
  "Open the init file."
  (interactive)
  (find-file user-init-file))

;;;; GPG
;; Signed git commits (from Magit) ask for the GPG passphrase in the
;; minibuffer.  gpg-agent hands the prompt to this Emacs pinentry server,
;; which needs `allow-emacs-pinentry' in ~/.gnupg/gpg-agent.conf.
(use-package pinentry
  :config
  (setq epg-pinentry-mode 'loopback)   ; Emacs's own GPG use prompts here too
  (pinentry-start))

;;;; Evil
(use-package evil
  :pin nongnu-devel
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-Y-yank-to-eol t
        evil-undo-system 'undo-redo
        evil-split-window-below t
        evil-vsplit-window-right t
        evil-disable-insert-state-bindings t)
  :config
  (evil-mode 1))

(use-package evil-collection
  :pin nongnu-devel
  :after evil
  :init
  (setq evil-collection-key-blacklist '("SPC"))
  :config
  (evil-collection-init))

;;;; Leader key (core; bindings are at the end)
(defvar my/leader-map (make-sparse-keymap) "Doom-style leader keymap.")

(dolist (map (list evil-normal-state-map evil-visual-state-map evil-motion-state-map))
  (define-key map (kbd "SPC") my/leader-map))

(defun my/leader-bind (&rest pairs)
  "Bind alternating KEY DEF arguments under the leader map."
  (while pairs
    (define-key my/leader-map (kbd (pop pairs)) (pop pairs))))

;;;; Terminal (Eat)
;; Input modes (switch inside an Eat buffer):
;;   semi-char  default; most keys go to the shell, C-c/C-x/M-x reach Emacs
;;   C-c M-d    char mode: every key goes to the terminal (vim, htop); M-RET exits
;;   C-c C-e    emacs mode: freeze output to scroll, search, copy; C-c C-j returns
;;   C-c C-l    line mode: edit the command line in Emacs, RET sends it
;; Evil: type in insert state, navigate output in normal state.  If ESC
;; collides with a program like vim, use char mode.
;; Shell integration (dir tracking, prompt jumps): add to ~/.zshrc
;;   [ -n "$EAT_SHELL_INTEGRATION_DIR" ] && source "$EAT_SHELL_INTEGRATION_DIR/zsh"
(use-package eat
  :config
  (setq eat-kill-buffer-on-exit t         ; close the buffer when the shell exits
        ;; Eat's own TERM type isn't readable by privileged programs like
        ;; macOS's setuid top, so use one every system already knows.
        eat-term-name "xterm-256color"))

;; Terminals open in a normal split along the bottom of the frame.
(add-to-list 'display-buffer-alist
             '((major-mode . eat-mode)
               (display-buffer-reuse-window display-buffer-at-bottom)
               (window-height . 0.35)))

(defun my/terminal-toggle ()
  "Open the project terminal, or close its window if it's selected."
  (interactive)
  (if (derived-mode-p 'eat-mode)
      (delete-window)
    (eat-project)))

(defun my/eat-close-window (process)
  "Close the window that showed PROCESS's buffer once the shell exits."
  (let ((win (get-buffer-window (process-buffer process))))
    (when win
      (run-with-timer 0.1 nil
                      (lambda ()
                        (when (and (window-live-p win)
                                   (not (one-window-p t)))
                          (delete-window win)))))))
(add-hook 'eat-exit-hook #'my/eat-close-window)

;;;; Consult
;; Built-in Emacs has no live search. project-find-regexp makes you type the
;; whole query before showing results, and the built-in buffer/xref/imenu
;; prompts can't preview where a choice will take you.
;;
;; Consult adds:
;;   - consult-ripgrep (SPC /): project search that re-runs rg as you type
;;   - live preview of the location as you move through any candidate list
;;   - consult-buffer (SPC ,): buffers, recent files, and project files
;;   - consult-line (SPC s s): every match in the buffer as a list
;;   - pickers with preview for xref, imenu, and flymake results
;;
;; It builds on the standard completing-read, so it works with fido as-is.
(use-package consult
  :config
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref
        ;; In-buffer completion (TAB in code) uses the minibuffer UI.
        completion-in-region-function #'consult-completion-in-region))

;;;; Magit
(use-package magit
  :config
  (setq magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1
        magit-diff-refine-hunk t))     ; word-level highlights in the current hunk

;; Magit binds SPC itself; make it the leader there too.
(with-eval-after-load 'magit
  (dolist (map (list magit-mode-map
                     magit-status-mode-map
                     magit-log-mode-map
                     magit-diff-mode-map
                     magit-revision-mode-map))
    (define-key map (kbd "SPC") nil)
    (evil-define-key '(normal visual motion) map (kbd "SPC") my/leader-map)))

;;;; Leader bindings
;; Conventions: d = close (buffer, window), k = kill a group of buffers,
;; x = forget/discard (project entry, bookmark, compilation),
;; capital letter = bigger variant.
(my/leader-bind
 ;; Top level
 "SPC" #'project-find-file
 "."   #'find-file
 ","   #'consult-buffer
 "/"   #'consult-ripgrep
 ":"   #'execute-extended-command
 "u"   #'universal-argument
 "h"   help-map

 ;; b: buffer
 "b b" #'consult-buffer
 "b i" #'ibuffer
 "b n" #'next-buffer
 "b l" #'evil-switch-to-windows-last-buffer
 "b p" #'previous-buffer
 "b r" #'revert-buffer
 "b d" #'kill-current-buffer

 ;; f: file
 "f f" #'find-file
 "f r" #'consult-recent-file
 "f s" #'save-buffer
 "f S" #'write-file
 "f R" #'rename-visited-file
 "f c" #'my/find-init-file
 "f y" (lambda () (interactive) (kill-new (buffer-file-name)))

 ;; p: project
 "p p" #'project-switch-project
 "p f" #'project-find-file
 "p s" (lambda () (interactive) (project-save-some-buffers t))
 "p b" #'consult-project-buffer
 "p d" #'project-dired
 "p c" #'project-compile
 "p a" #'project-remember-projects-under
 "p k" #'project-kill-buffers
 "p x" #'project-forget-project

 ;; s: search
 "s s" #'consult-line
 "s o" #'occur
 "s i" #'consult-imenu
 "s p" #'consult-ripgrep

 ;; r: replace
 "r r" #'query-replace
 "r R" #'query-replace-regexp
 "r p" #'project-query-replace-regexp
 "r s" #'xref-find-references-and-replace   ; rename symbol at point

 ;; c: code
 "c d" #'xref-find-definitions
 "c r" #'xref-find-references
 "c a" #'xref-find-apropos
 "c b" #'xref-go-back
 "c f" #'xref-go-forward
 "c k" #'eldoc-doc-buffer
 "c c" #'project-compile
 "c C" #'recompile
 "c x" #'kill-compilation
 "c n" #'next-error
 "c p" #'previous-error
 "c o" #'ff-find-other-file                 ; toggle .c <-> .h

 ;; g: git
 "g g" #'magit-status
 "g b" #'magit-blame-addition

 ;; w: window
 "w v" #'evil-window-vsplit
 "w s" #'evil-window-split
 "w h" #'evil-window-left
 "w j" #'evil-window-down
 "w k" #'evil-window-up
 "w l" #'evil-window-right
 "w =" #'balance-windows
 "w u" #'winner-undo
 "w r" #'winner-redo
 "w d" #'delete-window
 "w o" #'delete-other-windows

 ;; m: marks / bookmarks
 "m m" #'bookmark-set
 "m j" #'bookmark-jump
 "m l" #'bookmark-bmenu-list
 "m x" #'bookmark-delete

 ;; t: toggle
 "t l" #'display-line-numbers-mode
 "t w" #'visual-line-mode
 "t h" #'hs-toggle-all
 "t r" #'read-only-mode

 ;; o: open
 "o d" #'dired-jump
 "o t" #'my/terminal-toggle ; project terminal; press again to hide
 "o T" #'eat                ; general terminal; SPC u SPC o T for another

 ;; q: quit
 "q q" #'save-buffers-kill-terminal
 "q r" #'restart-emacs)

(which-key-add-key-based-replacements
  "SPC b" "buffer"   "SPC f" "file"    "SPC p" "project"
  "SPC s" "search"   "SPC r" "replace" "SPC c" "code"
  "SPC g" "git"      "SPC w" "window"  "SPC m" "marks"
  "SPC t" "toggle"   "SPC o" "open"    "SPC h" "help"
  "SPC q" "quit")

;;;; Custom file (keeps Customize output out of this file)
(load custom-file 'noerror 'nomessage)

;;;; Theme: adamrt, a quiet charcoal theme defined inline (no package needed).
(deftheme adamrt "A quiet, nearly monochrome charcoal theme."
  :background-mode 'dark :kind 'color-scheme)

(let* ((bg         "#282c34")
       (bg-alt     "#202325")
       (fg         "#d8dcd9")
       (fg-dim     "#959c98")   ; secondary text
       (fg-soft    "#b0b6b2")   ; types, preprocessor lines
       (comment    "#8a948f")
       (line-bg    "#2b3032")
       (selection  "#303537")
       (border     "#454c4f")
       (region     "#3b464c")
       (search     "#46555e")
       ;; Accent colors.
       (blue       "#8fb8d1")   ; keywords
       (green      "#9fbd8a")   ; strings
       (sand       "#c9b891")   ; function names where declared/defined
       ;; Status colors.
       (red        "#b58f8c")
       (yellow     "#b4aa91")
       ;; Diff backgrounds, pre-blended over bg.
       (added-bg   "#39473f") (added-hl   "#405243") (added-refine   "#495f49")
       (removed-bg "#483a3f") (removed-hl "#554043") (removed-refine "#654749")
       (section-bg "#303741") (heading-bg "#38424d") (heading-hl     "#414e5a"))
  (custom-theme-set-faces
   'adamrt
   ;; Base
   `(default ((t (:background ,bg :foreground ,fg))))
   `(cursor ((t (:background ,fg))))
   `(fringe ((t (:background ,bg))))
   `(region ((t (:background ,region :extend t))))
   `(secondary-selection ((t (:background ,selection))))
   `(highlight ((t (:background ,selection :foreground ,fg))))
   `(hl-line ((t (:background ,line-bg :extend t))))
   `(shadow ((t (:foreground ,fg-dim))))
   `(vertical-border ((t (:foreground ,border))))
   `(window-divider ((t (:foreground ,border))))
   `(minibuffer-prompt ((t (:foreground ,blue))))
   `(link ((t (:foreground ,blue :underline t))))
   `(line-number ((t (:foreground ,border))))
   `(line-number-current-line ((t (:foreground ,fg-dim :background ,line-bg))))
   `(error ((t (:foreground ,red))))
   `(warning ((t (:foreground ,yellow))))
   `(success ((t (:foreground ,green))))
   `(trailing-whitespace ((t (:background ,removed-bg))))
   ;; Search and parens
   `(isearch ((t (:background ,search :foreground ,fg :weight bold))))
   `(lazy-highlight ((t (:background ,selection :foreground ,fg))))
   `(match ((t (:background ,selection :foreground ,blue :weight bold))))
   `(show-paren-match ((t (:background ,selection :weight bold))))
   `(show-paren-mismatch ((t (:background ,removed-hl :foreground ,red))))
   ;; Syntax
   `(font-lock-comment-delimiter-face ((t (:foreground ,comment))))
   `(font-lock-comment-face ((t (:foreground ,comment))))
   `(font-lock-doc-face ((t (:foreground ,comment))))
   `(font-lock-function-name-face ((t (:foreground ,sand))))
   `(font-lock-keyword-face ((t (:foreground ,blue))))
   `(font-lock-preprocessor-face ((t (:foreground ,fg-soft))))
   `(font-lock-string-face ((t (:foreground ,green))))
   `(font-lock-type-face ((t (:foreground ,fg-soft))))
   `(font-lock-warning-face ((t (:foreground ,yellow))))
   ;; Everything else is plain text
   `(font-lock-function-call-face ((t (:foreground ,fg))))
   `(font-lock-variable-name-face ((t (:foreground ,fg))))
   `(font-lock-variable-use-face ((t (:foreground ,fg))))
   `(font-lock-builtin-face ((t (:foreground ,fg))))
   `(font-lock-constant-face ((t (:foreground ,fg))))
   `(font-lock-number-face ((t (:foreground ,fg))))
   `(font-lock-escape-face ((t (:foreground ,fg))))
   `(font-lock-property-name-face ((t (:foreground ,fg))))
   `(font-lock-property-use-face ((t (:foreground ,fg))))
   `(font-lock-operator-face ((t (:foreground ,fg))))
   `(font-lock-negation-char-face ((t (:foreground ,fg))))
   ;; Mode line
   `(mode-line ((t (:background ,selection :foreground ,fg :box nil))))
   `(mode-line-inactive ((t (:background ,bg-alt :foreground ,fg-dim :box nil))))
   `(mode-line-highlight ((t (:background ,border))))
   `(header-line ((t (:background ,bg-alt :foreground ,fg))))
   `(which-func ((t (:foreground ,blue))))
   ;; Completion and which-key
   `(icomplete-selected-match ((t (:background ,selection :foreground ,fg :weight bold))))
   `(completions-common-part ((t (:foreground ,blue))))
   `(completions-first-difference ((t (:foreground ,fg :weight bold))))
   `(completions-highlight ((t (:background ,selection))))
   `(completion-preview ((t (:foreground ,comment))))
   `(which-key-key-face ((t (:foreground ,blue))))
   `(which-key-group-description-face ((t (:foreground ,fg-soft))))
   `(which-key-command-description-face ((t (:foreground ,fg))))
   ;; Diagnostics
   `(flymake-error ((t (:underline (:style wave :color ,red)))))
   `(flymake-warning ((t (:underline (:style wave :color ,yellow)))))
   `(flymake-note ((t (:underline (:style wave :color ,fg-dim)))))
   ;; Dired and xref
   `(dired-directory ((t (:foreground ,blue))))
   `(dired-symlink ((t (:foreground ,fg-soft))))
   `(dired-marked ((t (:foreground ,yellow :background ,selection))))
   `(xref-file-header ((t (:foreground ,fg-soft :weight bold))))
   `(xref-line-number ((t (:foreground ,fg-dim))))
   ;; Diffs and Magit
   `(diff-added ((t (:foreground ,green :background ,added-bg :extend t))))
   `(diff-removed ((t (:foreground ,red :background ,removed-bg :extend t))))
   `(diff-refine-added ((t (:foreground ,fg :background ,added-hl))))
   `(diff-refine-removed ((t (:foreground ,fg :background ,removed-hl))))
   `(diff-refine-changed ((t (:foreground ,fg :background ,selection))))
   `(magit-diff-added ((t (:inherit diff-added))))
   `(magit-diff-removed ((t (:inherit diff-removed))))
   `(magit-diff-added-highlight ((t (:foreground ,green :background ,added-hl :extend t))))
   `(magit-diff-removed-highlight ((t (:foreground ,red :background ,removed-hl :extend t))))
   `(magit-diff-context ((t (:foreground ,fg-soft :background ,bg :extend t))))
   `(magit-diff-context-highlight ((t (:foreground ,fg :background ,section-bg :extend t))))
   `(magit-diff-hunk-heading ((t (:foreground ,fg-soft :background ,heading-bg :extend t))))
   `(magit-diff-hunk-heading-highlight ((t (:foreground ,fg :background ,heading-hl :weight bold :extend t))))
   `(magit-diff-file-heading-highlight ((t (:background ,heading-bg :weight bold :extend t))))
   `(magit-diff-refine-added ((t (:foreground ,fg :background ,added-refine :weight bold))))
   `(magit-diff-refine-removed ((t (:foreground ,fg :background ,removed-refine :weight bold))))
   `(magit-section-highlight ((t (:background ,section-bg :extend t))))
   `(magit-section-heading ((t (:foreground ,blue :weight bold))))
   `(magit-branch-current ((t (:foreground ,blue :weight bold))))
   `(magit-branch-local ((t (:foreground ,fg-soft))))
   `(magit-branch-remote ((t (:foreground ,fg-soft))))
   `(magit-hash ((t (:foreground ,fg-dim))))
   `(magit-filename ((t (:foreground ,fg))))
   `(magit-log-author ((t (:foreground ,fg-soft))))
   `(magit-log-date ((t (:foreground ,fg-dim))))))

(enable-theme 'adamrt)

;;; init.el ends here
