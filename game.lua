function parseRoom(filename)
    local legend = {}
    legend[" "] = "empty"
    legend["#"] = "wall"
    legend["="] = "window"
    legend["^"] = "door_top"
    legend[">"] = "door_right"
    legend["v"] = "door_bottom"
    legend["<"] = "door_left"
    legend["."] = "floor"

    local room = {}
    room.floor = {}
    room.horizontal = {}
    room.vertical = {}
    room.doorX = {}
    room.doorY = {}
    room.name = string.match(string.match(filename, "[^/]+.txt"), "[^/.]+"):sub(4):gsub("_", " ")
    room.solved = false
    room.story = {}
    room.won = {}

    for i = 1,101 do
        room.floor[i] = {}
        room.horizontal[i] = {}
        room.vertical[i] = {}

        for j = 1,101 do
            room.floor[i][j] = "empty"
            room.horizontal[i][j] = "empty"
            room.vertical[i][j] = "empty"
        end
    end

    local f = love.filesystem.newFile(filename)
    f:open("r")

    local horizontal = true
    local lineNr = 1

    room.objects = {}
    local x = 13
    local y = 1

    local phase = 1

    for line in f:lines() do
        --local line = f:read()
        --if line == nil then noObjectList() end

        if phase == 1 then
            if line == "---" then
                phase = 2
            else
                if horizontal then
                    for i = 2, #line, 2 do
                        local c = line:sub(i,i)
                        room.horizontal[i/2][1+(lineNr-1)/2] = legend[c]
                    end
                else
                    for i = 1, #line, 2 do
                        local c = line:sub(i,i)
                        room.vertical[1+(i-1)/2][lineNr/2] = legend[c]
                    end
                    for i = 2, #line, 2 do
                        local c = line:sub(i,i)
                        room.floor[i/2][lineNr/2] = legend[c]
                    end
                end
                horizontal = not horizontal
                lineNr = lineNr+1
            end
        elseif phase == 2 then
            if line == "---" or line == nil  then
                phase = 3
            else
                amount, what = string.match(line, "([0-9]+) (.+)")

                for j = 1, tonumber(amount) do
                    local o = {what = what, x = x, y = y, r = 2, errorStr = {}, allX = {}, allY = {}, wallHorX = {}, wallHorY = {}, wallVerX = {}, wallVerY = {} }
                    if o.what == "bed" then
                        o.r = 1
                    end
                    table.insert(room.objects, o)
                end

                y = y+2
                if y > 7 then
                    y = 1
                    x = x+4
                end
            end
        elseif phase == 3 then
           if line == nil or line == "---" then
               phase = 4
           else
               table.insert(room.story, line)
           end
        elseif phase == 4 then
           if line == nil or line == "---" then
               break
           else
               table.insert(room.won, line)
           end
        end
    end

    return room
end

function expandObject(obj)
    obj.x = round(obj.x)
    obj.y = round(obj.y)
    obj.allX = {} obj.allY = {} obj.wallHorX = {} obj.wallHorY = {} obj.wallVerX = {} obj.wallVerY = {}
    table.insert(obj.allX, obj.x) table.insert(obj.allY, obj.y)
    if obj.what == "bed" then
        if obj.r == 0 then
            table.insert(obj.allX, obj.x) table.insert(obj.allX, obj.x+1) table.insert(obj.allX, obj.x+1)
            table.insert(obj.allY, obj.y+1) table.insert(obj.allY, obj.y) table.insert(obj.allY, obj.y+1)
            table.insert(obj.wallHorX, obj.x) table.insert(obj.wallHorX, obj.x+1)
            table.insert(obj.wallHorY, obj.y+1) table.insert(obj.wallHorY, obj.y+1)
            table.insert(obj.wallVerX, obj.x+1) table.insert(obj.wallVerX, obj.x+1)
            table.insert(obj.wallVerY, obj.y) table.insert(obj.wallVerY, obj.y+1)
        elseif obj.r == 1 then
            table.insert(obj.allX, obj.x) table.insert(obj.allX, obj.x-1) table.insert(obj.allX, obj.x-1)
            table.insert(obj.allY, obj.y+1) table.insert(obj.allY, obj.y) table.insert(obj.allY, obj.y+1)
            table.insert(obj.wallHorX, obj.x) table.insert(obj.wallHorX, obj.x-1)
            table.insert(obj.wallHorY, obj.y+1) table.insert(obj.wallHorY, obj.y+1)
            table.insert(obj.wallVerX, obj.x) table.insert(obj.wallVerX, obj.x)
            table.insert(obj.wallVerY, obj.y) table.insert(obj.wallVerY, obj.y+1)
        elseif obj.r == 2 then
            table.insert(obj.allX, obj.x) table.insert(obj.allX, obj.x-1) table.insert(obj.allX, obj.x-1)
            table.insert(obj.allY, obj.y-1) table.insert(obj.allY, obj.y) table.insert(obj.allY, obj.y-1)
            table.insert(obj.wallHorX, obj.x) table.insert(obj.wallHorX, obj.x-1)
            table.insert(obj.wallHorY, obj.y) table.insert(obj.wallHorY, obj.y)
            table.insert(obj.wallVerX, obj.x) table.insert(obj.wallVerX, obj.x)
            table.insert(obj.wallVerY, obj.y) table.insert(obj.wallVerY, obj.y-1)
        elseif obj.r == 3 then
            table.insert(obj.allX, obj.x) table.insert(obj.allX, obj.x+1) table.insert(obj.allX, obj.x+1)
            table.insert(obj.allY, obj.y-1) table.insert(obj.allY, obj.y) table.insert(obj.allY, obj.y-1)
            table.insert(obj.wallHorX, obj.x) table.insert(obj.wallHorX, obj.x+1)
            table.insert(obj.wallHorY, obj.y) table.insert(obj.wallHorY, obj.y)
            table.insert(obj.wallVerX, obj.x+1) table.insert(obj.wallVerX, obj.x+1)
            table.insert(obj.wallVerY, obj.y) table.insert(obj.wallVerY, obj.y-1)
        end
    elseif obj.what == "shelf" or obj.what == "couch" or obj.what == "desk" then
        if obj.r == 0 then
            table.insert(obj.allX, obj.x+1);
            table.insert(obj.allY, obj.y);
            table.insert(obj.wallVerX, obj.x+1);
            table.insert(obj.wallVerY, obj.y);
        elseif obj.r == 1 then
            table.insert(obj.allX, obj.x);
            table.insert(obj.allY, obj.y+1);
            table.insert(obj.wallHorX, obj.x);
            table.insert(obj.wallHorY, obj.y+1);
        elseif obj.r == 2 then
            table.insert(obj.allX, obj.x-1);
            table.insert(obj.allY, obj.y);
            table.insert(obj.wallVerX, obj.x);
            table.insert(obj.wallVerY, obj.y);
        elseif obj.r == 3 then
            table.insert(obj.allX, obj.x);
            table.insert(obj.allY, obj.y-1);
            table.insert(obj.wallHorX, obj.x);
            table.insert(obj.wallHorY, obj.y);
        end
    end
end

function loadRoom(i)
    currentRoom = i
    room = rooms[i]
    objects = room.objects
    checkRules()
end

function drawRoom()
    room.doorX = {}
    room.doorY = {}
    for x = 1,100 do
        for y = 1,100 do
            love.graphics.setColor(255, 255, 255)
            if room.floor[x][y] == "floor" then
                love.graphics.draw(images.parquet, tilesize*x, tilesize*y, 0)
            end

            love.graphics.setColor(255, 255, 255)
            local top = room.horizontal[x][y]
            if top == "wall" then
                love.graphics.draw(images.wall, tilesize*x, tilesize*y+1, -math.pi/2)
            elseif top == "window" then
                love.graphics.draw(images.window, tilesize*x, tilesize*y+1, -math.pi/2)
            elseif top == "door_top" then
                love.graphics.draw(images.door, tilesize*x, tilesize*(y-1), 0) 
                table.insert(room.doorX, x);
                table.insert(room.doorY, y-1);
            elseif top == "door_bottom" then
                love.graphics.draw(images.door, tilesize*(x+1), tilesize*(y+1), math.pi)
                table.insert(room.doorX, x);
                table.insert(room.doorY, y);
            end

            love.graphics.setColor(255, 255, 255)
            local left = room.vertical[x][y]
            if left == "wall" then
                love.graphics.draw(images.wall, tilesize*x-1, tilesize*y, 0)
            elseif left == "window" then
                love.graphics.draw(images.window, tilesize*x-1, tilesize*y, 0)
            elseif left == "door_right" then
                love.graphics.draw(images.door, tilesize*(x+1), tilesize*(y), -3*math.pi/2)
                table.insert(room.doorX, x);
                table.insert(room.doorY, y);
            elseif left == "door_left" then
                love.graphics.draw(images.door, tilesize*(x-1), tilesize*(y+1), -math.pi/2)
                table.insert(room.doorX, x-1);
                table.insert(room.doorY, y);
            end
        end
    end
end

function drawDebug()
    for x = 1,100 do
        for y = 1,100 do
            if occupied(x, y) then
                love.graphics.setColor(0, 0, 255)
                love.graphics.circle("fill", tilesize*(x+0.5), tilesize*(y+0.5), tilesize/10)
            end
        end
    end
end

function drawObject(object)
    local what = object.what
    local x = object.x
    local y = object.y
    local r = object.r

    love.graphics.push()
    love.graphics.translate(tilesize*(x+0.5), tilesize*(y+0.5))
    love.graphics.rotate(r/2*math.pi)

    if object.dirty then
        love.graphics.setColor(255, 0, 0)
    else
        love.graphics.setColor(255, 255, 255)
    end

    if what == "plant" then
        love.graphics.draw(images.plant, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "armchair" then
        love.graphics.draw(images.armchair, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "officechair" then
        love.graphics.draw(images.officechair, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "table" then
        love.graphics.draw(images.couchtable, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "shelf" then
        love.graphics.draw(images.bookshelf, 3*tilesize/2, -tilesize/2, math.pi/2)
    elseif what == "couch" then
        love.graphics.draw(images.couch, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "desk" then
        love.graphics.draw(images.desk, -tilesize/2, tilesize/2, -math.pi/2)
    elseif what == "bed" then
        love.graphics.draw(images.bed, -tilesize/2, 3*tilesize/2, -math.pi/2)
    else
        unknownObjectType()
    end
    love.graphics.pop()
end

function isInTable(tableX, tableY, x, y)
    for i=1, #tableX do
        if tableX[i] == x and tableY[i] == y then 
            return true
        end
    end

    return false
end

function neighborybility(posX, posY)
    accessibleNeighbors = {}
    accessX = {}
    accessY = {}

    -- left
    if posX > 1 then
        
        if accessible(posX-1, posY) and room.vertical[posX][posY] ~= "window" and room.vertical[posX][posY] ~= "wall" then
            --nopeTest = "WOOT"
            table.insert(accessX, posX-1)
            table.insert(accessY, posY)
        end
    end
    -- right
    if posX < 100 then
        if accessible(posX+1, posY) and room.vertical[posX+1][posY] ~= "window" and room.vertical[posX+1][posY] ~= "wall" then
            table.insert(accessX, posX+1)
            table.insert(accessY, posY)
        end
    end
    -- top
    if posY > 1 then
        if accessible(posX, posY-1) and room.horizontal[posX][posY] ~= "window" and room.horizontal[posX][posY] ~= "wall" then
            table.insert(accessX, posX)
            table.insert(accessY, posY-1)
        end
    end
    -- bottom
    if posY < 100 then
        if accessible(posX, posY+1) and room.horizontal[posX][posY+1] ~= "window" and room.horizontal[posX][posY+1] ~= "wall" then
            table.insert(accessX, posX)
            table.insert(accessY, posY+1)
        end
    end


    table.insert(accessibleNeighbors, accessX)
    table.insert(accessibleNeighbors, accessY)
    return accessibleNeighbors
end

function doorybility(startx, starty)
    local toCheckX = {}
    local toCheckY = {}

    local accessiblePoints = {}
    local accessibleX = {}
    local accessibleY = {}

    if(accessible(startx, starty)) then
        table.insert(toCheckX, startx)
        table.insert(toCheckY, starty)
        table.insert(accessibleX, startx)
        table.insert(accessibleY, starty)
    end

    while #toCheckX > 0 do
        local testX = table.remove(toCheckX)
        local testY = table.remove(toCheckY)
        ins = neighborybility(testX, testY)
        --nopeText = "neee "..#ins[1].." "..testX.." "..testY..""

        for i=1, #ins[1] do
            if not isInTable(accessibleX, accessibleY, ins[1][i], ins[2][i]) then
                table.insert(accessibleX, ins[1][i])
                table.insert(accessibleY, ins[2][i])
                table.insert(toCheckX, ins[1][i])
                table.insert(toCheckY, ins[2][i])
            end
        end
    end

    table.insert(accessiblePoints, accessibleX)
    table.insert(accessiblePoints, accessibleY)
    return accessiblePoints
end


function checkRules()
    local solved = true
    -- nopeText = ""

    local accessibleX = {}
    local accessibleY = {}
    local ac = {}
    
    for i=1, #room.doorX do
        ac = doorybility(room.doorX[i], room.doorY[i]);
        table.insert(accessibleX, ac[1])
        table.insert(accessibleY, ac[2])
    end

    allVisibleX = {}
    allVisibleY = {}

    --nopeText = "ABC "..#allVisibleX.." "..#ac.." "..#accessibleX.." "..#doorybility(room.doorX[1], room.doorY[1])[1]..""
    local allVis = true
    if #accessibleX > 0 then
        for i=1, #accessibleX[1] do
            for j=2, #accessibleX do
                if not isInTable(accessibleX[j], accessibleY[j], accessibleX[1][i], accessibleY[1][i]) then
                    allVis = false
                    break
                end
            end
            if allVis == true then
                table.insert(allVisibleX, accessibleX[1][i])
                table.insert(allVisibleY, accessibleY[1][i])
            end
        end
    end
    nopeText = "ABC "..#allVisibleX..""


    for i=1,#objects do
        objects[i].errorStr = {}
        if objects[i].x < 11 then
            objects[i].dirty = not allowed(objects[i])
        else
            solved = false
            objects[i].dirty = false
        end
        if objects[i].x < 1 or objects[i].y < 1 then
            objects[i].dirty = true
            table.insert(objects[i].errorStr, "All objects must be inside of the room.")
        end
    end
    
    wallypied()

    y = 0
    for x = 0,99 do
        what = occupied(x,y)
        if what then
            for i=1,#what do
                what[i].dirty = true
                table.insert(what[i].errorStr,"All objects must be inside of the room.")
            end
        end
        what = occupied(y,x)
        if what then
            for i=1,#what do
                what[i].dirty = true
                table.insert(what[i].errorStr,"All objects must be inside of the room.")
            end
        end
    end
    y = -1
    for x = 0,99 do
        what = occupied(x,y)
        if what then
            for i=1,#what do
                what[i].dirty = true
                table.insert(what[i].errorStr,"All objects must be inside of the room.")
            end
        end
        what = occupied(y,x)
        if what then
            for i=1,#what do
                what[i].dirty = true
                table.insert(what[i].errorStr,"All objects must be inside of the room.")
            end
        end
    end

    for x = 1,11 do
        for y = 1,99 do
            what = occupied(x,y)
            if what then
                if (doorypied(x,y)) then
                    for i=1,#what do
                        what[i].dirty = true
                        table.insert(what[i].errorStr,"Door needs to be accessible.")
                    end
                end
                if (windowypied(x,y)) then
                    for i=1,#what do
                        if what[i].what == "shelf" then
                            what[i].dirty = true
                            table.insert(what[i].errorStr,"Shelf must not block the window.")
                        end
                    end
                end
                if (#what > 1 and room.floor[x][y] == "floor") then
                    for i=1,#what do
                        what[i].dirty = true
                        table.insert(what[i].errorStr,"Objects must not overlap.")
                    end
                else
                if room.floor[x][y] == "empty" then
                  for i=1,#what do
                    what[i].dirty = true
                    table.insert(what[i].errorStr,"All objects must be inside of the room.")
                  end
                end
                    -- TODO: degenerate walls
                end
            end
        end
    end

    for i=1,#objects do
        local n = objects[i].errorStr
        if #n > 0 then
            solved = false
        end
    end
    if solved then
        if (not room.solved) and not love.mouse.isDown(1) then
            soundtrack:setVolume(0.2)
            room.solved = true
            love.audio.play(sounds.win)
        end
    end
end

function occupies(object, x, y)
    local what = object.what
    local ox = round(object.x)
    local oy = round(object.y)
    local r = object.r

    if what == "plant" or what == "armchair" or what == "officechair" or what == "table"  then
        return ox == x and oy == y
    elseif what == "shelf" or what == "couch" or what == "desk" then
        return (x == ox and y == oy) or
            (r == 0 and x == ox+1 and y == oy) or
            (r == 1 and x == ox and y == oy+1) or
            (r == 2 and x == ox-1 and y == oy) or
            (r == 3 and x == ox and y == oy-1)
    elseif what == "bed" then
        if r == 0 then
            return x >= ox and x <= ox+1 and y >= oy and y <= oy+1
        elseif r == 1 then
            return x >= ox-1 and x <= ox and y >= oy and y <= oy+1
        elseif r == 2 then
            return x >= ox-1 and x <= ox and y >= oy-1 and y <= oy
        elseif r == 3 then
            return x >= ox and x <= ox+1 and y >= oy-1 and y <= oy
        end
    else
        unknownObjectType()
    end
end

function pathTo(fromX, fromY, toX, toY)
    return true
end

-- direction: 0 top, 1 right, 2 bottom, 3 left
function noWall(x,y,direction)
    local hiddenByWall = false
        --print("direction: "..direction)
        if direction == 0 then
            --print("aber wieso denn nicht")
            top = room.horizontal[x][y]
            if top == "window" or top == "wall" or top == "door_top" or top == "door_bottom" or top == "door_left" or top == "door_right" then 
                hiddenByWall = true
            end
        elseif direction == 1 then
            right = room.vertical[x+1][y]
            if right == "window" or right == "wall" or right == "door_top" or right == "door_bottom" or right == "door_left" or right == "door_right" then 
                hiddenByWall = true
            end
        elseif direction == 2 then
            bottom = room.horizontal[x][y+1]
            if bottom == "window" or bottom == "wall" or bottom == "door_top" or bottom == "door_bottom" or bottom == "door_left" or bottom == "door_right" then 
                hiddenByWall = true
            end
        elseif direction == 3 then
            left = room.vertical[x][y]
            if left == "window" or left == "wall" or left == "door_top" or left == "door_bottom" or left == "door_left" or left == "door_right" then 
                hiddenByWall = true
            end
        end
    if hiddenByWall then return false end
    return true
end

function allowed(object)
    local ox = round(object.x)
    local oy = round(object.y)

    if object.what == "armchair" then
        local r = object.r
        if not (object.r == 1 and isInTable(allVisibleX, allVisibleY, ox+1, oy) and noWall(ox,oy,r)
                or object.r == 2 and isInTable(allVisibleX, allVisibleY, ox, oy+1) and noWall(ox,oy,r)
                or object.r == 3 and isInTable(allVisibleX, allVisibleY, ox-1, oy) and noWall(ox,oy,r)
                or object.r == 0 and isInTable(allVisibleX, allVisibleY, ox, oy-1) and noWall(ox,oy,r) ) then
                table.insert(object.errorStr,"Armchair needs to be accessible from the front.")
            return false
        end

    elseif object.what == "couch" then
        local r = object.r
        if not (object.r == 0 and (isInTable(allVisibleX, allVisibleY, ox, oy-1) and noWall(ox,oy,r) and isInTable(allVisibleX, allVisibleY, ox+1, oy-1) and noWall(ox+1,oy,r))
                or object.r == 1 and (isInTable(allVisibleX, allVisibleY, ox+1, oy) and noWall(ox,oy,r) and isInTable(allVisibleX, allVisibleY, ox+1, oy+1) and noWall(ox,oy+1,r))
                or object.r == 2 and (isInTable(allVisibleX, allVisibleY, ox, oy+1) and noWall(ox,oy,r) and isInTable(allVisibleX, allVisibleY, ox-1, oy+1) and noWall(ox-1,oy,r))
                or object.r == 3 and (isInTable(allVisibleX, allVisibleY, ox-1, oy) and noWall(ox,oy,r) and isInTable(allVisibleX, allVisibleY, ox-1, oy-1) and noWall(ox,oy-1,r))) then
                table.insert(object.errorStr,"The couch's whole front needs to be accessible.")
            return false
        end
    elseif object.what == "shelf" then
        local r = object.r
        if not (object.r == 0 and (isInTable(allVisibleX, allVisibleY, ox, oy-1) and noWall(ox,oy,r) and isInTable(allVisibleX, allVisibleY, ox+1, oy-1) and noWall(ox+1,oy,r))
                or object.r == 1 and (isInTable(allVisibleX, allVisibleY, ox+1, oy) and noWall(ox,oy,r) and isInTable(allVisibleX, allVisibleY, ox+1, oy+1) and noWall(ox,oy+1,r))
                or object.r == 2 and (isInTable(allVisibleX, allVisibleY, ox, oy+1) and noWall(ox,oy,r) and isInTable(allVisibleX, allVisibleY, ox-1, oy+1) and noWall(ox-1,oy,r))
                or object.r == 3 and (isInTable(allVisibleX, allVisibleY, ox-1, oy) and noWall(ox,oy,r) and isInTable(allVisibleX, allVisibleY, ox-1, oy-1) and noWall(ox,oy-1,r))) then
                table.insert(object.errorStr,"The shelf's whole front needs to be accessible.")
            return false
        end
    elseif object.what == "officechair" then
        local r = object.r
        if not (isInTable(allVisibleX, allVisibleY, ox+1,oy) and noWall(ox,oy,1) or isInTable(allVisibleX, allVisibleY, ox-1, oy) and noWall(ox,oy,3) or isInTable(allVisibleX, allVisibleY, ox, oy+1) and noWall(ox,oy,2)  or isInTable(allVisibleX, allVisibleY, ox,oy-1) and noWall(ox,oy,0)) then
            table.insert(object.errorStr, "Office chair needs to be accessible.")
            return false
        end
    elseif object.what == "table" then
        local r = object.r
        local ok = false
        what = occupied(ox+1,oy)
        if what then
          if what[1].what == "couch" and what[1].r ~= 1 and noWall(ox,oy,1) then
             ok = true 
          end
        end
        what = occupied(ox-1,oy)
        if what then
          if what[1].what == "couch" and what[1].r ~= 3 and noWall(ox,oy,3) then
            ok = true
          end
        end
        what = occupied(ox,oy+1)
        if what then
          if what[1].what == "couch" and what[1].r ~= 2 and noWall(ox,oy,2) then
            ok = true
          end
        end
        what = occupied(ox,oy-1)
        if what then
          if what[1].what == "couch" and what[1].r ~= 0 and noWall(ox,oy,0) then
            ok = true
          end
        end
        if not ok then
            table.insert(object.errorStr, "Couch table needs to be next to a couch.")
        end
        return ok
    elseif object.what == "desk" then
        local r = object.r
        local ok = false
        if object.r == 0 then
          what = occupied(ox,oy-1)
          if what then
            if what[1].what == "officechair" and noWall(ox,oy,r) then
             ok = true 
            end
          end

          what = occupied(ox+1, oy-1)
          if what then
            if what[1].what == "officechair" and noWall(ox+1,oy,r) then
              ok = true 
            end
          end
          
        elseif object.r == 1 then
          what = occupied(ox+1,oy)
          if what then
            if what[1].what == "officechair" and noWall(ox,oy,r) then
             ok = true 
            end
          end
         
          what = occupied(ox+1, oy+1)
          if what then
            if what[1].what == "officechair" and noWall(ox,oy+1,r) then
              ok = true 
            end
          end
        
        elseif object.r == 2 then
          what = occupied(ox,oy+1)
          if what then
            if what[1].what == "officechair" and noWall(ox,oy,r) then
             ok = true 
            end
          end

          what = occupied(ox-1, oy+1)
          if what then
            if what[1].what == "officechair" and noWall(ox-1,oy,r) then
              ok = true 
            end
          end
          
        elseif object.r == 3 then
          what = occupied(ox-1,oy)
          if what then
            if what[1].what == "officechair" and noWall(ox,oy,r) then 
             ok = true 
            end
          end

          what = occupied(ox-1, oy-1)
          if what then
            if what[1].what == "officechair" and noWall(ox,oy-1,r) then 
              ok = true 
            end
          end
        end
        if not ok then
            table.insert(object.errorStr, "An officechair needs to be in front of the desk.")
        end
        return ok

    elseif object.what == "bed" then
        if not ( object.r == 0 and ( isInTable(allVisibleX, allVisibleY, ox, oy-1) and noWall(ox,oy,0) or isInTable(allVisibleX, allVisibleY, ox+1, oy-1) and noWall(ox+1,oy,0) or isInTable(allVisibleX, allVisibleY, ox, oy+2) and noWall(ox,oy+1,2) or isInTable(allVisibleX, allVisibleY, ox+1, oy+2) and noWall(ox+1,oy+1,2) or isInTable(allVisibleX, allVisibleY, ox-1, oy) and noWall(ox,oy,3) or isInTable(allVisibleX, allVisibleY, ox-1, oy+1) and noWall(ox,oy+1,3) or isInTable(allVisibleX, allVisibleY, ox+2, oy) and noWall(ox+1,oy,1) or isInTable(allVisibleX, allVisibleY, ox+2, oy+1) and noWall(ox+1,oy+1,1))
                 or object.r == 1 and (isInTable(allVisibleX, allVisibleY, ox+1, oy) and noWall(ox,oy,1) or isInTable(allVisibleX, allVisibleY, ox+1, oy+1) and noWall(ox,oy+1,1) or isInTable(allVisibleX, allVisibleY, ox-2, oy) and noWall(ox-1,oy,3) or isInTable(allVisibleX, allVisibleY, ox-2, oy+1) and noWall(ox-1,oy+1,3) or isInTable(allVisibleX, allVisibleY, ox, oy-1) and noWall(ox,oy,0) or isInTable(allVisibleX, allVisibleY, ox-1, oy-1) and noWall(ox-1,oy,0) or isInTable(allVisibleX, allVisibleY, ox, oy+2) and noWall(ox,oy+1,2) or isInTable(allVisibleX, allVisibleY, ox-1, oy+2) and noWall(ox-1,oy+1,2))
                 or object.r == 2 and (isInTable(allVisibleX, allVisibleY, ox, oy+1) and noWall(ox,oy,2) or isInTable(allVisibleX, allVisibleY, ox-1, oy+1) and noWall(ox-1,oy,2) or isInTable(allVisibleX, allVisibleY, ox, oy-2) and noWall(ox,oy-1,0) or isInTable(allVisibleX, allVisibleY, ox-1, oy-2) and noWall(ox-1,oy-1,0) or isInTable(allVisibleX, allVisibleY, ox-2, oy) and noWall(ox-1,oy,3) or isInTable(allVisibleX, allVisibleY, ox-2, oy-1) and noWall(ox-1,oy-1,3) or isInTable(allVisibleX, allVisibleY, ox+1, oy) and noWall(ox,oy,1) or isInTable(allVisibleX, allVisibleY, ox+1, oy-1) and noWall(ox,oy-1,1))
                 or object.r == 3 and (isInTable(allVisibleX, allVisibleY, ox-1, oy) and noWall(ox,oy,3) or isInTable(allVisibleX, allVisibleY, ox-1, oy-1) and noWall(ox,oy-1,3) or isInTable(allVisibleX, allVisibleY, ox+2, oy) and noWall(ox+1,oy,1) or isInTable(allVisibleX, allVisibleY, ox+2, oy-1) and noWall(ox+1,oy-1,1) or isInTable(allVisibleX, allVisibleY, ox, oy+1) and noWall(ox,oy,2) or isInTable(allVisibleX, allVisibleY, ox+1, oy+1) and noWall(ox+1,oy,2) or isInTable(allVisibleX, allVisibleY, ox, oy-2) and noWall(ox,oy-1,0) or isInTable(allVisibleX, allVisibleY, ox+1, oy-2) and noWall(ox+1,oy-1,0))) then
            table.insert(object.errorStr, "Bed needs to be accessible.")
            return false
        end
    end
    return true
end

function doorypied(x, y)
  if room.horizontal[x][y] == "door_bottom" or room.horizontal[x][y+1] == "door_top" or room.vertical[x][y] == "door_right" or room.vertical[x+1][y] == "door_left" then
    return true
  end
  return false
end

function windowypied(x, y)
  if room.horizontal[x][y] == "window" or room.horizontal[x][y+1] == "window" or room.vertical[x][y] == "window" or room.vertical[x+1][y] == "window" then
    return true
  end
  return false
end

function wallypied()
    for i = 1, #objects do
        expandObject(objects[i])
        local isWallypied = false
            --table.insert(objects[i].errorStr, "WOOT "..#objects[i].wallHorX.." "..#objects[i].wallHorY)
        for j = 1, #objects[i].wallHorX do
            local xi = objects[i].wallHorX[j]
            local yi = objects[i].wallHorY[j]
            if xi < 1 or yi < 1 then isWallypied = true break end
            --print(xi.." "..yi.."")
            local top = room.horizontal[xi][yi] 
            if top == "wall" or top == "window" or top == "door" then
                isWallypied = true
                break
            end
        end
        for j = 1, #objects[i].wallVerX do
            local xi = objects[i].wallVerX[j]
            local yi = objects[i].wallVerY[j]
            if xi < 1 or yi < 1 then isWallypied = true break end
            --print(xi.." "..yi.."")
            local left = room.vertical[xi][yi]
            if left == "wall" or left == "window" or left == "door" then
                isWallypied = true
                break
            end
        end
        if isWallypied then
            objects[i].dirty = true
            table.insert(objects[i].errorStr, "Objects cannot go through walls, windows nor doors")
        end
    end
end

function occupied(x, y)
    o = {}
    for i = 1, #objects do
        if occupies(objects[i], x, y) then
            table.insert(o, objects[i])
        end
    end
    if #o > 0 then
        return o
    else
        return false
    end
end

function accessible(x, y)
    o = occupied(x,y)
    return x > 0 and y > 0 and room.floor[x][y] == "floor" and not o
end

function nope(text)
    if nopeText == "" then
        nopeText = text
    end
end

function menuIndex()
    local xx = math.floor((love.mouse.getX()/scale)/(85+16))
    local yy = 1+math.floor((love.mouse.getY()/scale-32+4)/(23))
    local j = (xx)*5+(yy)
    if xx >= 0 and yy >= 1 and xx <= 2 and yy <= 5 and j >= 1 and j <= #rooms then
        return j
    else
        return nil
    end
end
