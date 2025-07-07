(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_PROJECT_NOT_FOUND (err u101))
(define-constant ERR_PROJECT_ENDED (err u102))
(define-constant ERR_GOAL_REACHED (err u103))
(define-constant ERR_GOAL_NOT_REACHED (err u104))
(define-constant ERR_ALREADY_CONTRIBUTED (err u105))
(define-constant ERR_NO_CONTRIBUTION (err u106))
(define-constant ERR_INSUFFICIENT_FUNDS (err u107))
(define-constant ERR_INVALID_AMOUNT (err u108))
(define-constant ERR_PROJECT_ACTIVE (err u109))

(define-data-var project-counter uint u0)

(define-map projects
  { project-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    goal: uint,
    raised: uint,
    deadline: uint,
    active: bool,
    funded: bool
  }
)

(define-map contributions
  { project-id: uint, contributor: principal }
  { amount: uint }
)

(define-map project-contributors
  { project-id: uint }
  { contributors: (list 100 principal) }
)

(define-public (create-project (title (string-ascii 100)) (description (string-ascii 500)) (goal uint) (duration uint))
  (let
    (
      (project-id (+ (var-get project-counter) u1))
      (deadline (+ stacks-block-height duration))
    )
    (asserts! (> goal u0) ERR_INVALID_AMOUNT)
    (asserts! (> duration u0) ERR_INVALID_AMOUNT)
    (map-set projects
      { project-id: project-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        goal: goal,
        raised: u0,
        deadline: deadline,
        active: true,
        funded: false
      }
    )
    (map-set project-contributors
      { project-id: project-id }
      { contributors: (list) }
    )
    (var-set project-counter project-id)
    (ok project-id)
  )
)

(define-public (contribute (project-id uint) (amount uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
      (existing-contribution (map-get? contributions { project-id: project-id, contributor: tx-sender }))
      (contributors-data (default-to { contributors: (list) } (map-get? project-contributors { project-id: project-id })))
    )
    (asserts! (get active project) ERR_PROJECT_ENDED)
    (asserts! (<= stacks-block-height (get deadline project)) ERR_PROJECT_ENDED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-none existing-contribution) ERR_ALREADY_CONTRIBUTED)
    (asserts! (< (get raised project) (get goal project)) ERR_GOAL_REACHED)
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set contributions
      { project-id: project-id, contributor: tx-sender }
      { amount: amount }
    )
    
    (map-set project-contributors
      { project-id: project-id }
      { contributors: (unwrap! (as-max-len? (append (get contributors contributors-data) tx-sender) u100) ERR_INVALID_AMOUNT) }
    )
    
    (map-set projects
      { project-id: project-id }
      (merge project { raised: (+ (get raised project) amount) })
    )
    
    (ok true)
  )
)

(define-public (finalize-project (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
    )
    (asserts! (or (is-eq tx-sender (get creator project)) (is-eq tx-sender CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)
    (asserts! (get active project) ERR_PROJECT_ENDED)
    (asserts! (> stacks-block-height (get deadline project)) ERR_PROJECT_ACTIVE)
    
    (if (>= (get raised project) (get goal project))
      (begin
        (try! (as-contract (stx-transfer? (get raised project) tx-sender (get creator project))))
        (map-set projects
          { project-id: project-id }
          (merge project { active: false, funded: true })
        )
        (ok { success: true, funded: true })
      )
      (begin
        (map-set projects
          { project-id: project-id }
          (merge project { active: false, funded: false })
        )
        (ok { success: true, funded: false })
      )
    )
  )
)

(define-public (claim-refund (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
      (contribution (unwrap! (map-get? contributions { project-id: project-id, contributor: tx-sender }) ERR_NO_CONTRIBUTION))
    )
    (asserts! (not (get active project)) ERR_PROJECT_ACTIVE)
    (asserts! (not (get funded project)) ERR_GOAL_REACHED)
    (asserts! (< (get raised project) (get goal project)) ERR_GOAL_REACHED)
    
    (try! (as-contract (stx-transfer? (get amount contribution) tx-sender tx-sender)))
    
    (map-delete contributions { project-id: project-id, contributor: tx-sender })
    
    (ok (get amount contribution))
  )
)

(define-public (emergency-refund (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
      (contributors-data (unwrap! (map-get? project-contributors { project-id: project-id }) ERR_PROJECT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (get active project) ERR_PROJECT_ENDED)
    
    (map-set projects
      { project-id: project-id }
      (merge project { active: false, funded: false })
    )
    
    (ok (fold refund-contributor (get contributors contributors-data) { project-id: project-id, refunded: u0 }))
  )
)

(define-private (refund-contributor (contributor principal) (data { project-id: uint, refunded: uint }))
  (let
    (
      (contribution (map-get? contributions { project-id: (get project-id data), contributor: contributor }))
    )
    (match contribution
      contrib
      (begin
        (unwrap-panic (as-contract (stx-transfer? (get amount contrib) tx-sender contributor)))
        (map-delete contributions { project-id: (get project-id data), contributor: contributor })
        { project-id: (get project-id data), refunded: (+ (get refunded data) (get amount contrib)) }
      )
      data
    )
  )
)

(define-read-only (get-project (project-id uint))
  (map-get? projects { project-id: project-id })
)

(define-read-only (get-contribution (project-id uint) (contributor principal))
  (map-get? contributions { project-id: project-id, contributor: contributor })
)

(define-read-only (get-project-contributors (project-id uint))
  (map-get? project-contributors { project-id: project-id })
)

(define-read-only (get-project-count)
  (var-get project-counter)
)

(define-read-only (is-project-funded (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project (>= (get raised project) (get goal project))
    false
  )
)

(define-read-only (is-project-expired (project-id uint))
  (match (map-get? projects { project-id: project-id })
    project (> stacks-block-height (get deadline project))
    false
  )
)

(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)

(define-read-only (can-claim-refund (project-id uint) (contributor principal))
  (match (map-get? projects { project-id: project-id })
    project
    (and
      (not (get active project))
      (not (get funded project))
      (< (get raised project) (get goal project))
      (is-some (map-get? contributions { project-id: project-id, contributor: contributor }))
    )
    false
  )
)
