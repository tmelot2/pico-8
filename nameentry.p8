pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function log(s)
	printh(s, "log.txt")
end

function _init()
end

function _update60()
	-- left
	if btnp(0) then
		hse.curSlot = max(hse.curSlot-1, 1)
	-- right
	elseif btnp(1) then
		hse.curSlot = min(hse.curSlot+1, hse.slots)
	-- up
	elseif btnp(2) then
		hse.changeLetter(0)
	-- down
	elseif btnp(3) then
		hse.changeLetter(1)
	elseif btnp(4) or btnp(5) then
		hse.finish()
	end
end

function _draw()
	cls(0)
	hse.draw()
end

-- dir=0 prev, 1 next
function hseChangeLetter(dir)
	curLetter=hse.curName[hse.curSlot]

	-- get index of current letter
	-- todo: update to just store index instead of letter, lookup name on submit
	index=0
	for i=1,#hse.letters do
		if hse.letters[i]==curLetter then
			index=i
			break
		end
	end
	if index==0 then
		return
	end

	-- update letter
	-- prev
	if dir==0 then
		newLetterIndex=index-1
		-- wrap around for dat user friendliness
		if newLetterIndex<1 then
			newLetterIndex=#hse.letters
		end
	-- next
	elseif dir==1 then
		newLetterIndex=index+1
		-- wrap around for dat user friendliness
		if newLetterIndex>#hse.letters then
			newLetterIndex=1
		end
	end
	newLetter=hse.letters[newLetterIndex]
	hse.curName[hse.curSlot]=newLetter
end

function hseDraw()
	-- rectfill(hse.x, hse.y, hse.w, hse.h, 7)
	for i=1,hse.slots do
		-- rectfill(hse.x,hse.y,hse.x + 6,hse.y + 10,9)

		w=8

		-- Slot selection border
		-- todo: if i want animation for the box or buttons this wont work
		-- instead ill read the current slot & interpolate the box position or something
		-- maybe i could just make a little bump animation & that's good enough?
		if i==hse.curSlot then
			x=((i-1)*w)
			rect(
				hse.x + x - w/4,
				hse.y - 2,
				hse.x + x + w/2,
				hse.y + 6,
				6
			)

			-- Buttons
			-- up
			x=((i-1)*w)
			print(
				'⬆️',
				hse.x + x - w/4,
				hse.y - 10
			)
			-- down
			print(
				'⬇️',
				hse.x + x - w/4,
				hse.y + 10
			)
		end

		-- Print slot
		print(
			hse.curName[i],
			hse.x + ((i-1)*w),
			hse.y,
			7
		)
	end
end

function hseFinish()
	name=''
	for i=1,#hse.curName do
		name=name..hse.curName[i]
	end
	log('Submitted name ['..name..']')
end

-- high score entry
hse={
	x=15,
	y=15,
	w=60,
	h=30,
	letters={' ','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9'},
	-- letters={' ','a','b','c'},
	slots=3,
	curSlot=1,
	curName={'a','b','c'},
	draw=hseDraw,
	changeLetter=hseChangeLetter,
	finish=hseFinish
}


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
