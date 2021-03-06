;;; testsuit.el -- Test Suit for PSGML

;; $Id: testsuit.el,v 1.15 2005/03/08 18:39:30 lenst Exp $

(require 'cl)
(require 'psgml)
(require 'psgml-parse)

(defconst psgml-test-cases
  '(
    ("tc01.sgml" (warning "Undefined entity.*"))
    ("tc02.xml")
    ("tc03.xml")
    ("tc04.sgml")
    ("tc05.sgml")
    ("tc07.sgml")
    ("tc08.xml")
    ("tc13.el" (warning "Invalid character"))
    ("tc15.el")
    ("tc16.el")
    ("tc17.html")
    ("tc18.el")
    ("tc19.sgml" (warning "B end-tag implied by B start-tag"))
    ("tc20.sgml" (warning "Start-tag of undefined element FOO"))
    ("tc21.sgml")
    ("tc22.el")
    ("tc23.sgml")
    ))


(defun testsuit-pi-handler (string)
  (when (string-match "ASSERT\\>" string )
    (let ((form (car (read-from-string (substring string (match-end 0))))))
      (assert (eval form) nil
              "Assertion fail: %S" form))))

  
(defun testsuit-run-test-case (case-description)
  (let* ((file (first case-description))
         (expected (rest case-description))
         (sgml-show-warnings t)
         (warning-expected nil)
         (sgml-pi-function 'testsuit-pi-handler))
    (setq sgml-catalog-assoc nil)       ; To allow testing catalog parsing
    (setq sgml-ecat-assoc nil)
    (message "--Testing %s" file)
    (find-file file)
    (setq sgml-warning-message-flag nil)
    (condition-case errcode
        (progn
          (if (string-match "\\.el$" (buffer-file-name))
              (progn (eval-buffer))
            (message "current buffer: %s" (current-buffer))
            (sgml-load-doctype)
            ;;(sgml-next-trouble-spot)
            (sgml-parse-until-end-of nil)))
      (error
       (if expected
           (case (caar expected)
             (error (debug)))
         (error "Unexpected %s" errcode))))

    (while (and expected)
      (case (caar expected)
        (warning
         (setq warning-expected t)
         (let ((warning-pattern (cadar expected)))
           (with-current-buffer  "*Messages*"
             (goto-char (point-min))
             (or (re-search-forward warning-pattern nil t)
                 (error "No %s warning" warning-pattern)))))
        (assert
         (or (eval (cadar expected))
             (error "Fail: %s" (cadar expected)))))
      (setq expected (cdr expected)))
    (when (and sgml-warning-message-flag (not warning-expected))
      (error "Unexpected warnings")) ))


(defun testsuit-run ()
  (interactive)
  (loop for tc in psgml-test-cases
        do (testsuit-run-test-case tc))
  (message "Done"))
