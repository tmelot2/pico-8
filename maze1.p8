pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

screenwidth = 127
screenheight = 127

MAZE_SIZE=32
TILE_SIZE=4

maze={}
solution=nil

-- player
p={}
-- player trail
pt={}

-- animation system
t=0
anim={}

logfile='log.txt'

-- main
function _init()
	srand(1)
	t=0
	maze=initmaze()
	p=initplayer()

	-- set key delay
	poke(0x5f5c, 2)
end

function _update60()	
	t+=1
	input()
	animate()
	updateplayer()
	-- camera(p.x-64,p.y-64)
	-- adddebug('fps '..stat(7))
end

function _draw()
	cls(0)

	drawmaze()
	drawplayer()

	drawdebug()
end


-- amaze
function initmaze()
	m={}
	for x=1,MAZE_SIZE do
		m[x] = {}
		for y=1,MAZE_SIZE do
			wall=true 
			-- if frnd(100)<5 then wall=false end
			m[x][y] = wall
		end
	end

	-- initmaze_portal_sorcerer(m)
	initmaze_dfs(m)
	-- initmaze_windy(m)

	-- add perimeter
	for x=1,MAZE_SIZE do
		for y=1,MAZE_SIZE do
			if x==1 or x==MAZE_SIZE then m[x][y]=true end
			if y==1 or y==MAZE_SIZE then m[x][y]=true end
		end
	end

	-- fullness
	tot=MAZE_SIZE*MAZE_SIZE
	filled=0
	for x=1,MAZE_SIZE do
		for y=1,MAZE_SIZE do
			if m[x][y] then filled+=1 end
		end
	end
	printh('maze filled '..flr(100*(filled/tot))..'%',logfile)

	-- todo: add start, exit

	return m
end

function initmaze_windy(m)
	for x=1,MAZE_SIZE,2 do
		for y=1,MAZE_SIZE,2 do
			if frnd(2)%2==0 then
				m[x][y]=false
				m[x+1][y]=false
				m[x][y+1]=false
			end
		end
	end
	return m
end

function initmaze_dfs(m)
	log('')
	log('start!')
	extra_carve=0
	seen={}
	-- visit={{x=frnd(MAZE_SIZE)+1, y=frnd(MAZE_SIZE)+1}}
	visit={{x=2, y=2}}
	while #visit>0 do
		-- pop
		cur=visit[1]
		-- del(visit,cur) 

		m[cur.x][cur.y]=false

		-- seen
		k=getkey(cur.x,cur.y)
		seen[k]=true

		dir=frnd(3)
		i=0
		has_unvisited=false
		repeat
			dir=(dir+1)%4
			log(dir)
			-- u
			if dir==0 then
				newp={x=cur.x, y=cur.y-2}
				halfp={x=cur.x, y=cur.y-1}
			-- d
			elseif dir==1 then
				newp={x=cur.x, y=cur.y+2}
				halfp={x=cur.x, y=cur.y+1}
			-- l
			elseif dir==2 then
				newp={x=cur.x-2, y=cur.y}
				halfp={x=cur.x-1, y=cur.y}
			-- r
			elseif dir==3 then
				newp={x=cur.x+2, y=cur.y}
				halfp={x=cur.x+1, y=cur.y}
			end

			--new point seen with chance to carve into already seen path
			s=seen[getkey(newp.x,newp.y)]
			if s==true and extra_carve<3 then
				if rnd(100)<0.5 then
					s=false
					extra_carve+=1
				end
			end

			if inmazebounds(newp) and s!=true then
				has_unvisited=true
				m[halfp.x][halfp.y]=false
				add(visit,newp,1)
			end

			i+=1
		until has_unvisited==true or i==3

		if has_unvisited==false then 
			del(visit,cur)
		end
	end
	
	log('ec '..extra_carve)
	log('done!')
	return m
end

function initmaze_portal_sorcerer(m)
	-- carve hallways
	-- todo: replace with sloped lines
	for carves=1,frnd(15)+20 do
		-- horizontal
		x=frnd(MAZE_SIZE-1)+2
		y=frnd(MAZE_SIZE-1)+2
		l=frnd(15)+5
		if x+l > MAZE_SIZE-1 then l=MAZE_SIZE-x-2 end
		if x<1 then x=1 end
		for i=1,l do
			m[x+i][y]=false
		end
		
		-- vertical
		x=frnd(MAZE_SIZE-1)+2
		y=frnd(MAZE_SIZE-1)+2
		l=frnd(15)+5
		if y+l > MAZE_SIZE-1 then l=MAZE_SIZE-y-2 end
		if y<1 then y=1 end
		for i=1,l do
			m[x][y+i]=false
		end
	end

	-- remove some 3-empty tiles
	removed=0
	for x=1,MAZE_SIZE do
		for y=1,MAZE_SIZE do
			cnt=0
			-- l
			if m[x-1] ~= nil and m[x-1][y] ~= nil and not m[x-1][y] then cnt+=1 end
			-- r
			if m[x+1] ~= nil and m[x+1][y] ~= nil and not m[x+1][y] then cnt+=1 end
			-- u
			if m[x][y-1] ~= nil and m[x][y-1] ~= nil and not m[x][y-1] then cnt+=1 end
			-- d
			if m[x][y+1] ~= nil and m[x][y+1] ~= nil and not m[x][y+1] then cnt+=1 end
			if cnt>=3 and frnd(100)<65 then 
				m[x][y]=false 
				removed+=1
			end
		end
	end
	printh('removed '..removed,logfile)
	return m
end

function inmazebounds(p)
	if p.x>0 and p.x<MAZE_SIZE and p.y>0 and p.y<MAZE_SIZE then
		return true
	else
		return false
	end
end

function drawmaze()
	for ix,x in ipairs(maze) do
		for iy,y in ipairs(x) do
			if y==true then
				sspr(8,0, 4,4, TILE_SIZE*(ix-1),TILE_SIZE*(iy-1))
			end
		end
	end
end

-- 1 based
function getmazewall(x,y)
	if x<1 or x>MAZE_SIZE or y<1 or y>MAZE_SIZE then return true end
	return maze[x][y]
end

function solvemaze()
	-- bfs
	result={}
	seen={}
	start={x=1,y=1}
	finish={x=31,y=31}
	visit={start}
	
	while #visit>0 do
		cur=visit[1]

		-- u
		newp={cur.x,cur.y-2}
		if inmazebounds(newp) then add(visit,newp) end
		-- d
		newp={cur.x,cur.y+2}
		if inmazebounds(newp) then add(visit,newp) end
		-- l
		newp={cur.x-2,cur.y}
		if inmazebounds(newp) then add(visit,newp) end
		-- r
		newp={cur.x+2,cur.y}
		if inmazebounds(newp) then add(visit,newp) end
		
	end

	return result
end


-- aplayer
function initplayer()
	mx=frnd(20)
	my=frnd(20)
	return {
		mx=mx, my=my,
		x=TILE_SIZE*(mx-1),y=TILE_SIZE*(my-1),
		sx=12, sy=12
	}
end

function updateplayer()
	updateplayertrail()
end

function updateplayertrail()
	if getAnimation('player.x') then
		add(pt,{x=p.x+1, y=p.y+1, t=frnd(50)})
	end
end

function drawplayer()
	drawplayertrail()
	sspr(p.sx,p.sy, 4,4, p.x,p.y)
end

function drawplayertrail()
	pdur=150
	for par in all(pt) do
		par.t+=frnd(2)
		if par.t>pdur then
			del(pt,par)
		else
			-- fade
			pal={8,2,1}
			-- pal={11,10,9}
			if pdur-par.t>0.5*pdur then 
				pc=pal[1]
			elseif pdur-par.t<0.5*pdur and pdur-par.t>0.2*pdur then 
				pc=pal[2]
			elseif pdur-par.t<0.2*pdur then 
				pc=pal[3]
			end
			-- drift
			-- todo: should move to update
			if frnd(400)==0 then
				if frnd(2)%2==0 then px=frnd(1)+1 else px=-(frnd(1)+1) end
				if frnd(2)%2==0 then py=frnd(1)+1 else py=-(frnd(1)+1) end
				par.x+=px
				par.y+=py
			end
			pset(par.x, par.y, pc)
		end
	end
end

function moveplayertorandom()
	repeat
		nx = frnd(20+10)+1
		ny = frnd(20+10)+1
		didmove=moveplayer(nx,ny)
	until didmove==true
end

function moveplayer(mazex, mazey)
	dur=4
	if getmazewall(mazex,mazey) == false then 
		p.mx=mazex
		p.my=mazey

		sx=p.x
		ax=newAnimation(
			'player.x',
			p, 'x',
			sx, TILE_SIZE*(p.mx-1),
			0, dur,
			easelinear
		)
		sy=p.y
		ay=newAnimation(
			'player.y',
			p, 'y',
			sy, TILE_SIZE*(p.my-1),
			0, dur,
			easelinear
		)
		add(anim,ax)
		add(anim,ay)
		addAnimCallback('player.x', changeplayercolor)
		return true
	else
		return false
	end
end

function changeplayercolor()
	if p.sx==8 then p.sx=12 else p.sx=8 end
end


-- aanimation
-- id, object, prop, start val, end val, time, duration, easing func
function newAnimation(id,o,prop,s,e,t,d,f)
	-- if anim exists, start from current place, reset timer
	a=getAnimation(id)
	if a ~= nil then
		a.s=o[prop]
		a.e=e
		a.t=0
		a.d=d
		a.f=f
	else
		a={
			id=id,
			obj=o, prop=prop,
			s=s, e=e,
			t=0, d=dur,
			f=f
		}
		add(anim,a)
	end
end

function addAnimCallback(id,cb)
	a = getAnimation(id)
	if a then a.cb=cb end
end

function getAnimation(id)
	for i,a in ipairs(anim) do
		if a.id == id then
			return anim[i]
		end
	end
	return nil
end

function animate()
	for a in all(anim) do
		if a.t>=a.d then
			if a.cb != nil then
				a.cb()
			end
			del(anim,a)
		end
		percent = a.t/a.d
		val = ease(percent, a.s, a.e-a.s, a.f)
		a.obj[a.prop] = val
		a.t+=1
	end
end


-- ainput
function input()
	if btnp(0) then
		moveplayer(p.mx-1, p.my)
	end
	if btnp(1) then
		moveplayer(p.mx+1, p.my)
	end
	if btnp(2) then
		moveplayer(p.mx, p.my-1)
	end
	if btnp(3) then
		moveplayer(p.mx, p.my+1)
	end

	-- z
	if btnp(4) then
		-- moveplayertorandom()
		solution=solvemaze()
	end

	-- x
	if btn(5) then maze=initmaze() end
end


-- autil
function listtostr(l)
	if #l==0 then return '' end
	r=''
	for i in all(l) do
		if r=='' then
			r=i
		else
			r=''..r..','..i
		end
	end
	return r
end

function getkey(x,y)
	return x..','..y
end

function log(s)
	printh(s,logfile)
end

function round(x)
	if ceil(x)-x >= 0.5 then
		return ceil(x)
	else
		return flr(x)
	end
end

function frnd(x)
	return flr(rnd(x))
end

dbg={}
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

-- percent, start, end (offset from start), ease func
function ease(percent,s,e,f)
	return s + (e)*f(percent)
end
function easelinear(t)
	return t
end
function easecubicout(t)
	return 1 - (1-t)^3
end
function easequarticout(t)
	return 1 - (1-t)^4
end
function easeexpout(t)
	if t==1 then return 1 end
	return 1 - 2^(-10*t)
end

__gfx__
00000000666515511221122118810000111112210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666551152882299282280000122112210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700666551152882299282280000122112210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000555115511221122118810000122111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000001441133100000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000004aa43bb300000000122212210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004aa43bb300000000122212210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001441133100000000111112210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaacccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000abbaceec0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000abbaceec0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaacccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbb99990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b88b92290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000b88b92290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbb99990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
