;;;;; tré – Copyright (c) 2006–2013 Sven Michael Klose <pixel@copei.de>

(%defun quasiquote (x)
  x
  (%error "QUASIQUOTE (or ',' for short) outside backquote."))

(%defun quasiquote-splice (x)
  x
  (%error "QUASIQUOTE-SPLICE (or ',@' for short) outside backquote."))