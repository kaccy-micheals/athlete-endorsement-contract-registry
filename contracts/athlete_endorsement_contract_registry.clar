;; title: athlete_endorsement_contract_registry
;; version: 1.0.0
;; summary: Smart contract for Athlete Endorsement Contract Registry

(define-constant ERR-NOT-FOUND u404)
(define-constant ERR-UNAUTHORIZED u401)
(define-constant ERR-INVALID-AMOUNT u400)
(define-constant ERR-ALREADY-EXISTS u409)
(define-constant ERR-EXPIRED u410)

(define-data-var contract-counter uint u0)

(define-map contracts
  { contract-id: uint }
  {
    athlete: principal,
    brand: principal,
    amount: uint,
    status: (string-ascii 20),
    created-at: uint,
    expires-at: uint,
    description: (string-ascii 200)
  }
)

(define-map athlete-contracts
  { athlete: principal }
  { contract-ids: (list 100 uint) }
)

(define-map brand-contracts
  { brand: principal }
  { contract-ids: (list 100 uint) }
)

(define-read-only (get-contract (contract-id uint))
  (map-get? contracts { contract-id: contract-id })
)

(define-read-only (get-athlete-contracts (athlete principal))
  (map-get? athlete-contracts { athlete: athlete })
)

(define-read-only (get-brand-contracts (brand principal))
  (map-get? brand-contracts { brand: brand })
)

(define-public (register-contract
  (athlete principal)
  (brand principal)
  (amount uint)
  (expires-at uint)
  (description (string-ascii 200))
)
  (let
    (
      (contract-id (var-get contract-counter))
    )
    (if (<= amount u0)
      (err ERR-INVALID-AMOUNT)
      (if (>= burn-block-height expires-at)
        (err ERR-EXPIRED)
        (begin
          (map-set contracts
            { contract-id: contract-id }
            {
              athlete: athlete,
              brand: brand,
              amount: amount,
              status: "active",
              created-at: burn-block-height,
              expires-at: expires-at,
              description: description
            }
          )
          (var-set contract-counter (+ contract-id u1))
          (ok contract-id)
        )
      )
    )
  )
)

(define-public (update-contract-status
  (contract-id uint)
  (new-status (string-ascii 20))
  (caller principal)
)
  (let
    (
      (contract (map-get? contracts { contract-id: contract-id }))
    )
    (if (is-none contract)
      (err ERR-NOT-FOUND)
      (let
        (
          (existing-contract (unwrap! contract (err ERR-NOT-FOUND)))
        )
        (if (or
          (is-eq caller (get athlete existing-contract))
          (is-eq caller (get brand existing-contract))
        )
          (begin
            (map-set contracts
              { contract-id: contract-id }
              (merge existing-contract { status: new-status })
            )
            (ok true)
          )
          (err ERR-UNAUTHORIZED)
        )
      )
    )
  )
)

(define-public (terminate-contract (contract-id uint) (caller principal))
  (let
    (
      (contract (map-get? contracts { contract-id: contract-id }))
    )
    (if (is-none contract)
      (err ERR-NOT-FOUND)
      (let
        (
          (existing-contract (unwrap! contract (err ERR-NOT-FOUND)))
        )
        (if (is-eq caller (get brand existing-contract))
          (begin
            (map-set contracts
              { contract-id: contract-id }
              (merge existing-contract { status: "terminated" })
            )
            (ok true)
          )
          (err ERR-UNAUTHORIZED)
        )
      )
    )
  )
)

(define-public (renew-contract
  (contract-id uint)
  (new-expires-at uint)
  (caller principal)
)
  (let
    (
      (contract (map-get? contracts { contract-id: contract-id }))
    )
    (if (is-none contract)
      (err ERR-NOT-FOUND)
      (let
        (
          (existing-contract (unwrap! contract (err ERR-NOT-FOUND)))
        )
        (if (is-eq caller (get brand existing-contract))
          (begin
            (map-set contracts
              { contract-id: contract-id }
              (merge existing-contract { expires-at: new-expires-at })
            )
            (ok true)
          )
          (err ERR-UNAUTHORIZED)
        )
      )
    )
  )
)
