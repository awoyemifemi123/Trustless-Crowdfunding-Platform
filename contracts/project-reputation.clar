(define-constant ERR_NOT_CONTRIBUTOR (err u300))
(define-constant ERR_ALREADY_RATED (err u301))
(define-constant ERR_INVALID_RATING (err u302))
(define-constant ERR_PROJECT_NOT_FUNDED (err u303))
(define-constant ERR_PROJECT_STILL_ACTIVE (err u304))

(define-map project-ratings
  { project-id: uint, rater: principal }
  { rating: uint, comment: (string-ascii 200) }
)

(define-map creator-reputation
  { creator: principal }
  { 
    total-score: uint,
    rating-count: uint,
    projects-completed: uint,
    average-rating: uint
  }
)

(define-map project-rating-summary
  { project-id: uint }
  {
    total-ratings: uint,
    average-rating: uint,
    rating-sum: uint
  }
)

(define-public (rate-project (project-id uint) (rating uint) (comment (string-ascii 200)))
  (let
    (
      (project-data (contract-call? .Trustless-Crowdfunding-Platform get-project project-id))
      (contribution-data (contract-call? .Trustless-Crowdfunding-Platform get-contribution project-id tx-sender))
      (existing-rating (map-get? project-ratings { project-id: project-id, rater: tx-sender }))
    )
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_RATING)
    (asserts! (is-some contribution-data) ERR_NOT_CONTRIBUTOR)
    (asserts! (is-none existing-rating) ERR_ALREADY_RATED)
    
    (match project-data
      project
      (let
        (
          (creator (get creator project))
          (is-funded (get funded project))
          (is-active (get active project))
        )
        (asserts! is-funded ERR_PROJECT_NOT_FUNDED)
        (asserts! (not is-active) ERR_PROJECT_STILL_ACTIVE)
        
        (map-set project-ratings
          { project-id: project-id, rater: tx-sender }
          { rating: rating, comment: comment }
        )
        
        (update-project-summary project-id rating)
        (update-creator-reputation creator rating)
        (ok true)
      )
      ERR_PROJECT_NOT_FUNDED
    )
  )
)

(define-private (update-project-summary (project-id uint) (new-rating uint))
  (let
    (
      (current-summary (default-to 
        { total-ratings: u0, average-rating: u0, rating-sum: u0 }
        (map-get? project-rating-summary { project-id: project-id })
      ))
      (new-total (+ (get total-ratings current-summary) u1))
      (new-sum (+ (get rating-sum current-summary) new-rating))
      (new-average (/ new-sum new-total))
    )
    (map-set project-rating-summary
      { project-id: project-id }
      {
        total-ratings: new-total,
        average-rating: new-average,
        rating-sum: new-sum
      }
    )
  )
)

(define-private (update-creator-reputation (creator principal) (new-rating uint))
  (let
    (
      (current-rep (default-to
        { total-score: u0, rating-count: u0, projects-completed: u0, average-rating: u0 }
        (map-get? creator-reputation { creator: creator })
      ))
      (new-count (+ (get rating-count current-rep) u1))
      (new-total (+ (get total-score current-rep) new-rating))
      (new-average (/ new-total new-count))
    )
    (map-set creator-reputation
      { creator: creator }
      {
        total-score: new-total,
        rating-count: new-count,
        projects-completed: (get projects-completed current-rep),
        average-rating: new-average
      }
    )
  )
)

(define-read-only (get-project-rating (project-id uint) (rater principal))
  (map-get? project-ratings { project-id: project-id, rater: rater })
)

(define-read-only (get-creator-reputation (creator principal))
  (map-get? creator-reputation { creator: creator })
)

(define-read-only (get-project-rating-summary (project-id uint))
  (map-get? project-rating-summary { project-id: project-id })
)

(define-read-only (get-creator-average-rating (creator principal))
  (match (map-get? creator-reputation { creator: creator })
    rep (get average-rating rep)
    u0
  )
)