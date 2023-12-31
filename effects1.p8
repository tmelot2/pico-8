pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

PI = 3.14159265359
BLACK = 0
WHITE = 7

function _init()
  tick = 0
end

-- game loop
function _update()
  tick += 1
end

function _draw()
  cls(2)
  drawDebug()

  wavyLine(6, 58, 17, 10)
  wavyLine(6, 58, 18, 10)
  wavyLine(6, 58, 19, 10)
  wavyLine(6, 58, 20, 10)
  wavyLine(6, 58, 21, 10)
  wavyLine(6, 58, 22, 10)
  wavyLine(6, 58, 23, 10)
  wavyLine(6, 58, 24, 10)
  wavyLine(6, 58, 25, 10)
  wavyLine(6, 58, 26, 10)
  wavyText('hello MARLOWE!', 5, 20, 10)
  wavyLine(6, 58, 27, 10)
  


  wavyLine(7, 100, 58, 10)
  wavyLine(7, 100, 58, 10)
  wavyLine(7, 100, 59, 10)
end

function drawDebug()
  print(tick, 0, 0)
end

function toRads(d)
  return d * PI/180
end

function comicText(s, x, y, col)
  color(BLACK)
  print(s,x,y-1)  
  print(s,x,y+1)  
  print(s,x-1,y)  
  print(s,x+1,y)  
  print(s,x,y,col)  
end

function wavyText(s, x, y, height, col)
  for i=1,#s do
    local y = y + height * sin(toRads(i - tick))
    comicText(s[i], x + 4*i, y, i-tick/4)
  end
end

function wavyLine(x, x2, y, height)
  len = 4/4
  for i=1,x2 do
    local y = y + height * sin(toRads(1/4*i - tick))
    c = y%4 + 8
    pset(x+len*i,y,c)
    -- pset(x+1+len*i,y,tick)
    -- pset(x+2+len*i,y,tick)
    -- pset(x+3+len*i,y,tick)
    -- pset(x+4+len*i,y,tick)
    -- pset(x+5+len*i,y,tick)
  end
end


-->8

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
