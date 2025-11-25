;; MysticScrolls - Ancient Knowledge Exchange 
;; A Stacks smart contract for inscribing, trading, and managing mystical scrolls.

;; Error definitions
(define-constant err-forbidden (err u100))
(define-constant err-wrong-keeper (err u101))
(define-constant err-no-offering (err u102))
(define-constant err-price-insufficient (err u103))
(define-constant err-scroll-absent (err u104))
(define-constant err-corrupt-data (err u105))
(define-constant err-tribute-excessive (err u106))
(define-constant err-null-entity (err u107))

;; NFT token
(define-non-fungible-token mystic-scroll uint)

;; Variables
(define-data-var grand-keeper principal tx-sender)
(define-data-var scroll-sequence uint u1)

;; Maps
(define-map scroll-archive
  { scroll-num: uint }
  { keeper: principal, scribe: principal, inscription: (string-ascii 256), tribute: uint })

(define-map bazaar
  { scroll-num: uint }
  { cost: uint, vendor: principal })

;; Auth helper
(define-private (check-keeper-auth)
  (is-eq tx-sender (var-get grand-keeper)))

;; Address validator
(define-private (verify-entity (entity principal))
  (not (is-eq entity 'SP000000000000000000002Q6VF78)))

;; Change keeper
(define-public (appoint-keeper (successor principal))
  (begin
    (asserts! (check-keeper-auth) err-forbidden)
    (asserts! (verify-entity successor) err-null-entity)
    (ok (var-set grand-keeper successor))
  ))

;; Get keeper
(define-read-only (retrieve-keeper)
  (ok (var-get grand-keeper)))

;; Inscribe scroll
(define-public (inscribe (inscription (string-ascii 256)) (tribute uint))
  (let ((scroll-num (var-get scroll-sequence)))
    (asserts! (> (len inscription) u0) err-corrupt-data)
    (asserts! (<= tribute u1000) err-tribute-excessive)
    (try! (nft-mint? mystic-scroll scroll-num tx-sender))
    (map-set scroll-archive
      { scroll-num: scroll-num }
      { keeper: tx-sender, scribe: tx-sender, inscription: inscription, tribute: tribute }
    )
    (var-set scroll-sequence (+ scroll-num u1))
    (ok scroll-num)
  ))

;; Offer scroll
(define-public (offer-scroll (scroll-num uint) (cost uint))
  (let ((current-keeper (unwrap! (nft-get-owner? mystic-scroll scroll-num) err-scroll-absent)))
    (asserts! (> cost u0) err-price-insufficient)
    (asserts! (is-eq tx-sender current-keeper) err-wrong-keeper)
    (map-set bazaar
      { scroll-num: scroll-num }
      { cost: cost, vendor: tx-sender }
    )
    (ok true)
  ))

;; Withdraw offering
(define-public (withdraw-offering (scroll-num uint))
  (let ((offering-data (unwrap! (map-get? bazaar { scroll-num: scroll-num }) err-no-offering)))
    (asserts! (< scroll-num (var-get scroll-sequence)) err-scroll-absent)
    (asserts! (is-eq tx-sender (get vendor offering-data)) err-wrong-keeper)
    (map-delete bazaar { scroll-num: scroll-num })
    (ok true)
  ))

;; Obtain scroll
(define-public (obtain (scroll-num uint))
  (let
    (
      (offering-data (unwrap! (map-get? bazaar { scroll-num: scroll-num }) err-no-offering))
      (full-cost (get cost offering-data))
      (vendor-principal (get vendor offering-data))
      (scroll-info (unwrap! (map-get? scroll-archive { scroll-num: scroll-num }) err-scroll-absent))
      (original-scribe (get scribe scroll-info))
      (tribute-rate (get tribute scroll-info))
      (scribe-tribute (/ (* full-cost tribute-rate) u10000))
      (vendor-proceeds (- full-cost scribe-tribute))
    )
    (asserts! (< scroll-num (var-get scroll-sequence)) err-scroll-absent)
    (try! (stx-transfer? scribe-tribute tx-sender original-scribe))
    (try! (stx-transfer? vendor-proceeds tx-sender vendor-principal))
    (try! (nft-transfer? mystic-scroll scroll-num vendor-principal tx-sender))
    (map-set scroll-archive
      { scroll-num: scroll-num }
      (merge scroll-info { keeper: tx-sender })
    )
    (map-delete bazaar { scroll-num: scroll-num })
    (ok true)
  ))

;; Read scroll info
(define-read-only (examine (scroll-num uint))
  (ok (unwrap! (map-get? scroll-archive { scroll-num: scroll-num }) err-scroll-absent)))

;; Read offering info
(define-read-only (examine-offering (scroll-num uint))
  (ok (unwrap! (map-get? bazaar { scroll-num: scroll-num }) err-no-offering)))