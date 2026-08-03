pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- Organic Wave Generator
-- Demonstrates summing sine waves for random-like fluctuation

-- Configuration
local num_waves = 5
local base_speed = 0.03
local threshold = 2.2 -- Trigger event when sum > this value
local waves = {}
local particles = {}

function _init()
  -- Initialize waves with random phases and prime-based frequencies
  for i = 1, num_waves do
    add(waves, {
      freq = (i * 0.7) + 0.3, -- Non-integer multipliers prevent looping
      phase = rnd(1),         -- Random start position (0 to 1 in PICO-8 sin)
      amp = 0.5 + rnd(0.5),   -- Random amplitude contribution
      col = i + 1             -- Color for visualization
    })
  end
end

function _update()
  -- Update particles (visual effect for triggers)
  for p in all(particles) do
    p.x += p.dx
    p.y += p.dy
    p.life -= 1
  end
  -- Remove dead particles
  if #particles > 0 and particles[1].life <= 0 then
    del(particles, particles[1])
  end

  -- Calculate current wave value
  local t = time()
  local sum_val = 0

  for w in all(waves) do
    -- PICO-8 sin() takes 0..1 as a full circle
    local val = sin((t * base_speed * w.freq) + w.phase)
    sum_val += val * w.amp
  end

  -- Normalize roughly to -2..2 range depending on amp sum
  -- Trigger event if wave peaks high enough and we don't have too many particles
  if sum_val > threshold and #particles < 20 then
    add(particles, {
      x = 64,
      y = 64 - (sum_val * 20), -- Spawn at wave height
      dx = -1 + rnd(2),
      dy = -1 + rnd(2),
      life = 30,
      col = 7
    })
  end
end

function _draw()
  cls(1) -- Dark blue background
  local t = time()
  local center_y = 64
  local scale = 20

  -- Draw Threshold Line
  line(0, center_y - (threshold * scale), 127, center_y - (threshold * scale), 6)
  print("TRIGGER ZONE", 2, center_y - (threshold * scale) - 6, 6)

  -- 1. Draw Individual Component Waves (Faint)
  for w in all(waves) do
    for x = 0, 127 do
      local val = sin(((x * 0.01) + (t * base_speed * w.freq)) + w.phase)
      local py = center_y - (val * w.amp * scale)
      pset(x, py, w.col + 8) -- Darker colors for components
    end
  end

  -- 2. Draw The Summed "Organic" Wave (Bright)
  for x = 0, 126 do
    local sum1 = 0
    local sum2 = 0

    -- Calculate sum for current pixel and next pixel (for line)
    for w in all(waves) do
      local t1 = (x * 0.01) + (t * base_speed * w.freq)
      local t2 = ((x + 1) * 0.01) + (t * base_speed * w.freq)

      sum1 += sin(t1 + w.phase) * w.amp
      sum2 += sin(t2 + w.phase) * w.amp
    end

    local y1 = center_y - (sum1 * scale)
    local y2 = center_y - (sum2 * scale)

    line(x, y1, x + 1, y2, 7) -- Bright white line
  end

  -- 3. Draw Trigger Particles
  for p in all(particles) do
    circfill(p.x, p.y, 2, p.col)
  end

  -- Stats
  print("WAVES: " .. num_waves, 2, 2, 7)
  print("SUMMING SINES FOR ORGANIC NOISE", 2, 10, 7)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
