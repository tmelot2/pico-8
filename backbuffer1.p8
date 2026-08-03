pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

local SCREEN = 0x6000
local BACK = 0x8000
local SIZE = 0x2000 -- 8k


sw = 128
sh = 128

px = sw/2
py = sh/2
t=0

-- main
function _init()
	cls(0)
	memset(BACK,0,SIZE)
end

function _update60()
	input()
	t+=1
end

function update_back_buffer()
	ROW_BYTES=64
	DRIP_CLEAR_RATE=0.4 -- chance drip will clear
	DRIP_DARKEN_RATE=0.25 -- chance drip will darken

	for i=1,160 do
		bx=rnd()*ROW_BYTES -- 0..63 (2 pixels per byte)
		by=rnd()*sh        -- 0..127
		use_hi=rnd() < 0.5 -- pick hi or lo nibble

		addr = BACK + by * ROW_BYTES + bx
		c = peek(addr)
		c_above = peek(addr - ROW_BYTES)

		-- Clear pixel
		if rnd() < 0.1 then
			poke(addr, 0)
		-- Drip, take color from above (or clear)
		else
			drip_len = rnd()*8
			if rnd() < DRIP_CLEAR_RATE then c_above=0 end -- clear drip
			if rnd() < DRIP_DARKEN_RATE and c_above>1 then c_above=1 end -- darken drip

			-- High nibble (left pixel)
			if rnd() < 0.5 then
				for i=0,drip_len do
					poke(addr + (ROW_BYTES*i), (c_above & 0xF0) | (c & 0x0F))
				end
			-- Low nibble (right pixel)
			else
				poke(addr, (c_above & 0x0F) | (c & 0xF0))
				for i=0,drip_len do
					poke(addr + (ROW_BYTES*i), (c_above & 0x0F) | (c & 0xF0))
				end
			end
		end
	end
end

function _draw()
	cls(0)

	update_back_buffer()

	-- Render back buffer
	memcpy(SCREEN,BACK,SIZE)

	-- Render front to screen
	-- spr(1,px,py)
	spr(2,px,py)
	spr(3,px+8,py)
end


-- input
function input()
	if btn(0) then px-=1 end -- l
	if btn(1) then px+=1 end -- r
	if btn(2) then py-=1 end -- u
	if btn(3) then py+=1 end -- d
	if btnp(4) then  -- x
		sn=4
		poke(0x5F55, BACK>>8)
		-- sspr(sn*8, 0, 8, 8, px, py, 16, 16)
		if rnd() < 1.4 then
			cx=px+8
			cy=py+4
			rc=rnd()*7+1
			for i=0,rc do
			rx=rnd(50)-25
			ry=rnd(50)-25
			r=rnd()*5
			line(cx, cy, px+rx, py+ry, 8)
			circfill(px+rx, py+ry, r, 8)
			circ(px+rx, py+ry, r+1, 2)
			circ(px+rx, py+ry, r+2, 1)
			circ(px+rx, py+ry, r+3, 0)
			end
		end
		poke(0x5F55, SCREEN>>8)
	end
end




__gfx__
0000000028511582001555555555510000000000b003000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000086655668056666666666665080000000010000b000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070056655665566266666615c1650100800800b0bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000155995515621261516b5556501888880b00bb10300000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000155a9551565256efe6555865188ee888001b300100000000000000000000000000000000000000000000000000000000000000000000000000000000
007007005665566556656666661a516501888e8000b1030000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000866556680566665555666650001800080bb000b000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000028511582005555000055550000000000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000
