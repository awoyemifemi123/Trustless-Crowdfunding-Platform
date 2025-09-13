(define-constant ERR_PROJECT_NOT_FOUND (err u400))
(define-constant ERR_INVALID_TIMEFRAME (err u401))

(define-map project-analytics
  { project-id: uint }
  {
    total-contributors: uint,
    avg-contribution: uint,
    funding-velocity: uint,
    peak-day-amount: uint,
    success-score: uint
  }
)

(define-map daily-contributions
  { project-id: uint, day: uint }
  { amount: uint, contributors: uint }
)

(define-map project-totals
  { project-id: uint }
  { total-amount: uint, total-days: uint }
)

(define-public (track-contribution (project-id uint) (amount uint))
  (let
    (
      (current-day (/ stacks-block-height u144))
      (current-analytics (default-to
        { total-contributors: u0, avg-contribution: u0, funding-velocity: u0, peak-day-amount: u0, success-score: u0 }
        (map-get? project-analytics { project-id: project-id })
      ))
      (daily-data (default-to
        { amount: u0, contributors: u0 }
        (map-get? daily-contributions { project-id: project-id, day: current-day })
      ))
      (totals-data (default-to
        { total-amount: u0, total-days: u0 }
        (map-get? project-totals { project-id: project-id })
      ))
      (new-contributors (+ (get total-contributors current-analytics) u1))
      (new-avg (if (is-eq new-contributors u0) amount (/ (+ (* (get avg-contribution current-analytics) (get total-contributors current-analytics)) amount) new-contributors)))
      (new-daily-amount (+ (get amount daily-data) amount))
      (new-velocity (if (is-eq (get total-days totals-data) u0) amount (/ (+ (get total-amount totals-data) amount) (+ (get total-days totals-data) u1))))
      (new-peak (if (> new-daily-amount (get peak-day-amount current-analytics)) new-daily-amount (get peak-day-amount current-analytics)))
      (new-score (+ 
        (if (> new-velocity u100) u30 (/ (* new-velocity u30) u100))
        (if (> new-avg u1000) u40 (/ (* new-avg u40) u1000))
        u30
      ))
    )
    (map-set daily-contributions
      { project-id: project-id, day: current-day }
      {
        amount: new-daily-amount,
        contributors: (+ (get contributors daily-data) u1)
      }
    )
    (map-set project-totals
      { project-id: project-id }
      {
        total-amount: (+ (get total-amount totals-data) amount),
        total-days: (if (is-eq (get amount daily-data) u0) (+ (get total-days totals-data) u1) (get total-days totals-data))
      }
    )
    (map-set project-analytics
      { project-id: project-id }
      {
        total-contributors: new-contributors,
        avg-contribution: new-avg,
        funding-velocity: new-velocity,
        peak-day-amount: new-peak,
        success-score: new-score
      }
    )
    (ok true)
  )
)

(define-read-only (get-project-analytics (project-id uint))
  (map-get? project-analytics { project-id: project-id })
)

(define-read-only (get-daily-stats (project-id uint) (day uint))
  (map-get? daily-contributions { project-id: project-id, day: day })
)

(define-read-only (get-project-velocity (project-id uint))
  (match (map-get? project-analytics { project-id: project-id })
    analytics (get funding-velocity analytics)
    u0
  )
)

(define-read-only (get-success-score (project-id uint))
  (match (map-get? project-analytics { project-id: project-id })
    analytics (get success-score analytics)
    u0
  )
)

(define-read-only (get-peak-day-performance (project-id uint))
  (match (map-get? project-analytics { project-id: project-id })
    analytics (get peak-day-amount analytics)
    u0
  )
)
