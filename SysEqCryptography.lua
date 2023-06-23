math.randomseed( os.time() )

-- Libary-less Table Dump from StackOverflow
-- https://stackoverflow.com/a/27028488
local function dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '\n['..k..'] = ' .. dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

-- Generates Public key(List of linear equations)
-- Takes in the private_key to generate the lists
local function generateLists(private_key, mod_val, offset_Val)
  local templist = {}
  for i = 1,1000 do
    -- Eq V + X + Y + Z
    local foo = {math.random(10000),math.random(10000),math.random(10000),math.random(10000)}
    -- Summation + Error mod 257
    local summ = ( (foo[1] * private_key[1]) + (foo[2] * private_key[2])
                  + (foo[3] * private_key[3]) + (foo[4] * private_key[4])
                  + math.random(offset_Val) ) % mod_val

    templist[i] = {foo[1],foo[2],foo[3],foo[4],summ} 
  end
  
  return templist
end


-- Encodes the Message using random partition selections of Public Key
-- Takes in the public key, mod_val, message and returns an encoded message
function generateEncoded(public_key, mod_val, alph_size, msgobj)
  local templist = {}
  for i = 1, #msgobj do
    --[[ Partition of Equations 
        - Select a random partition of equations(5 in this example)
        - Sum up the 5 equations to formulate a new Equation
    ]]       
    local i1,i2,i3,i4,i5 = math.random(1000), math.random(1000), math.random(1000),
                           math.random(1000), math.random(1000)
 
    --Calculations for combined equations
    local comb_eq = {public_key[i1][1] + public_key[i2][1] + public_key[i3][1] + public_key[i4][1] + public_key[i5][1],
                 public_key[i1][2] + public_key[i2][2] + public_key[i3][2] + public_key[i4][2] + public_key[i5][2],
                 public_key[i1][3] + public_key[i2][3] + public_key[i3][3] + public_key[i4][3] + public_key[i5][3],
                 public_key[i1][4] + public_key[i2][4] + public_key[i3][4] + public_key[i4][4] + public_key[i5][4]
    }

    local comb_eq_summ = ((public_key[i1][5] + public_key[i2][5] + public_key[i3][5] + public_key[i4][5] + public_key[i5][5]) % mod_val)
    
    --[[ Encoding:
        - Calculate distance by dividing modVal by size of alphabet
        - Take the message and multiply its index location by distance
        - Then, add to combined equation sum and modulus again
    ]]
    comb_eq_res = ((msgobj[i] * alph_size) + comb_eq_summ) % mod_val
    templist[i] = {comb_eq[1],comb_eq[2],comb_eq[3],comb_eq[4],comb_eq_res}
  end

  return templist
end


-- Decode message using private key to remove offset and retreive msg values
-- Takes in the Encoded Message(system of equations), returns decoded message
function decodeMessage(enc_msg, private_key, mod_val, alph_size)
  --[[ Decoding:
       - Private Key can be used to calculate actual expected values
       - Subtract Error Sums with Actual expected sums to get encErr
       - encErr contains distance + error amount
  ]]

  local templist = {} 
  --For visualizing Error amount
  local templist2 = {}
  
  -- Combined Error Result - Expected Value = Distance + Offset
  -- Offset < 1 by the way we picked, integer division removes the offset
  for i = 1, #enc_msg do
    local accVal = ((enc_msg[i][1] * private_key[1]) + (enc_msg[i][2] * private_key[2]) +
                    (enc_msg[i][3] * private_key[3]) + (enc_msg[i][4] * private_key[4]) ) % mod_val

    local encErr = enc_msg[i][5] - accVal

    --If negative, find positive reciprocal in modulus
    if encErr < 0 then
      encErr = encErr + mod_val
    end

    templist[i] = encErr // alph_size
    templist2[i] = encErr /alph_size
  end

  return templist, templist2
end


--[[Variable Definition:
    - Private Info
      - privatekey: Key that solves for the equation list before offset
      - offsetVal: Error that is added into the public_eq_list
        - MUST follow these rules:
          - Offset < [(alphsize) / (Variable number)]

    - Public Info
      - public_eq_list: List of 1000 equations with randomized offsets
      - modVal: Large prime number for Modular Calculations
      - charamt: The number of unique characters for alphabet
      - alphsize: distance calculation for modVal divided into charamt parts,
                  used in calculating offset
]]
local privatekey = {3, -9, 34, -47}

--[[ Changeable Values for Public Info
     - public_eq_list: Public Table for system of equations
     
     - Alphabet Size: Size of the Alphabet(A-Z = 26 characters)
     - Offset Value: Possible distance of error, must follow restrictions below:
       - Offset < [(alphsize) / (Variable number)]
       - 4 < [(523 / 26) / 4 ]   =>   4 < 5.02
]]

local modVal = 523
local charamt = 26
local alphdist = modVal // charamt  
local offsetVal = 4
local public_eq_list = generateLists(privatekey, modVal, offsetVal)

-- original msg -> HELLOWORLD
-- msg2: returned equation after encoding
-- msg3: Completely Decoded without Error
-- msg4: Decoded with Error
local msg = {8,5,12,12,15,23,15,18,12,4}
local msg2, msg3, msg4 = {}, {}, {}

msg2 = generateEncoded(public_eq_list, modVal, alphdist, msg)
msg3, msg4 = decodeMessage(msg2, privatekey, modVal, alphdist)

print("Original Message ".. dump(msg))
print("\n\nEncoded Message : V+X+Y+Z = sum (mod "..modVal..") ".. dump(msg2))
print("\n\nDecoded Message w/ Err: ".. dump(msg4))
print("\n\nDecoded Message w/out Err: ".. dump(msg3))
