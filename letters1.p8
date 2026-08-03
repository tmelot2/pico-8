pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

screenwidth = 127
screenheight = 127

-- main
function _init()
	scale=2
end

function _update60()	
	input()
end

function _draw()
	cls(1)

	x=5
	y=40

	rectfill(5,5,60,25,2)
	comictext('comic text', 8, 12)
	scale_text2('scaled', 8, 30, 8, scale)

	-- spr(1,0,1,1,1)
end

function comictext(s,x,y)
	w=4
	rectfill(x+2,y-2, x+(#s*w)+4,y+6, 1)
	for i=1,#s do
		--u
		print(s[i], x+i*w, y-1, 15)
		--d
		print(s[i], x+i*w, y+1, 15)
		--l
		print(s[i], x+i*w-1, y, 15)
		--r
		print(s[i], x+i*w+1, y, 15)

		--ul
		print(s[i], x+i*w-1, y-1, 15)
		--ur
		print(s[i], x+i*w+1, y-1, 15)
		--dl
		print(s[i], x+i*w-1, y+1, 15)
		--dr
		print(s[i], x+i*w+1, y+1, 15)
		
		--c
		print(s[i], x+i*w, y, 0)
	end
end



-- https://www.lexaloffle.com/bbs/?pid=114184#p
function scale_text(str,x,y,c,scale)
	-- P8 mem funcs are (dst, src, len)
	-- 1 hex = 4 bits = 1 nibble
	-- 2 hex = 8 bits = 1 byte

	-- Copy 512b from Gfx start to User data start
    memcpy(0x4300,0x0,0x0200)
    -- Zero out 512b from Gfx start
    memset(0x0,0,0x0200)
    -- Remap screen addr to use spritesheet (0x0000) as screen memory
    poke(0x5f55,0x00)
    -- Print string at (0,0) with color 7
    print(str,0,0,7)
    -- Remap screen addr back to default (0x6000)
    poke(0x5f55,0x60)

    -- Setup width & height for whole string
    local w,h = #str*4,5
    -- Swap color 7 with input color
    pal(7,c)
    -- Set color 0 as transparency color
    palt(0,true)
    -- Stretch spritesheet rect from (0,0,w,h) to screen
    sspr(0,0,w,h,x,y,w*scale,h*scale)
    -- Reset palette
    pal()

    -- Copy 512b from User data start to Gfx start
    memcpy(0x0,0x4300,0x0200)
end

-- Mine, same as above but doesn't copy memory around
-- Uses high memory as buffer
function scale_text2(str,x,y,c,scale)
	BASE=0xE0
	GFX=0x00
	SCREEN=0x60

	-- Print text into buffer
	-- 1. remap screen to user, print to screen, put screen back
	poke(0x5F55, BASE)
	print("test",0,0,c)
	poke(0x5F55, SCREEN)

	-- 2. remap gfx to user, sspr to screen, put gfx back
	poke(0x5F54, BASE)
	w=#str*4
	h=5
	sspr(0,0,w,h,x,y,w*scale,h*scale)
	poke(0x5F54, GFX)
end



-- input
function input()
	if (btn(0)) scale-=0.5
	if (btn(1)) scale+=0.5
	if (btn(2)) scale-=0.02
	if (btn(3)) scale+=0.02
end



__gfx__
00000000999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000009900000888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700099999008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000099909908000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000099008000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000090008000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008888080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
