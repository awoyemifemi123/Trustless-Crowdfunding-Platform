(define-constant ERR_INVALID_AMOUNT (err u500))
(define-constant ERR_NO_CONTRIBUTION (err u501))
(define-constant ERR_ALREADY_CLAIMED (err u502))

(define-constant TIER_BRONZE u1)
(define-constant TIER_SILVER u2)
(define-constant TIER_GOLD u3)
(define-constant TIER_DIAMOND u4)

(define-constant POINTS_PER_STX u10)
(define-constant EARLY_BIRD_BONUS u50)
(define-constant MULTI_PROJECT_BONUS u100)

(define-map contributor-profile
  { contributor: principal }
  {
    total-points: uint,
    projects-backed: uint,
    total-contributed: uint,
    current-tier: uint,
    early-bird-count: uint
  }
)

(define-map contribution-rewards
  { project-id: uint, contributor: principal }
  {
    points-earned: uint,
    was-early-bird: bool,
    claimed: bool
  }
)

(define-map project-contribution-window
  { project-id: uint }
  { creation-block: uint, early-window-end: uint }
)

(define-public (initialize-project-window (project-id uint))
  (begin
    (map-set project-contribution-window
      { project-id: project-id }
      { 
        creation-block: stacks-block-height,
        early-window-end: (+ stacks-block-height u144)
      }
    )
    (ok true)
  )
)

(define-public (record-contribution (project-id uint) (amount uint))
  (let
    (
      (window-data (map-get? project-contribution-window { project-id: project-id }))
      (is-early (match window-data
        data (<= stacks-block-height (get early-window-end data))
        false
      ))
      (base-points (/ (* amount POINTS_PER_STX) u1000000))
      (bonus-points (if is-early EARLY_BIRD_BONUS u0))
      (total-points (+ base-points bonus-points))
      (current-profile (default-to
        { total-points: u0, projects-backed: u0, total-contributed: u0, current-tier: u0, early-bird-count: u0 }
        (map-get? contributor-profile { contributor: tx-sender })
      ))
      (new-projects-backed (+ (get projects-backed current-profile) u1))
      (multi-project-bonus (if (>= new-projects-backed u5) MULTI_PROJECT_BONUS u0))
      (final-points (+ total-points multi-project-bonus))
      (new-total-points (+ (get total-points current-profile) final-points))
      (new-tier (calculate-tier new-total-points))
    )
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    (map-set contribution-rewards
      { project-id: project-id, contributor: tx-sender }
      {
        points-earned: final-points,
        was-early-bird: is-early,
        claimed: false
      }
    )
    
    (map-set contributor-profile
      { contributor: tx-sender }
      {
        total-points: new-total-points,
        projects-backed: new-projects-backed,
        total-contributed: (+ (get total-contributed current-profile) amount),
        current-tier: new-tier,
        early-bird-count: (if is-early (+ (get early-bird-count current-profile) u1) (get early-bird-count current-profile))
      }
    )
    (ok final-points)
  )
)

(define-private (calculate-tier (points uint))
  (if (>= points u10000)
    TIER_DIAMOND
    (if (>= points u5000)
      TIER_GOLD
      (if (>= points u1000)
        TIER_SILVER
        TIER_BRONZE
      )
    )
  )
)

(define-read-only (get-contributor-profile (contributor principal))
  (map-get? contributor-profile { contributor: contributor })
)

(define-read-only (get-contribution-reward (project-id uint) (contributor principal))
  (map-get? contribution-rewards { project-id: project-id, contributor: contributor })
)

(define-read-only (get-tier-name (tier uint))
  (if (is-eq tier TIER_DIAMOND)
    "Diamond"
    (if (is-eq tier TIER_GOLD)
      "Gold"
      (if (is-eq tier TIER_SILVER)
        "Silver"
        "Bronze"
      )
    )
  )
)

(define-read-only (get-voting-weight-multiplier (contributor principal))
  (match (map-get? contributor-profile { contributor: contributor })
    profile
    (let ((tier (get current-tier profile)))
      (if (is-eq tier TIER_DIAMOND) u4
        (if (is-eq tier TIER_GOLD) u3
          (if (is-eq tier TIER_SILVER) u2 u1)
        )
      )
    )
    u1
  )
)
