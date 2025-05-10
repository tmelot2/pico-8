pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

textBam={
	t=0,
	curIndex=1,
	text={
		{str='you',    d=15, scale=2},
		{str='got',    d=15, scale=2},
		{str=' a',     d=15, scale=3},
		{str='high',   d=15, scale=3},
		{str='score!', d=15, scale=5},
	}
}

function textBamInit()
	-- textBam.t=textBam.text[1].d
end

function textBamUpdate()
	textBam.t+=1
	if textBam.t == textBam.text[textBam.curIndex].d then
		textBam.curIndex+=1
		textBam.t=0
	end
end

function textBamDraw()
	local t=textBam.t

	if t == 1 or t == 4 then
		cls(6)
	end
	curText=textBam.text[textBam.curIndex]
	scale_text(curText.str, 5, 34, 7, curText.scale)
	print(textBam.t, 5, 110, 7)
	end

function _init()
	textBamInit()
end

function _update60()
	textBamUpdate()
end

function _draw()
	cls(0)
	textBamDraw()
end

function scale_text(str,x,y,c,scale)
	-- https://www.lexaloffle.com/bbs/?pid=114184#p
    memcpy(0x4300,0x0,0x0200)
    memset(0x0,0,0x0200)
    poke(0x5f55,0x00)
    print(str,0,0,7)
    poke(0x5f55,0x60)

    local w,h = #str*4,5
    pal(7,c)
    palt(0,true)
    sspr(0,0,w,h,x,y,w*scale,h*scale)
    pal()

    memcpy(0x0,0x4300,0x0200)
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
