-- package.path = package.path .. ";./?/init.lua"
local path = ""

local vec3 = require("vec3")
local pretty = require("pretty")

-- matrix library
-- notes
-- flat array, column-major order as in matlab, julia, etc

local class = require(path .. "class")
local mathx = require(path .. "mathx")
local tablex = require(path .. "tablex")
local unpack = table.unpack or unpack

local mat4 = class({
	name = "mat4",
})

--stringification
function mat4:__tostring()
    local columns = {}
    for i=1,4 do
        local k = 1+(i-1)*4
        print(i,k)
        table.insert(columns, "(%.2f, %.2f, %.2f, %.2f)"):format(self.data[k], self.data[k+1], self.data[k+2], self.data[k+3])
    end
    return "(" .. table.concat(columns, ",") .. ")T"
end

-- create a new matrix given column order values m_ij
-- if m11 is nil this creates the zero matrix
-- if m11 is a table then the values are copied directly into the matrix
function mat4:new(m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44)
    if m11 == nil then
        self:sset(nil)
	elseif type(m11) == "number" then
		self:sset(m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44)
	elseif type(m11) == "table" then
        self.mset(m11)
    else
        error("Unsupported constructor argument " .. tostring(m11))
	end
end


function mat4:sset(m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44)
    if m11 == nil then
        self.data = { 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0 }
    else
        assert( m11 and m21 and m31 and m41 and m12 and m22 and m32 and m42 and m13 and m23 and m33 and m43 and m14 and m24 and m34 and m44 )
        self.data = { m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44 }
    end
	return self
end

function mat4:mset(m)
    self.data = tablex.copy(m.data)
	return self
end

function mat4:swap(m)
    local data = tablex.copy(m.data)
	self:mset(data)
	m:sset(unpack(data))
	return self
end

-- Element access

function mat4:get(i, j)
    return self.data[i + 1+(j-1)*4]
end

function mat4:set(i, j, value)
    self.data[i + 1+(j-1)*4] = value
    return self
end

-- tests

local tests = {
    function()
        pretty.print(vec3(2,3,4))
        local ident = mat4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
        print(table.concat(ident.data, ","))
        pretty.print(ident)
    end,


}

for _, test in ipairs(tests) do 
    test() 
end
