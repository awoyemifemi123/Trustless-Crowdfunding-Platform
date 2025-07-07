(define-constant ERR_MILESTONE_NOT_FOUND (err u200))
(define-constant ERR_MILESTONE_EXPIRED (err u201))
(define-constant ERR_ALREADY_VOTED (err u202))
(define-constant ERR_INSUFFICIENT_VOTES (err u203))
(define-constant ERR_MILESTONE_APPROVED (err u204))
(define-constant ERR_NOT_CONTRIBUTOR (err u205))
(define-constant ERR_FUNDS_RELEASED (err u206))
(define-constant ERR_INVALID_AMOUNT (err u207))
(define-constant ERR_NOT_AUTHORIZED (err u208))

(define-data-var milestone-counter uint u0)

(define-map milestones
  { milestone-id: uint }
  {
    project-id: uint,
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 300),
    funding-amount: uint,
    votes-needed: uint,
    votes-received: uint,
    deadline: uint,
    approved: bool,
    funds-released: bool
  }
)

(define-map milestone-votes
  { milestone-id: uint, voter: principal }
  { vote: bool }
)

(define-public (create-milestone (project-id uint) (title (string-ascii 100)) (description (string-ascii 300)) (funding-amount uint) (votes-needed uint) (duration uint))
  (let
    (
      (milestone-id (+ (var-get milestone-counter) u1))
      (deadline (+ stacks-block-height duration))
    )
    (asserts! (> funding-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> votes-needed u0) ERR_INVALID_AMOUNT)
    (asserts! (> duration u0) ERR_INVALID_AMOUNT)
    (map-set milestones
      { milestone-id: milestone-id }
      {
        project-id: project-id,
        creator: tx-sender,
        title: title,
        description: description,
        funding-amount: funding-amount,
        votes-needed: votes-needed,
        votes-received: u0,
        deadline: deadline,
        approved: false,
        funds-released: false
      }
    )
    (var-set milestone-counter milestone-id)
    (ok milestone-id)
  )
)

(define-public (vote-milestone (milestone-id uint) (vote bool))
  (let
    (
      (milestone (unwrap! (map-get? milestones { milestone-id: milestone-id }) ERR_MILESTONE_NOT_FOUND))
      (existing-vote (map-get? milestone-votes { milestone-id: milestone-id, voter: tx-sender }))
    )
    (asserts! (<= stacks-block-height (get deadline milestone)) ERR_MILESTONE_EXPIRED)
    (asserts! (not (get approved milestone)) ERR_MILESTONE_APPROVED)
    (asserts! (is-none existing-vote) ERR_ALREADY_VOTED)
    (map-set milestone-votes
      { milestone-id: milestone-id, voter: tx-sender }
      { vote: vote }
    )
    (if vote
      (map-set milestones
        { milestone-id: milestone-id }
        (merge milestone { votes-received: (+ (get votes-received milestone) u1) })
      )
      true
    )
    (ok true)
  )
)

(define-public (release-milestone-funds (milestone-id uint))
  (let
    (
      (milestone (unwrap! (map-get? milestones { milestone-id: milestone-id }) ERR_MILESTONE_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get creator milestone)) ERR_NOT_AUTHORIZED)
    (asserts! (>= (get votes-received milestone) (get votes-needed milestone)) ERR_INSUFFICIENT_VOTES)
    (asserts! (not (get funds-released milestone)) ERR_FUNDS_RELEASED)
    (map-set milestones
      { milestone-id: milestone-id }
      (merge milestone { approved: true, funds-released: true })
    )
    (ok (get funding-amount milestone))
  )
)

(define-read-only (get-milestone (milestone-id uint))
  (map-get? milestones { milestone-id: milestone-id })
)

(define-read-only (get-milestone-vote (milestone-id uint) (voter principal))
  (map-get? milestone-votes { milestone-id: milestone-id, voter: voter })
)

(define-read-only (get-milestone-count)
  (var-get milestone-counter)
) 

(define-read-only (is-milestone-approved (milestone-id uint))
  (match (map-get? milestones { milestone-id: milestone-id })
    milestone (>= (get votes-received milestone) (get votes-needed milestone))
    false
  )
)
