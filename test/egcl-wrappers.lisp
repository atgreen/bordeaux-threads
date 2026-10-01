;;;; Real v2 CLOS wrappers and portable semaphores over EGCL's native SPI.
;;;; This focused test does not assert that the complete BT system is supported.

(load (merge-pathnames "egcl-native.lisp" *load-truename*))
(dolist (file '("apiv2/api-locks.lisp" "apiv2/api-semaphores.lisp"))
  (load (merge-pathnames file *egcl-test-root*)))

(let ((lock (bt2:make-lock :name "shared wrapper")))
  (assert (bt2:lockp lock))
  (assert (string= "shared wrapper" (bt2:lock-name lock)))
  (bt2:acquire-lock lock)
  (unwind-protect
      (assert
       (eq :contended
           (egcl-thread:join-thread
            (egcl-thread:make-thread
             (lambda ()
               (assert (bt2:lockp lock))
               (assert (null (bt2:acquire-lock lock :wait nil)))
               :contended)))))
    (bt2:release-lock lock))
  (assert
   (eq :acquired
       (egcl-thread:join-thread
        (egcl-thread:make-thread
         (lambda ()
           (assert (bt2:acquire-lock lock :timeout 5))
           (unwind-protect :acquired (bt2:release-lock lock))))))))
(format t "EGCL-BT-V2-WRAPPER-OK~%")

(let ((semaphore (bt2:make-semaphore :name "permit accounting" :count 2)))
  (assert (bt2:semaphorep semaphore))
  (assert (bt2:wait-on-semaphore semaphore :timeout 0))
  (assert (bt2:wait-on-semaphore semaphore :timeout 0))
  (assert (null (bt2:wait-on-semaphore semaphore :timeout 0)))
  (bt2:signal-semaphore semaphore :count 2)
  (assert (bt2:wait-on-semaphore semaphore :timeout 0))
  (assert (bt2:wait-on-semaphore semaphore :timeout 0))
  (assert (null (bt2:wait-on-semaphore semaphore :timeout 0))))
(format t "EGCL-BT-V2-PERMITS-OK~%")

;; The ready semaphore proves the callback ran; the gate may be signalled
;; before or after its wait, and must retain the permit in either case.
(let* ((ready (bt2:make-semaphore :count 0))
       (gate (bt2:make-semaphore :count 0))
       (worker
         (egcl-thread:make-thread
          (lambda ()
            (bt2:signal-semaphore ready)
            (if (bt2:wait-on-semaphore gate :timeout 10) :released :timed-out)))))
  (assert (bt2:wait-on-semaphore ready :timeout 10))
  (bt2:signal-semaphore gate)
  (assert (eq :released (egcl-thread:join-thread worker)))
  (assert (null (bt2:wait-on-semaphore gate :timeout 0))))
(format t "EGCL-BT-V2-SEMAPHORE-OK~%")
