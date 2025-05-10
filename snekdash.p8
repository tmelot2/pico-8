pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Snek Dash
-- lrud zx
-- ⬅️➡️⬆️⬇️🅾️❎

-- map dimension: 16x15

-- flags
-- 0 wall
-- 1 bg tile, appears in tiny maps
-- 2 spawner tile

-- tile pages
-- 0 art
-- 3 copies of background tiles that are flagged as spawners

-- debug
skiptitle=0
dbg={}
drawVerticalCenter=false
drawHorizontalCenter=false

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
  dashing=false,
  dashframe=0, -- 0 = not dashing, >0 = dashing
  -- frame counter for after dash recharge animation
  dashreloadframe=0
}
DASH_RELOAD_FRAMES=4

snakepalettes = {
 [1]={name='snek', p={3,3,3,2,2,1,0}},
 [2]={name='texas coral snek', p={0,0,0,10,8,8,8,10}},
 [3]={name='snek-zero', p={12,12,1,1,0,12,12,1,1,0,0}},
 [4]={name='snekorpion', p={10,10,0,0,10,10,0,0,10,10,10,10,0,0}},
 [5]={name='rainbow snek', p={7,7,14,14,8,8,9,9,10,10,11,11,3,3,12,12,2,2}},
 [6]={name='something snek', p={3,3,3,3,0,0,11,11,0,0}}
}
curPal=2
snakepalette=snakepalettes[curPal].p

-- player dead effect
circles = {}

-- game 
-- scenes
-- 6 high score name entry
-- 5 high score text bam / check
-- 4 title to game transition
scene=0
timer=0
score=10
dashamount=20
dashframes=20
comboNum=0
comboTimer=0
COMBO_THRESHOLD=60

-- levels
levels={
  [1]={ name='classic', mx=48, my=0},
  [2]={ name='dual', mx=0, my=0 },
  [3]={ name='split', mx=32, my=0 },
  [4]={ name='scatter', mx=16, my=0 },
  [5]={ name='x', mx=64, my=0 },
  [6]={ name='segments', mx=80, my=0 },
  [7]={ name='the wall', mx=96, my=0 },
  [8]={ name='layers', mx=0, my=15 },
  [9]={ name='criss-cross', mx=16, my=15 }
}
curLevel=1

-- food
food={}
foodsprites={1,2,17,33,49,50}
shine={}
crumbs={}

-- background
bgcolor=5

-- message
msgTimer=0
shakeTime=6

-- audio
play_music=false

function _init()
  cartdata('tm-snek-dash')
  reset_high_scores()

  if (skiptitle==1) scene=1

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
    	timer=0
    end

  elseif scene==2 then
    gameoverupdate()

  elseif scene==3 then
  	deadupdate()

  elseif scene==4 then
    togameupdate()

  elseif scene==5 then
    checkHighScoreUpdate()

  elseif scene==6 then
    nameEntryUpdate()

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
  elseif scene==4 then
    togamedraw()
  elseif scene==5 then
    checkHighScoreDraw()
  elseif scene==6 then
    nameEntryDraw()
  end

  -- addDebug('cpu '..stat(1))
  drawDebug(1,110)

  if drawVerticalCenter then
    line(64,0,64,128,7)
  end
  if drawHorizontalCenter then
    line(0,64,128,64,7)
  end
end

-- atitle
function titleinit()
	timer=0
	slt=5 -- select level timer, for anim
	dir=0 --0 left, 1 right
  scd={t=0, y=-15, v=2} -- snek color display
	if (play_music) music(3)
	hs=read_scores(curLevel)
  bigsnektimer=0
  offset=frnd(180)
end

function titleupdate()
	if (slt<4) slt+=1

	--lr
	if btnp(0) then
		if curLevel>1 then
			curLevel-=1
			hs=read_scores(curLevel)
			sfx(6)
			slt=0
			dir=0
		end
	elseif btnp(1) then
		if curLevel<#levels then
			curLevel+=1
			hs=read_scores(curLevel)
			sfx(12)
			slt=0
			dir=1
		end
	end

  --ud
  colorChanged=false
  if btnp(2) then
    if (curPal>1) then
      sfx(11)
      colorChanged=true
    end
  	curPal-=1
  elseif btnp(3) then
    if (curPal<#snakepalettes) then
      sfx(13)
      colorChanged=true
    end
  	curPal+=1
  end
  if (curPal<1) curPal=1
  if (curPal>#snakepalettes) curPal=#snakepalettes
  snakepalette=snakepalettes[curPal].p

  if colorChanged then
    scd.t=1
    scd.y=-5
  end
  if scd.t>0 then
    -- animate in
    if scd.t<5 then
      scd.y+=scd.v
    end
    -- animate out
    if scd.t>20 then
      scd.y-=scd.v
    end
    -- end animation
    if scd.y<-10 then
      scd.t=0
    else
      scd.t+=1
    end
  end

  -- o
	if btnp(4) then
  	sfx(7)
    togameinit()
	end
end

function titledraw()
  rectfill(0,0,screenwidth, screenheight, 1)

  by=30
  -- scrolling bg
  clip(0,by,128,64)
  w=30
  speed=2
  for x=-2, 1+screenwidth/w do
    for y=-2, 1+screenheight/w do
      if (x+y)%2==0 then c=1 else c=3 end
      x1=(-timer/speed%w)+x*w
      y1=(-timer/speed%w)+y*w

      x1+=abs(13*cos((timer+130)/270)+2) + 4*cos(timer/400)
      y1+=3*sin(timer/140)+1

      rectfill(x1,y1, x1+w,y1+w, c)
    end
  end
  clip()

  -- faded overlay
  fillp(▒)
  rectfill(0,by,128,94,5)
  fillp()
  borderpal={}
  len=#snakepalette
  for i=1,len+15 do
    add(borderpal,snakepalette[i])
    if i>len then
      add(borderpal,0)
    end
  end
  -- border
  for x=0,128 do
    c=borderpal[#borderpal-(x+timer)%#borderpal]
    pset(128-x,by,c)
    pset(128-x,by+1,c)
    pset(x,by+64,c)
    pset(x,by+65,c)
  end

  -- big snek bg
  bigsnektimer+=1
  if abs(bigsnektimer)%275==0 then
    bigsnektimer=0
    offset=frnd(180)
  end
  w=3
  h=7
  c={2,5,13}
  start=-4
  last=-40
  for i=start,last,-1 do
    x=bigsnektimer+(i*3)
    y=10+h*sin((offset+i+bigsnektimer)/44)
    cc=c[i%3+1]
    rectfill(x,y,x+w,y+h,cc)
    if i==last then
      line(x,y,x,y+h,0)
    end
    if i==start then
      rectfill(x,y+1,x+w,y+h-1,11)
      line(x+w,y+1,x+w,y+h-1,0)
    end
    line(x,y,x+w,y,0)
    line(x,y+h,x+w,y+h,0)
  end

  local titletxt="snek dash!"
  x=29
  y=8
  wavyPrint(titletxt, x, y, 2, 5)
  wavyPrint(titletxt, x+1, y+1, 3, 7)

  -- words
  local bx=40
  local by=19
  local byStr='BY TED MELOT'
  print(byStr, bx-1, by-1, 5)
  print(byStr, bx, by, 9)

  -- snek color selection
  print(snakepalettes[curPal].name, 5, scd.y, 5)
  print(snakepalettes[curPal].name, 5+1, scd.y+1, 9)

  local bx=18
  local by=121
  local startStr = "presssss 🅾️ to ssssstart"
  wavyPrintAll(startStr, bx-1, by-1, 1, 0)
  wavyPrintAll(startStr, bx-1, by, 1, 0)
  wavyPrintAll(startStr, bx, by-1, 1, 0)
  wavyPrintAll(startStr, bx+1, by+1, 1, 0)
  wavyPrintAll(startStr, bx+1, by, 1, 0)
  wavyPrintAll(startStr, bx, by+1, 1, 0)
  wavyPrintAll(startStr, bx, by, 1, 6)

  -- tiny map
  sx,sy=41,35
  if dir==0 then
	sx-=1*(4-slt)
  elseif dir==1 then
  	sx+=1*(4-slt)
  end
  draw_tiny_map(curLevel,sx,sy)

  -- arrow buttons
  shadow=true
  show_left=curLevel>1
  show_right=curLevel<#levels
  bx=19
  by=55
  yy=0
  if timer%50<7 then
	  yy=1
	  shadow=false
  end

  if show_left then
  	  if (shadow) print('⬅️',bx+1,by+yy+4,1)
	  print('⬅️',bx,3+by+yy,0)
    print('⬅️',bx+2,2+by+yy,0)
    print('⬅️',bx+1,1+by+yy,0)
    print('⬅️',bx+1,3+by+yy,0)
    print('⬅️',bx+1,2+by+yy,7)
  end

  bx=104
  if show_right then
  	if (shadow) print('➡️',bx+2,55+yy+4,1)
    print('➡️',bx,2+by+yy,0)
    print('➡️',bx+2,2+by+yy,0)
    print('➡️',bx+1,1+by+yy,0)
    print('➡️',bx+1,3+by+yy,0)
    print('➡️',bx+1,2+by+yy,7)
  end

  -- top 3 scores
  n1=getHighScoreText(1, hs[1].name, hs[1].score)
  n2=getHighScoreText(2, hs[2].name, hs[2].score)
  n3=getHighScoreText(3, hs[3].name, hs[3].score)

  y=98
  inc=7

  print1stplace(n1, 4+sx, y)
  print2ndPlace(n2, 4+sx, y+inc)
  print3rdPlace(n3, 4+sx, y+2*inc)

  -- levels
  width=#levels*2
  bx=hcenter("")-(width/2)
  by=92
  for i=1,#levels do
    if i==curLevel then
      pset(bx+2*i, by, 8)
      pset(bx+2*i, by-1, 8)
      pset(bx+2*i, by-2, 8)
    else
      pset(bx+2*i, by, 6)
      pset(bx+2*i, by-1, 6)
    end
  end
end

function getHighScoreText(slot, name, score)
  if name == '' then
    name='---'
  end
  if score == 0 then
    score=''
  end
  return slot..' '..name..' '..score
end

-- atogame: transition from title to game
function togameinit()
  scene=4
  t=15
end

function togameupdate()
  t-=1
  if t==0 then
    gameinit()
  end
end

function togamedraw()
  gradient={7,7,6,5,1,1,0,0}
  percent=1-t/15
  index=flr(#gradient*percent)
  rectfill(0,0,128,128,gradient[index+1])
end

function draw_tiny_map(num,atx,aty)
  local map=levels[num]
  w,h=16,15 -- map dimension
  size=1 -- cell size
  pad=2 -- padding between cells
  total_w=0 -- total width
  total_h=0 -- total height

  -- shadow
  dist=3
  rectfill(atx+dist,aty+dist, dist+atx+(w-1/2)*size+(w-1/2)*pad, dist+aty+(h-1/2)*size+(h-1/2)*pad, 0)
  --frame
  rect(atx-1,aty-1, 1+atx+(w-1/2)*size+(w-1/2)*pad, 1+aty+(h-1/2)*size+(h-1/2)*pad, 1)
  -- bg
  rectfill(atx,aty, atx+(w-1/2)*size+(w-1/2)*pad, aty+(h-1/2)*size+(h-1/2)*pad, 0)

  for x=0,w-1 do
    for y=0,h-1 do
      tile=mget(map.mx+x, map.my+y)
      is_wall=fget(tile,0)
      is_bg=fget(tile,1)
      if is_wall then
        c=15
      elseif is_bg then
        c=2
      else
        c=1
      end
      rect(atx+(x*size)+(x*pad), aty+(y*size)+(y*pad), atx+(x*size)+size+(x*pad), aty+(y*size)+size+(y*pad), c)
    end
  end

  total_w+=((1+size)*w) + (pad-1)*w
  total_h+=((1+size)*h) + (pad-1)*h

  title=map.name
  text_w=4*#title
  comictext(title, (atx+total_w/2)-(text_w/2), 1+aty+(h*size)+(h*pad)+2)
end


-- agame
function gameinit()
  spawnplayer()
  player.width=7
  player.height=7
  player.c=8
  player.h={}
  player.l=15
  player.dead=false
  player.dashing=false
  player.dashreloadframe=0
  scene=1
  timer=0
  score=0

  food={}
  spawnfood(4)
  crumbs={}

  messageend()
  comboNum=0
  comboTimer=COMBO_THRESHOLD+1

  if (play_music) music(1)
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
    player.dashframe=0
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
      sfx(9)
    end
  end

  -- collisions
  -- map
  pc={x=player.x/8, y=((player.y-2)/8)-1}
  mc=mget(levels[curLevel].mx+pc.x, levels[curLevel].my+pc.y)
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
    kill_player()
    return
  end

  -- self
  for v in all(player.h) do
    if (player.x == v.x and player.y == v.y) then
     kill_player()
     return
    end
  end

  -- food
  playerfoodcollide(food,{x=player.x,y=player.y})

  -- player length
  -- add to trail
  add(player.h,{x=player.x,y=player.y})
  -- delete end of trail
  if (#player.h >= player.l) then
    del(player.h,player.h[1])
  end

  crumbsupdate()

  -- combo
  if comboTimer > 0 then
    comboTimer+=1

    if timer%30==0 then
	    score+=1
	end

    if comboTimer > COMBO_THRESHOLD then
      comboEnd(comboNum)
      comboNum=0
      comboTimer=0
    end
  end
end

function gamedraw()
  -- bg
  rectfill(0,0,screenwidth, screenheight, 0)

  -- level
  l=levels[curLevel]
  map(l.mx,l.my, 0,10, 16,15)

  -- crumbs
  crumbsdraw()

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

  -- hud
  rectfill(0,0,screenwidth, 10, 0)
  messagedraw()
  combodraw()
  print("score: " .. score, 4, 4, 8)
end

function crumbsupdate()
  local i=0
  for c in all(crumbs) do
    if not c.deleted then
      c.x+=c.vx
      -- bounce off either side of screen
      if (c.x < 1) then c.x = 1 c.vx = c.vx * -0.50
      elseif (c.x > screenwidth-1) then c.x = screenwidth-1 c.vx = c.vx * -0.50
      end

      c.y+=c.vy
      -- bounce off top or bottom of screen
      if (c.y < 11) then c.y = 11 c.vy = c.vy * -0.50
      elseif (c.y > screenheight-1) then c.y = screenheight-1 c.vy = c.vy * -0.50
      end

      c.vx*=0.50
      c.vy*=0.50
      c.tick+=1
      if (c.tick==450) then del(crumbs,c) end

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
-- randomize position in tiles/map, then convert to screen x/y
function spawnfood(c)
  for i=1,c do
  	repeat
	    rx,ry=frnd(16),frnd(15)
	    wx=levels[curLevel].mx+rx
	    wy=levels[curLevel].my+ry
	    f=fget(mget(wx,wy))
	    wall=f==1
	until wall==false

	half_tile=4
	tilex=rx*8 + half_tile + frnd(4) * rndneg()
	-- +4 (along with half_tile) offsets from top status bar
	tiley=ry*8 + 4 + half_tile + frnd(4) * rndneg()
	local newfood={x=tilex, y=tiley, s=foodsprites[frnd(#foodsprites)+1]}
	add(food, newfood)
	add(shine,{x=newfood.x-2,y=newfood.y-2,tick=0})
  end
end

function spawncrumbs(x,y,d)
  local num=frnd(7)+8
  local range=5

  -- if player dashing, more crumbs & move further
  if (player.dashframe > 0) then
    num+=5
    range=15
  end

  local friction=0.20
  local colors
  if frnd(2) == 0 then
    colors={1,2}
  else
    colors={4,2}
  end
  local sign1=1
  local vx=0
  local vy=0

  for i=1,num do
    if (rnd(1) < friction) then sign=-1 else sign=1 end

    -- fan out crumbs in the direction of player movement
    if (d==1) then
      vx=rnd(range/2)*sign
      vy=rnd(range)*-1
    elseif (d==2) then
      vx=rnd(range)*-1
      vy=rnd(range/2)*-sign
    elseif (d==3) then
      vx=rnd(range/2)*sign
      vy=rnd(range)
    elseif (d==4) then
      vx=rnd(range)
      vy=rnd(range/2)*sign
    end

    add(crumbs,{
      x=x,
      y=y,
      vx=vx,
      vy=vy,
      c=colors[frnd(#colors)+1],
      tick=frnd(75)
    })
 end
end

-- aplayer
function spawnplayer()
	mx,my=15*(curLevel), 14*(curLevel)
  spawners = {}
  player.dir=1 -- Always start pointing up

  -- Get list of spawner tiles, if any
  for x=1,15 do
    for y=1,14 do
      m=mget(levels[curLevel].mx+x, levels[curLevel].my+y)
      if fget(m,2) then
        add(spawners, {x=x, y=y})
      end
    end
  end

  -- Spawn at a random spawner
  if #spawners > 0 then
    spawnTile=spawners[frnd(#spawners)+1]
    player.x=spawnTile.x * 8
    player.y=spawnTile.y * 10
    return
  end

  -- No spawners, so spawn in middle of screen
  player.x=screenwidth/2
  player.y=screenheight/2
end

-- collects food in foodlist, spawns new food
function collectfood(foodlist, food)
  spawncrumbs(food.x,food.y,player.dir)
  if player.dashing then
    sfx(10)
  else
    sfx(2)
  end
  del(foodlist,food)

  foodpoints=0
  if player.dashing then
	  foodpoints=15
  else
	  foodpoints=10
  end

  points=flr(foodpoints*log10(foodpoints*(comboNum+1)))
  score+=points

  player.l += 20
  spawnfood(1)
  eatmessage()

  -- start combo timer
  if comboTimer==0 then
    comboNum=1
    comboTimer=1
  elseif comboTimer<COMBO_THRESHOLD then
    comboNum+=1
    comboTimer=1
  end
end

-- collects food if pos collides with any food
function playerfoodcollide(food,pos)
  for f in all(food) do
    if (iscolliding({x=pos.x,y=pos.y,w=1,h=1},{x=f.x,y=f.y,w=8,h=8})) then
      collectfood(food,f)
      dasheatmessage()
    end
  end
end

function playerdraw()
  if not player.dead then
    -- head (current pos)
    pset(player.x,player.y,11)
  end

  -- tail
  local i = 1
  for i,v in ipairs(player.h) do
    if (v.x!=player.x or v.y!=player.y) then
      if player.dashreloadframe>0 and player.dashreloadframe<3 and #player.h-i<30 then
        if frnd(100)<80 then
          c=7
        else
          c=snakepalette[i%(#snakepalette)+1]
        end
      else
        c=snakepalette[i%(#snakepalette)+1]
      end
    pset(v.x,v.y,c)
    end
    i+=1
  end
end


-- acombo
function combodraw()
  if comboNum>0 then
    s='combo: '..comboNum
    -- print(s, 60, 4, 10)
    if comboTimer>0 and comboTimer<=20 then
      percent=.25*comboTimer
      scale=max(2-percent,1)
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
  score+=comboNum*10
end


-- agameover & dead
function kill_player()
  player.dead=true
  deadinit()
end

function deadinit()
	scene=3
	timer=0
	circles={}
	pauseTimer=0
end

function deadupdate()
	timer+=1

  maxplayerh=max(maxplayerh,#player.h)
  delete_cnt=maxplayerh/120

	if #player.h > 0 then
		add(circles, {
		  x=player.h[#player.h].x,
		  y=player.h[#player.h].y,
		  r=frnd(4)+2,
		  c=snakepalette[#player.h%(#snakepalette)+1]
		})

		for i=0,delete_cnt do
			del(player.h,player.h[#player.h])
		end

		if timer % 2 == 0 then
			sfx(0,-1,timer)
		end
	else
		pauseTimer += 1
		if pauseTimer > 80 then
			checkHighScoreInit()
		end
	end
end

function deaddraw()
	len=20

	crumbsdraw()
	playerdraw()

	for c in all(circles) do
  	circfill(c.x, c.y, c.r, c.c)
  	for i=0,frnd(3) do
  		nx=rndneg()*2+c.r + flr(rnd(len)*cos(rnd(1)))
  		ny=rndneg()*2+c.r + flr(rnd(len)*sin(rnd(1)))
  		bigger = flr(rnd(10)) > 7
  		if bigger then size = 2 else size = 1 end
  		circfill(c.x+nx, c.y+ny, size+2, 0)
      circfill(c.x+nx, c.y+ny, size+1, 7)
      circfill(c.x+nx, c.y+ny, size, c.c)
  		if flr(rnd(10) > 8) then
  			line(c.x-0.1*nx, c.y-0.1*ny, c.x+nx,c.y+ny, c.c)
  		end
  	end
	end
	circles={}
end

function checkHighScoreInit()
  scene=5
  slot=get_high_score_slot(curLevel, score)
  if score>0 and slot>0 then
    textBamMsg={
      '      you',
      '      got',
      '    a',
      '   high',
      'score!',
    }
    textBamMsg={
      '       a',
      '    winner',
      '   is',
      '    a',
      ' uuu!',
    }
    textBamMsg={
      '      oh',
      '      my',
      '    god',
      '   dat',
      'score!',
    }
    textBamMsg={
      '   where\'d',
      '       i',
      '    put',
      '    my',
      ' keys?'
    }
    textBamMsg={
      '   most',
      '   winners',
      '   don\'t',
      '    do',
      ' drugs'
    }
    textBamMsg={
      '     you',
      '    only',
      '    get',
      '    one',
      ' shot'
    }
    scene=5
    textBam={
      t=0,
      curIndex=1,
      text={
        {str=textBamMsg[1], d=12, scale=2, sfx=14},
        {str=textBamMsg[2], d=12, scale=2, sfx=14},
        {str=textBamMsg[3], d=12, scale=3, sfx=14},
        {str=textBamMsg[4], d=12, scale=3, sfx=14},
        {str=textBamMsg[5], d=12, scale=5, sfx=15}
      }
    }
    sfx(textBam.text[1].sfx)
  else
    gameoverinit()
  end
end

function checkHighScoreUpdate()
  if textBam.t==0 then
    sfx(textBam.text[textBam.curIndex].sfx)
  end
  textBam.t+=1
  if textBam.t == textBam.text[textBam.curIndex].d then
    textBam.curIndex+=1
    textBam.t=0
    if textBam.curIndex > #textBam.text then
      nameEntryInit()
    end
  end
end

function checkHighScoreDraw()
  local t=textBam.t

  if textBam.curIndex == 5 and (t == 1 or t == 4) then
    cls(6)
  else
    cls(0)
  end
  curText=textBam.text[textBam.curIndex]

  local x=5
  local y=34
  local range=5
  if textBam.t < 6 then
    range=5
  else
    range=0
  end
  if frnd(2)==0 then
    x+=frnd(range)
  else
    x-=frnd(range)
  end
  if frnd(2)==0 then
    y+=frnd(range)
  else
    y-=frnd(range)
  end

  scale_text(curText.str, x, y, 7, curText.scale)
end

function nameEntryInit()
  scene=6
  -- high score entry
  hse={
    x=55,
    y=52,
    w=60,
    h=30,
    letters={' ','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9'},
    -- letters={' ','a','b','c'},
    slots=3,
    curSlot=1,
    curNameIndexes={2,3,4},
    draw=hseDraw,
    changeLetter=hseChangeLetter,
    finish=hseFinish
  }

end

function nameEntryUpdate()
  -- left
  if btnp(0) then
    sfx(17)
    hse.curSlot = max(hse.curSlot-1, 1)
  -- right
  elseif btnp(1) then
    sfx(17)
    hse.curSlot = min(hse.curSlot+1, hse.slots)
  -- up
  elseif btnp(2) then
    hse.changeLetter(0)
  -- down
  elseif btnp(3) then
    hse.changeLetter(1)
  elseif btnp(4) or btnp(5) then
    sfx(15)
    sfx(15)
    sfx(15)
    hse.finish()
  end
end

-- dir=0 prev, 1 next
function hseChangeLetter(dir)
  letterIndex=hse.curNameIndexes[hse.curSlot]

  newLetterIndex=0
  -- update letter
  -- prev
  if dir==0 then
    sfx(16)
    newLetterIndex=letterIndex-1
    -- wrap around for dat user friendliness
    if newLetterIndex<1 then
      newLetterIndex=#hse.letters
    end
  -- next
  elseif dir==1 then
    sfx(16)
    newLetterIndex=letterIndex+1
    -- wrap around for dat user friendliness
    if newLetterIndex>#hse.letters then
      newLetterIndex=1
    end
  end
  hse.curNameIndexes[hse.curSlot]=newLetterIndex
end

function hseFinish()
  name=''
  for i=1,#hse.curNameIndexes do
    letterIndex=hse.curNameIndexes[i]
    letter=hse.letters[letterIndex]
    name=name..letter
  end
  -- log('Submitted name ['..name..']')

  cls(7)

  gameoverinit()
end

function hseDraw()
  cls(0)

  for i=1,hse.slots do
    w=8

    -- Slot selection border
    if i==hse.curSlot then
      x=((i-1)*w)
      rect(
        hse.x + x - w/4,
        hse.y - 2,
        hse.x + x + w/2,
        hse.y + 6,
        6
      )

      -- Buttons
      -- up
      x=((i-1)*w)
      print(
        '⬆️',
        hse.x + x - w/4,
        hse.y - 10
      )
      -- down
      print(
        '⬇️',
        hse.x + x - w/4,
        hse.y + 10
      )
    end

    -- Print slot
    letterIndex=hse.curNameIndexes[i]
    print(
      hse.letters[letterIndex],
      hse.x + ((i-1)*w),
      hse.y,
      7
    )
  end
end

function nameEntryDraw()
  hse.draw()
  local t='enter your name'
  comictext(t, hcenter(t),34,7)

  t='🅾️  submit'
  comictext(t, hcenter(t),70,7)
end

function gameoverinit()
  t=0
  scene=2
  timer=0
  music(-1)

  slot=get_high_score_slot(curLevel, score)
  if score>0 and slot>0 then
  	-- name=chr(97+frnd(122-97))..chr(97+frnd(122-97))..chr(97+frnd(122-97))
  	insert_high_score(curLevel, slot, score, name)
  end
  high_scores=read_scores(curLevel)

  stars={}
  for i=1,25 do
    star={x=frnd(100),y=frnd(106),s=1+frnd(3)}
    -- rare color
    if frnd(40)==0 then
      star.c=12
    -- rare color
    elseif frnd(40)==0 then
      star.c=9
    -- speed based color
    else
      if star.s==3 then
        star.c=7
      elseif star.s==2 then
        star.c=13
      end
    end
    add(stars,star)
  end

  letters={'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','end'}
end


function gameoverupdate()
  timer+=1

  for i=1,#stars do
    pt=stars[i]
    pt.x-=pt.s
    if pt.x<0 then
      pt.x=115
      pt.y=frnd(106)
      pt.s=1+frnd(3)
      if frnd(40)==0 then
        star.c=12
      elseif frnd(40)==0 then
        star.c=9
      else
        if star.s==3 then
          star.c=7
        elseif star.s==2 then
          star.c=13
        end
      end
    end
  end

  if timer > 10 then
    if btn(5) then
      sfx(8)
      scene=0
      titleinit()
    elseif btn(4) then
      -- o
      sfx(7)
      togameinit()
    end
  end
end

function gameoverdraw()
  cls()
  highscoredraw()
  local text='🅾️ try again'
  wavyPrintAll(text,hcenter(text)-7,99,1,7)
  local text='❎ level select'
  wavyPrintAll(text,hcenter(text)+4,107,1,7)

  if t==0 then
    cls(7)
  elseif t==1 then
    cls(6)
  elseif t==2 then
    cls(5)
  end
end

function highscoredraw()
  -- scrolling bg
  w=30
  speed=2
  for x=-2, 1+screenwidth/w do
    for y=-2, 1+screenheight/w do
      if (x+y)%2==0 then c=1 else c=3 end
      x1=(-timer/speed%w)+x*w
      y1=(-timer/speed%w)+y*w

      x1+=abs(13*cos((timer+130)/270)+2) + 4*cos(timer/400)
      y1+=3*sin(timer/140)+1

      rectfill(x1,y1, x1+w,y1+w, c)
    end
  end

  -- nested border, {inner, ..., outer}
  padding=12
  border={9,10,5,0}
  for i=#border,1,-1 do
    rectfill(0+padding-i,padding-i,128-padding+i,116+i,border[i])
  end
  rectfill(0+padding,padding,128-padding,116,0)

  -- stars
  clip(12,12,128-0,108)
  for i=1,#stars do
    pset(stars[i].x, stars[i].y, stars[i].c)
  end
  clip()

  -- map title
  t+=1
	title=levels[curLevel].name..' high scores'
  colorpal={8,9,10,11,12,13,14,15}
  for i=1,#title do
    onechar=sub(title,i,i)
    color=flr((t/4 + i) % #colorpal + 1)
    centerx=screenwidth/2
    wavyPrint2(onechar,centerx-(#title*(4)/2)+4*i,19,2,colorpal[color])
  end

  -- scores
  by=29
	for i,s in ipairs(high_scores) do
		if s.name=='' then n='___' else n=s.name end
		sc=''..i..' '..n..' '..s.score
		if i==1 then
			print1stplace(sc, 49, by+(7*i))
		elseif i==2 then
			print2ndPlace(sc, 49, by+(7*i))
		elseif i==3 then
			print3rdPlace(sc, 49, by+(7*i))
		else
			print(sc, 49, by+(7*i),5)
		end
	end

  -- new score
	local text=''..score
	x1=28
	x2=100
	y1=80
	y2=86
	print(text,hcenter(text),80,11)

  -- corner ornaments
  spr(29,14,14,1,1,false,true)
  spr(29,107,14,1,1,true,true)
  spr(45,14,107,1,1,false,false)
  spr(45,107,107,1,1,true,false)
  spr(61,11,41)
  spr(61,111,41)
  spr(61,11,79)
  spr(61,111,79)
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
    player.dashframe=1
    -- up
    if (player.dir==1) then
      player.y -= dashamount
      for i=1,dashamount do
        local newpos = {x=player.x,y=(dashamount+player.y)-i}
        add(player.h,newpos)
        player.dashing=true
        playerfoodcollide(food,newpos)
        player.dashing=false
    end

    -- left
    elseif (player.dir==2) then
      player.x -= dashamount
      for i=1,dashamount do
        local newpos = {x=(dashamount+player.x)-i,y=player.y}
        add(player.h,newpos)
        player.dashing=true
        playerfoodcollide(food,newpos)
        player.dashing=false
      end

    -- down
    elseif (player.dir==3) then
      player.y += dashamount
      for i=1,dashamount do
        local newpos = {x=player.x,y=(player.y-dashamount)+i}
        add(player.h,newpos)
        player.dashing=true
        playerfoodcollide(food,newpos)
        player.dashing=false
      end

    -- right
    elseif (player.dir==4) then
      player.x += dashamount
      for i=1,dashamount do
        local newpos = {x=(player.x-dashamount)+i,y=player.y}
        add(player.h,newpos)
        player.dashing=true
        playerfoodcollide(food,newpos)
        player.dashing=false
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
  local msgs={
    'yum',
    'delicious',
    'deliciousioso!!',
    'so good',
    'mmm',
    'tastes like chicken',
    'woo!',
    'my favorite',
    'farm fresh',
    'whut',
  }
  messageupdate(msgs[frnd(#msgs)+1], 'shake')
end

function dasheatmessage()
  local msgs={
    'radical',
    'bodacious',
    'righteous eating',
    'omg',
    'oooommmmgggggg',
    'wow',
    '<3 fruit',
    'meaningwave exists!'
  }
  messageupdate(msgs[frnd(#msgs)+1], 'shakeHard')
end

function messageupdate(newMsg, msgType)
  msgTimer=0
  message=newMsg
  messageType=msgType or 'normal'
end

function messageend()
  msgTimer=61
  message=''
end

function messagedraw()
  if msgTimer<60 then
    local intensity
    if messageType == 'normal' then
      intensity=1
    elseif messageType == 'shake' then
      intensity=2
    elseif messageType == 'shakeHard' then
      intensity=7
    end

    x,y = 15,23
    if msgTimer < shakeTime then
      if frnd(11)%2==0 then shakeRangeX = frnd(intensity) else shakeRangeX = -1*frnd(intensity) end
      if frnd(11)%2==0 then shakeRangeY = frnd(intensity) else shakeRangeY = -1*frnd(intensity) end
      x+=shakeRangeX
      y+=shakeRangeY
    end
    wavyPrint(message, x-15, y, 2, 8)
  end
  msgTimer+=1
end

function wavyPrint(s,x,y,h,c)
  for s in all(s) do
    print(s,10+x,y + h*sin((1.2*x-timer*1.4)*(3.1459/180)), c)
    -- comictext(s,x,y + h*sin((1.2*x-timer*1.4)*(3.1459/180)), c)
    x+=5
  end
end

-- Copy of wavyPrint1 without offset x.
--
-- Look, ok, this is dumb. For no reason, wavyPrint1 has 10+x as the x coord. This was prolly
-- copy pasted from somewhere without ever realizing. If I fix, it breaks some text rendering.
-- I could fix, but for now, wavyPrint2.
function wavyPrint2(s,x,y,h,c)
  for s in all(s) do
    print(s,x,y + h*sin((1.2*x-timer*1.4)*(3.1459/180)), c)
    x+=5
  end
end

function wavyPrintAll(s,x,y,h,c)
  print(s,x,y + h*sin((1.2*x-timer*1.4)*(3.1459/180)), c)
end


-- ahighscore
-- high score format
-- every 25 bytes in cartdata() is a level
-- bytes
-- 	1,2 	16-bit score (0-32767)
-- 	3,4,5	name, 3 chr
--
-- level num & score slot are 1-based
--
-- write chars with ord() (char to code)
function write_score(level_num, score, name, slot)
	-- log('writing score '..score..' '..name..' to slot '..slot)
	local base=0x5e00
	local levelStartAddr=base+25*(level_num-1)
	local slotAddr=(slot-1)*5
	poke2(levelStartAddr+slotAddr, score)
	poke(levelStartAddr+slotAddr+2, ord(name,1), ord(name,2), ord(name,3))
end

-- level num & score slot are 1-based
-- returns table of scores for level
-- { 1={name,score}, 2={name,score}, ...}
-- reads chars with chr() (code to char)
function read_scores(level_num)
	-- log('reading scores for level '..level_num)
	local base=0x5e00
	local levelStartAddr=base+25*(level_num-1)
	local highscores={}
	for i=0,4 do
		local slotAddr=5*i
		local score=peek2(levelStartAddr+slotAddr)
		local name=get_name(levelStartAddr, slotAddr)
		if name==chr(0)..chr(0)..chr(0) then
			name=''
		end
		highscores[i+1]={score=score, name=name}
	end
	return highscores
end

function get_name(levelStartAddr, slotAddr)
  return chr(peek(levelStartAddr+slotAddr+2))..chr(peek(levelStartAddr+slotAddr+3))..chr(peek(levelStartAddr+slotAddr+4))
end

-- checks if score is a high score for level num
-- if so, returns score slot it goes in
-- otherwise, returns -1
function get_high_score_slot(level_num, new_score)
	-- log('checking if '..new_score..' is a high score')
	local scores=read_scores(level_num)
	for i=1,#scores do
		local curScore=scores[i].score
		if new_score>curScore then
			-- log(new_score..' ('..curScore..') is a new high score in slot '..i)
			return i
		end
	end
	return -1
end

function insert_high_score(level_num, slot, new_score, name)
	local scores=read_scores(level_num)

	-- log('new high score name '..name..' slot '..slot..' new score '..new_score)
	add(scores, {name=name,score=new_score}, slot)

	for i=1,#scores do
		if i>5 then
			break
		end
		write_score(level_num, scores[i].score, scores[i].name, i)
	end
end

function reset_high_scores()
	for i=0,255 do
		poke(0x5e00+i, 0)
	end
end

function print1stplace(s,x,y)
	print_highlight_text(s,x,y,10,9)
end

function print2ndPlace(s,x,y)
	print_highlight_text(s,x,y,6,5)
end

function print3rdPlace(s,x,y)
	print_highlight_text(s,x,y,9,4)
end

-- c color, hc highlight color
function print_highlight_text(s,x,y,c,hc)
	print(s, x, y, c) -- color
	clip(x,y,x+4*#s,1)
	print(s, x, y, hc) -- highlight
	clip()
end

function comictext(s,x,y)
	w=4
	c=15
	for i=1,#s do
		--u
		print(s[i], x+(i-1)*w, y-1, c)
		--d
		print(s[i], x+(i-1)*w, y+1, c)
		--l
		print(s[i], x+(i-1)*w-1, y, c)
		--r
		print(s[i], x+(i-1)*w+1, y, c)

		--c
		print(s[i], x+(i-1)*w, y, 0)
	end
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
    -- rect(x,y+7*i, x+20, y+7*i, 0)
    print(i..' '..d, x+1, y+i*7, 7)
  end
  dbg={}
end

function addDebug(d)
  dbg[#dbg+1] = d
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

-->8
--util
function bits(s)
  result=''
  for i=7,0,-1 do
    result ..= s >> i & 1
  end
  return result
end

function table_key_count(t)
  c=0
  for _,_ in pairs(t) do
    c+=1
  end
  return c
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

function log10(n)
  log10_table = {
    0, 0.3, 0.475,
    0.6, 0.7, 0.775,
    0.8375, 0.9, 0.95, 1
  }

  if (n < 1) return 0
  local t = 0
  while n > 10 do
    n /= 10
    t += 1
  end
  return log10_table[flr(n)] + t
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

function dottedLine(x0, y0, x1, y1, spacing, col)
  local dx = x1 - x0
  local dy = y1 - y0
  local len = sqrt(dx*dx + dy*dy)
  local steps = flr(len / spacing)
  for i=0,steps do
    local t = i / steps
    local x = x0 + dx * t
    local y = y0 + dy * t
    pset(x, y, col)
  end
end
__gfx__
00000000077777700077000041111111000000000000000000000000000700000007000000070000000000100000000000000000000000000000000000000000
00000000711111170711700041111111000000000000000000070000000700000007000000000000010000000000000001000000000000000000000000000000
0000000071bb9b177182170041111111000000000000000000070000000700000000000000000000000000000000010000000000000000000000000000000000
00000000718898177188217044444444000000000000000000777000777777777700077770000007000010000000000000001000000000000000000000000000
00000000712888177188821711114111000000000000000000070000000700000000000000000000100000000100000000000000000000000000000000000000
000000000712817071b3b31711114111000000000000000000070000000700000007000000000000001000000000000000100000000001000000000000000000
00000000007117007111117011114111000000000000000000000000000700000007000000000000000000100000000000000010000000000000000000000000
00000000000770007777770044444444000000000000000000000000000700000007000000070000000000000000000000000000000000000000000000000000
00000000000007000b009bb012122447744221211111111111111111777777777777777772122447111111111111111111111111500000000000000000000000
000000000000717000bb900b112224477442221115212212212212517ff1221221221ff771222447101111000011110000111101500000000000000000000000
000000000007131700888800121224477442212112121121121121217f121121121121f772122447110000111100001111000011a00000000000000000000000
000000000071fa17088eee8011222447744222111122121221212211712112111121121771222447110000111100001111000011a00000000000000000000000
00000000071fa17008888e8012122447744221211211212222121121721121111112112772122447110000111100001111000011900000000000000000000000
0000000071aa170008888880112224477442221112121224422121217212111441112127712224471100001111000011110000119a0000000000000000000000
00000000071170000888888012122447744221211121224444221211712111444411121772122447101111000011110000111101a8a000000000000000000000
00000000007700000088880011222447744222111212244aa44221217211144aa441112771222447101111000011110000111101aa99aa550000000000000000
00000000000660001111111177777777111111111212244aa44221217211144aa441112774422127101111000011110000111101500000000000000000000000
00000000007117001111111144444444121212121121224444221211712111444411121774422217101111000011110000111101500000000000000000000000
00000000074f94701111111144444444212121211212122442212121721211144111212774422127110000111100001111000011a00000000000000000000000
0000000061f999161111111122222222222222221211212222121121721121111112112774422217110000111100001111000011a00000000000000000000000
0000000061999f161111111122222222222222221122121221212211712112111121121774422127110000111100001111000011900000000000000000000000
000000000749f47011111111121212124444444412121121121121217f121121121121f7744222171100001111000011110000119a0000000000000000000000
000000000071170011111111212121214444444415212212212212517ff1221221221ff774422127101111000011110000111101aca000000000000000000000
00000000000660001111111111111111777777771111111111111111777777777777777774422217101111000011110000111101aa99aa550000000000000000
00000000007777000006776000000000000000006122221617777771717777177777777766777766101111000011110000111101000000000000000000000000
000000000713b17000703b0600000000000000006024420670244207102442011024420110244201101111000011110000111101000a00000000000000000000
00000000710e8017070b400700000000000000007244442772444427724444277244442722444422110000111100001111000011000900000000000000000000
0000000071e8881770048e070000000000000000744aa447744aa447744aa447744aa447244aa442110000111100001111000011009b90000000000000000000
0000000071884a17708e88070000000000000000744aa447744aa447744aa447744aa447244aa442110000111100001111000011000900000000000000000000
000000000718a1777088000700000000000000007244442772444427724444277244442722444422110000111100001111000011000a00000000000000000000
00000000071111707000077000000000000000006024420670244207102442011024420110244201101111000011110000111101000000000000000000000000
00000000007777000777700000000000000000006122221617777771717777177777777766777766111111111111111111111111000000000000000000000000
000000000a000000000000000000000000000000000000000000000000000aa000a00000a0000000000000000000000000000000000000000000000000000000
00000000aa0000aa00000a0000aaaa000a00000000000000000aa0000000aa0000a00000a0000000000000000000000000000000000000000000000000000000
000000aa990000aa0000aa000aa000000a000000000aaaa0000aa000000aa00000a00000a0000000000000000000000000000000000000000000000000000000
00000aa9220000aaa000a0000a0000000a000000000a00a0000aa000000a000000a00000a0000000000000000000000000000000000000000000000000000000
0000aa92000000a0a000a0000a0000000a0aa000000a00aa00aa0a0000aa000000a00000a0000000000000000000000000000000000000000000000000000000
000aa920000000a0aa00a000a0aa00000aaa0000000a000a00a00a0000aaaa0000a00000a0a00000000000000000000000000000000000000000000000000000
000a920aaa0000a00aa0a000aaa000000a000000000a000a00a00aa000000aa0aaaaaaaaaaa00000000000000000000000000000000000000000000000000000
00aaaaa99aa000a000a0a000a0000000aa000000000a00aa0aaaaaaa0000aa000aa00000a0000000000000000000000000000000000000000000000000000000
00aa9992aa900a00000aa000a0000000aaaa0000000a00a00a0000a0000aa0000a000000a0000000000000000000000000000000000000000000000000000000
0099222aa9200a00000aa000a0000000a00aaaa0000a0aa00a00000a000a00000a000000a0000000000000000000000000000000000000000000000000000000
002200aa92000a000000a000a00aaa00a0000000000aaa000a00000a00aa00000a000000a0000000000000000000000000000000000000000000000000000000
00000aa92000000000000000aaaa0a00a0000000000aa0000a00000000a0000000a00000a0000000000000000000000000000000000000000000000000000000
0000aa92000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aa920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00099200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11000011110000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11000011110000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11000011110000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11000011110000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111157711577715151111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111577157571571115757111111111111111111111111111511111111111111111111111111111111111111111111
11111111111111111111111111111111111115711157571577115717111111111111111111111111111571111111111111111111111111111111111111111111
11111111111111111111111111111111111115777157571571115771111111551115551115511515111571111111111111111111111111111111111111111111
11111111111111111111111111111111111111157157571577715757111111577115151151111575711171111111111111111111111111111111111111111111
11111111111111111111111111111111111115771111111111111717111111575715777155771575711511111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111575715757117511577711171111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111575715777157771575711111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111177711717111171171711111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111717117711111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111155115151111155515551551111115551555151111551555111111111111111111111111111111111111111111
11111111111111111111111111111111111111159915959111119995999599111115999599959115199199911111111111111111111111111111111111111111
11111111111111111111111111111111111111159911999111115915991595911115999599159115959159111111111111111111111111111111111111111111
11111111111111111111111111111111111111159595519111115911951591911115959195119515919159111111111111111111111111111111111111111111
11111111111111111111111111111111111111119991991111111911199199111111919119911991991119111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
00000000000000000a888a000000000000000000a888a000000000000000000a888a000000000000000000a888a000000000000000000a888a00000000000000
15353535353535353535353535353535151515151515151515151515151515353535353535353535353535353535151515151515151515151515151515353535
51535353535353535353535353535353515151515151515151515151515151535353535353535353535353535353515151515151515151515151515151535353
15353535353535353535353535353535151515151111111111111111111111111111111111111111111111111535151515151515151515151515151515353535
51535353535353535353535353535353515151511ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff1353515151515151515151515151515151535353
15353535353535353535353535353535151515151ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff1535151515151515151515151515151515353535
51535353535353535353535353535353515151511000000000000000000000000000000000000000000000001353515151515151515151515151515151535353
15353535353535353535353535353535151515151ff0110110110110110110110110110110110110110110ff1005151515151515151515151515151515353535
51535353535353535353535353535353515151511ff0110110110110110110110110110110110110110110ff1003515151515151515151515151515151535353
15353535353535353535353535353535151515151000000000000000000000000000000000000000000000001005151515151515151515151515151515353535
51535353535353535353535353535353515151511ff0110110110110110110110110110110110110110110ff1003515151515151515151515151515151535353
15353535353535353535353535353535151515151ff0110110110110110110110110110110110110110110ff1005151515151515151515151515151515353535
51535353535353535353535353535353515151511000000000000000000000000000000000000000000000001003515151515151515151515151515151535353
15353535353535353535353535353535151515151ff0110110220220220220220220220220220220110110ff1005151515151515151515151515151515353535
51535353535353535353535353535353515151511ff0110110220220220220220220220220220220110110ff1003515151515151515151515151515151535353
15353535353535353535353535353535151515151000000000000000000000000000000000000000000000001005151515151515151515151515151515353535
51535353535353535353535353535353515151511ff0110110220220220220220220220220220220110110ff1003515151515151515151515151515151535353
15353535353535353535353535353535151515151ff0110110220220220220220220220220220220110110ff1005151515151515151515151515151515353535
51535353535353535353535353535353515151511000000000000000000000000000000000000000000000001003515151515151515151515151515151535353
15353535353535353535353535353535151515151ff0110110220220220220220220220220220220110110ff1005151515151515151515151515151515353535
51535353535353535353535353535353515151511ff0110110220220220220220220220220220220110110ff1003515151515151515151515151515151535353
15353535353535353535353535353535151515151000000000000000000000000000000000000000000000001005151515151515151515151515151515353535
53515151515151515151515151515151535353531ff0110110220220220220220220220220220220110110ff1001535353535000005353535353535353515151
35151515151515151515151515151515353535351ff0110110220220220220220220220220220220110110ff1005353535350777770535353535353535151515
53515151515151515151515151515151535353531000000000000000000000000000000000000000000000001001535353507700777053535353535353515151
35151515151515151515151515151515353535351ff0110110220220220220220220220220220220110110ff1005353535307701077035353535353535151515
53515151515151515151515151515151535353531ff0110110220220220220220220220220220220110110ff1001535353507700777053535353535353515151
35151515151515151515151515151515353535351000000000000000000000000000000000000000000000001005353535350777770535353535353535151515
53515151515151515151515151515151535353531ff0110110220220220220220220220220220220110110ff1001535353531000001353535353535353515151
35151515151515151515151515151515353535351ff0110110220220220220220220220220220220110110ff1005353535353111113535353535353535151515
53515151515151515151515151515151535353531000000000000000000000000000000000000000000000001001535353535353535353535353535353515151
35151515151515151515151515151515353535351ff0110110220220220220220220220220220220110110ff1005353535353535353535353535353535151515
53515151515151515151515151515151535353531ff0110110220220220220220220220220220220110110ff1001535353535353535353535353535353515151
35151515151515151515151515151515353535351000000000000000000000000000000000000000000000001005353535353535353535353535353535151515
53515151515151515151515151515151535353531ff0110110220220220220220220220220220220110110ff1001535353535353535353535353535353515151
35151515151515151515151515151515353535351ff0110110220220220220220220220220220220110110ff1005353535353535353535353535353535151515
53515151515151515151515151515151535353531000000000000000000000000000000000000000000000001001535353535353535353535353535353515151
35151515151515151515151515151515353535351ff0110110220220220220220220220220220220110110ff1005353535353535353535353535353535151515
53515151515151515151515151515151535353531ff0110110220220220220220220220220220220110110ff1001535353535353535353535353535353515151
35151515151515151515151515151515353535351000000000000000000000000000000000000000000000001005353535353535353535353535353535151515
53515151515151515151515151515151535353531ff0110110110110110110110110110110110110110110ff1001535353535353535353535353535353515151
35151515151515151515151515151515353535351ff0110110110110110110110110110110110110110110ff1005353535353535353535353535353535151515
53515151515151515151515151515151535353531000000000000000000000000000000000000000000000001001535353535353535353535353535353515151
35151515151515151515151515151515353535351ff0110110110110110110110110110110110110110110ff1005353535353535353535353535353535151515
53515151515151515151515151515151535353531ff0110110110110110110110110110110110110110110ff1001535353535353535353535353535353515151
35151515151515151515151515151515353535351000000000000000000000000000000000000000000000001005353535353535353535353535353535151515
53515151515151515151515151515151535353531ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff1001535353535353535353535353535353515151
35151515151515151515151515151515353535351ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff0ff1005353535353535353535353535353535151515
53515151515151515151515151515151535353531111111111111111111111111111111111111111111111111001535353535353535353535353535353515151
35151515151515151515151515151515353535353535000000000000000000000000000000000000000000000005353535353535353535353535353535151515
53515151515151515151515151515151535353535353000000000000000000000000000000000000000000000001535353535353535353535353535353515151
3515151515151515151515151515151535353535353535353535ff3f353fff15ff15ff1fff15ff15151515151515353535353535353535353535353535151515
515353535353535353535353535353535151515151515151515f00f0f1f000ff00ff00f000ff00f3535353535353515151515151515151515151515151535353
15353535353535353535353535353535151515151515151515f0fff0f5f0f0f0fff0ff3f0ff0ff35353535353535151515151515151515151515151515353535
51535353535353535353535353535353515151515151515151f0f1f0f1f000f000f000ff0ff0f353535353535353515151515151515151515151515151535353
15353535353535353535353535353535151515151515151515f0fff0fff0f0fff0fff0ff0ff0ff35353535353535151515151515151515151515151515353535
515353535353535353535353535353535151515151515151515f00f000f0f0f00ff00ff000ff00f3535353535353515151515151515151515151515151535353
1535353535353535353535353535353515151515151515151515ff1fff1f1f3ff53ff53fff35ff35353535353535151515151515151515151515151515353535
51535353535353535353535353535353515151515151515151515151515151535353535353535353535353535353515151515151515151515151515151535353
15353535353535353535353535353535151515151515151515151515151515353535353535353535353535353535151515151515151515151515151515353535
000000000000000a888a000000000000000000a888a000000000000000000a888a000000000000000000a888a000000000000000000a888a0000000000000000
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111119911111199919991991111119911999199919991111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111a111111a1a11a11a1a111111a1111a111a1a111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111a111111aaa11a11a1a111111a11aaa1aaa1aaa1111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111a111111a1111a11a1a111111a11a111a11111a1111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111aaa11111a111aaa1aaa11111aaa1aaa1aaa1aaa1111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111155511111155151115511111155515511555111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111611111611161116161111161611611616111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111166611111611161116161111166611611666111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111161111111611161116161111111611611116111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111166611111166166616661111111616661116111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111144411111444144414441111144414111411111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111911111191191119991111111919111911111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111119911111191199119191111111919991999111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111911111191191119191111111919191919111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111199911111191191119191111111919991999111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111000000000000100010001000100010001111100000011111000010001111100010001000100010000000000000000000111111111111111
11111111111111111066606660666006600660066006600660111006666601111066600660111006600660066006600660666066606660666011111111111111
11111111111111111060606060600060006000600060006000111066000660111106006060111060006000600060006000060060606060060011111111111111
11111111111111111066606600660066606660666066606660111066060660111106006060111066606660666066606660060066606600060111111111111111
11111111111111111060006060600000600060006000600060111066000660111106006060111000600060006000600060060060606060060111111111111111
11111111111111111060106060666066006600660066006600111106666600111106006600111066006600660066006600060060606060060111111111111111
11111111111111111100110000000000010001000100010001111110000001111110010001111100010001000100010001100100000000100111111111111111

__gff__
0000000100000000000000000000000000000001010101010101020202000000000002010101010101010202020000000000000000010101010102020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006060000000000000000000000000000040000000000000000000000000000000400000000000000000000000000000004000000000000000000000000000000
__map__
1524242424242424242424242424241615242424242424242424242424242416152424242424242424242424242424161524242424242424242424242424241615242424242424242424242424242416152424242424242424242424242424161524242424242424242424242424241600000000000000000000000000000000
130b0b0d0b0b0b0b0b0b0b0c0c0b0b14130b0c0c0d0c0d0d0d0c0c0c0d0c0c14130b0c0b0b0b0a0b0b0b0b0c0c0b0b14130b0b0b0b0b0b0b0b0b0b0c0d0b0b1413360b0b0b0b0b0b0b0b0b0c0c0b3614130b0c0b2a352c0b0b2a352c0c0b0b14130b0c0b0b0b0a17180b0b0c0c0b0b1400000000000000000000000000000000
131e0a0c0d1e0a0c0b0c0d0b0c0b0c14130c0c0b0c0c0d330c0c0b0c0c0d0c14131e0b0c0c1e000c0b000c0b0c0b0c14131e0d0c0c0d0a0d0b0c0c0d0c0b0c14131e361b1b1b1b1b1b1b1b1b1b360c14131e0b0c2a352c0c0b2a352c0c0b0c14131e0b0c0c1e002728000c0b0c0b0c1400000000000000000000000000000000
130c0c0c0b0c0c0d0c0c0c0c0c0c0c1413330c0c360c0c0a0b0c0c360c0c3314130c0c0c0b0d00000b000c000c0c0c14130c0c1a1b1b1b1b1b1b1b1b1c0c0c14130d2a360b0c0b0b0b0c0c0c362c0c14130c0c0c2a352c000b2a352c0c0c0c14130c0c0c0b0d003838000c000c0c0c1400000000000000000000000000000000
130c0d1a1b1b1c0c1e1a1b1b1c000c14130c0c0c1a1b1b36361b1b1c0c0c0c14130c000000000000000000000d000c14130c002a2b2b2b2b2b2b2b2b2c000c14130c2a0b361b1b1b1b1b1b360c2c0c14130cd0002a352cd0002a352c0dd00c14130c000000000017180000000d000c1400000000000000000000000000000000
131e0b2a17182b1b1b2b17182c0a0b14130c361a2b2b2b2b2b2b2b2b1c360c14131e00000000d000d000d00000000b14131e0b2a2b2b2b2b2b2b2b2b2c0a0b14131e2a0b2a360b0cf000362c0b2c0d14131e00002a352c00002a352c00000b14131e0000000000272800000000000b1400000000000000000000000000000000
130c0b2a19292b2b2b2b19292c0d0c14130c0b2a2b2b2b2b2b2b2b2b2c0c0d14131b1b1b1b1b1b1b1b1b1b1b1b1b1b14130c0b2a2b2b2b2b2b2b2b2b2c0c0c14130c2a0c2a0b361b1b360b2c0c2c0c14131b1b1b3b353b1b1b3b353b1b1b1b14131b1b1b1b1b1b14131b1b1b1b1b1b1400000000000000000000000000000000
130b0a2a19292b2b2b2b19292c0b1e14130b0c362b2b2b36362b2b2b360d0c1413393939393939393939393939393914130b0a2a2b2b2b2b2b2b2b2b2c0b1e14130b2a0c2a0b2a39392c0b2c0b2c1e1413393939393939393939353939393914132b2bc0c02b2b38382b2bc0c02b2b1400000000000000000000000000000000
130b002a19292b2b2b2b19292c0b0c14130c332a2bc12b2b2b2bc12b2c0c0b14133b3b3b3b3b3b3b3b3b3b3b3b3b3b14130b002a2b2b2b2b2b2b2b2b2c0b0c14130b2ae02a0b363b3b360c2ce02c0c14133b3b3b2b352b3b3b2b352b3b3b3b14133b3b3b3b3b3b14133b3b3b3b3b3b1400000000000000000000000000000000
130c0a2a27282b3b3b2b27282c000b14130d363a2bc12b2b2b2bc12b3c360c14130c0000000000000000000000000b14130c0a2a2b2b2b2b2b2b2b2b2c000b14130c2a0b2a360c0c0b0b362c0c2c0b14130c00002a352c00002a352c00000b14130c0000000000171800000000000b1400000000000000000000000000000000
130c0c3a3b3b3c0a0c3a3b3b3c0c0c14130c0d0c3a3b3b36363b3b3c0c0c0a14130c00000d1e0000000000000b000c14130d0c2a2b2b2b2b2b2b2b2b2c0c0c14130c2a0b363b3b3b3b3b3b360b2c0c14130c001e2a352c00002a352c0b000c14130c00000d1e0027280000000b000c1400000000000000000000000000000000
130b0b0c0a0b0c1e0c1e1e0c0b0c0c14130c0b0c360c0b0a0b330c360c0d0c14130b0b0c000b0c1e0c1e1e0c0b0c0c14130b0b3a3b3b3b3b3b3b3b3b3c0c0c14130b2a360b0b0cf0000c000c362c0c14130bd00c2a352c1ed02a352c0bd00c14130b0b0c000b0c38381e1e0c0b0c0c1400000000000000000000000000000000
130b0c0b0a0c0d0c0c0c0b0c0a0d0c14130b0b0b0c0c0d0d0c0c0c0c0d0d0b14130b0c0b0ae00c0cf00ce00c0a0c0c14130b0c0b0d0c0c0d0c0c0b0c0a0c0d14130b363b3b3b3b3b3b3b3b3b3b360d14130b0c0b2a352c0c002a352c0a0c0c14130b0c0b0a0c0c17180c0b0c0a0c0c1400000000000000000000000000000000
131e0c0c0c0b0c0a0b0b0a0b0d0b0c14130c0c0c0c0b0c0b0b0c0b0b0c0b0c14131e0c0c0c0b0c0a0b0b0a0b0c000c14131e0c0c0c0b0c0a0d0b0a0b0c0b0c1413360c0c0c0b0c0d0b0b0a0b0c0b3614131e0c0c2a352c0a0b2a352c0c000c14131e0c0c0c0b0c27280b0a0b0c000c1400000000000000000000000000000000
2523232323232323232323232323232625232323232323232323232323232326252323232323232323232323232323262523232323232323232323232323232625232323232323232323232323232326252323232323232323232323232323262523232323232323232323232323232600000000000000000000000000000000
1524242424242424242424242424241615242424242424242424242424242416000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
132b2b2b2b2b2b2b2b2b2b2b2b2b2b14131a1b1c35000000000000351a1b1c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
132b2b2b2b2b2b2b2b2b2b2b2b2b2b14132a2b2c35000000000000352a2b2c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
132b2b2b2b2b2b2b2b2b2b2b2b2b2b14133a3b3c39393939393939353a3b3c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13393900393939393939393939393914133939393537361a1c36373539393914000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13000000000d000c000000000d0000141300000035361a2b2b1c363500000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13000a0000000c00000d0000000a001413000000351a2b2b2b2b1c3500000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1339393939393939393939003939391413000000352a2b2b2b2b2c3500000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13000c000000000000000a000000001413000000353a2b2b2b2b3c3500000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130000000a00000d000000000c000d141300000035363a2b2b3c363500000014000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13393939393900393939393939390014133939393537363a3c36373539393914000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
132b2b2b2b2bc02b2b2b2b2b2b2b2b14131a1b1c35393939393939391a1b1c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
132b2b2b2b2b2b2b2b2b2b2b2b2b2b14132a2b2c35000000000000352a2b2c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
132b2b2b2b2b2b2b2b2b2b2b2b2b2b14133a3b3c35000000000000353a3b3c14000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2523232323232323232323232323232625232323232323232323232323232326000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000037670396703b6703b6703c6703c6703b67039670376703667033670306702d6702a6702867023670216701f6701e6701c6701a67015670106700d6700867004670036700367009670096700a67009670
001100001f4701847018070184701f0701f4701a0701a0701c470210701c4701d4701d47023470244701f4701f4701d4701c4701a47018470184701a4701f4702157021470215702347023470242702427024270
0002000023050350501a05009020170102d0102105017050100500d050000501b3002930037300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000180701a070180701a07021070180001f0701d0701c0701c07018070180701807018070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000024040200402007020070200701f0701f0701f0701f0701f0701f0601f0601f0601e0601e0601e06000060000600007000000000000000000000000000000000000000000000000000000000000000000
0103000018175181753017537175186401d640186301a6201d600040000200002000020000200002000020000100006000130001300011000100000e0000c0000b0000b0000c0000b0000a0000a0000a0000a000
000200002455012030240002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002f05036040240002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001b05016000000002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000004400144007330103301b330273303d45002400004003850007200032000320003200032000320003200112000520005200052000a2000b2002b4000000000000000000000000000000000000000000
000300001c45028450364501c4200c4101a4102e450234501945012450104501b3002930037300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002a55012030240002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200002255010030240002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000285500f030240002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0002000004650026500575004750037200271001710017100a6000e600096000560004600086000a60009600027000170001700017000170000700007002b0002f00032000300002b00029000230001e0001b000
00030000156500a750007500465003650036500264002640026400264002640026400274003640017400173002630026300163001630016200162001620016200172001620016200161001610006000061000600
00010000245502e5502d5000050024500276002640021400244002240000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000195502e550045500440002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003c750097503a7500d75033750117502c750157502675019750227501b750207501e7501d750207502075020750207502075020750207502075020750207500d4000f40013400114000f4000f4000f400
__music__
00 41424344
00 01424344
00 41424344
00 41420344

