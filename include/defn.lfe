;; Simpler, functional alternatives to 'defun' and 'lambda'. Clojure names.
;;
;;
;; Functions and funs look the same.
;; Simple definitions and pattern matched ones look the same. 
;; Square brackets are interchangeable with standard ones: using them around
;; arguments is a nice visual hint.
;;
;; (fn [a b] (+ a b))
;; (defn fst [(tuple x _)] x)
;;
;; Multiple clauses are allowed, as long as arity is the same, just like
;; standard Erlang. 
;;
;; (defn ternary-or
;;   ['true _] 'true
;;   [_ 'true] 'true
;;   ['false 'false] 'false
;;   [_ _] 'undefined)
;;
;; Multiple (when ...) guards may be inserted between arguments. Expressions
;; inside a guard must all be true for it to pass. In the case of multiple guards,
;; however, only one must be true to pass.
;; Like standard Erlang, guards must be composed of trivial functions. 
;;
;; (defn hex-char?
;;   [c] (when (=< #x41 c) (=< c #x46)) ; A-F
;;       (when (=< #x61 c) (=< c #x66)) ; a-f
;;       (when (=< #x30 c) (=< c #x39)) ; 0-9
;;       'true
;;   [_] 'false)
;;
;;
;; The simplicity is due to disallowing multiple sequential expressions in the
;; body. They were only useful for side effects you don't need to know the
;; return value of, which are common in CL but non-existant in well written Erlang.
;; You can use (progn ...) if the need does come up.

(defmacro fn (exps 
  (if (> 2 (length exps)) (exit (tuple 'fn_clause_too_short exps)))
  (lfe_utils:base:shorthand-to-lambda exps)))

(defmacro defn ((cons name exps) 
  (cond ((not (is_atom name)) (exit (tuple 'bad_fun_name name)))
        ((> 2 (length exps)) (exit (tuple 'defn_clause_too_short name exps))))
  `(define-function ,name ,(lfe_utils:base:shorthand-to-lambda exps))))


(eval-when-compile
;; Build lambda or match-lambda from shorthand.
(defun lfe_utils:base:shorthand-to-lambda [exps]
  (if (and (== 2 (length exps)) 
           (lfe_utils:base:not-patternmatch? (car exps)))
    `(lambda ,(car exps) ,(cadr exps))
    `(match-lambda ,@(lfe_utils:base:parse-clause exps))))

;; Recursively build match-lambda clauses from the shorthand.
(defun lfe_utils:base:parse-clause [exps]
  (let* (((cons args exps) exps)
         (guard? (lambda [e] (andalso (is_list e) (== 'when (car e)))))
         ((tuple guards exps) (: lists splitwith guard? exps))
         ((cons body exps) exps))
    (cons `(,args ,@guards ,body)
          (if (== '() exps) 
            '() 
            (lfe_utils:base:parse-clause exps)))))


;; Test if expression contains anything other than unquoted atoms.
(defun lfe_utils:base:not-patternmatch? [exps]
  (: lists all (lambda [e] (andalso (is_atom e) (/= 39 (car (atom_to_list e)))))
               exps))
)