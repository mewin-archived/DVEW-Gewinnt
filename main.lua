local field = {}
local field_p = {}
local FIELD_W, FIELD_H = 15, 9
local COLOR_GREEN = "\27[0;32m"
local COLOR_RED = "\27[0;31m"
local COLOR_RESET = "\27[0;m"
local COLOR_GRAY = "\27[1;35m"
local ANIM_PAUSE = 200
local cursor = -1
local sign = "D"
local done = false
local player = 0
local preview = true

for x = 0,FIELD_W - 1 do
  field[x] = {}
  field_p[x] = {}
  for y = 0,FIELD_H - 1 do
   field[x][y] = " "
   field_p[x][y] = -1
  end
end

function printField()
  os.execute("clear")
  for x = -1,FIELD_W - 1 do
    io.write(cursor == x and sign or " ")
  end
  print()
  for x = -1,FIELD_W - 1 do
    io.write(cursor == x and "V" or " ")
  end
  print()
  for y = 0,FIELD_H - 1 do
    io.write("|")
    for x = 0,FIELD_W - 1 do
      local _sign = field[x][y]
      if field_p[x][y] == 0 then io.write(COLOR_RED)
      elseif field_p[x][y] == 1 then io.write(COLOR_GREEN)
      elseif preview and x == cursor and 
              (y == FIELD_H - 1 or field_p[x][y + 1] ~= -1) then
        io.write(COLOR_GRAY)
        _sign = sign
      end
      io.write(_sign)
      io.write(COLOR_RESET)
    end
    print("|")
  end
end

function printHelp()
  print("Commands: help, exit, p(lace), r(ight), l(eft), D, V, E, W")
  readCmd()
end

function nextPlayer()
  player = 1 - player
end

function sleep(ms)
  os.execute("sleep " .. 0.001 * ms)
end

function anim_place(tX, tY, y)
  field_p[tX][y] = player
  field[tX][y] = sign
  preview = false
  printField()
  preview = true
  sleep(ANIM_PAUSE)
  if tY == y then return end
  field_p[tX][y] = -1
  field[tX][y] = " "
  anim_place(tX, tY, y + 1)
end

function place()
  if cursor < 0 then
    print("Please move above field.")
    readCmd()
    return
  end
  for i = FIELD_H-1,0,-1 do
    if field[cursor][i] == " " then
      -- field[cursor][i] = sign
      -- field_p[cursor][i] = player
      anim_place(cursor, i, 0)
      nextPlayer()
      return
    end
  end
  print("Column full!")
  readCmd()
end

function readCmd()
  local cmd
  io.write("Player " .. player .. "> ")
  cmd = io.read()

  if cmd == "help" then printHelp()
  elseif cmd == "exit" then done = true
  elseif cmd == "d" or cmd == "D" then sign = "D"
  elseif cmd == "v" or cmd == "V" then sign = "V"
  elseif cmd == "e" or cmd == "E" then sign = "E"
  elseif cmd == "w" or cmd == "W" then sign = "W"
  elseif cmd == "l" or cmd == "L" or cmd == "left" or cmd == "LEFT" then cursor = cursor < 0 and cursor or cursor - 1
  elseif cmd == "r" or cmd == "R" or cmd == "right" or cmd == "RIGHT" then cursor = cursor >= FIELD_W - 1 and cursor or cursor + 1
  elseif cmd == "p" or cmd == "P" or cmd == "place" or cmd == "PLACE" then place()
  else
    print("Unknown command: " .. cmd)
    readCmd()
  end
end

function checkWin(x, y, p, txt, dir)
  local text = txt or "DVEW"

  if x < 0 or y < 0 or p < 0 then
    for _p = 0, 1 do
      for _x = 0, FIELD_W - 1 do
        for _y = 0, FIELD_H - 1 do
          if checkWin(_x, _y, _p) then
            print("Player " .. _p .. " wins.")
            done = true
            return
          end
        end
      end
    end
    return
  end

  if field_p[x][y] ~= p or field[x][y] ~= text:sub(1, 1) then
    return false
  end

  if not dir then
    if checkWin(x, y, p, text, "N") then return true end
    if checkWin(x, y, p, text, "E") then return true end
    if checkWin(x, y, p, text, "S") then return true end
    -- if checkWin(x, y, p, text, "W") then return true end
    if checkWin(x, y, p, text, "NE") then return true end
    if checkWin(x, y, p, text, "SE") then return true end
    if checkWin(x, y, p, text, "SW") then return true end
    if checkWin(x, y, p, text, "NW") then return true end
    return false
  end

  if text:len() == 1 then
    return true
  end

  local nX, nY = x, y
  if dir:find("N") then
    if nY < 1 then return false end
    nY = nY - 1
  end
  if dir:find("S") then
    if nY >= FIELD_H - 1 then return false end
    nY = nY + 1
  end
  if dir:find("E") then
    if nX >= FIELD_W - 1 then return false end
    nX = nX + 1
  end
  if dir:find("W") then
    if nX < 1 then return false end
    nX = nX - 1
  end

  return checkWin(nX, nY, p, text:sub(2), dir)
end

function checkWin_old()
  local p = 1
  local win = -1
  for player = 0,1 do
    for x = 0, FIELD_W - 1 do -- spalten
      for y = 0, FIELD_H - 1 do -- oben nach uten
        if field_p[x][y] == player
          and field[x][y] == string.sub("DVEW", p, p) then
          p = p + 1
          if p > 4 then win = player end
        else
          p = 1
        end
      end
      p = 1
      for y = FIELD_H - 1, 0, -1 do -- unten nach oben
        if field_p[x][y] == player
          and field[x][y] == string.sub("DVEW", p, p) then
          p = p + 1
          if p > 4 then win = player end
        else
          p = 1
        end        
      end
    end
    p = 1
    for y = 0, FIELD_H - 1 do -- zeilen
      for x = 0, FIELD_W - 1 do -- links nach rechts
        if field_p[x][y] == player
          and field[x][y] == string.sub("DVEW", p, p) then
          p = p + 1
          if p > 4 then win = player end
        else
          p = 1
        end
      end
      p = 1
      for x = FIELD_W - 1, 0, -1 do -- recht nach links
        if field_p[x][y] == player
          and field[x][y] == string.sub("DVEW", p, p) then
          p = p + 1
          if p > 4 then win = player end
        else
          p = 1
        end
      end
    end
  end
  if win >= 0 then
    print("Player " .. win .. " wins.")
    done = true
  end
end

while not done do
  printField()
  checkWin(-1, -1, -1)
  if not done then readCmd() end
end
