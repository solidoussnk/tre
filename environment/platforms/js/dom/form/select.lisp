;;;;; tré – Copyright (c) 2009–2010,2012–2013 Sven Michael Klose <pixel@copei.de>

(defun form-select? (x)
  (& (element? x)
     (x.has-tag-name? "select")))

(defun form-select-get-options (x)
  (let select-element (ancestor-or-self-select-element x)
    (get-option-elements select-element)))

(defun form-select-get-select-names (x)
  (map-select-elements (fn _.read-attribute "name") x))

(defun form-select-get-by-name (x name)
  (do-select-elements (i x "select")
    (& (i.attribute-value? "name" name)
       (return i))))

(defun form-select-get-option-by-value (x name)
  (do-children (i x)
    (& (i.attribute-value? "value" name)
       (return i))))

(defun form-select-unselect-options (x)
  (do-children (i x x)
    (i.remove-attribute "selected")))

(defun form-select-select-option (x)
  (when x
    (form-select-unselect-options x.parent-node)
    (= x.selected t)
    (x.write-attribute "selected" "1"))
  x)

(defun form-select-select-option-by-value (x n)
  (form-select-select-option (form-select-get-option-by-value x n))
  x)

(dont-obfuscate selected)

(defun form-select-get-selected-option (x)
  (do-children (i x)
	(& i.selected
	   (return i))))

(defun form-select-get-selected-option-text (x)
  (form-select-get-selected-option x).text-content)

(defun form-select-get-selected-option-value (x)
  (let-when o (form-select-get-selected-option x)
	(o.read-attribute "value")))

(defun form-select-add-option (x txt &optional (attrs nil))
  (with (select-element (ancestor-or-self-select-element x)
		 option-element (new *element "option" attrs))
	(option-element.add-text txt)
	(select-element.add option-element)))

(defun form-select-rename-option (option-element txt)
  (option-element.remove-children)
  (option-element.add-text txt))

(defun form-select-option-texts-to-string-lists (options)
  (when options
	(let option options.
  	  (cons (string-list option.text-content)
			(form-select-option-texts-to-string-lists .options)))))

(defun form-select-add-string-list-options (select-element options)
  (when options
	(let option-element (new *element "option")
	  (option-element.add-text (list-string options.))
	  (select-element.add option-element))
	(form-select-add-string-list-options select-element .options)))

(defun form-select-sort (x)
  (with (select-element (ancestor-or-self-select-element x)
		 option-list    (form-select-option-texts-to-string-lists (form-select-get-options x))
		 sorted-options (sort option-list :test #'<=-list))
	(select-element.remove-children)
	(form-select-add-string-list-options select-element sorted-options)))