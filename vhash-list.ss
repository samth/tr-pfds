#lang typed-scheme
(provide add-elem isempty? get vhash-list VHashList)

(require "skewbinaryrandomaccesslist.ss")
(define-struct: (A) Base ([prevbase : (Block A)]
                          [prevoffset : Integer]
                          [key-value-pairs : (RAList (Pair A A))]
                          [size : Integer]))
(define-struct: Mt ())

(define-type-alias (Block A) (U Mt (Base A)))

(define-struct: (A) List ([offset : Integer]
                          [base : (Base A)]
                          [size : Integer]))

(define-type-alias VHashList (All (A) (List A)))

(define empty-vlist (make-List 0 (make-Base (make-Mt) 0 empty 1) 0))

(: isempty? : (All (A) ((VHashList A) -> Boolean)))
(define (isempty? vlist)
  (zero? (List-size vlist)))

(: add : (All (A) (A A (VHashList A) -> (VHashList A))))
(define (add key value vlst)
  (if (with-handlers ([exn:fail? (lambda (error?) #t)])
        (get key vlst)
        #f)
      (add-elem key value vlst)
      (error (format "Duplicate key: ~a already exists in the hash-list :" key) 'add-elem)))

(: not-error? : Any -> Any)
(define (not-error? res)
  (not (exn:fail? res)))

(: add-elem : (All (A) (A A (VHashList A) -> (VHashList A))))
(define (add-elem key value vlst)
  (let* ([offset (List-offset vlst)]
         [size (List-size vlst)]
         [base (List-base vlst)]
         [prevbase (Base-prevbase base)]
         [prevoffset (Base-prevoffset base)]
         [keys (Base-key-value-pairs base)]
         [basesize (Base-size base)]
         [newoffset (add1 offset)]
         [pair (cons key value)])
    (if (< offset basesize) 
        (make-List newoffset 
                   (make-Base prevbase 
                              prevoffset
                              (ralist-cons pair keys)
                              basesize)
                   (add1 size))
        (make-List 1 
                   (make-Base base 
                              offset
                              (ralist-cons pair empty)
                              (* basesize 2))
                   (add1 size)))))

(: first : (All (A) ((VHashList A) -> (Pair A A))))
(define (first vlst)
  (let ([offset (List-offset vlst)]
        [size (List-size vlst)]
        [base (List-base vlst)])
    (if (< (sub1 offset) size)
        (head (Base-key-value-pairs base))
        (error "List is empty :" 'first))))

(: rest : (All (A) ((VHashList A) -> (VHashList A))))
(define (rest vlst)
  (let* ([offset (List-offset vlst)]
         [size (List-size vlst)]
         [base (List-base vlst)]
         [len (Base-size base)]
         [prev (Base-prevbase base)])
    (cond 
      [(and (zero? len) (zero? offset)) (error "List is empty :" 'rest)]
      [(> offset 1) (make-List (sub1 offset) 
                               (make-Base (Base-prevbase base)
                                          (Base-prevoffset base)
                                          (tail (Base-key-value-pairs base))
                                          (Base-size base))
                               (sub1 size))]
      [(Base? prev) (make-List (Base-prevoffset base) prev (sub1 size))]
      [else empty-vlist])))
        

(: size : (All (A) ((VHashList A) -> Integer)))
(define (size vlst)
  (List-size vlst))

(: get : (All (A) (A (VHashList A) -> A)))
(define (get key vlist)
  (if (zero? (List-size vlist)) 
      (error (format "Key ~a not found in hash list :" key) 'get)
      (get-helper key vlist)))

(: get-helper : (All (A) (A (VHashList A) -> A)))
(define (get-helper key vlist)
  (let ([fst (first vlist)])
    (if (eq? key (car fst)) 
        (cdr fst)
        (get key (rest vlist)))))

(: vhash-list : (All (A) ((Listof A) (Listof A) -> (VHashList A))))
(define (vhash-list keys values)
  (foldr (inst add A) empty-vlist keys values))