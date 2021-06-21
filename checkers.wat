(module
	(import "events" "piecemoved"
		(func $notify_piece_moved (param $fromX i32) (param $fromY i32)
			(param $toX i32) (param $toY i32) (param $p i32)
		)
	)
	(import "events" "piececrowned"
		(func $notify_piece_crowned (param $pieceX i32) (param $pieceY i32))
	)
	(memory $mem 1)
	(global $currentTurn (mut i32) (i32.const 0))
	(global $WHITE i32 (i32.const 2))
	(global $BLACK i32 (i32.const 1))
	(global $CROWN i32 (i32.const 4))

	(func $indexForPosition (param $x i32) (param $y i32) (result i32)
		(i32.add
			(i32.mul
				(i32.const 8)
				(get_local $y)
			)
			(get_local $x)
		)
	)

	;; Offset = (x + y * 8) * 4
	(func $offsetForPosition (param $x i32) (param $y i32) (result i32)
		(i32.mul
			(call $indexForPosition (get_local $x) (get_local $y))
			(i32.const 4)
		)
	)

	;; Has the piece been crowned?
	(func $isCrowned (param $piece i32) (result i32)
		(i32.eq
			(i32.and (get_local $piece) (get_global $CROWN))
			(get_global $CROWN)
		)
	)

	;; Is the piece white?
	(func $isWhite (param $piece i32) (result i32)
		(i32.eq
			(i32.and (get_local $piece) (get_global $WHITE))
			(get_global $WHITE)
		)
	)

	;; Is the piece black?
	(func $isBlack (param $piece i32) (result i32)
		(i32.eq
			(i32.and (get_local $piece) (get_global $BLACK))
			(get_global $BLACK)
		)
	)

	;; Add crown to a piece
	(func $withCrown (param $piece i32) (result i32)
		(i32.or (get_local $piece) (get_global $CROWN))
	)

	;; Remove crown from a piece
	(func $withNoCrown (param $piece i32) (result i32)
		(i32.and (get_local $piece) (i32.const 3))
	)

	;; Set piece on board
	(func $setPiece (param $x i32) (param $y i32) (param $piece i32)
		(i32.store
			(call $offsetForPosition
				(get_local $x)
				(get_local $y)
			)
			(get_local $piece)
		)
	)

	;; Get piece from board
	(func $getPiece (param $x i32) (param $y i32) (result i32)
		(if (result i32)
			(block (result i32)
				(i32.and
					(call $inRange
						(i32.const 0)
						(i32.const 7)
						(get_local $x))
					(call $inRange
						(i32.const 0)
						(i32.const 7)
						(get_local $y))
				)
			)
		(then
			(i32.load
				(call $offsetForPosition
					(get_local $x)
					(get_local $y)))
			)
		(else
			(unreachable))
		)
	)

	;; Are values within range (inclusive high and low)
	(func $inRange (param $low i32) (param $high i32) (param $value i32) (result i32)
		(i32.and
			(i32.ge_s (get_local $value) (get_local $low))
			(i32.le_s (get_local $value) (get_local $high))
		)
	)

	;; Is space occupied?
	(func $isOccupied (param $x i32) (param $y i32) (result i32)
		(i32.gt_s
			(call $getPiece (get_local $x) (get_local $y))
			(i32.const 0)
		)
	)


	;; Get current turn (white or black?)
	(func $getTurn (result i32)
		(get_global $currentTurn)
	)

	;; Switch turn to the other player at the end of turn
	(func $toggleTurn
		(if (i32.eq (call $getTurn) (i32.const 1))
			(then (call $setTurn (i32.const 2)))
			(else (call $setTurn (i32.const 1)))
		)
	)

	;; Set turn
	(func $setTurn (param $piece i32)
		(set_global $currentTurn (get_local $piece))
	)

	;; Whose turn is it?
	(func $whoseTurn (param $player i32) (result i32)
		(i32.gt_s
			(i32.and (get_local $player) (call $getTurn))
			(i32.const 0)
		)
	)

	;; Should it get crowned?
	;; Black pieces are crowned in row 0, white in row 7
	(func $shouldCrown (param $pieceY i32) (param $piece i32) (result i32)
		(i32.or
			(i32.and
				(i32.eq
					(get_local $pieceY)
					(i32.const 0)
				)
				(call $isBlack (get_local $piece))
			)
			(i32.and
				(i32.eq
					(get_local $pieceY)
					(i32.const 7)
				)
				(call $isWhite (get_local $piece))
			)
		)
	)

	;; Convert a piece into a crowned piece then invoke host notifier
	(func $crownPiece (param $x i32) (param $y i32)
		(local $piece i32)
		(set_local $piece (call $getPiece (get_local $x) (get_local $y)))

		(call $setPiece (get_local $x) (get_local $y)
			(call $withCrown (get_local $piece))
		)
		(call $notify_piece_crowned (get_local $x) (get_local $y))
	)
	(func $distance (param $x i32) (param $y i32) (result i32)
		(i32.sub (get_local $x) (get_local $y))
	)

	;; Is move valid?
	(func $isValidMove  (param $fromX i32) (param $fromY i32)
						(param $toX i32) (param $toY i32) (result i32)
		(local $player i32)
		(local $target i32)

		(set_local $player (call $getPiece (get_local $fromX) (get_local $fromY)))
		(set_local $target (call $getPiece (get_local $toX) (get_local $toY)))

		(if (result i32)
			(block (result i32)
				(i32.and
					(call $validJumpDistance (get_local $fromY) (get_local $toY))
					(i32.and
						(call $whoseTurn (get_local $player))
						;; Target must be unoccupied
						(i32.eq (get_local $target) (i32.const 0))
					)
				)
			)
			(then (i32.const 1))
			(else (i32.const 0))
		)
	)

	;; Ensure travel is only 1 or 2 squares
	(func $validJumpDistance (param $from i32) (param $to i32) (result i32)
		(local $d i32)
		(set_local $d
			(if (result i32)
				(i32.gt_s (get_local $to) (get_local $from))
				(then (call $distance (get_local $to) (get_local $from)))
				(else (call $distance (get_local $from) (get_local $to)))
			)
		)
		(i32.le_u
			(get_local $d)
			(i32.const 2)
		)
	)

	;; Exported $move function to be called by the host
	(func $move (param $fromX i32) (param $fromY i32)
				(param $toX i32) (param $toY i32) (result i32)
		(if (result i32)
			(block (result i32)
				(call $isValidMove (get_local $fromX) (get_local $fromY)
									(get_local $toX) (get_local $toY))
			)
			(then
				(call $do_move (get_local $fromX) (get_local $fromY)
								 (get_local $toX) (get_local $toY))
			)
			(else (i32.const 0))
		)
	)

	;; Internal move function, performs actual move post-validation of target
	;; Not handled:
	;; - removing opponent piece during a jump
	;; - detect win condition
	(func $do_move (param $fromX i32) (param $fromY i32)
				   (param $toX i32) (param $toY i32) (result i32)
		(local $curPiece i32)
		(set_local $curPiece (call $getPiece (get_local $fromX) (get_local $fromY)))

		(call $toggleTurn)
		(call $setPiece (get_local $toX) (get_local $toY) (get_local $curPiece))
		(call $setPiece (get_local $fromX) (get_local $fromY (i32.const 0)))
		(if (call $shouldCrown (get_local $toY) (get_local $curPiece))
			(then (call $crownPiece (get_local $toX) (get_local $toY)))
		)
		(call $notify_piece_moved (get_local $fromX) (get_local $fromY)
								(get_local $toX) (get_local $toY) (get_local $curPiece)
		)
		(i32.const 1) ;; 1 means valid move
	)

	;; Manually place each piece on the board to initialize the game
    (func $initBoard
        ;; Place the white pieces at the top of the board
        (call $setPiece (i32.const 1) (i32.const 0) (i32.const 2))
        (call $setPiece (i32.const 3) (i32.const 0) (i32.const 2))
        (call $setPiece (i32.const 5) (i32.const 0) (i32.const 2))
        (call $setPiece (i32.const 7) (i32.const 0) (i32.const 2))

        (call $setPiece (i32.const 0) (i32.const 1) (i32.const 2))
        (call $setPiece (i32.const 2) (i32.const 1) (i32.const 2))
        (call $setPiece (i32.const 4) (i32.const 1) (i32.const 2))
        (call $setPiece (i32.const 6) (i32.const 1) (i32.const 2))

        (call $setPiece (i32.const 1) (i32.const 2) (i32.const 2))
        (call $setPiece (i32.const 3) (i32.const 2) (i32.const 2))
        (call $setPiece (i32.const 5) (i32.const 2) (i32.const 2))
        (call $setPiece (i32.const 7) (i32.const 2) (i32.const 2))

        ;; Place the black pieces at the bottom of the board
        (call $setPiece (i32.const 0) (i32.const 7) (i32.const 1))
        (call $setPiece (i32.const 2) (i32.const 7) (i32.const 1))
        (call $setPiece (i32.const 4) (i32.const 7) (i32.const 1))
        (call $setPiece (i32.const 6) (i32.const 7) (i32.const 1))

        (call $setPiece (i32.const 1) (i32.const 6) (i32.const 1))
        (call $setPiece (i32.const 3) (i32.const 6) (i32.const 1))
        (call $setPiece (i32.const 5) (i32.const 6) (i32.const 1))
        (call $setPiece (i32.const 7) (i32.const 6) (i32.const 1))

        (call $setPiece (i32.const 0) (i32.const 5) (i32.const 1))
        (call $setPiece (i32.const 2) (i32.const 5) (i32.const 1))
        (call $setPiece (i32.const 4) (i32.const 5) (i32.const 1))
        (call $setPiece (i32.const 6) (i32.const 5) (i32.const 1))

        (call $setTurn (i32.const 1))  ;; Black goes first
    )

    (export "getPiece" (func $getPiece))
    (export "isOccupied" (func $isOccupied))
    (export "initBoard" (func $initBoard))
    (export "getTurn" (func $getTurn))
    (export "move" (func $move))
    (export "memory" (memory $mem))
    (export "offsetForPosition" (func $offsetForPosition))
    (export "isCrowned" (func $isCrowned))
    (export "isWhite" (func $isWhite))
    (export "isBlack" (func $isBlack))
    (export "withCrown" (func $withCrown))
    (export "withNoCrown" (func $withNoCrown))


)
