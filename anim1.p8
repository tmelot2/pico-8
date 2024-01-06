pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

timer = 0

screenwidth = 127
screenheight = 127
ballSpawner={ x = screenwidth/2, y = screenheight-10, on = false }


-- main
function _init()
	balls = {}
	starfield = {}
	cx = 0
	cy = 0
	initStarfield()
end

function _update60()	
	timer += 1
	if timer > 59 then
		timer = 0
	end
	
	input()
	updateBalls()
	updateBallSpawner()
	updateStarfield()
	updateBurst()
end

function _draw()
	cls(0)
	drawStarfield()
	drawBalls()
	drawHud()
	-- drawBurst()
end


-- input
function input()
	-- movement
	mv = 2
	-- spawner speed toggle
	if btn(5) then mv=4 else mv=2 end

	-- l
	if btn(0) then ballSpawner.x -= mv end
	-- r
	if btn(1) then ballSpawner.x += mv end
	-- u
	if btn(2) then ballSpawner.y -= mv end
	-- d
	if btn(3) then ballSpawner.y += mv end

	-- spawner toggle
	if btn(4) then ballSpawner.on = true else ballSpawner.on = false end
end


-- hud
function drawHud()
	print('balls: ' .. #balls, 1, 1, 7)
	print('stars: ' .. #starfield, 1, 7, 7)
	print('fps: ' .. stat(7), 1, 14, 7)

	-- reticle
	if btn(4) then c=6 size=6 else c=5 size=4 end
	line(0, ballSpawner.y, screenwidth, ballSpawner.y, c)
	line(ballSpawner.x, 0, ballSpawner.x, screenwidth, c)
	rect(ballSpawner.x-size, ballSpawner.y-size, ballSpawner.x+size, ballSpawner.y+size, c)
end


-- starfield
function initStarfield()
	c = {5,6,7}
	for i=1,100 do
		add(starfield, newStar(true))
	end
end

function newStar(start)
	-- layers
	v = flr(rnd(3))
	if v == 0 then
		c = 5
		v=0.5
	elseif v == 1 then
		c = 6
	elseif v == 2 then
		c = 10
	end

	-- spawn x pos
	if start then x=rnd(screenwidth) else x=0 end

	return { 
		x = x, y = rnd(screenheight),
		vx = v,
		c = c
	}
end

function updateStarfield()
	-- spawn to limit
	STAR_LIMIT = 100
	more = 0 
	if #starfield < STAR_LIMIT then
		more = STAR_LIMIT - #starfield +1
	end
	for i=1,more do
		add(starfield, newStar())
	end

	-- update
	for s in all(starfield) do
		s.x += max(s.vx, 2*(ballSpawner.x/screenwidth) * s.vx)
		if ballSpawner.y > screenheight/2 then
			s.y -= s.vx*abs((screenheight/2)-ballSpawner.y)/screenheight
		elseif ballSpawner.y < screenheight/2 then
			s.y += s.vx*abs((screenheight/2)-ballSpawner.y)/screenheight
		end

		-- delete
		if s.x > screenwidth then
			del(starfield, s)
		end
	end
end

function drawStarfield()
	for s in all(starfield) do
		pset(s.x, s.y, s.c)
	end
end


-- balls
function newBall()
	if ballSpawner.on then
		colors = {8,9,10,11,14}
		vxn = 1
		if flr(rnd(10)) % 2 == 0 then
			vxn = -1
		end
		return { 
			x=ballSpawner.x, y=ballSpawner.y, 
			vx=vxn*rnd(1.5), vy=-rnd(1.8),
			s=flr(rnd(8)) + 3,
			c=colors[1+flr(rnd(#colors))],
			lm=flr(rnd(160) + 60), -- lifetime max
			t=0 -- timer
		}
	end
end

function updateBalls()
	-- spawn
	if timer % 2 == 0 then
		for c = 0,flr(rnd(5)) do
			add(balls, newBall())
		end
	end

	-- update
	for b in all(balls) do
		b.x += b.vx
		b.y += b.vy

		-- bounce
		if ceil(b.x+b.s) > screenwidth-2 or b.x-b.s < 0 then
			b.vx = 0.8 * -b.vx
		end
		if b.y+b.s > screenheight or b.y-b.s < 0 then
			b.vy = 0.8 * -b.vy
		end

		-- size
		b.t +=1
		b.s -= 0.2*(b.lm-(b.lm - b.t))/b.lm
		if b.s < 1 then b.s=1 end
		if b.t >= b.lm then
			del(balls,b)
		end
	end
end

function drawBalls()
	count = 0
	for b in all(balls) do
		if b.s > 1 then
			circfill(b.x, b.y, flr(b.s), b.c)
			circ(b.x, b.y, flr(b.s)+0, 0)
			circ(b.x, b.y, flr(b.s)+1, 7)
			circ(b.x, b.y, flr(b.s)+2, 0)
		else
			pset(b.x, b.y, b.c)
			pset(b.x+1, b.y+1, 5)
			pset(b.x-1, b.y-1, 5)
			pset(b.x-1, b.y+1, 5)
			pset(b.x+1, b.y-1, 5)
		end
		count += 1
	end
end

-- ball spawner
function updateBallSpawner()
	-- > right
	if ballSpawner.x > screenwidth then ballSpawner.x = screenwidth end
	-- < left
	if ballSpawner.x < 0 then ballSpawner.x = 0 end
	-- ^ up
	if ballSpawner.y < 0 then ballSpawner.y = 0 end
	-- v down
	if ballSpawner.y > screenheight then ballSpawner.y = screenheight end
end

-- burst
burstTimer = 0
function updateBurst()
	burstTimer += 1
end

function drawBurst()
	cx = screenwidth/2
	cy = screenheight/2
	l = 8
	c = {8}
	cc = c[1]
	for i=0,l do
		circ(cx+16*cos(i/l+(0.05*burstTimer/8)), cy+16*sin(i/l+(0.05*burstTimer/8)), 5+20*cos(burstTimer/128), cc)
	end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
