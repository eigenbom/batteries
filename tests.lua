-- package.path = package.path .. ";./?/init.lua"
local path = ""

local vec3 = require("vec3")
local pretty = require("pretty")

-- matrix library
-- note: flat array column-major order

local class = require(path .. "class")
local mathx = require(path .. "mathx")
local tablex = require(path .. "tablex")
local assert = require(path .. "assert")
local unpack = table.unpack or unpack

local mat4 = class({
	name = "mat4",
})

-- returns the index into a flat-array of matrix 4x4 values stored in column-major order
local function index(row, col)
    return col+(row-1)*4
end

--stringification
function mat4:__tostring()
    local columns = {}
    for col=1,4 do
        local k = index(1, col)
        table.insert(columns, string.format("(%.2f, %.2f, %.2f, %.2f)", self.data[k], self.data[k+1], self.data[k+2], self.data[k+3]))
    end
    return "(" .. table.concat(columns, ", ") .. ")"
end

-- create a new matrix given column order values m_ij
-- if data_or_m11 is nil this creates the zero matrix
-- if data_or_m11 is a table this is used directly as the data
function mat4:new(data_or_m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44)
    if data_or_m11 == nil then
        self:sset(nil)
	elseif type(data_or_m11) == "number" then
		self:sset(data_or_m11, m21, m31, m41, m12, m22, m32, m42, m13, m23, m33, m43, m14, m24, m34, m44)
	elseif type(data_or_m11) == "table" then
        self.data = data_or_m11
    else
        error("Unsupported constructor argument " .. tostring(m11))
	end
end

--explicit ctors
function mat4:copy()
	return mat4(tablex.copy(self.data))
end

function mat4:zero()
	return mat4(nil)
end

--modify
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
    return tablex.copy(m.data, self.data)
end

--[[
function mat4:swap(m)
    local data = tablex.copy(m.data)
	self:mset(data)
	m:sset(unpack(data))
	return self
end
--]]


function mat4:get(row, col)
    return self.data[index(row,col)]
end

function mat4:set(row, col, value)
    self.data[index(row,col)] = value
    return self
end


-- Matrix multiplication
function mat4:mmuli(m)
    assert:type(m, "mat4", "mat4.mmuli - m", 1)
    local a = self:copy()
    for col=1,4 do
        for row=1,4 do
            self:set(row, col, a:get(row,1)*m:get(1,col) + a:get(row,2)*m:get(2,col) + a:get(row,3)*m:get(3,col) + a:get(row,4)*m:get(4,col))
        end
    end
    return self
end

function mat4:mmul(m)
    assert:type(m, "mat4", "mat4.mmuli - m", 1)
    local result = mat4()
    for col=1,4 do
        for row=1,4 do
            result:set(row, col, self:get(row,1)*m:get(1,col) + self:get(row,2)*m:get(2,col) + self:get(row,3)*m:get(3,col) + self:get(row,4)*m:get(4,col))
        end
    end
    return result
end

-----------------------------------------------------------
--equality comparison
-----------------------------------------------------------

--threshold for equality in each dimension
local EQUALS_EPSILON = 1e-9

--true if a and b are functionally equivalent
function mat4.equals(a, b)
    for i=1,16 do
        if math.abs(a.data[i] - b.data[i]) > EQUALS_EPSILON then 
            return false
        end
    end
    return true
end

--true if a and b are not functionally equivalent
--(very slightly faster than `not mat4.equals(a, b)`)
function mat4.nequals(a, b)
    return not mat4.equals(a,b)
end


-- Multiply a matrix m by v and place result in into (optional)
-- Only supports vec3
function mat4.vmul(m, v, into)
    if not into then into = vec3:zero() end

    assert:type(m, "mat4", "mat4.vmul - m", 1)
    assert:type(v, "vec3", "mat4.vmul - v", 1)
    assert:type(into, "vec3", "mat4.vmul - into", 1)
    
    return into:sset(
        m.data[1]*v.x + m.data[5]*v.y + m.data[9]*v.z + m.data[13],
        m.data[2]*v.x + m.data[6]*v.y + m.data[10]*v.z + m.data[14],
        m.data[3]*v.x + m.data[7]*v.y + m.data[11]*v.z + m.data[15] )
end

-- tests

local tests = {
    function()
        pretty.print(vec3(2,3,4))
        local ident = mat4(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
        print(table.concat(ident.data, ","))
        pretty.print(ident)
        print(type(ident), ident:type())
        pretty.print(mat4.vmul(ident, vec3(2,3,4)))

        -- Rotation
        local rotate90 = mat4( 0,1,0,0, -1,0,0,0, 0,0,1,0, 0,0,0,1 )
        assert(vec3.equals(mat4.vmul(rotate90, vec3(1,0,0)),vec3(0,1,0)))
        assert(vec3.equals(mat4.vmul(rotate90, vec3(0,1,0)),vec3(-1,0,0)))
    end,

    function()
        -- Matrix multiplication
        local rotate90 = mat4( 0,1,0,0, -1,0,0,0, 0,0,1,0, 0,0,0,1 )
        local rotateNeg90 = mat4( 0,-1,0,0, 1,0,0,0, 0,0,1,0, 0,0,0,1 )
        local transform = rotate90:mmul(rotateNeg90)
        local identity = mat4( 1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1 )
        assert(mat4.equals(transform, identity))
    end,


}

for i, test in ipairs(tests) do 
    print("Test " .. i)
    test() 
end
