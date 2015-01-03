
(in-package #:uncommonshell)

#|

# The IOPUB publish/subscribe channel #

|#

(defclass iopub-channel ()
  ((kernel :initarg :kernel :reader iopub-kernel)
   (socket :initarg :socket :initform nil :accessor iopub-socket)))

(defun make-iopub-channel (kernel)
  (let ((socket (pzmq:socket (kernel-ctx kernel) :pub)))  
    (let ((iopub (make-instance 'iopub-channel
                                :kernel kernel
                                :socket socket)))
      (let ((config (slot-value kernel 'config)))
        (let ((endpoint (format nil "~A://~A:~A"
                                  (config-transport config)
                                  (config-ip config)
                                  (config-iopub-port config))))
          (format t "[IOPUB] iopub endpoint is: ~A~%" endpoint)
          (pzmq:bind socket endpoint)
	  (setf (slot-value kernel 'iopub) iopub)
          iopub)))))



(defun send-status-update (iopub hdr ids sig status)
  (let ((status-content `((:execution--state . ,status))))
    (let ((status-msg (make-instance 
		       'message
		       :header (make-instance 
				'header
				:msg-id (format nil "~W" (uuid:make-v4-uuid))
				:username (header-username hdr)
				:session (header-session hdr)
				:msg-type "status"
				:version (header-version hdr))
		       :parent-header hdr
		       :metadata ""
		       :content (json:encode-json-to-string status-content))))
      (message-send (iopub-socket iopub) status-msg :identities ids :raw-content t))))

;; (json:encode-json-to-string '((:execution--state . :busy)))