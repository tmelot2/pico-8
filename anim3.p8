pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

screenwidth = 128
screenheight = 128

dbg={}

cx = screenwidth/2
cy = screenheight/2+4
t = 0
rb = {8,9,10,11,12,13,15,15,2}
ci=0

-- main
function _init()
	cls()
end

function _update60()	
	input()

	t+=1
end

function _draw()
	-- cls()

	-- next color
	if t%4==0 then ci += 1 end
	if ci > #rb-1 then ci=0 end
	
	-- 2 pixels per byte
	-- int = 1 byte
	-- memory based screen wipe
	-- 0brrrrllll
	local c=0
	local count=0
	sh=3
	for i=0,0x1fff,4 do
		e=flr(rnd(20))
		a,b,c,d=peek(0x6000+i,4)
		if e==0 then
			poke(0x6000+i, a >>< sh, b >>< sh, c >>< sh, d >>< sh)
		else
			poke(0x6000+i, a & 0b11110000, b & 0b11110000, c & 0b11110000, d & 0b11110000)
		end
		count+=1
	end
	addDebug(count)

	-- circle
	for i=0,7 do
		-- time, period, max, min, offset
		size = oscillate(t, 120, 5, 1, i*8)
		circ(cx+16*cos(i/8+(0.005*t)), cy+16*sin(i/8+(0.005*t)), size, rb[ci+1])
	end

	-- debug
	drawDebug()
end

function drawDebug()
	local i=0
	for i,d in ipairs(dbg) do
		rect(0,7*i, 20, 7*i, 0)
		print(i..' '..d, 1, i*7, 7)
	end
	print('fps '..stat(7), 1, i*7, 7)
	dbg={}
end

function addDebug(d)
	dbg[#dbg+1] = d
end


-- tick, period, max, min, offset
function oscillate(t, p, max, min, o) 
	return (min+max) + (max-min) * sin((t+o)%p/p)
end

-- input
function input()
	amt=1.5
	if btn(0) then cx-=amt end
	if btn(1) then cx+=amt end
	if btn(2) then cy-=amt end
	if btn(3) then cy+=amt end

	if cx<0 then cx=0 end
	if cx>screenwidth then cx=screenwidth end
	if cy<0 then cy=0 end
	if cy>screenheight then cy=screenheight end
end

__gfx__
00000000099999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000099999900999990009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000aa99aa0099aaa0009aa9900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000099000099999000900a990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000099000099aaa0009000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000009900009999900090099a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000990000aaaaa0009999a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa000000000000aaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
