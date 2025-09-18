;; Bookrent Lending Manager Contract
;; Manages textbook borrowing, returns, and fee calculations

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_TEXTBOOK_NOT_FOUND (err u201))
(define-constant ERR_TEXTBOOK_NOT_AVAILABLE (err u202))
(define-constant ERR_ALREADY_BORROWED (err u203))
(define-constant ERR_NOT_BORROWED (err u204))
(define-constant ERR_LATE_RETURN (err u205))
(define-constant ERR_INVALID_PERIOD (err u206))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u207))

;; Lending configuration
(define-constant DEFAULT_LENDING_PERIOD u2016) ;; 2 weeks in blocks (assuming 10min blocks)
(define-constant LATE_FEE_PER_BLOCK u100) ;; Late fee per block in microSTX
(define-constant MAX_LENDING_PERIOD u4032) ;; 4 weeks maximum

;; Data Variables
(define-data-var lending-enabled bool true)
(define-data-var late-fee-rate uint LATE_FEE_PER_BLOCK)
(define-data-var max-books-per-user uint u5)

;; Borrowing records
(define-map borrowing-records
  { textbook-id: uint, borrower: principal }
  {
    borrowed-at: uint,
    due-date: uint,
    returned: bool,
    returned-at: (optional uint),
    late-fee-paid: uint
  }
)

;; User borrowing history
(define-map user-borrowing-count
  principal
  uint
)

;; Accumulated fees
(define-map user-fees
  principal
  uint
)

;; Institution lending policies
(define-map institution-policies
  principal
  {
    lending-period: uint,
    institution-late-fee-rate: uint,
    max-books: uint
  }
)

;; Public Functions

;; Enable/disable lending system
(define-public (set-lending-enabled (enabled bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set lending-enabled enabled)
    (ok true)
  )
)

;; Update late fee rate
(define-public (set-late-fee-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set late-fee-rate new-rate)
    (ok true)
  )
)

;; Set maximum books per user
(define-public (set-max-books-per-user (max-books uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set max-books-per-user max-books)
    (ok true)
  )
)

;; Set institution-specific lending policies
(define-public (set-institution-policy 
    (institution principal)
    (lending-period uint)
    (institution-late-fee-rate uint)
    (max-books uint)
  )
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= lending-period MAX_LENDING_PERIOD) ERR_INVALID_PERIOD)
    
    (map-set institution-policies institution {
      lending-period: lending-period,
      institution-late-fee-rate: institution-late-fee-rate,
      max-books: max-books
    })
    
    (ok true)
  )
)

;; Borrow a textbook
(define-public (borrow-textbook (textbook-id uint) (lending-period-blocks uint))
  (let
    (
      (borrower tx-sender)
      (current-block stacks-block-height)
      (actual-period (if (> lending-period-blocks u0) 
                       (if (<= lending-period-blocks MAX_LENDING_PERIOD)
                         lending-period-blocks
                         MAX_LENDING_PERIOD)
                       DEFAULT_LENDING_PERIOD))
      (due-date (+ current-block actual-period))
      (current-borrows (default-to u0 (map-get? user-borrowing-count borrower)))
    )
    
    ;; Check if lending is enabled
    (asserts! (var-get lending-enabled) ERR_UNAUTHORIZED)
    
    ;; Check borrowing limit
    (asserts! (< current-borrows (var-get max-books-per-user)) ERR_ALREADY_BORROWED)
    
    ;; Validate lending period
    (asserts! (<= actual-period MAX_LENDING_PERIOD) ERR_INVALID_PERIOD)
    
    ;; Record the borrowing
    (map-set borrowing-records 
      { textbook-id: textbook-id, borrower: borrower }
      {
        borrowed-at: current-block,
        due-date: due-date,
        returned: false,
        returned-at: none,
        late-fee-paid: u0
      }
    )
    
    ;; Update user borrowing count
    (map-set user-borrowing-count borrower (+ current-borrows u1))
    
    (ok due-date)
  )
)

;; Return a textbook
(define-public (return-textbook (textbook-id uint))
  (let
    (
      (borrower tx-sender)
      (current-block stacks-block-height)
      (borrow-key { textbook-id: textbook-id, borrower: borrower })
      (borrow-record (unwrap! (map-get? borrowing-records borrow-key) ERR_NOT_BORROWED))
    )
    
    ;; Check if already returned
    (asserts! (not (get returned borrow-record)) ERR_NOT_BORROWED)
    
    ;; Calculate late fee if applicable
    (let
      (
        (late-blocks (if (> current-block (get due-date borrow-record))
                        (- current-block (get due-date borrow-record))
                        u0))
        (late-fee (* late-blocks (var-get late-fee-rate)))
      )
      
      ;; Update borrowing record
      (map-set borrowing-records borrow-key 
        (merge borrow-record {
          returned: true,
          returned-at: (some current-block),
          late-fee-paid: late-fee
        })
      )
      
      ;; Update user borrowing count
      (let 
        (
          (current-borrows (default-to u0 (map-get? user-borrowing-count borrower)))
        )
        (map-set user-borrowing-count borrower (if (> current-borrows u0) (- current-borrows u1) u0))
      )
      
      ;; Add late fee to user's accumulated fees if any
      (if (> late-fee u0)
        (let
          (
            (current-fees (default-to u0 (map-get? user-fees borrower)))
          )
          (map-set user-fees borrower (+ current-fees late-fee))
        )
        true
      )
      
      (ok {
        returned-at: current-block,
        late-fee: late-fee,
        was-late: (> late-blocks u0)
      })
    )
  )
)

;; Pay accumulated late fees
(define-public (pay-late-fees)
  (let
    (
      (payer tx-sender)
      (fees-owed (default-to u0 (map-get? user-fees payer)))
    )
    
    (asserts! (> fees-owed u0) ERR_INSUFFICIENT_PAYMENT)
    
    ;; Clear the fees (in a real implementation, this would transfer STX)
    (map-delete user-fees payer)
    
    (ok fees-owed)
  )
)

;; Extend borrowing period (if not overdue)
(define-public (extend-borrowing (textbook-id uint) (additional-blocks uint))
  (let
    (
      (borrower tx-sender)
      (current-block stacks-block-height)
      (borrow-key { textbook-id: textbook-id, borrower: borrower })
      (borrow-record (unwrap! (map-get? borrowing-records borrow-key) ERR_NOT_BORROWED))
    )
    
    ;; Check if not returned and not overdue
    (asserts! (not (get returned borrow-record)) ERR_NOT_BORROWED)
    (asserts! (<= current-block (get due-date borrow-record)) ERR_LATE_RETURN)
    
    ;; Check extension validity
    (let
      (
        (new-due-date (+ (get due-date borrow-record) additional-blocks))
        (max-due-date (+ (get borrowed-at borrow-record) MAX_LENDING_PERIOD))
      )
      
      (asserts! (<= new-due-date max-due-date) ERR_INVALID_PERIOD)
      
      ;; Update due date
      (map-set borrowing-records borrow-key 
        (merge borrow-record {
          due-date: new-due-date
        })
      )
      
      (ok new-due-date)
    )
  )
)

;; Read-only functions

;; Get borrowing record
(define-read-only (get-borrowing-record (textbook-id uint) (borrower principal))
  (map-get? borrowing-records { textbook-id: textbook-id, borrower: borrower })
)

;; Check if textbook is currently borrowed
(define-read-only (is-textbook-borrowed (textbook-id uint) (borrower principal))
  (match (map-get? borrowing-records { textbook-id: textbook-id, borrower: borrower })
    record (not (get returned record))
    false
  )
)

;; Get user's current borrowing count
(define-read-only (get-user-borrowing-count (user principal))
  (default-to u0 (map-get? user-borrowing-count user))
)

;; Get user's accumulated fees
(define-read-only (get-user-fees (user principal))
  (default-to u0 (map-get? user-fees user))
)

;; Calculate current late fee for a borrowing
(define-read-only (calculate-current-late-fee (textbook-id uint) (borrower principal))
  (match (map-get? borrowing-records { textbook-id: textbook-id, borrower: borrower })
    record 
      (if (get returned record)
        u0
        (let
          (
            (current-block stacks-block-height)
            (due-date (get due-date record))
          )
          (if (> current-block due-date)
            (* (- current-block due-date) (var-get late-fee-rate))
            u0
          )
        )
      )
    u0
  )
)

;; Check if borrowing is overdue
(define-read-only (is-borrowing-overdue (textbook-id uint) (borrower principal))
  (match (map-get? borrowing-records { textbook-id: textbook-id, borrower: borrower })
    record 
      (and 
        (not (get returned record))
        (> stacks-block-height (get due-date record))
      )
    false
  )
)

;; Get lending system status
(define-read-only (get-lending-status)
  {
    enabled: (var-get lending-enabled),
    late-fee-rate: (var-get late-fee-rate),
    max-books-per-user: (var-get max-books-per-user),
    default-lending-period: DEFAULT_LENDING_PERIOD,
    max-lending-period: MAX_LENDING_PERIOD
  }
)

;; Get institution policy
(define-read-only (get-institution-policy (institution principal))
  (map-get? institution-policies institution)
)

;; Get borrowing history for a user (simplified)
(define-read-only (get-borrowing-summary (user principal))
  {
    current-borrows: (get-user-borrowing-count user),
    accumulated-fees: (get-user-fees user),
    max-allowed-books: (var-get max-books-per-user)
  }
)

