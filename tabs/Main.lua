-- Lpeg Calc

local utf8 = require("utf8")
local lpeg = require("lpeg")
local re = require("re")

-- Use this function to perform your initial setup
function setup()
    print("Lpeg Calculator")
    expr, tree, res = "", "", ""
    parameter.action("edit", function()
        if not isKeyboardShowing() then
            tree, res = "", ""
            showKeyboard()
        end
    end)
    parameter.action("clear", function()
        expr, tree, res = "", "", ""
    end)
end
    
local white = lpeg.S(" \t\r\n") ^ 0
--local number = white * lpeg.R("09") ^ 1 * (("." * lpeg.R("09") ^ 1) ^ -1) / tonumber
local number = white * re.compile("[0-9]+([.][0-9]+)?") / tonumber
local muldiv = white * lpeg.C(lpeg.S("/*"))
local addsub = white * lpeg.C(lpeg.S("+-"))
local comma = white * lpeg.S(",")
local ident = white * lpeg.C(re.compile("[a-z_][a-z_0-9]*"))
local openParen = white * lpeg.S("(")
local closeParen = white * lpeg.S(")")

-- Non-terminals
local Exp = lpeg.V("Exp")
local Term = lpeg.V("Term")
local Factor = lpeg.V("Factor")
local Fcall = lpeg.V("Fcall")

local grammar = lpeg.P({
    "input",
    input = Exp * -1,
    Exp = lpeg.Ct(Term * (addsub * Term)^1) + Term,
    Term = lpeg.Ct(Factor * (muldiv * Factor)^1) + Factor,
    Factor = number + Fcall + openParen * Exp * closeParen,
    Fcall = lpeg.Ct(ident * openParen * (Exp * (comma * Exp)^0)^-1 * closeParen),
})

-- This function gets called once every frame
function draw()
    -- This sets a dark background color 
    background(40, 40, 50)

    -- This sets the line thickness
    strokeWidth(5)

    -- Do your drawing here
    fontSize(30)
    textWrapWidth(WIDTH-30)
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
        local first = n[1]
        if type(first) == "string" then
            local t = {}
            for i=2,#n do
                t[#t+1] = ev(n[i])
            end
            local f = math[first]
            if not f then
                error("Unknown math function: " .. first)
            end
            return f(unpack(t))
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

