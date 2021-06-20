(module
	(memory $mem 1)
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

)
