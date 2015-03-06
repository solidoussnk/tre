; tré – Copyright (c) 2008–2015 Sven Michael Klose <pixel@copei.de>

(defun update-section? (section cached-sections)
  (| (member section (sections-to-update))
     (not (assoc section cached-sections))))

(defun map-section (x fun sections cached-sections)
  (with-cons section data x
    (with-temporaries ((current-section)       section
                       (current-section-data)  data)
      (. section
         (? (update-section? section cached-sections)
            (funcall fun section data)
            (assoc-value section cached-sections))))))

(defun map-sections (fun sections cached-sections)
  (@ [map-section _ fun sections cached-sections]
     sections))

(defun codegen (x)
  (backend (middleend x)))

(defun codegen-section (section data)
  (developer-note "Codegen ~A.~%" section)
  (codegen data))

(defun codegen-sections (sections)
  (alet (map-sections #'codegen-section sections (cached-output-sections))
    (= (cached-output-sections) !)
    (apply #'+ (cdrlist !))))

(defun quick-compile-sections (x)
  (codegen-sections (frontend-sections x)))

(defun make-toplevel-function ()
  `((defun accumulated-toplevel ()
      ,@(reverse (accumulated-toplevel-expressions)))))

(defun codegen-delayed-exprs ()
  (with-temporary (sections-to-update) '(delayed-exprs)
    (quick-compile-sections (list (. 'delayed-exprs
                                     (delayed-exprs))))))

(defun codegen-accumulated-toplevels ()
  (& (accumulate-toplevel-expressions?)
     (accumulated-toplevel-expressions)
     (with-temporaries ((sections-to-update) '(accumulated-toplevel)
                        (accumulate-toplevel-expressions?) nil)
       (quick-compile-sections (list (. 'accumulated-toplevel
                                        #'make-toplevel-function))))))

(defun generic-codegen (before-import after-import imports)
  (print-status "Let me think. Hmm...~F")
  (!? (middleend-init)
      (funcall !))
  (!? (codegen imports)
      (+! (imports) !))
  (transpiler-postprocess (list (!? (prologue-gen) (funcall !))
                                (!? (decl-gen) (funcall !))
                                (codegen-sections before-import)
                                (reverse (raw-decls))
                                (imports)
                                (codegen-sections after-import)
                                (codegen-accumulated-toplevels)
                                (codegen-delayed-exprs)
                                (!? (epilogue-gen) (funcall !)))))

(defun frontend-section-load (path)
  (print-definition `(load ,path))
  (frontend (read-file path)))

(defun frontend-section (section data)
  (developer-note "Frontend ~A.~%" section)
  (?
    (symbol? section)  (frontend (? (function? data)
                                    (funcall data)
                                    data))
    (string? section)  (frontend-section-load section)
    (error "Don't know what to do with section ~A." section)))

(defun frontend-sections (sections)
  (alet (map-sections #'frontend-section sections (cached-frontend-sections))
    (= (cached-frontend-sections) !)))

(defun generic-frontend (sections)
  (!? (frontend-init)
      (funcall !))
  (generic-codegen (frontend-sections (!? (sections-before-import)
                                          (funcall !)))
                   (frontend-sections (+ (!? (sections-after-import)
                                             (funcall !))
                                         sections
                                         (!? (ending-sections)
                                             (funcall !))))
                   (import-from-host)))

(defun tell-number-of-warnings ()
  (alet (length *warnings*)
    (fresh-line)
    (format t "; ~A warning~A.~%"
            (? (zero? !) "No" !)
            (? (== 1 !) "" "s"))))

(defun print-transpiler-stats (start-time)
  (& (obfuscate?)
     (print-obfuscations?)
     (print-obfuscations))
  (warn-unused-functions)
  (tell-number-of-warnings)
  (print-status "~A seconds passed.~%~F"
                (integer (/ (- (nanotime) start-time) 1000000000))))

(define-filter wrap-strings-in-lists (x)
  (? (string? x)
     (list x)
     x))

(defun compile-sections (sections &key (transpiler nil))
  (let start-time (nanotime)
    (= *warnings* nil)
    (with-temporaries (*transpiler*   (| transpiler
                                         (copy-transpiler *default-transpiler*))
                       *assert*       (| *assert* (assert?)))
      (& (sections-to-update)
         (clr (emitted-decls)))
      (= (host-functions) (make-host-functions))
      (= (host-variables) (make-host-variables))
      (prog1
        (generic-frontend (wrap-strings-in-lists sections))
        (print-transpiler-stats start-time)
        (print-status "Phew!~%")))))

(defun compile (expression &key (transpiler nil))
  (compile-sections `((t ,expression)) :transpiler transpiler))
