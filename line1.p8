pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

screenwidth = 127
screenheight = 127

-- main
function _init()
	t=0
	dbg={}
end

function _update60()	
	t+=1
end

function _draw()
	width = 50
	height = 10

	cls(0)
	print('pico',1,10,9)
	rect(1, 18, width, 18+height, 10)
	line(1, 18, width, 18+height, 8)

	print('naive',1,31,9)
	rect(1, 38, width, 38+height, 10)
	drawLineNaive(1, 38, width, 38+height, 8)

	print('bresenham',1,52,9)
	rect(1, 59, width, 59+height, 10)
	drawLineBresenham(1, 59, width, 59+height, 8)

	drawdebug()
	
end


function drawLineNaive(x1,y1,x2,y2,c)
	if abs(x2-x1) > abs(y2-y1) then d=abs(x2-x1) else d=abs(y2-y1) end
	for i=0,d do
		pset(x1+i, y1+i/d*(y2-y1), c)
	end
end

function drawLineBresenham(x1,y1,x2,y2,c)
	-- slope
	dx = abs(x2-x1)
	dy = abs(y2-y1)
	if dy>dx then slope = true else slope = false end

	-- optionally transpose x & y
	if slope then
		x1,y1 = y1,x1
		x2,y2 = y2,x2
	end

	-- optionally transpose 1 & 2
	if x1>x2 then
		x1,x2 = x2,x1
		y1,y2 = y2,y1
	end

	-- recalculate d
	dx = abs(x2-x1)
	dy = abs(y2-y1)
	error = dx \ 2
	y=y1
	if y1<y2 then yStep = 1 else yStep = -1 end

	points = {}
	adddebug(x1)
	adddebug(x2)
	for x=x1,x2+1 do
		adddebug(i)
		if slope then 
			pset(y,x,11)
		else
			pset(x,y,14)
		end
		error -= dy
		if error < 0 then
			y += yStep
			error += dx
		end
	end
end

function drawdebug()
	local i=0
	for i,d in ipairs(dbg) do
		print(d, 66, i*7, 7)
	end
	-- print('fps '..stat(7), 1, i*7, 7)
	dbg={}
end

function adddebug(d)
	dbg[#dbg+1] = d
end

-- input
function input()
end



__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
