;;;; End-to-end ASDF activation test for the TorCL backend.

(require :asdf)
(asdf:load-asd
 (merge-pathnames "../bordeaux-threads.asd" *load-truename*))
(asdf:load-system :bordeaux-threads :force t)

(assert bordeaux-threads:*supports-threads-p*)
(assert bordeaux-threads-2:+supports-threads-p+)
(assert (not (bordeaux-threads-2::implemented-p
              'bordeaux-threads-2:interrupt-thread)))
(assert (not (bordeaux-threads-2::implemented-p
              'bordeaux-threads-2:destroy-thread)))
(assert (not (bordeaux-threads-2::implemented-p
              'bordeaux-threads-2:with-timeout)))
(assert
 (handler-case
     (progn
       (bordeaux-threads:with-timeout (0) :unexpected)
       nil)
   (error () t)))
(assert
 (handler-case
     (progn
       (bordeaux-threads-2:with-timeout (0) :unexpected)
       nil)
   (bordeaux-threads-2:not-implemented () t)))
(format t "TORCL-BT-ASDF-FLAGS-OK~%")

(let* ((ready (bordeaux-threads-2:make-semaphore :count 0))
       (release (bordeaux-threads-2:make-semaphore :count 0))
       (thread
         (progn
          (format t "TORCL-BT-ASDF-MAKING-THREAD~%")
         (bordeaux-threads-2:make-thread
          (lambda ()
            (bordeaux-threads-2:signal-semaphore ready)
            (assert (bordeaux-threads-2:wait-on-semaphore release :timeout 10))
            (values 17 19))
          :name "TorCL ASDF worker"))))
  (format t "TORCL-BT-ASDF-THREAD-MADE~%")
  (assert (bordeaux-threads-2:wait-on-semaphore ready :timeout 10))
  (assert (string= "TorCL ASDF worker"
                   (bordeaux-threads-2:thread-name thread)))
  (assert (bordeaux-threads-2:thread-alive-p thread))
  (assert (member thread (bordeaux-threads-2:all-threads)))
  (bordeaux-threads-2:signal-semaphore release)
  (assert (equal '(17 19)
                 (multiple-value-list
                  (bordeaux-threads-2:join-thread thread))))
  (assert (null (bordeaux-threads-2:thread-alive-p thread)))
  (assert (null (member thread (bordeaux-threads-2:all-threads))))
  (assert
   (null (gethash (bordeaux-threads-2::thread-native-thread thread)
                  bordeaux-threads-2::.known-threads.))))

(format t "TORCL-BT-ASDF-LOAD-OK~%")
