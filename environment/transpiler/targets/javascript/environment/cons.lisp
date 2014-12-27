; tré – Copyright (c) 2008–2009,2012–2014 Sven Michael Klose <pixel@copei.de>

(defvar *default-listprop* nil)

(declare-cps-exception %cons cons list)

(defnative %cons (a d)
  (= this.__class ,(obfuscated-identifier 'cons)
     this._  a
     this.__ d
     this._p *default-listprop*)
  this)

(defnative cons (x y)
  (new %cons x y))
