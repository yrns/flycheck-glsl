;;; flycheck-glsl.el --- Flycheck checker for GLSL -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(require 'flycheck)
(require 'dash)

(defvar flycheck-glsl-stages '("vert" "tesc" "tese" "geom" "frag" "comp")
  "Valid values for glslangValidator -S.")

(defun flycheck-glsl-stage (f)
  "Return a valid stage based on the file extension for F."
  (let ((ext (file-name-extension f)))
    (cond
     ((-contains? flycheck-glsl-stages ext) ext)
     ;; e.g.: shader.vert.glsl
     ((string-equal "glsl" ext) (flycheck-glsl-stage (file-name-base f)))
     ((string-equal "vs" ext) "vert")
     ((string-equal "fs" ext) "frag"))))

(flycheck-def-option-var flycheck-glsl-client "vulkan100" glsl-checker
  "--client vulkan100 or opengl100"
  :type '(choice (const :tag "vulkan" "vulkan100")
                 (const :tag "opengl" "opengl100")
                 (string :tag "Client name")))

(flycheck-define-checker glsl
  "A GLSL syntax checker using glslangValidator."
  :command ("glslangValidator"
            "--relaxed-errors"
            "-t"                        ; multi-threaded mode
            "-d"                        ; default to desktop
            "-Od"                       ; disable optimization
            "-I."                       ; add directory to include path
            "-o" "/dev/null" ; once you specify a client, it emits a binary
            ;; "--stdin"                   ; must be before -S
            (option "--client" flycheck-glsl-client)
            ;; "-S" (eval (flycheck-glsl-stage (buffer-file-name)))
            source
            )
  :error-patterns
  ((error line-start "ERROR: " (optional (file-name) ":" line ": ") (message) line-end)
   (warning line-start "WARNING: " column ":" line ":" (message) line-end)
   (info line-start
         "NOTE: "
         column ":"
         line ":"
         (message)
         line-end))
  :error-filter
  (lambda (errors)
    ;; some errors such as lack of entry point don't have a line
    ;; number; this makes it so those errors aren't filtered out
    (flycheck-fill-empty-line-numbers
     ;; some of these no-line-number errors aren't useful:
     (seq-filter (lambda (err)
                   (let ((m (flycheck-error-message err)))
                     (and (null (string-match "No code generated." m))
                          (null (string-match "compilation terminated" m))))) errors)))
  :modes (glsl-mode)
  :standard-input nil)

;;;###autoload
(defun flycheck-glsl-setup ()
  "Setup Flycheck with GLSL."
  (interactive)
  (add-to-list 'flycheck-checkers 'glsl))

(provide 'flycheck-glsl)
;;; flycheck-glsl.el ends here
