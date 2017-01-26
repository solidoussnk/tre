(defun codegen-closure-scope (name)
  (alet (get-funinfo name)
    (place-assign (? (funinfo-fast-scope? !)
                     (place-expand-0 (funinfo-parent !) (funinfo-scope-arg !))
                     (place-expand-closure-scope !)))))
