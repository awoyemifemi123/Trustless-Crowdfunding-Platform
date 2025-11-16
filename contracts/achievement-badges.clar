(define-constant ERR_NOT_AUTHORIZED (err u600))
(define-constant ERR_ALREADY_MINTED (err u601))
(define-constant ERR_TOKEN_NOT_FOUND (err u602))
(define-constant ERR_NON_TRANSFERABLE (err u603))
(define-constant ERR_INVALID_BADGE_TYPE (err u604))

(define-constant BADGE_FIRST_CONTRIBUTION u1)
(define-constant BADGE_SERIAL_BACKER u2)
(define-constant BADGE_WHALE_SUPPORTER u3)
(define-constant BADGE_PROJECT_CREATOR u4)
(define-constant BADGE_SUCCESSFUL_CREATOR u5)

(define-data-var token-id-nonce uint u0)

(define-non-fungible-token achievement-badge uint)

(define-map badge-metadata
  { token-id: uint }
  {
    badge-type: uint,
    owner: principal,
    earned-at: uint,
    context-data: uint
  }
)

(define-map user-badges
  { owner: principal, badge-type: uint }
  { token-id: uint, earned: bool }
)

(define-public (mint-achievement (recipient principal) (badge-type uint) (context-data uint))
  (let
    (
      (new-token-id (+ (var-get token-id-nonce) u1))
      (existing-badge (map-get? user-badges { owner: recipient, badge-type: badge-type }))
    )
    (asserts! (<= badge-type BADGE_SUCCESSFUL_CREATOR) ERR_INVALID_BADGE_TYPE)
    (asserts! (is-none existing-badge) ERR_ALREADY_MINTED)
    
    (try! (nft-mint? achievement-badge new-token-id recipient))
    
    (map-set badge-metadata
      { token-id: new-token-id }
      {
        badge-type: badge-type,
        owner: recipient,
        earned-at: stacks-block-height,
        context-data: context-data
      }
    )
    
    (map-set user-badges
      { owner: recipient, badge-type: badge-type }
      { token-id: new-token-id, earned: true }
    )
    
    (var-set token-id-nonce new-token-id)
    (ok new-token-id)
  )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  ERR_NON_TRANSFERABLE
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? achievement-badge token-id))
)

(define-read-only (get-badge-metadata (token-id uint))
  (map-get? badge-metadata { token-id: token-id })
)

(define-read-only (get-user-badge (owner principal) (badge-type uint))
  (map-get? user-badges { owner: owner, badge-type: badge-type })
)

(define-read-only (has-badge (owner principal) (badge-type uint))
  (is-some (map-get? user-badges { owner: owner, badge-type: badge-type }))
)
