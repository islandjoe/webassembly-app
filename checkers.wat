(module
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
			(call $withCrown (get_local $x) (get_local $y))
		)
		(call $notify_piece_crowned (get_local $x) (get_local $y))
	)
	(func $distance (param $x i32) (param $y i32) (result i32)
		(i32.sub (get_local $x) (get_local $y))
	)

)
