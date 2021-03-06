(fn pass-optimize (x)
  (? (enabled-pass? :inject-debugging)
     x
     (optimize x)))

(fn pass-opt-tailcall (x)
  (? (enabled-pass? :inject-debugging)
     x
     (alet (opt-tailcall x)
       (? (equal ! x)
          !
          (optimize !)))))

(define-transpiler-end :middleend
    middleend-input          #'identity
    expression-expand        #'expression-expand
    unassign-lambdas         #'unassign-lambdas
    accumulate-toplevel      #'accumulate-toplevel-expressions
    inject-debugging         #'inject-debugging
    quote-keywords           #'quote-keywords
    optimize                 #'pass-optimize
    opt-tailcall             #'pass-opt-tailcall)
