;; StakeDraw - Decentralized Lottery Pool Smart Contract
;; A fair and transparent lottery system built on Stacks blockchain

;; Constants
(define-constant POOL_MASTER tx-sender)
(define-constant ERR_UNAUTHORIZED_ACCESS (err u100))
(define-constant ERR_DRAW_CLOSED (err u102))
(define-constant ERR_BALANCE_TOO_LOW (err u103))
(define-constant ERR_INVALID_ENTRY_FEE (err u104))
(define-constant ERR_NO_CHAMPIONS (err u105))
(define-constant ERR_NO_ENTRIES_FOUND (err u106))
(define-constant ERR_REFUND_WINDOW_CLOSED (err u107))
(define-constant ERR_DRAW_STILL_ACTIVE (err u108))
(define-constant ERR_CHAMPIONS_ALREADY_DRAWN (err u109))
(define-constant ERR_INVALID_DRAW_DURATION (err u110))
(define-constant ERR_INVALID_REFUND_WINDOW (err u111))
(define-constant ERR_INVALID_CHAMPION_ID (err u112))

;; State Variables
(define-data-var draw-is-live bool false)
(define-data-var entry-fee-amount uint u1000000) ;; 1 STX
(define-data-var total-prize-pool uint u0)
(define-data-var entries-count uint u0)
(define-data-var champions-to-select uint u1)
(define-data-var draw-closing-block uint u0)
(define-data-var refund-deadline-block uint u0)
(define-data-var pool-master-commission uint u5) ;; 5% commission
(define-data-var champion-reward-amount uint u0)
(define-data-var champions-have-been-drawn bool false)

;; Data Maps
(define-map entry-registry {entry-id: uint} {participant: principal})
(define-map participant-entries principal uint)
(define-map champion-registry {champion-id: uint} {wallet: principal, reward-claimed: bool})

;; Private Helper Functions
(define-private (verify-pool-master)
  (is-eq tx-sender POOL_MASTER))

(define-private (ensure-draw-is-active)
  (if (var-get draw-is-live)
    (ok true)
    ERR_DRAW_CLOSED))

(define-private (check-wallet-balance (required-stx uint))
  (if (>= (stx-get-balance tx-sender) required-stx)
    (ok true)
    ERR_BALANCE_TOO_LOW))

(define-private (generate-winning-entry (seed uint) (offset uint))
  (mod (+ seed offset) (var-get entries-count)))

(define-private (send-reward-to-champion (champion-wallet principal) (reward-stx uint))
  (as-contract (stx-transfer? reward-stx tx-sender champion-wallet)))

(define-private (calculate-master-commission (pool-total uint))
  (/ (* pool-total (var-get pool-master-commission)) u100))

;; Public Functions
(define-public (initialize-new-draw (duration-blocks uint) (refund-window-blocks uint) (ticket-cost uint) (champion-count uint) (commission-rate uint))
  (begin
    (asserts! (verify-pool-master) ERR_UNAUTHORIZED_ACCESS)
    (asserts! (> ticket-cost u0) ERR_INVALID_ENTRY_FEE)
    (asserts! (> champion-count u0) ERR_NO_CHAMPIONS)
    (asserts! (<= commission-rate u20) ERR_UNAUTHORIZED_ACCESS) ;; Max 20% commission
    (asserts! (not (var-get draw-is-live)) ERR_UNAUTHORIZED_ACCESS)
    (asserts! (> duration-blocks u0) ERR_INVALID_DRAW_DURATION)
    (asserts! (> refund-window-blocks u0) ERR_INVALID_REFUND_WINDOW)
    (var-set draw-is-live true)
    (var-set entry-fee-amount ticket-cost)
    (var-set total-prize-pool u0)
    (var-set entries-count u0)
    (var-set champions-to-select champion-count)
    (var-set draw-closing-block (+ block-height duration-blocks))
    (var-set refund-deadline-block (+ block-height refund-window-blocks))
    (var-set pool-master-commission commission-rate)
    (var-set champions-have-been-drawn false)
    (ok true)))

(define-public (buy-entry-ticket)
  (let ((ticket-cost (var-get entry-fee-amount)))
    (begin
      (try! (ensure-draw-is-active))
      (try! (check-wallet-balance ticket-cost))
      (try! (stx-transfer? ticket-cost tx-sender (as-contract tx-sender)))
      (var-set total-prize-pool (+ (var-get total-prize-pool) ticket-cost))
      (var-set entries-count (+ (var-get entries-count) u1))
      (map-set entry-registry {entry-id: (var-get entries-count)} {participant: tx-sender})
      (map-set participant-entries tx-sender (+ (default-to u0 (map-get? participant-entries tx-sender)) u1))
      (ok (var-get entries-count)))))

(define-public (request-entry-refund (tickets-to-refund uint))
  (let ((user-tickets (default-to u0 (map-get? participant-entries tx-sender)))
        (refund-total (* tickets-to-refund (var-get entry-fee-amount))))
    (begin
      (try! (ensure-draw-is-active))
      (asserts! (<= block-height (var-get refund-deadline-block)) ERR_REFUND_WINDOW_CLOSED)
      (asserts! (>= user-tickets tickets-to-refund) ERR_NO_ENTRIES_FOUND)
      (var-set total-prize-pool (- (var-get total-prize-pool) refund-total))
      (var-set entries-count (- (var-get entries-count) tickets-to-refund))
      (map-set participant-entries tx-sender (- user-tickets tickets-to-refund))
      (as-contract (stx-transfer? refund-total tx-sender tx-sender)))))

(define-public (finalize-draw)
  (let ((pool-total (var-get total-prize-pool))
        (champion-count (var-get champions-to-select))
        (total-entries (var-get entries-count))
        (master-fee (calculate-master-commission pool-total)))
    (begin
      (asserts! (verify-pool-master) ERR_UNAUTHORIZED_ACCESS)
      (asserts! (>= block-height (var-get draw-closing-block)) ERR_DRAW_STILL_ACTIVE)
      (try! (ensure-draw-is-active))
      (asserts! (> total-entries u0) ERR_NO_CHAMPIONS)
      (var-set draw-is-live false)
      (try! (as-contract (stx-transfer? master-fee tx-sender POOL_MASTER)))
      (let ((remaining-pool (- pool-total master-fee)))
        (var-set champion-reward-amount (/ remaining-pool champion-count)))
      (ok true))))

(define-public (draw-champions (random-seed uint))
  (let ((champion-count (var-get champions-to-select))
        (total-entries (var-get entries-count)))
    (begin
      (asserts! (verify-pool-master) ERR_UNAUTHORIZED_ACCESS)
      (asserts! (not (var-get draw-is-live)) ERR_DRAW_CLOSED)
      (asserts! (not (var-get champions-have-been-drawn)) ERR_CHAMPIONS_ALREADY_DRAWN)
      (asserts! (> total-entries u0) ERR_NO_CHAMPIONS)
      (var-set champions-have-been-drawn true)
      (let ((drawn-champions (fold process-champion-selection
                                    (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)
                                    {seed: random-seed, champion-index: u0, remaining-slots: champion-count})))
        (ok (get champion-index drawn-champions))))))

(define-private (process-champion-selection (iteration uint) (context {seed: uint, champion-index: uint, remaining-slots: uint}))
  (if (> (get remaining-slots context) u0)
    (let ((winning-entry-id (generate-winning-entry (get seed context) iteration))
          (champion-wallet (get participant (unwrap-panic (map-get? entry-registry {entry-id: (+ winning-entry-id u1)})))))
      (begin
        (map-set champion-registry {champion-id: (get champion-index context)} {wallet: champion-wallet, reward-claimed: false})
        {seed: (+ (get seed context) u1),
         champion-index: (+ (get champion-index context) u1),
         remaining-slots: (- (get remaining-slots context) u1)}))
    context))

(define-public (claim-champion-reward (champion-id uint))
  (let ((champion-data (unwrap! (map-get? champion-registry {champion-id: champion-id}) ERR_INVALID_CHAMPION_ID))
        (champion-wallet (get wallet champion-data))
        (already-claimed (get reward-claimed champion-data)))
    (begin
      (asserts! (is-eq tx-sender champion-wallet) ERR_UNAUTHORIZED_ACCESS)
      (asserts! (not already-claimed) ERR_UNAUTHORIZED_ACCESS)
      (try! (send-reward-to-champion champion-wallet (var-get champion-reward-amount)))
      (asserts! (< champion-id (var-get champions-to-select)) ERR_INVALID_CHAMPION_ID)
      (map-set champion-registry {champion-id: champion-id} {wallet: champion-wallet, reward-claimed: true})
      (ok true))))

(define-public (emergency-pause-draw)
  (begin
    (asserts! (verify-pool-master) ERR_UNAUTHORIZED_ACCESS)
    (asserts! (var-get draw-is-live) ERR_DRAW_CLOSED)
    (var-set draw-is-live false)
    (ok true)))

;; Read-Only Functions
(define-read-only (get-entry-fee)
  (ok (var-get entry-fee-amount)))

(define-read-only (get-prize-pool-total)
  (ok (var-get total-prize-pool)))

(define-read-only (get-participant-entry-count (participant-wallet principal))
  (ok (default-to u0 (map-get? participant-entries participant-wallet))))

(define-read-only (get-total-entries)
  (ok (var-get entries-count)))

(define-read-only (is-draw-active)
  (ok (var-get draw-is-live)))

(define-read-only (get-draw-end-block)
  (ok (var-get draw-closing-block)))

(define-read-only (get-refund-deadline-block)
  (ok (var-get refund-deadline-block)))

(define-read-only (get-commission-rate)
  (ok (var-get pool-master-commission)))

(define-read-only (get-champion-details (champion-id uint))
  (ok (map-get? champion-registry {champion-id: champion-id})))

(define-read-only (are-champions-drawn)
  (ok (var-get champions-have-been-drawn)))

(define-read-only (get-champion-reward-amount)
  (ok (var-get champion-reward-amount)))