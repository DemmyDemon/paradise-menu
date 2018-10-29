local _defaultColors = {
    header_text = {r=253,g=180,b=51,a=255},
    header_background = {r=0,g=0,b=255,a=128},
    title_text = {r=255,g=200,b=71,a=255},
    title_background = {r=46,g=160,b=210,a=128},
    background = {r=0,g=0,b=0,a=128},
    background_active = {r=0,g=0,b=0,a=200},
    item = {r=255,g=255,b=255,a=255},
    item_value = {r=255,g=255,b=255,a=200},
    item_active = {r=255,g=255,b=200,a=255},
    item_value_active = {r=255,g=255,b=200,a=255},
}
local _sizes = {
    header_height = 0.1,
    title_height = 0.03,
    item_height = 0.03,
    item_text = 0.4,
    header_text = 1.2,
    title_text = 0.5
}

local function _identify(spec)

    if spec == nil then
        return 'unknown'
    end
    
    if #spec == 1 then -- Ye olde Label

        if type(spec[1]) == 'string' or type(spec[1]) == 'number' then
            return 'label'
        end

    elseif #spec == 2 then

        if type(spec[2]) == 'table' then
            return 'submenu'
        elseif type(spec[2]) == 'string' or type(spec[2]) == 'number' then
            return 'doublelabel'
        end

    elseif #spec == 4 then -- button

        if type(spec[2]) == 'string' then
            return 'button'
        elseif type(spec[2]) == 'number' then
            return 'button'
        else
            print(type(spec[2]))
        end

    elseif #spec == 5 then -- list

        if type(spec[2]) == 'table' then
            return 'list'
        end

    elseif #spec == 7 then -- Some kind of range

        if spec[2] == '%' then
            return 'float'
        elseif spec[2] == '/' then
            return 'int'
        end
    
    else
        return 'unknown'
    end
end

local function _stringpair(spec)

    local entryType = _identify(spec)

    if entryType == 'label' then
        return spec[1],nil,entryType
    elseif entryType == 'doublelabel' then
        return spec[1],spec[2],entryType
    elseif entryType == 'button' then
        return spec[1],spec[2],entryType
    elseif entryType == 'submenu' then
        return spec[1],'→',entryType
    elseif entryType == 'list' then
        return spec[1],'←'..spec[2][spec[3]]..'→',entryType
    elseif entryType == 'float' then
        return spec[1],'←'..math.modf(((100/spec[4])*spec[5])+0.01)..'%→',entryType
    elseif entryType == 'int' then
        return spec[1],'←'..spec[5]..'/'..spec[4]..'→',entryType
    else
        log('Unidentified menu spec: ',json.encode(spec))
        return '!MENU ERROR!',entryType
    end

end

local function _seek(heap,seekPath)

    if seekPath == nil or #seekPath == 0 then
        name = heap[1]
        data = heap[2]
        return name,data
    else

        local name = heap[1]
        heap = heap[2]

        for k, v in ipairs(seekPath) do
            name = heap[v][1]
            heap = heap[v][2]
        end

        return name,heap
    end
end

local function _itemText(menu,x,y,active,hint,label,text)
    x = x - (menu.w/2)
    y = y - (_sizes.item_height/2)
    
    SetTextWrap(x,x+(menu.w - 0.001))

    SetTextScale(_sizes.item_text,_sizes.item_text)
    if hint then
        SetTextJustification(2)
        if active then
            local alpha = menu.color.item_value_active.a
            if menu.disabled then
                alpha = math.floor(alpha/2)
            end
            SetTextColour(menu.color.item_value_active.r,menu.color.item_value_active.g,menu.color.item_value_active.b,alpha)
        else
            local alpha = menu.color.item_value.a
            if menu.disabled then
                alpha = math.floor(alpha/2)
            end
            SetTextColour(menu.color.item_value.r,menu.color.item_value.g,menu.color.item_value.b,alpha)
        end
    else
        SetTextJustification(1)
        if active then
            local alpha = menu.color.item_active.a
            if menu.disabled then
                alpha = math.floor(alpha/2)
            end
            SetTextColour(menu.color.item_active.r,menu.color.item_active.g,menu.color.item_active.b,alpha)
        else
            local alpha = menu.color.item.a
            if menu.disabled then
                alpha = math.floor(alpha/2)
            end
            SetTextColour(menu.color.item.r,menu.color.item.g,menu.color.item.b,alpha)
        end
    end
    SetTextOutline()
    --SetTextDropshadow(2,0,0,0,128)
    SetTextDropShadow()

    if label then
        SetTextJustification(0)
        x = x + menu.w/2
    else
        x = x + 0.001
    end
    
    SetTextEntry('STRING')
    AddTextComponentString(text)

    DrawText(x,y)
end

local function _titleText(menu,x,y,text)
    y = y - (_sizes.item_height/2)

    BeginTextCommandDisplayText('STRING')
    SetTextWrap(x,x+(menu.w - 0.001))

    SetTextJustification(0)
    SetTextFont(0)
    SetTextScale(_sizes.title_text,_sizes.title_text)
    --SetTextDropshadow(5,0,0,0,255)
    SetTextDropShadow()
    
    local alpha = menu.color.title_text.a

    if menu.disabled then
        alpha = math.floor(alpha/2)
    end

    SetTextColour(menu.color.title_text.r,menu.color.title_text.g,menu.color.title_text.b,alpha)
    
    AddTextComponentString(text)
    EndTextCommandDisplayText(x,y-0.005)
end

local function _rect(menu,x,y,w,h,color)
    local alpha = color.a
    if menu.disabled then
        alpha = math.floor(alpha/2)
    end
    DrawRect(x, y, w, h, color.r,color.g,color.b,alpha)
end

local function _sprite(menu,sprite,x,y,w,h)
    local alpha = 255
    if menu.disabled then
        alpha = 128
    end
    DrawSprite(menu.ytd,sprite,x,y,w,h,0.0,255,255,255,alpha)
end

local function _headerText(menu)

    local text = menu.header
    local w = menu.w
    local x = menu.x -- (w/2)
    local y = menu.y - (_sizes.header_height/2.7)
    SetTextProportional(1)
    SetTextScale(_sizes.header_text,_sizes.header_text)
    SetTextJustification(0)

    local alpha = menu.color.header_text.a

    if menu.disabled then
        alpha = math.floor(alpha/2)
    end

    SetTextColour(menu.color.header_text.r,menu.color.header_text.g,menu.color.header_text.b,alpha)
    SetTextWrap(x,x+w)
    SetTextFont(1)
    --SetTextOutline()
    --SetTextDropshadow(4,0,0,0,100)
    SetTextDropShadow()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x,y)
end

local function _drawHeader(menu)
    local x = menu.x
    local y = menu.y
    local w = menu.w
    local h = _sizes.header_height
    if menu.ytd and menu.ytdLoaded then
        _sprite(menu,'header',x,y,w,h)
    else
        _rect(menu,x, y, w, h, menu.color.header_background)
    end
    _headerText(menu)

    return x,y+(h/2)
end

local function _drawTitle(menu,x,y,title)
    local h = _sizes.title_height
    local w = menu.w
    y = y+(h/2)

    if menu.ytd and menu.ytdLoaded then
        _sprite(menu,'title',x,y,w,h)
    else
        _rect(menu,x, y, w, h, menu.color.title_background)
    end
    _titleText(menu,x,y,title)

    return x,y+(h/2)
end

local function _drawFooter(menu,x,y,footer)
    local h = _sizes.title_height
    local w = menu.w
    y = y+(h/2)

    if menu.ytd and menu.ytdLoaded then
        _sprite(menu,'footer',x,y,w,h)
    else
        _rect(menu,x, y, w, h, menu.color.title_background)
    end
    _titleText(menu,x,y,footer)

    return x,y+(h/2)
end

local function _drawLogo(menu,x,y)
    _sprite(menu,'logo',x + menu.w/2 - 0.03,y - 0.055,0.06,0.06*menu.aspectRatio)
end

local function _drawItem(menu,x,y,index,spec)
    local h = _sizes.item_height
    local w = menu.w
    y = y+(h/2)

    local text,hint,entryType = _stringpair(spec)

    if index == menu.index then
        _rect(menu,x,y,w,h,menu.color.background_active)
        if entryType ~= 'label' then
            _itemText(menu,x,y,true,false,false,text)
            _itemText(menu,x,y,true,true,false,hint)
        else
            _itemText(menu,x,y,true,false,true,text)
        end
    else
        _rect(menu,x,y,w,h,menu.color.background)
        if entryType ~= 'label' then
            _itemText(menu,x,y,false,false,false,text)
            _itemText(menu,x,y,false,true,false,hint)
        else
            _itemText(menu,x,y,false,false,true,text)
        end
    end

    return x,y+(h/2)
end

local function _increase(menu,spec,slow)
    local type = _identify(spec)
    if type == 'submenu' then
        --NOOP, submenus don't change!
    elseif type == 'button' then
        --NOOP, buttons don't change!
    elseif type == 'list' then
        local actualList = spec[2]
        local index = spec[3]
        local next = index+1
        if next > #actualList then
            if menu.wrap then
                spec[4](false,1,spec[5])
            end -- No ELSE as there is no change.
        else
            spec[4](false,next,spec[5])
        end
    elseif type == 'int' then
        local step = 1
        local min = spec[3]
        local max = spec[4]
        local value = spec[5]
        local next = value+step
        if next > max then
            if menu.wrap then
                spec[6](false,min,spec[7])
            end
        else
            spec[6](false,next,spec[7])
        end
    elseif type == 'float' then
        local step = 0.1
        if slow then
            step = 0.01
        end
        local min = spec[3]
        local max = spec[4]
        local value = spec[5]
        local next = value+step
        if next > max then
            if menu.wrap then
                spec[6](false,min,spec[7])
            end
        else
            spec[6](false,next,spec[7])
        end
    end
end

local function _decrease(menu,spec,slow)
    local type = _identify(spec)
    if type == 'submenu' then
        --NOOP, submenus don't change!
    elseif type == 'button' then
        --NOOP, buttons don't change!
    elseif type == 'list' then
        local actualList = spec[2]
        local index = spec[3]
        local next = index-1
        if next < 1 then
            if menu.wrap then
                spec[4](false,#actualList,spec[5])
            end -- No ELSE as there is no change.
        else
            spec[4](false,next,spec[5])
        end
    elseif type == 'int' then
        local step = 1
        local min = spec[3]
        local max = spec[4]
        local value = spec[5]
        local next = value-step
        if next < min then
            if menu.wrap then
                spec[6](false,max,spec[7])
            end
        else
            spec[6](false,next,spec[7])
        end
    elseif type == 'float' then
        local step = 0.1
        if slow then
            step = 0.01
        end
        local min = spec[3]
        local max = spec[4]
        local value = spec[5]
        local next = value-step
        if next < min then
            if menu.wrap then
                spec[6](false,max,spec[7])
            end
        else
            spec[6](false,next,spec[7])
        end
    end
end

local function _back(menu)
    
    if menu.backfunction then
        menu.backfunction(menu)
    end

    if #menu.path == 0 then
        if menu.abortable then
            menu.hide()
        end
    else
        table.remove(menu.path,#menu.path)
        
        menu.index = menu.wasIndex[#menu.wasIndex]
        table.remove(menu.wasIndex,#menu.wasIndex)

        menu.offset = menu.wasOffset[#menu.wasOffset]
        table.remove(menu.wasOffset,#menu.wasOffset)
    end
end

local function _hovered(menu,spec)
    if menu.hovertrigger then
        local type = _identify(spec)
        if type == 'submenu' then
            -- NOOP, these need to be triggered
        elseif type == 'label' then
            -- NOOP, labels can't be triggered
        elseif type == 'button' then
            spec[4](false,spec[3],menu)
        elseif type == 'list' then
            spec[4](false,spec[3],spec[5],menu)
        elseif type == 'int' then
            spec[6](false,spec[5],spec[7],menu)
        elseif type == 'float' then
            spec[6](false,spec[5],spec[7],menu)
        end
    end
end

local function _confirm(menu,spec)
    local type = _identify(spec)
    if type == 'submenu' then
        table.insert(menu.path,menu.index)
        table.insert(menu.wasIndex,menu.index)
        table.insert(menu.wasOffset,menu.offset)
        menu.index = 1
        menu.offset = 1
        if menu.forwardfunction then
            menu.forwardfunction(menu)
        end

        _hovered(menu,spec[2][1])

    elseif type == 'button' then
        spec[4](true,spec[3],menu)
    elseif type == 'list' then
        spec[4](true,spec[3],spec[5],menu)
    elseif type == 'int' then
        spec[6](true,spec[5],spec[7],menu)
    elseif type == 'float' then
        spec[6](true,spec[5],spec[7],menu)
    end
end

function pMenu(spec)
    local menu = {}

    menu.shown = false -- and not overridable by settings!
    menu.x = spec.x or 0.158
    menu.y = spec.y or 0.336
    menu.w = spec.w or 0.25
    menu.wrap = true
    if spec.wrap ~= nil then
        menu.wrap = spec.wrap
    end
    menu.repeatInterval = spec.repeatInterval or 200
    menu.lastInput = 0 -- Stores when the last input was processed
    menu.header = spec.header or 'Menu'
    menu.abortable = spec.abortable or false
    menu.color = {}
    menu.maxitems = spec.maxitems or 10
    menu.offset = 1 -- This is how far down the menu is "scrolled"

    menu.layer = spec.layer or 10

    menu.disabled = false
    if spec.disabled ~= nil then
        menu.disabled = spec.disabled
        menu.beginsDisabled = spec.disabled
    end

    if spec.color ~= nil then
        menu.color.header_text = spec.color.header_text or _defaultColors.header_text
        menu.color.header_background = spec.color.header_background or _defaultColors.header_background
        menu.color.title_text = spec.color.title_text or _defaultColors.title_text
        menu.color.title_background = spec.color.title_background or _defaultColors.title_background
        menu.color.background = spec.color.background or _defaultColors.background
        menu.color.background_active = spec.color.background_active or _defaultColors.background_active
        menu.color.item = spec.color.item or _defaultColors.item
        menu.color.item_value = spec.color.item_value or _defaultColors.item_value
        menu.color.item_active = spec.color.item_active or _defaultColors.item_active
        menu.color.item_value_active = spec.color.item_value_active or _defaultColors.item_value_active
    else
        menu.color = _defaultColors
    end

    if spec.ytd ~= nil then -- Could be a literal boolean false to suppress this feature.
        menu.ytd = spec.ytd
    else
        menu.ytd = 'paradise-menu'
    end

    menu.path = {}
    menu.index = 1

    menu.wasIndex = {} -- Stores the index of a menu when entering a sub-menu
    menu.wasOffset = {} -- Like above, but for the offset


    -- FOR ADVANCED MENU! Not very pretty, but it works.
    menu.hovertrigger = false -- Do items trigger with a selected=false when they are the active menu item?
    if spec.hovertrigger ~= nil then
        menu.hovertrigger = spec.hovertrigger
    end

    menu.backfunction = nil
    if spec.backfunction ~= nil then
        if type(spec.backfunction) == 'function' then
            menu.backfunction = spec.backfunction
        else
            log('Menu has a back function, but it is not a real function')
        end
    end

    menu.forwardfunction = nil
    if spec.forwardfunction ~= nil and type(spec.forwardfunction) == 'function' then
        menu.forwardfunction = spec.forwardfunction
    end

    menu.hidefunction = nil
    if spec.hidefunction ~= nil then
        if type(spec.hidefunction) == 'function' then
            menu.hidefunction = spec.hidefunction
        else
            log('Menu has a hide function, but it is not a real function')
        end
    end

    if menu.ytd then
        menu.ytdLoaded = false
        Citizen.CreateThread(function()
            if not HasStreamedTextureDictLoaded(menu.ytd) then
                RequestStreamedTextureDict(menu.ytd)
                local attempts = 100
                while not HasStreamedTextureDictLoaded(menu.ytd) do
                    attempts = attempts - 1
                    if attempts <= 0 then
                        return
                    else
                        Citizen.Wait(100)
                    end
                end
                menu.ytdLoaded = true
            else
                menu.ytdLoaded = true
            end
        end)
    end

    menu.aspectRatio = GetAspectRatio(0)

    function menu.show()
        if not menu.shown then
            menu.firstDraw = true
        end
        menu.shown = true;
    end

    function menu.pulse()
        menu.firstDraw  = true
    end

    function menu.hide()
        menu.shown = false;
        menu.index = 1
        menu.offset = 1
        menu.path = {}
        menu.wasOffset = {}
        menu.wasIndex = {}
        menu.disabled = menu.beginsDisabled
        if menu.hidefunction then
            menu.hidefunction(menu)
        end
    end

    function menu.visible()
        return menu.shown
    end

    function menu.disable()
        menu.disabled = true
    end

    function menu.enable()
        menu.disabled = false
    end

    function menu.enabled()
        return not menu.disabled
    end

    function menu.hideAll()
        TriggerEvent('paradise-menu:hide-all')
    end
    AddEventHandler('paradise-menu:hide-all',function()
        menu.hide()
    end)

    function menu.root()
        menu.index = 1
        menu.offset = 1
        menu.path = {}
        menu.wasOffset = {}
        menu.wasIndex = {}
    end

    function menu.draw(menuData)

        if not menu.shown then
            return
        end

        local now = GetGameTimer()

        SetUiLayer(menu.layer)

        local path = menu.path
        local title,data = _seek(menuData,path)
        local x,y = _drawHeader(menu)
        x,y = _drawTitle(menu,x,y,title)
        if menu.ytd and menu.ytdLoaded then
            _drawLogo(menu,x,y)
        end
        local repeatInterval = menu.repeatInterval
    
        if menu.index > #data then
            menu.index = #data
        end
    
        if IsControlPressed(0,21) then -- Shift
            repeatInterval = repeatInterval * 0.3
        end
    
        if menu.firstDraw then
            if not menu.disabled then
                menu.firstDraw = nil
                _hovered(menu,data[menu.index])
            end
        end
    
        if IsControlJustPressed(0,177) and not menu.disabled then -- Backspace
            menu.lastInput = now
            _back(menu)
    
        elseif IsControlJustPressed(0,176) and not menu.disabled then -- Enter
            menu.lastInput = now
            _confirm(menu,data[menu.index])
        elseif now > (menu.lastInput + repeatInterval) and not menu.disabled then
    
            if IsControlPressed(0,172) then -- up arrow or mouse scroll up
                menu.lastInput = now
    
                menu.index = menu.index - 1
    
                if menu.index < menu.offset and #data > menu.maxitems then
                    menu.offset = menu.offset - 1
                end
    
                if menu.index < 1 then
                    menu.index = #data
                    if #data > menu.maxitems then
                        menu.offset = #data - (menu.maxitems - 1)
                    end
                end
    
                _hovered(menu,data[menu.index])
    
            elseif IsControlPressed(0,173) then -- down arrow or mouse scroll down
                menu.lastInput = now
                menu.index = menu.index  + 1
    
                if menu.index > menu.maxitems + (menu.offset - 1) and #data > menu.maxitems then
                    menu.offset = menu.offset + 1
                end
    
                if menu.index > #data then
                    menu.index = 1
                    if #data > menu.maxitems then
                        menu.offset = 1
                    end
                end
    
                _hovered(menu,data[menu.index])
    
            elseif IsControlPressed(0,174) then -- left arrow
                menu.lastInput = now
                _decrease(menu,data[menu.index])
    
            elseif IsControlPressed(0,175) then -- right arrow
                menu.lastInput = now
                _increase(menu,data[menu.index])
    
            end
        end
    
        if type(data) == 'table' then
            local stopItem = menu.maxitems + (menu.offset - 1)
            for i=menu.offset,#data do
                if i >  stopItem then
                    break
                else
                    x,y = _drawItem(menu,x,y,i,data[i])
                end
            end
            
            x,y = _drawFooter(menu,x,y,menu.index..'/'..#data)
    
        else
            Citizen.Trace(debug.traceback('Unable to draw menu:  Passed data is not a table!'))
            menu.show = false
        end
    end

    return menu
end

exports('create',pMenu)