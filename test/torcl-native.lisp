;;;; Focused native synchronization tests for the in-progress TorCL backend.
;;;; Load with Alexandria and global-vars registered in ASDF. This deliberately
;;;; tests the real API files without claiming the complete BT system loads.

(require :asdf)
(asdf:load-system :alexandria)
(asdf:load-system :global-vars)
(defparameter *torcl-test-root* (merge-pathnames "../" *load-truename*))
(dolist (file '("apiv1/pkgdcl.lisp" "apiv1/bordeaux-threads.lisp"))
  (load (merge-pathnames file *torcl-test-root*)))
(let ((backend (merge-pathnames "apiv1/impl-torcl.lisp" *torcl-test-root*)))
  (when (probe-file backend) (load backend)))
(load (merge-pathnames "apiv1/default-implementations.lisp" *torcl-test-root*))
(format t "TORCL-BT-DEFAULTS-LOADED~%")

;; A no-op ACQUIRE-LOCK must fail this test, not be mistaken for support.
(let ((lock (bt:make-lock "contention")))
  (bt:acquire-lock lock)
  (unwind-protect
      (when (torcl-thread:join-thread
        (torcl-thread:make-thread (lambda () (bt:acquire-lock lock nil))))
        (error "contending worker acquired an already-held BT lock"))
    (bt:release-lock lock))
  (assert (bt:lock-p lock))
  (assert (torcl-thread:mutex-p lock)))
(format t "TORCL-BT-MUTEX-CONTENTION-OK~%")

(let ((lock (bt:make-recursive-lock "recursive")))
  (bt:acquire-recursive-lock lock)
  (unwind-protect
      (progn
        (bt:acquire-recursive-lock lock)
        (bt:release-recursive-lock lock)
        (assert (null (torcl-thread:join-thread
          (torcl-thread:make-thread (lambda () (bt:acquire-lock lock nil)))))))
    (bt:release-recursive-lock lock)))

(let ((lock (bt:make-lock)) (evaluations 0))
  (assert (equal '(19 23)
    (multiple-value-list
      (bt:with-lock-held ((progn (incf evaluations) lock)) (values 19 23)))))
  (assert (= 1 evaluations))
  (assert (= 42 (catch 'exit
    (bt:with-lock-held (lock) (throw 'exit 42)))))
  (assert (torcl-thread:join-thread
    (torcl-thread:make-thread
      (lambda ()
        (if (bt:acquire-lock lock nil)
            (progn (bt:release-lock lock) t)
            nil))))))
(format t "TORCL-BT-MUTEX-UNWIND-OK~%")

(let ((lock (bt:make-lock)) (cv (bt:make-condition-variable))
      (ready nil) (worker nil))
  (bt:acquire-lock lock)
  (unwind-protect
      (progn
        (assert (null (bt:condition-wait cv lock :timeout 0)))
        (setq worker (torcl-thread:make-thread
          (lambda ()
            (bt:acquire-lock lock)
            (unwind-protect
                (progn (setq ready t) (bt:condition-notify cv) 42)
              (bt:release-lock lock)))))
        (loop until ready do
          (unless (bt:condition-wait cv lock :timeout 10)
            (error "native condition notification timed out"))))
    (bt:release-lock lock))
  (assert (= 42 (torcl-thread:join-thread worker))))
(format t "TORCL-BT-CONDITION-OK~%")

(dolist (file '("apiv2/pkgdcl.lisp" "apiv2/bordeaux-threads.lisp"
                "apiv2/impl-torcl.lisp"))
  (load (merge-pathnames file *torcl-test-root*)))
(let ((lock (bt2::%make-lock "v2")) (cv (bt2::%make-condition-variable "v2")))
  (assert (bt2::%acquire-lock lock t nil))
  (unwind-protect
      (progn
        (assert (null (torcl-thread:join-thread
          (torcl-thread:make-thread (lambda () (bt2::%acquire-lock lock nil nil))))))
        (assert (null (torcl-thread:join-thread
          (torcl-thread:make-thread (lambda () (bt2::%acquire-lock lock t 0))))))
        (assert (null (bt2::%condition-wait cv lock 0))))
    (bt2::%release-lock lock)))

(let ((lock (bt2::%make-recursive-lock "v2 recursive")))
  (bt2::%acquire-recursive-lock lock t nil)
  (unwind-protect
      (progn
        (bt2::%acquire-recursive-lock lock nil 0)
        (bt2::%release-recursive-lock lock)
        (assert (null (torcl-thread:join-thread
          (torcl-thread:make-thread
            (lambda () (bt2::%acquire-recursive-lock lock nil nil)))))))
    (bt2::%release-recursive-lock lock))
  (assert (equal '(19 23) (multiple-value-list
    (bt2::%with-recursive-lock (lock nil) (values 19 23))))))

(let ((lock (bt2::%make-lock "v2 broadcast"))
      (cv (bt2::%make-condition-variable "v2 broadcast"))
      (ready 0) (released nil) (workers nil))
  (bt2::%acquire-lock lock t nil)
  (unwind-protect
      (progn
        (dotimes (i 2)
          (push (torcl-thread:make-thread
            (lambda ()
              (bt2::%acquire-lock lock t nil)
              (unwind-protect
                  (progn
                    (setq ready (+ ready 1))
                    (bt2::%condition-broadcast cv)
                    (loop until released do
                      (if (bt2::%condition-wait cv lock 10) nil
                          (error "broadcast worker timed out")))
                    42)
                (bt2::%release-lock lock)))) workers))
        (loop until (= ready 2) do
          (unless (bt2::%condition-wait cv lock 10)
            (error "broadcast workers did not start")))
        (setq released t)
        (bt2::%condition-broadcast cv))
    (bt2::%release-lock lock))
  (dolist (worker workers) (assert (= 42 (torcl-thread:join-thread worker)))))
(format t "TORCL-BT-NATIVE-SYNC-OK~%")
