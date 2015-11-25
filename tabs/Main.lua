-- Lpeg Calc

local utf8 = require("utf8")
local lpeg = require("lpeg")
local re = require("re")

-- Use this function to perform your initial setup
function setup()
    print("Lpeg Calculator")
    
    expr, tree, res = "", "", ""
    parameter.action("eval", function()
        if not isKeyboardShowing() then
            tree, res = "", ""
            showKeyboard()
        end
    end)
end
    
local white = lpeg.S(" \t\r\n") ^ 0
--local integer = white * lpeg.R("09") ^ 1 * (("." * lpeg.R("09") ^ 1) ^ -1) / tonumber
local integer = white * re.compile("[0-9]+([.][0-9]+)?") / tonumber
local muldiv = white * lpeg.C(lpeg.S("/*"))
local addsub = white * lpeg.C(lpeg.S("+-"))
local OpenParen = white * lpeg.S("(")
local CloseParen = white * lpeg.S(")")

local grammar = lpeg.P({
    "input",
    input = lpeg.V("exp") * -1,
    exp = lpeg.Ct(lpeg.V("term") * (addsub * lpeg.V("term"))^1) + lpeg.V("term"),
    term = lpeg.Ct(lpeg.V("factor") * (muldiv * lpeg.V("factor"))^1) + lpeg.V("factor"),
    factor = integer + OpenParen * lpeg.V("exp") * CloseParen,
})

-- This function gets called once every frame
function draw()
    -- This sets a dark background color 
    background(40, 40, 50)

    -- This sets the line thickness
    strokeWidth(5)

    -- Do your drawing here
    fontSize(30)
    fill(34, 255, 0, 255)
    if isKeyboardShowing() then
        text(tostring(expr) .. utf8.char(0x258c), WIDTH/2, HEIGHT/4*3)
    else
        text(tostring(expr), WIDTH/2, HEIGHT/4*3)
    end
    fill(201, 226, 46, 255)
    text(tree, WIDTH/2, HEIGHT/2)
    fill(0, 99, 255, 255)
    text(tostring(res), WIDTH/2, HEIGHT/4*1)
end

function keyboard(key)
    if key == BACKSPACE then
        expr = (expr == "") and "" or string.sub(expr, 1, #expr-1)
    elseif key == RETURN then
        hideKeyboard()
        res = evaluate(expr)
    else
        expr = expr .. key
    end
end

function evaluate(expr)
    local syntax_tree = grammar:match(expr)
    tree = json.encode(syntax_tree)
    
    local actionTable = {
        ["-"] = function(a, b) return a - b end,
        ["+"] = function(a, b) return a + b end,
        ["*"] = function(a, b) return a * b end,
        ["/"] = function(a, b) return a / b end,
    }
    local function ev(n)
        if type(n) == "number" then
            return n
        end
        local acc = ev(n[1])
        for i = 2, #n, 2 do
            local op = n[i]
            local b = ev(n[i+1])
            acc = actionTable[op](acc, b)
        end
        return acc
    end
    return syntax_tree and ev(syntax_tree)
end

