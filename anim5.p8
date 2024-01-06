pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- main

dbg={}

function _init()
	t=0
	started = false
end

dur=100
start=13
finish=110
col=8

function _update60()
	if started then
		if t<dur then 
			t+=1 
		else 
			started=false 
		end
	end

	-- lr adjust duration
	if btn(0) then dur-=1 end
	if btn(1) then dur+=1 end

	if btnp(4) then
		t=0
		started=true
	end

	if started then col=8 else col=11 end

	adddebug('duration '..dur)
end

function _draw()
	cls()
	y=18

	-- legend
	rectfill(78,6,118,11,1)
	rectfill(79,7,120,13,1)
	rect(77,5,119,12,5)
	-- ease in red
	spr(17,75,7)
	circ(85,9,1,8)
	-- ease out orange
	spr(18,88,7)
	circ(98,9,1,9)
	-- ease in-out green
	spr(17,100,7)
	spr(18,105,7)
	circ(115,9,1,11)

	-- vertical guides
	for i=1,63 do
		if i%2==0 then
			pset(13,15+i,1)
			pset(123,15+i,1)
		end
	end
	
	-- linear
	spr(1,1,y)
	dottedline(14,y+2,128,y+2,1,6)
	circ(ease(t/dur,start,finish,easelinear),y+2,1,10)
 
	line(1,y+5,128,y+5,1)

	-- quad	
	y+=7
	spr(2,1,y)
	dottedline(14,y+1,128,y+1,1,6)
	dottedline(14,y+9,128,y+9,1,6)
	dottedline(14,y+5,128,y+5,1,6)
	circ(ease(t/dur,start,finish,easequadin),y+1,1,8)
	circ(ease(t/dur,start,finish,easequadout),y+5,1,9)
	circ(ease(t/dur,start,finish,easequadinout),y+9,1,11)

	-- cubic 
	line(1,y+12,128,y+12,1)
	y+=14
	spr(3,1,y)
	dottedline(14,y+1,128,y+1,1,6)
	dottedline(14,y+9,128,y+9,1,6)
	dottedline(14,y+5,128,y+5,1,6)
	circ(ease(t/dur,start,finish,easecubicin),y+1,1,8)
	circ(ease(t/dur,start,finish,easecubicout),y+5,1,9)
	circ(ease(t/dur,start,finish,easecubicinout),y+9,1,11)

	-- quartic
	line(1,y+12,128,y+12,1)
	y+=14
	spr(4,1,y)
	dottedline(14,y+1,128,y+1,1,6)
	dottedline(14,y+9,128,y+9,1,6)
	dottedline(14,y+5,128,y+5,1,6)
	circ(ease(t/dur,start,finish,easequarticin),y+1,1,8)
	circ(ease(t/dur,start,finish,easequarticout),y+5,1,9)
	circ(ease(t/dur,start,finish,easequarticinout),y+9,1,11)

	-- sin
	line(1,y+12,128,y+12,1)
	y+=14
	spr(19,1,y)
	dottedline(14,y+1,128,y+1,1,6)
	dottedline(14,y+9,128,y+9,1,6)
	dottedline(14,y+5,128,y+5,1,6)
	circ(ease(t/dur,start,finish,easesinin),y+1,1,8)
	circ(ease(t/dur,start,finish,easesinout),y+5,1,9)
	circ(ease(t/dur,start,finish,easesininout),y+9,1,11)
	
	drawdebug()
end

function dottedline(x1,y1,x2,y2,c,skip)
	for i=0,128 do
		local percent = i/abs(x2-x1) 
		local x = i
		local y = ease(percent, y1, y2-y1, easesininout)
		if i%skip==0 then
			pset(x1+i, y, c)
		end
	end
end

function drawdebug()
	local i=0
	for i,d in ipairs(dbg) do
		print(d, 1, i*7, 7)
	end
	-- print('fps '..stat(7), 1, i*7, 7)
	dbg={}
end

function adddebug(d)
	dbg[#dbg+1] = d
end

-->8
-- easing

-- percent, start, end (offset from start), ease func
function ease(percent,s,e,f)
	return s + (e)*f(percent)
end

-- linear
function easelinear(t)
	return t
end

-- quad
function easequadin(t)
	return t^2
end

function easequadout(t)
	return 1-(1-t)^2
end

function easequadinout(t)
	if t<0.5 then 
		return 2*t^2
	end
	return 1 - ((-2*t+2)^2) / 2
end

-- cubic
function easecubicin(t)
	return t^3
end

function easecubicout(t)
	return 1 - (1-t)^3
end

function easecubicinout(t)
	if t<0.5 then 
		return 4*t^3
	end
	return 0.5*(2*t-2)^3+1
end

-- quartic
function easequarticin(t)
	return t^4
end

function easequarticout(t)
	return 1 - (1-t)^4
end

function easequarticinout(t)
	if t<0.5 then 
		return 8*t^4
	end
	return -8*(t-1)^4+1
end

-- sin
function easesinin(t)
	return -sin((t-1)/4)+1
end

function easesinout(t)
	return -sin(t/4)
end

function easesininout(t)
	return (1/2)*(1-cos(t/2))
end


__gfx__
00000000000009000990099209900299099009090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000009009009000990090009900909490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000009009049029090490049904909990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000009990994099909940229099400490000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000000009990000099000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000000000900000900900009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000000000900000900900002990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008000000009990000099000000229000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888000000000000000000000002990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
