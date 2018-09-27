
local ParadiseMenu -- Putting a wiiiide scope on this, as it's needed for this example, but you can do exactly as you wish.

RegisterCommand("paradise-menu-example",function()
    if ParadiseMenu then
        ParadiseMenu.show()
    else
        ParadiseMenu = pMenu({
            x = 0.158,                  -- Fraction of screen from left
            y = 0.336,                  -- Fraction of screen from top
            w = 0.25,                   -- Width in fraction of screen

            maxitems = 10,              -- How many items are shown in the menu before it starts to scroll down to show more

            wrap = true,                -- When we get to the end (100%, [15/15], or whatever), should it wrap around to the beginning (0%, [1/15])?
                                        -- Note that if it is at min/max, and a change is done in that direction, it will NOT issue a callback unless the menu wraps.

            header = "Menu",            -- The text in the pretty top box. The default is very boring!
            abortable = false,          -- INPUT_CELLPHONE_CANCEL (Backspace, usually) goes up a level from the sub-menu, but can it close the menu entirely?
                                        -- The default is false, but you'll most likely want to say "true" here!

            -- Some colors! Standard RGBA stuff you've probably seen before.
            color = {
                header_text = {r=253,g=180,b=51,a=255},         -- Color of the header text,"Menu" in this example
                header_background = {r=0,g=0,b=255,a=128},      -- The background behind that text.
                title_text = {r=255,g=200,b=71,a=255},          -- Color of "Example menu" in this example, but also "Sub-menu" and "Even deeper!" further down.
                title_background = {r=46,g=160,b=210,a=128},    -- The color behind the title text.
                background = {r=0,g=0,b=0,a=128},               -- Background of the actual menu items, when *not* active.
                background_active = {r=0,g=0,b=0,a=200},        -- Active items get this behind them.
                item = {r=255,g=255,b=255,a=255},               -- Menu item text.
                item_value = {r=255,g=255,b=255,a=200},         -- The value shown on the right, for example the "8" of the first button.
                item_active = {r=255,g=255,b=200,a=255},        -- Text of the item when it is active.
                item_value_active = {r=255,g=255,b=200,a=255},  -- Value again, but this time for the active item.
            },

            -- Note that the header_background,title_background and background values are *ignored* when an YTD is specified.
            -- The default value is:
            ytd = 'paradise-menu',
            -- You can set this to false to disable textures altogether, or specify a YTD of your chosing.
            -- Just make sure it has the same textures in it as the one that comes with this resource.
            -- Note that very little time is spent drawing sprites as opposed to simple rectangles, so almost no resources are saved by disabling them.
            -- Oh, and it looks like absolute ass without textures. You've been warned.

            -- All of the above can be omitted, and will default to the values shown here.
            -- These values are inherited by sub-menus, and *can not* be changed later unless you dig into the returned menu object manually. Please don't.

            -- For a more complete list of options, see the README.md file
        })
        ParadiseMenu.show()
    end
end,false)

local function example_callback(confirmed,value,thisMenu) -- We'll be calling this function a lot in this example.
    -- Please note that while buttons pass three values like this, lists and ranges pass the value they are changed to *before* the value field buttons have.
    -- See the actual example below.
    Citizen.Trace("Of course you can define as many callback functions as you want!")
    Citizen.Trace("I can't tell where I got "..value.." from!")
    Citizen.Trace("You could make the values very unique, I guess, but it really is better with more callbacks.")
    if confirmed and value == 'NOPE!' then
        thisMenu.hide() -- Very handy reference is always passed, just remember that buttons, ranges and lists can have different parameter counts!
    end
end

local someList = {"Horse","Cow","Cat","Dog"} -- We'll need this later to display a selection list.

Citizen.CreateThread(function()
    while true do
        if ParadiseMenu then
            if ParadiseMenu.visible() then
                ParadiseMenu.draw({

                    -- draw() does a visibility check before actually drawing.
                    -- The reason a visibility check is done before drawing here is because I don't want to waste a bunch of time building this table.
                    -- Normally you wouldn't want to re-define the table like this every frame, but in most cases it's still faster to do a visibility check before drawing.

                    -- Just keep the data you need for it available somewhere and regenerate that table whenever you need to.
                    -- As shown here is a waste of resources, but I hope it makes for a clear enough example.

                    -- Please note that in addition to the listed arguments, a reference to the menu calling the callback is also sent.
                    -- This is useful for things like hiding the menu or sending it back to root.
                    -- A complicating factor is that the specified new value/index is sent along with the provided data for lists and ranges, so it 

                    "Example menu",{

                        -- Note that ranges and lists carry an extra "id" after their callback. This is to make it easier to identify what range sent the value so more things can be handled in the same callback.
                        {"Button",          "horse","value",example_callback},      -- Displays "Button            horse", runs callback(true,"value",ref) when activated.
                        {"Float range",     '%',0.0,1.0,0.3,example_callback,"id"}, -- Displays "Float range       <30%>", runs callback(false,0.2,"id",ref) when decreased, callback(false,0.4,"id") when increased, and callback(true,0.3,"id",ref) when confirmed.
                        {"Integer range",   '/',0,43,14,example_callback,"id"},     -- Displays "Integer range   [14/43]", runs callback(false,13,"id",ref) when decreased, callback(false,15,"id") when increeased, and callback(true,14,"id",ref) when confirmed.
                        {"List",            someList,2,example_callback,"id"},      -- Displays "List              <Cow>", runs callback(false,1,"id",ref) when decreased, callback(false,3,"id") when increased, and callback(true,2,"id",ref) when confirmed.
                        {"Sub-menu",{                                               -- Displays "Sub-menu              >", changes the menu to that sub-menu when confirmed, fires no callback.
        
                            -- Sub-menus behave exactly like top level menus.
                            {"Moar button!",    "","Moar value!",example_callback},     -- Buttons do not have to display any "item value", but an empty string must be specified.
                            {"Moar range!",     '%',0.5,1.0,0.5,example_callback,"id"}, -- Ranges don't have to run from zero. They don't have to end at 100% either, bhe "current value" variable must be in range.
                            {"Even deeper!",{
                                {"Recursive menus",  "","Go as deep as you like, just beware of recursion/self-referencing!",example_callback},
                            }},
                            {"Moar list!",      someList,3,example_callback,"id"},
        
                        }},
                        {"Centered label"},                                                                 -- Labels just sit in the middle of the menu and do nothing.
                        {"Label that looks like","a button!"},                                              -- This one also does nothing, but it looks like a button. 
                                                                                                            -- Useful for when you want the look to stay the same, but the callback to never fire.

                        {"Another button",      "pink",{"table","values","are","fine"},example_callback},   -- Really, the "value" can be any variable you see fit. The menu does not care. It just passes it on.

                        {"Save",                "","kthnx",example_callback},                               -- Again, the button "right text" can be blank. No probllem.
                        {"Abort",               7,"NOPE!",example_callback},                                -- It doesn't even have to be a string.
                        -- As specified in the example callback function, if the value is NOPE! then the menu is closed. You can do this any way you see fit, obviously.
                    }
                })
            end
        end
        Citizen.Wait(0)
    end
end)