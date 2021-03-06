"@(#)mkrulebld.l	1.9"
;
;	Rule Builder construction for Franz Lisp version of rulebuilder
;
;					J. Nagle
;					Version 1.9 of 2/26/86
;
(setq knowledgebase "verifier")		; will be prepended with current dir.
;
;	errhandler  --  user error handler
;
;	Activated via ER%all mechanism
;
;	This really ought to check to see if the prover is within a
;	critical section.  All it does now is reset to the top level.
;
(defun errhandler (err)
	(princ "Error:")		; start message
	(mapcar '(lambda (elt) (princ " ") (princ elt))
		(cdddr err))		; print all message available
	(princ ".")			; English
	(terpri)			; finish message
	(setq |ER%all| 'errhandler)	; reenable handler
	(reset))			; reset to top level
;
;	pwd  --  obtain current working directory
;
;	WARNING  --  a zombie process is left around until Lisp exits.
;	So only use this when making a new rulebuilder.
;
(defun pwd nil
	(prog (inpipe outpipe dir)		; pipes and directory
		(process "pwd" inpipe outpipe)	; run "pwd"
		(setq dir (read outpipe))	; get the directory
		(close inpipe) (close outpipe)	; clean up I/O
		(return dir)))			; return result
;
;	initiallib  --  interactive note-lib
;
;	The default gets you the standard verifier knowledge base.
;	But this may be overridden by a value on the call line.
;
(defun initiallib nil
  (prog nil
	(cond ((> (argv -1) 2)		; too many args
	       (princ "usage: rulebuilder [<knowledge base>]") (terpri)
	       (return nil))		; force exit
	      ((eq (argv -1) 2)		; library given
	       (cond ((notelib1 (argv 1)) ; try to load it
		        (princ "Knowledge base ") (princ (argv 1)) 
			(princ " loaded.") (terpri)
			(return t)))	; success
		;	Fail, report to user.
		(princ "Unable to load knowledge base ")
		(princ (argv 1))
		(princ ", default knowledge base will be used.")
		(terpri)
	       ))
	;; No library given or not loadable, try the default.
	(cond  ((notelib1 verifierknowledgebase)
		(princ "Default Pascal-F knowledge base loaded.") (terpri)
		(return t)))		 ; success
	(princ "FATAL ERROR: cannot load any knowledge base.") (terpri)
	(return nil)))			; fails
;
;	notelib1  --  note a library, return nil if fail
;
;	Constructs the name with the standard suffixes.
;
(defun notelib1 (prefix)
  (prog (libn lispn)
	(setq libn (concat prefix '.lib)) ; .lib file
	(setq lispn (concat prefix '.lisp)) ; .lisp file
	(cond ((null (probef libn))		; lib readable?
	       (princ (concat "Cannot open " libn)) (terpri)
	       (return nil))			; fails
	      ((null (probef lispn))		; lisp readable?
	       (princ (concat "Cannot open " lispn)) (terpri)
	       (return nil))			; fails
	      ((null (note-lib libn lispn))	; try note-lib
	       (princ "The note-lib operation failed.") (terpri)
	       (return nil))
	      (t (return t))
	      )
	))
;
;	startrulebuilder  --  startup handling
;
(defun startrulebuilder nil
	(princ rulebuildername) (terpri)
	(setq user-top-level nil)	; return to normal
	(setq |ER%all| 'errhandler)	; use our error handler
	(and (null (initiallib)) (exit 1)) ; load library
	)
;
;
;	makerulebuilder  --  make the rule builder with our library loaded
;
(defun makerulebuilder nil
	(gc)				; garbage collection
	(setq rulebuildername 		; get timestamp
		(concat "Pascal-F Rule Builder of " (time-string)))
	(setq verifierknowledgebase	; set full pathname of knowledge base
		(cond   ((eq '/ (car (explode knowledgebase)))
				knowledgebase)	; has /, just use name
	      		(t (concat (pwd) "/" knowledgebase)))) ; no /, get pwd
	(sstatus ignoreeof t)		; no ctl-D exit
	(setq user-top-level 'startrulebuilder) ; autostart 
	(sstatus translink on)		; make all links real
	(gc)				; final garbage collection
	(dumplisp 'savedlisp)		; create a Lisp image.
	(setq user-top-level nil)	; back to normal
	)
;
;	Now do it
;
(makerulebuilder)
