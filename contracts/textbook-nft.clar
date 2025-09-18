;; Bookrent Textbook NFT Contract
;; Implements SIP-009 NFT standard for textbook management

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_METADATA (err u103))
(define-constant ERR_TOKEN_NOT_OWNED (err u104))

;; NFT Definition
(define-non-fungible-token textbook uint)

;; Data Variables
(define-data-var last-token-id uint u0)
(define-data-var contract-uri (optional (string-utf8 256)) none)

;; Token metadata structure
(define-map token-metadata
  uint
  {
    title: (string-utf8 100),
    author: (string-utf8 100),
    isbn: (string-ascii 17),
    publisher: (string-utf8 100),
    edition: (string-utf8 50),
    year: uint,
    condition: (string-ascii 20),
    institution: (string-utf8 100)
  }
)

;; Token URI mapping
(define-map token-uris
  uint
  (string-utf8 256)
)

;; Institution management
(define-map authorized-institutions
  principal
  bool
)

;; Textbook availability status
(define-map textbook-status
  uint
  {
    available: bool,
    borrowed-by: (optional principal),
    due-date: (optional uint)
  }
)

;; SIP-009 Implementation

;; Get last token ID
(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)

;; Get token URI
(define-read-only (get-token-uri (token-id uint))
  (ok (map-get? token-uris token-id))
)

;; Get owner of token
(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? textbook token-id))
)

;; Transfer token
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
    (asserts! (is-some (nft-get-owner? textbook token-id)) ERR_NOT_FOUND)
    (nft-transfer? textbook token-id sender recipient)
  )
)

;; Public Functions

;; Add authorized institution
(define-public (add-institution (institution principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set authorized-institutions institution true)
    (ok true)
  )
)

;; Remove authorized institution
(define-public (remove-institution (institution principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-delete authorized-institutions institution)
    (ok true)
  )
)

;; Mint new textbook NFT
(define-public (mint-textbook 
    (recipient principal)
    (title (string-utf8 100))
    (author (string-utf8 100))
    (isbn (string-ascii 17))
    (publisher (string-utf8 100))
    (edition (string-utf8 50))
    (year uint)
    (condition (string-ascii 20))
    (institution (string-utf8 100))
    (token-uri (string-utf8 256))
  )
  (let
    (
      (token-id (+ (var-get last-token-id) u1))
    )
    ;; Check authorization
    (asserts! 
      (or 
        (is-eq tx-sender CONTRACT_OWNER)
        (default-to false (map-get? authorized-institutions tx-sender))
      ) 
      ERR_UNAUTHORIZED
    )
    
    ;; Validate metadata
    (asserts! (> (len title) u0) ERR_INVALID_METADATA)
    (asserts! (> (len author) u0) ERR_INVALID_METADATA)
    (asserts! (> (len isbn) u0) ERR_INVALID_METADATA)
    (asserts! (> year u1900) ERR_INVALID_METADATA)
    
    ;; Mint NFT
    (try! (nft-mint? textbook token-id recipient))
    
    ;; Set metadata
    (map-set token-metadata token-id {
      title: title,
      author: author,
      isbn: isbn,
      publisher: publisher,
      edition: edition,
      year: year,
      condition: condition,
      institution: institution
    })
    
    ;; Set token URI
    (map-set token-uris token-id token-uri)
    
    ;; Set initial availability status
    (map-set textbook-status token-id {
      available: true,
      borrowed-by: none,
      due-date: none
    })
    
    ;; Update last token ID
    (var-set last-token-id token-id)
    
    (ok token-id)
  )
)

;; Update textbook status (for lending system)
(define-public (update-textbook-status 
    (token-id uint)
    (available bool)
    (borrowed-by (optional principal))
    (due-date (optional uint))
  )
  (begin
    ;; Only contract owner or token owner can update
    (asserts! 
      (or 
        (is-eq tx-sender CONTRACT_OWNER)
        (is-eq tx-sender (unwrap! (nft-get-owner? textbook token-id) ERR_NOT_FOUND))
      ) 
      ERR_UNAUTHORIZED
    )
    
    (map-set textbook-status token-id {
      available: available,
      borrowed-by: borrowed-by,
      due-date: due-date
    })
    
    (ok true)
  )
)

;; Burn textbook NFT (for damaged/lost books)
(define-public (burn-textbook (token-id uint))
  (let
    (
      (owner (unwrap! (nft-get-owner? textbook token-id) ERR_NOT_FOUND))
    )
    ;; Only owner can burn
    (asserts! (is-eq tx-sender owner) ERR_UNAUTHORIZED)
    
    ;; Burn the NFT
    (try! (nft-burn? textbook token-id owner))
    
    ;; Clean up metadata
    (map-delete token-metadata token-id)
    (map-delete token-uris token-id)
    (map-delete textbook-status token-id)
    
    (ok true)
  )
)

;; Set contract URI
(define-public (set-contract-uri (uri (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-uri (some uri))
    (ok true)
  )
)

;; Read-only functions

;; Get textbook metadata
(define-read-only (get-textbook-metadata (token-id uint))
  (map-get? token-metadata token-id)
)

;; Get textbook status
(define-read-only (get-textbook-status (token-id uint))
  (map-get? textbook-status token-id)
)

;; Check if textbook is available for borrowing
(define-read-only (is-textbook-available (token-id uint))
  (match (map-get? textbook-status token-id)
    status (get available status)
    false
  )
)

;; Get textbook borrower
(define-read-only (get-textbook-borrower (token-id uint))
  (match (map-get? textbook-status token-id)
    status (get borrowed-by status)
    none
  )
)

;; Get textbook due date
(define-read-only (get-due-date (token-id uint))
  (match (map-get? textbook-status token-id)
    status (get due-date status)
    none
  )
)

;; Check if institution is authorized
(define-read-only (is-institution-authorized (institution principal))
  (default-to false (map-get? authorized-institutions institution))
)

;; Get contract URI
(define-read-only (get-contract-uri)
  (ok (var-get contract-uri))
)

;; Get all textbooks by owner (simplified version)
(define-read-only (get-textbook-info (token-id uint))
  (match (nft-get-owner? textbook token-id)
    owner 
      (some {
        owner: owner,
        metadata: (map-get? token-metadata token-id),
        status: (map-get? textbook-status token-id),
        uri: (map-get? token-uris token-id)
      })
    none
  )
)

