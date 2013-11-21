;;;;; tré – Copyright (c) 2008–2013 Sven Michael Klose <pixel@copei.de>

(defconstant *mouse-events*   '("click" "dblclick" "mouseup" "mousedown" "mousemove" "mouseover" "mouseout"))
(defconstant *touch-events*   '("touchdown" "touchmove" "touchup"))
(defconstant *ignored-dragndrop-events* '("dragenter" "dragover"))
(defconstant *key-events*     '("keypress" "keydown" "keyup"))
(defconstant *form-events*    '("submit" "change" "focus" "blur"))
(defconstant *media-events*   '("play" "ended"))
(defconstant *network-events* '("online" "offline"))
(defconstant *other-events*   '("contextmenu" "drop" "unload"))

(defconstant *all-events* (+ *mouse-events* *touch-events* *ignored-dragndrop-events*
                             *key-events* *form-events*
                             *media-events* 
                             *network-events*
                             *other-events*))

(defconstant *non-generic-events* `("mouseup" "mousedown" ,@*ignored-dragndrop-events* "drop" ,@*key-events* "unload"))
