pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
screenwidth = 127
screenheight = 127

COUNT=20
SPD=0.25

t=0
points={}
fadeAmt=0

thrust=0.09
fric=0.95

dbg={}

fadeTable={
 {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
 {1,1,1,1,1,1,1,0,0,0,0,0,0,0,0},
 {2,2,2,2,2,2,1,1,1,0,0,0,0,0,0},
 {3,3,3,3,3,3,1,1,1,0,0,0,0,0,0},
 {4,4,4,2,2,2,2,2,1,1,0,0,0,0,0},
 {5,5,5,5,5,1,1,1,1,1,0,0,0,0,0},
 {6,6,13,13,13,13,5,5,5,5,1,1,1,0,0},
 {7,6,6,6,6,13,13,13,5,5,5,1,1,0,0},
 {8,8,8,8,2,2,2,2,2,2,0,0,0,0,0},
 {9,9,9,4,4,4,4,4,4,5,5,0,0,0,0},
 {10,10,9,9,9,4,4,4,5,5,5,5,0,0,0},
 {11,11,11,3,3,3,3,3,3,3,0,0,0,0,0},
 {12,12,12,12,12,3,3,1,1,1,1,1,1,0,0},
 {13,13,13,5,5,5,5,1,1,1,1,1,0,0,0},
 {14,14,14,13,4,4,2,2,2,2,2,1,1,0,0},
 {15,15,6,13,13,13,5,5,5,5,5,1,1,0,0}
}

function fade(i)
 for c=0,15 do
  if flr(i+1)>=16 then
   pal(c,0)
  else
   pal(c,fadeTable[c+1][flr(i+1)])
  end
 end
end

function drawDebug()
	local i=0
	for i,d in ipairs(dbg) do
		rect(0,7*i, 20, 7*i, 0)
		print(i..' '..d, 1, i*7, 7)
	end
	dbg={}
end

function addDebug(d)
	dbg[#dbg+1] = d
end

function rand(a,b)
	if (a>b) a,b=b,a
	return a+flr(rnd(b-a+1))
end

function newPoint()
	min=0.01
	dx=rnd(SPD)+min
	if (flr(rnd(2))%2==0) dx=-dx
	dy=rnd(SPD)+min
	if (flr(rnd(2))%2==0) dy=-dy
	return {
		x=rnd(screenwidth), y=rnd(screenheight),
		dx=dx, dy=dy
	}
end

-- main
function _init()
	for i=1,COUNT do
		p = newPoint()
		if i == 1 then
			p.x=screenwidth/2
			p.y=screenheight/2
			p.dx=0
			p.dy=0
		end
		add(points, p)
	end
end

function _update60()	
	input()
	for i,p in ipairs(points) do
		if i == 1 then
			p.dx*=fric
			p.dy*=fric
		end

		p.x+=p.dx
		p.y+=p.dy
		if p.x<0 or p.x>screenwidth then p.dx=-p.dx end
		if p.y<0 or p.y>screenheight then p.dy=-p.dy end
	end
	t+=1
	addDebug('fps '..stat(7))
end

function _draw()
	cls()

	-- lines
	connected=0
	linePal={10,7,5,1,1}
	for i,p in ipairs(points) do
		for j,p2 in ipairs(points) do
			if p ~= pp then 
				local dx=p.x-p2.x
				local dy=abs(p.y-p2.y)
				local d=sqrt(dx*dx+dy*dy)
				if d < 29 then
					connected+=1
					local c=d\#linePal
					if t%2==0 and d >=20 then c=0 end
					line(p.x,p.y, p2.x,p2.y, linePal[c])
				end
			end
		end
	end
	addDebug('connected '..connected)

	-- points
	for i,p in ipairs(points) do
		if i==1 then
			if t%2==0 then color(5) else color(10) end
			s=1
			if t%2==0 then s+=1 end
		else
			color(6)
			s=1
		end
		pset(p.x, p.y)
		circ(p.x, p.y, s)
	end

	drawDebug()
end

-- input
function input()
	-- move pointer
	if btn(0) then points[1].dx -= thrust end
	if btn(1) then points[1].dx += thrust end
	if btn(2) then points[1].dy -= thrust end
	if btn(3) then points[1].dy += thrust end
	
	-- z fade out
	if btnp(4) then
		fadeAmt+=1 
	-- z fade in
	elseif btnp(5) then
		fadeAmt-=1 
	end

	if fadeAmt > 15 then fadeAmt = 15 end
	if fadeAmt < 0 then fadeAmt = 0 end

	fade(fadeAmt)
end

-- random floating points
-- draw line between nearby ones
-- brighter line when closer
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
