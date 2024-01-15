pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- Snek Dash

-- flags
-- 0 wall

-- debug
skiptitle=1
dbg={}

-- screen
screenwidth=127
screenheight=127

-- player
player={
  x=screenwidth/2,
  y=screenheight/2,
  width=7,
  height=7,
  h={}, -- history (tail)
  l=4, -- length
  c=8, -- color
  dir=1, -- u=1 l=2 d=3 r=4
  dashframe=0, -- 0 = not dashing, >0 = dashing
  -- frame counter for after dash recharge animation
  dashreloadframe=0
}
DASH_RELOAD_FRAMES=4

-- snake palettes
snakepalettes = {
 plain={3,3,3,2,2,1,0},
 texascoralsnake={0,0,0,10,8,8,8,10},
 snakezero={12,12,12,12,12,12,12,1,1,0,0},
 snakorpion={10,10,10,10,10,10,10,10,0,0},
 rainbow={7,7,14,14,8,8,9,9,10,10,11,11,3,3,12,12,2,2}
}
-- snakepalette=snakepalettes.plain
snakepalette=snakepalettes.rainbow

-- player dead effect
circles = {}

-- game 
scene=0
timer = 0
score = 0
dashamount = 20
dashframes = 20
comboNum = 0
comboTimer = 0
COMBO_THRESHOLD = 60

-- levels
levels={
  [1]={ name='Duel', mx=0, my=0 },
  [2]={ name='Scattered', mx=16, my=0 }
}
curLevel=1

-- food
food={}
foodsprites = {1,2,17}
shine={}
crumbs={}

-- background
bgcolor = 5

-- message
msgTimer = 0
shakeTime = 6

function _init()
  if (skiptitle==1) scene = 1

  if (scene==0) then
    titleinit()
  elseif scene==1 then
    gameinit()
  end
end

function _update()
  timer+=1

  if scene==0 then
    titleupdate()

  elseif scene==1 then
  	if not player.dead then
      gameupdate()
    else
    	timer = 0
    end

  elseif scene==2 then
    gameoverupdate()

  elseif scene==3 then
  	deadupdate()
  end
end

function _draw()
  if scene==0 then
    titledraw()
  elseif scene==1 then
    gamedraw()
  elseif scene==2 then
   gameoverdraw()
  elseif scene==3 then
   deaddraw()
  end

  drawDebug(50,-5)
end


-- atitle
function titleinit()
  music(3)
end

function titleupdate()
  if btnp(4) then
    gameinit()
  end
end

function titledraw()

  local titletxt = "snek dash!!1"
  rectfill(0,0,screenwidth, screenheight, 3)
  wavyPrint(titletxt, 24, 29, 5, 5)
  wavyPrint(titletxt, 25, 30, 5, 7)

  local bx=40
  local by=58
  local byStr = 'BY TED MELOT'
  print(byStr, bx-1, by-1, 5)
  print(byStr, bx, by, 9)

  local bx=11
  local by=95
  local startStr = "presssss z to ssssstart"
  wavyPrintAll(startStr, bx-1, by-1, 2, 5)
  wavyPrintAll(startStr, bx, by, 2, 6)
end


-- agame
function gameinit()
  player.x=screenwidth/2
  player.y=screenheight/2
  player.width=7
  player.height=7
  player.dir=frnd((4))+1
  player.c=8
  player.h={}
  player.l=200
  player.dead=false
  player.dashreloadframe=0
  scene=1
  timer=0
  score=0

  food = {}
  spawnfood(4)
  crumbs={}

  music(1)
end

function gameupdate()
  timer+=1

  playercontrol()

  -- move player
  if (timer%1==0) then
    if (player.dir == 1) then player.y-=1
    elseif (player.dir == 2) then player.x-=1
    elseif (player.dir == 3) then player.y+=1
    elseif (player.dir == 4) then player.x+=1
    end
  end

  -- player dash
  if (player.dashframe > 0) then
   if (player.dashframe > dashframes) then
    player.dashframe = 0
    player.dashreloadframe=1
    add(shine,{id='dash_recharge', x=player.x-3, y=player.y-3, tick=0})
   else
    player.dashframe += 1
   end
  end

  if player.dashreloadframe>0 then
    player.dashreloadframe+=1
    if player.dashreloadframe>=DASH_RELOAD_FRAMES then
      player.dashreloadframe=0
    end
  end

  -- collisions
  pc={x=player.x/8, y=((player.y-2)/8)-1}
  mc=mget(((curLevel-1)*16)+pc.x, pc.y)
  f=fget(mc)

  dead=false
  -- hit a wall
  if f==1 then
    dead=true
  -- off edge of screen
  elseif (player.x <= 0 or player.x >= screenwidth or player.y < 12 or player.y >= screenheight) then
    dead=true
  end

  if dead==true then
    gameover()
    return
  end

  -- self
  for v in all(player.h) do
    if (player.x == v.x and player.y == v.y) then
     gameover()
     return
    end
  end

 -- food
 local playerobj={x=player.x,y=player.y,w=1,h=1}
 for f in all(food) do
  local foodobj={x=f.x,y=f.y,w=4,h=4}
  -- got food!
  if iscolliding(playerobj,foodobj) then
    collectfood(food,f)
  end
 end

  -- player length
  -- add to trail
  add(player.h,{x=player.x,y=player.y})
  -- delete end of trail
  if (#player.h >= player.l) then
    del(player.h,player.h[1])
  end

  crumbsupdate()

  -- score
  if timer%30==0 then
    score+=1
  end

  -- combo
  if comboTimer > 0 then
    comboTimer += 1
    if comboTimer > COMBO_THRESHOLD then
      comboEnd(comboNum)
      comboNum = 0
      comboTimer = 0
    end
  end
end

function gamedraw()
  -- bg
  rectfill(0,0,screenwidth, screenheight, 0)

  -- level
  l=levels[curLevel]
  -- map(0,0, 0,10, 16,15)
  map(l.mx,l.my, 0,10, 16,15)

  -- crumbs
  crumbsdraw()

  -- hud
  rectfill(0,0,screenwidth, 10, 0)
  -- message & combo
  messagedraw()
  combodraw()
  -- border
  -- rect(0,11,screenwidth,screenheight,6)
  -- rounded border
  --ul
  pset(0,11,1)
  pset(1,12,1)
  --ur
  pset(screenwidth,11,1)
  pset(screenwidth-1,12,1)
  --dl
  pset(0,screenheight,1)
  pset(1,screenheight-1,1)
  --dr
  pset(screenwidth,screenheight,1)
  pset(screenwidth-1,screenheight-1,1)
  -- rect(0,11,screenwidth,11,7)
  -- text
  print("score: " .. score, 4, 4, 7)

  playerdraw()

  -- food
  for f in all(food) do
   spr(f.s,f.x,f.y)
  end

  -- shine
  for p in all(shine) do
   spr(6+p.tick,p.x,p.y)
   p.tick+=1
   if (p.tick > 4) then del(shine,p) end
  end
end

function crumbsupdate()
 local i=0
 for c in all(crumbs) do
  if not c.deleted then
    c.x += c.vx
    -- bounce off either side of screen
    if (c.x < 1) then c.x = 1 c.vx = c.vx * -0.50
    elseif (c.x > screenwidth-1) then c.x = screenwidth-1 c.vx = c.vx * -0.50
    end

    c.y += c.vy
    -- bounce off top or bottom of screen
    if (c.y < 11) then c.y = 11 c.vy = c.vy * -0.50
    elseif (c.y > screenheight-1) then c.y = screenheight-1 c.vy = c.vy * -0.50
    end

    c.vx *= 0.50
    c.vy *= 0.50
    c.tick += 1
    if (c.tick == 450) then del(crumbs,c) end

    if flr(player.x) == flr(c.x) and flr(player.y) == flr(c.y) then
      c.deleted = true
    end
    i+=1
  end
 end
end

function crumbsdraw()
  for c in all(crumbs) do
    if not c.deleted then
      pset(c.x, c.y, c.c)
    end
  end
end

-- randomly spawn new food, c=count
function spawnfood(c)
 for i=1,c do
  newfood = {x=rnd(screenwidth-10)+2,y=rnd(screenheight-25)+14,s=foodsprites[frnd(#foodsprites)+1]}
  add(food,newfood)
  add(shine,{x=newfood.x-2,y=newfood.y-2,tick=0})
 end
end

function spawncrumbs(x,y,d)
 local num = frnd(7)+8
 local range = 5

 -- if player dashing, more crumbs & move further
 if (player.dashframe > 0) then
  num += 5
  range = 15
 end

 local friction = 0.20
 local colors
 if frnd(2) == 0 then
   colors = {1,2}
 else
   colors = {4,2}
 end
 local sign1 = 1
 local vx = 0
 local vy = 0

 for i=1,num do
  if (rnd(1) < friction) then sign=-1 else sign=1 end
  -- fan out crumbs in the direction of player movement
  if (d == 1) then
   vx = rnd(range/2)*sign
   vy = rnd(range)*-1
  elseif (d == 2) then
   vx = rnd(range)*-1
   vy = rnd(range/2)*-sign
  elseif (d == 3) then
   vx = rnd(range/2)*sign
   vy = rnd(range)
  elseif (d == 4) then
   vx = rnd(range)
   vy = rnd(range/2)*sign
  end

  add(crumbs,{
   x = x,
   y = y,
   vx = vx,
   vy = vy,
   c = colors[frnd(#colors)+1],
   tick = frnd(75)
  })
 end
end

-- aplayer
-- collects food in foodlist, spawns new food
function collectfood(foodlist, food)
  spawncrumbs(food.x,food.y,player.dir)
  sfx(2)
  del(foodlist,food)
  score+=100
  player.l += 20
  spawnfood(1)
  eatmessage()

  -- start combo timer
  if comboTimer == 0 then
    comboNum = 1
    comboTimer = 1
  elseif comboTimer < COMBO_THRESHOLD then
    comboNum += 1
    comboTimer = 1
  end
end

function collectfoodExtraPoints(p)
  score += p
end

-- collects food if pos collides with any food
function dashfoodcollect(food,pos)
 for f in all(food) do
  if (iscolliding({x=pos.x,y=pos.y,w=1,h=1},{x=f.x,y=f.y,w=4,h=4})) then
   collectfood(food,f)
   collectfoodExtraPoints(500)
   dasheatmessage()
  end
 end
end

function playerdraw()
  if not player.dead then
  -- head (current pos)
  pset(player.x,player.y,11)
  -- spr(0, player.x, player.y)
  end

  -- tail
  local i = 1
  for i,v in ipairs(player.h) do
   if (v.x!=player.x or v.y!=player.y) then
    if player.dashreloadframe>0 and player.dashreloadframe<3 and #player.h-i<30 then
      if frnd(100)<80 then
        c = 7
      else
        c = snakepalette[i%(#snakepalette)+1]
      end
    else
      c = snakepalette[i%(#snakepalette)+1]
    end
    pset(v.x,v.y,c)
   end
   i += 1
  end
end


-- acombo
function combodraw()
  if comboNum > 0 then
    s='combo: '..comboNum
    -- print(s, 60, 4, 10)
    if comboTimer>0 and comboTimer<=20 then
      percent=.25*comboTimer
      scale=max(2-percent,1)
      log('p '..percent)
      log('scale '..scale)
    else
      scale=1
    end
    scale_text(s,60,4,10,scale)
    combobardraw(96, 3, 25)
  end
end

function combobardraw(x,y,w)
  h=5
  percent=comboTimer/COMBO_THRESHOLD

  if percent<0.04 then
    h+=2
    y-=1
  else
    lh=5
  end

  -- outline
  rectfill(x, y, x+w, y+h, 6)
  -- bg
  rectfill(x+1, y+1, x+w-1, y+h-1, 0)
  -- progress
  if percent<0.40 then
    c=11
  elseif percent<0.75 then
    c=9
  elseif percent<0.85 then
    c=2
  elseif percent<0.95 then
    c=1
  end
  rectfill(x+1, y+1, x+(1-percent)*w+1, y+h-1, c)

  if percent<0.05 then
    lh=6
  else
    lh=2
  end
  line(x+(1-percent)*w+1, y-(lh/2), x+(1-percent)*w+1, y+h+(lh/2), 14)

  -- start flash
  if percent<0.05 then
    c=11
    rectfill(x,y,x+w,y+h,10)
  end
end

function comboEnd(num)
  print(num, 5, 75, 11)
end


-- agameover & dead
function gameover()
  player.dead = true 
  deadinit()
end

function gameoverinit()
 scene = 2
 timer = 0
 music(-1)

 rectfill(0,0,screenwidth,screenheight,8)
 local text = 'u died fool'
 print(text,hcenter(text),vcenter(text)-20,7)

 finalScoreDraw()

 local text = 'press z to try'
 print(text,hcenter(text),vcenter(text)+22,7)
 local text = 'z'
 print(text,hcenter(text)-2,vcenter(text)+22,11)
 local text = 'it again'
 print(text,hcenter(text),vcenter(text)+30,7)
end

function gameoverupdate()
  timer += 1
  if btn(4) and btn(5) then
    gameinit()
  end
end

function gameoverdraw()
 local pad=20

 if timer > 70 then
  for x=1,1950 do
   local xx = flr(rnd(screenwidth))
   local yy = flr(rnd(screenheight-pad))
   local cc = pget(xx,yy)
   if (cc==7 or flr(rnd(10))<=3) then
    -- change to drip left/right at first
    if timer < 180 then
     -- drop left/right
     if (flr(rnd(100))==5) then xx+=1 elseif(flr(rnd(100))==10) then xx-=1 end
     -- drip darker from top
     if (flr(rnd(50)) == 10) then pset(flr(rnd(screenwidth+1)),0,2) end
    -- change to only become red after
    elseif timer < 360 then
     if (flr(rnd(100)) == 2) then
      pset(flr(rnd(screenwidth+1)),flr(rnd(screenheight)),8)
     end
    -- black drips from top
    else
      if (flr(rnd(100))%5==0) then pset(flr(rnd(screenwidth)),0,0) end
    end
    pset(xx,yy+1,cc)
   end
  end
 finalScoreDraw()
 end
end

function deadinit()
	scene = 3
	timer = 0
	circles = {}
	pauseTimer = 0
end

function deadupdate()
	timer += 1

	if #player.h > 1 then
		add(circles, {
      x=player.h[#player.h].x, 
      y=player.h[#player.h].y, 
      r=frnd(4)+2, 
      c=snakepalette[#player.h%(#snakepalette)+1]
    })
		delete_cnt = 1 + (flr(timer/5)*flr(timer/5)) / 8

		for i=0,delete_cnt do
			del(player.h,player.h[#player.h])
		end

		if timer % 2 == 0 then
			sfx(0,-1,timer)
		end
	else
		pauseTimer += 1
		if pauseTimer > 80 then
			gameoverinit()
		end
	end
end

function deaddraw()
	len = 20

	crumbsdraw()
	playerdraw()

	for c in all(circles) do
		circfill(c.x, c.y, c.r, c.c)
		for i=0,frnd(3) do
			nx=rndneg()*2+c.r + flr(rnd(len)*cos(rnd(1)))
			ny=rndneg()*2+c.r + flr(rnd(len)*sin(rnd(1)))
			bigger = flr(rnd(10)) > 7
			if bigger then size = 2 else size = 1 end
			circfill(c.x+nx, c.y+ny, size, c.c)
			if flr(rnd(10) > 8) then
				line(c.x-0.1*nx, c.y-0.1*ny, c.x+nx,c.y+ny, c.c)
			end
		end
	end
	circles={}
end


function finalScoreDraw()
	local text = ''..score
	x1 = 28
	x2 = 100
	y1 = 60
	y2 = 66
	rectfill(x1,y1,x2,y2,8)
	rect(x1,y1-1,x2,y2+1,3)
	print(text,hcenter(text),vcenter(text)-0,11)
end


-- ainput
function playercontrol()
 -- l?
  if (btn(0) and player.dir!=4) then player.dir=2
 -- r?
  elseif (btn(1) and player.dir!=2) then player.dir=4
  -- u?
  elseif (btn(2) and player.dir!=3) then player.dir=1
  -- d?
  elseif (btn(3) and player.dir!=1) then player.dir=3
  end

  -- dash
  if (btnp(4) and player.dashframe == 0) then
   player.dashframe = 1
   -- up
   if (player.dir==1) then
    player.y -= dashamount
    for i=1,dashamount do
     local newpos = {x=player.x,y=(dashamount+player.y)-i}
     add(player.h,newpos)
     dashfoodcollect(food,newpos)
    end
   -- left
   elseif (player.dir==2) then
    player.x -= dashamount
    for i=1,dashamount do
     local newpos = {x=(dashamount+player.x)-i,y=player.y}
     add(player.h,newpos)
     dashfoodcollect(food,newpos)
    end
   -- down
   elseif (player.dir==3) then
    player.y += dashamount
    for i=1,dashamount do
     local newpos = {x=player.x,y=(player.y-dashamount)+i}
     add(player.h,newpos)
     dashfoodcollect(food,newpos)
    end
   -- right
   elseif (player.dir==4) then
    player.x += dashamount
    for i=1,dashamount do
     local newpos = {x=(player.x-dashamount)+i,y=player.y}
     add(player.h,newpos)
     dashfoodcollect(food,newpos)
    end
   end

   for x=1,dashamount do
    del(player.h,player.h[1])
   end

   sfx(5)
  end
end


-- atext
function eatmessage()
  local msgs = {
    'yum',
    'delicious',
    'deliciousioso!!',
    'so good',
    'mmm',
    'tastes like chicken',
    'woo!',
    'my favorite',
    'farm fresh',
    'wait wut',
    'i <3 pizza'
  }
  messageupdate(msgs[frnd(#msgs)+1], 'shake')
end

function dasheatmessage()
  local msgs = {
    'radical',
    'bodacious',
    'righteous eating',
    'omg',
    'oooommmmgggggg',
    'wow',
    'meaningwave exists!'
  }
  messageupdate(msgs[frnd(#msgs)+1], 'shakeHard')
end

function messageupdate(newMsg, msgType)
  msgTimer = 0
  message = newMsg
  messageType = msgType or 'normal'
end

function messagedraw()
  if msgTimer < 60 then
    local intensity
    if messageType == 'normal' then
      intensity = 1
    elseif messageType == 'shake' then
      intensity = 2
    elseif messageType == 'shakeHard' then
      intensity = 7
    end

    x,y = 15,23
    if msgTimer < shakeTime then
      if frnd(11)%2==0 then shakeRangeX = frnd(intensity) else shakeRangeX = -1*frnd(intensity) end
      if frnd(11)%2==0 then shakeRangeY = frnd(intensity) else shakeRangeY = -1*frnd(intensity) end
      x += shakeRangeX
      y += shakeRangeY
    end
    wavyPrint(message, x-15, y, 2, 8)
  end
  msgTimer += 1
end

function wavyPrint(s,x,y,h,c)
  for s in all(s) do
    print(s,10+x,y + h*sin((1.2*x-timer*1.4)*(3.1459/180)), c)
    x+=5
  end
end

function wavyPrintAll(s,x,y,h,c)
  print(s,10+x,y + h*sin((1.2*x-timer*1.4)*(3.1459/180)), c)
end


-- autil
function table_key_count(t)
  c=0
  for _,_ in pairs(t) do
    c+=1
  end
  return c
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

function drawDebug(x,y)
  local i=0
  for i,d in ipairs(dbg) do
    rect(x,y+7*i, x+20, y+7*i, 0)
    print(i..' '..d, x+1, y+i*7, 7)
  end
  dbg={}
end

function addDebug(d)
  dbg[#dbg+1] = d
end

function log(s)
  printh(s, 'log.txt')
end

--- center align from: pico-8.wikia.com/wiki/centering_text
function hcenter(s,extra_x)
  -- string length time     s the
  -- pixels in a char's width
  -- cut in half and rounded down
  ex = extra_x or 0
  return (screenwidth / 2)-flr((#s*(4+ex))/2)
end

function vcenter(s)
  -- string char's height
  -- cut in half and rounded down
  return (screenheight /2)-flr(5/2)
end

--- collision check
function iscolliding(obj1, obj2)
  local x1 = obj1.x
  local y1 = obj1.y
  local w1 = obj1.w
  local h1 = obj1.h

  local x2 = obj2.x
  local y2 = obj2.y
  local w2 = obj2.w
  local h2 = obj2.h

  if(x1 < (x2 + w2)  and (x1 + w1)  > x2 and y1 < (y2 + h2) and (y1 + h1) > y2) then
    return true
  else
    return false
  end
end

-- shorthand for flr(rnd(x))
function frnd(x)
 return flr(rnd(x))
end

function rndneg()
	if flr(rnd(2)) == 0 then
		return 1
	else
		return -1
	end
end

__gfx__
00000000bb9b00008200000041111111000000000000000000000000000700000007000000070000000000100000000000000000000000000000000000000000
00000000889800008820000041111111000000000000000000070000000700000007000000000000010000000000000001000000000000000000000000000000
00000000288800008882000041111111000000000000000000070000000700000000000000000000000000000000000000000000000000000000000000000000
0000000002800000b3b3000044444444000000000000000000777000777777777700077770000007000010000000000000001000000000000000000000000000
00000000000000000000000011114111000000000000000000070000000700000000000000000000100000000000000000000000000000000000000000000000
00000000000000000000000011114111000000000000000000070000000700000007000000000000001000000010000000100000000000000000000000000000
00000000000000000000000011114111000000000000000000000000000700000007000000000000000000100000001000000010000000000000000000000000
00000000000000000000000044444444000000000000000000000000000700000007000000070000000000000000000000000000000000000000000000000000
00000000000300000b009bb012122447744221211111111111111111777777777777777772122447111111111111111111111111000000000000000000000000
0000000000fa000000bb900b112224477442221115212212212212517ff1221221221ff771222447101111000011110000111101000000000000000000000000
000000000fa0000000888800121224477442212112121121121121217f121121121121f772122447110000111100001111000011000000000000000000000000
00000000aa000000088eee8011222447744222111122121221212211712112111121121771222447110000111100001111000011000000000000000000000000
000000000000000008888e8012122447744221211211212222121121721121111112112772122447110000111100001111000011000000000000000000000000
00000000000000000888888011222447744222111212122442212121721211144111212771222447110000111100001111000011000000000000000000000000
00000000000000000888888012122447744221211121224444221211712111444411121772122447101111000011110000111101000000000000000000000000
00000000000000000088880011222447744222111212244aa44221217211144aa441112771222447101111000011110000111101000000000000000000000000
00000000000000000000000077777777111111111212244aa44221217211144aa441112774422127101111000011110000111101000000000000000000000000
00000000000000000000000044444444121212121121224444221211712111444411121774422217101111000011110000111101000000000000000000000000
00000000000000000000000044444444212121211212122442212121721211144111212774422127110000111100001111000011000000000000000000000000
00000000000000000000000022222222222222221211212222121121721121111112112774422217110000111100001111000011000000000000000000000000
00000000000000000000000022222222222222221122121221212211712112111121121774422127110000111100001111000011000000000000000000000000
000000000000000000000000121212124444444412121121121121217f121121121121f774422217110000111100001111000011000000000000000000000000
000000000000000000000000212121214444444415212212212212517ff1221221221ff774422127101111000011110000111101000000000000000000000000
00000000000000000000000011111111777777771111111111111111777777777777777774422217101111000011110000111101000000000000000000000000
00000000000000000000000000000000000000000000000021220000717777170000000000000000101111000011110000111101000000000000000000000000
00000000000000000000000000000000000000000000000012240000102442010000000000000000101111000011110000111101000000000000000000000000
00000000000000000000000000000000000000000000000022440000724444270000000000000000110000111100001111000011000000000000000000000000
000000000000000000000000000000000000000000000000244a0000744aa4470000000000000000110000111100001111000011000000000000000000000000
00000000000000000000000000000000000000000000000000000000744aa4470000000000000000110000111100001111000011000000000000000000000000
00000000000000000000000000000000000000000000000000000000724444270000000000000000110000111100001111000011000000000000000000000000
00000000000000000000000000000000000000000000000000000000102442010000000000000000101111000011110000111101000000000000000000000000
00000000000000000000000000000000000000000000000000000000717777170000000000000000111111111111111111111111000000000000000000000000
__gff__
0000000100000000000000000000000000000001010101010101000000000000000000010101010101010000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1524242424242424242424242424241615242424242424242424242424242416000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130b0b0b0b0b0b0b0b0b0b0c0c0b0b14130b0c0c0c0c0d0d0d0c0c0c0c0c0c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
131e0a0c0c1e0a0c0b0c0c0b0c0b0c14130c0c0b0c0c0d330c0c0b0c0c0c0c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130c0c0c0b0c0c0a0c0c0c0c0c0c0c1413330c0c370c0c0c0c0c370c0c0b3314000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130c1a1b1b1b1c0c1e1a1b1b1b1c0c14130c0c0c1a1b1b371b1b1c0c0c0c0c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
131e2a17182b2b1b1b2b2b17182c0b14130c371a2b2b2b2b2b2b2b1c370c0c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130c2a19292b2b2b2b2b2b19292c0c14130c0b2a2b2b2b2b2b2b2b2c0c0c0c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130b2a19292b2b2b2b2b2b19292c1e14130b0c372b2b2b372b2b2b370c330c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130b2a27282b2b3b3b2b2b27282c0c14130c332a2b2b2b2b2b2b2b2c0c0c0b14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130c3a3b3b3b3c0a0c3a3b3b3b3c0b14130c373a2b2b2b2b2b2b2b3c370c0c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130c0c0c0c0c0c0c0c1e0c0c0c0c0c14130c0c0c3a3b3b373b3b3c0c0c0c0a14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130b0b0c0a0b0c1e0c1e1e0c0b0c0c14130c0b0c370c0c0a330c370c0d0d0c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130b0c0b0a0c0c0c0c0c0b0c0a0c0c14130b0b0b0c0c0c0c0c0c0c0c0d0d0b14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
131e0c0c0c0b0c0a0b0b0a0b0c0b0c14130c0c0c0c0b0c0b0b0c0b0b0c0b0c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2523232323232323232323232323232625232323232323232323232323232326000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000037670396703b6703b6703c6703c6703b67039670376703667033670306702d6702a6702867023670216701f6701e6701c6701a67015670106700d6700867004670036700367009670096700a67009670
001100001f4701847018070184701f0701f4701a0701a0701c470210701c4701d4701d47023470244701f4701f4701d4701c4701a47018470184701a4701f4702157021470215702347023470242702427024270
010600003557730573325033050632506325063560737607306003b6033c603356033c60335603346033c6031c0001d0001c4001d0001c0001c0001c0001c0001c0001d0001c0001d0001c000000000000000000
00100000180701a070180701a07021070180001f0701d0701c0701c07018070180701807018070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002400030000245501d3701a070000001a070000001a0701a670000001a670000001a670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0103000018175181753017537175186401d640186301a6201d600040000200002000020000200002000020000100006000130001300011000100000e0000c0000b0000b0000c0000b0000a0000a0000a0000a000
__music__
00 41424344
00 01424344
00 41424344
00 41420344
