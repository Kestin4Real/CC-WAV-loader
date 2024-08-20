local api = {}
local file = nil

local function ReadBytesBig(amount)
    local integer = 0
    for i=1, amount do
        integer = bit.blshift(integer, 8) + file.read()
    end
    return integer
end

local function ReadBytesLittle(amount, signed)
    if signed == nil then signed = false end
    local integer = 0
    for i=1, amount do
        local byte = file.read()
        integer = integer + bit.blshift(byte, 8 * (i-1))
        if signed then if i == amount then
            local sign = bit.brshift(byte, 7) == 1
            if not sign then return integer end
            integer = integer - bit.blshift(1, 7 + (8 * (i-1)))
            integer = integer - (math.pow(256, amount) / 2)
        end end
    end
    return integer
end

local function ReadBytesAsHex(amount)
    local hex = ''
    for i=1, amount do
        hex = hex .. string.format('%02X', file.read())
    end
    return hex
end

local function ParseFMTchunk(audio, file) --FMT subchunk parser
    if not (ReadBytesLittle(4) == 16) then print('File is in a incorrect format or corrupted 0x04') return end --Check for chunk size 16
    if not (ReadBytesAsHex(2) == '0100') then print('File is in a incorrect format or corrupted 0x05') return end --Check WAVE type 0x01
    audio.channels = ReadBytesLittle(2) --number of channels
    audio.frequency = ReadBytesLittle(4) --sample frequency
    ReadBytesBig(4) --bytes/sec (Garbage Data)
    ReadBytesBig(2) --block alignment (Garbage Data)
    audio.bytesPerSample = ReadBytesLittle(2) / 8 --bits per sample
end

local function ParseDATAchunk(audio, file) --DATA subchunk parser
    --size of the data chunk
    audio.samples = ReadBytesLittle(4) / audio.channels / audio.bytesPerSample
    audio.lenght = audio.samples / audio.frequency
    for s=0, audio.samples-1 do
        local sample = 0
        for c=0, audio.channels-1 do
            sample = sample + ReadBytesLittle(audio.bytesPerSample, audio.bytesPerSample > 1);
            if audio.bytesPerSample == 1 then sample = sample - 128 end
        end
        audio[s] = math.floor(sample / audio.channels / math.max(256 * (audio.bytesPerSample - 1), 1))
    end
end

local function ParseDUMMYchunk(audio, file) --Parser for non essential data
    ReadBytesLittle(ReadBytesLittle(4))
end

local parsers = {}
parsers['666D7420'] = ParseFMTchunk --FMT subchunk parser
parsers['64617461'] = ParseDATAchunk --DATA subchunk parser

function api.Load(path)
    path = shell.resolve(path)
    if not fs.exists(path) then print('File does not exists') return end
    if fs.isDir(path) then print('File does not exists') return end
    file = fs.open(path, 'rb')
    local audio = {}

    if not (ReadBytesAsHex(4) == '52494646') then print('File is in a incorrect format or corrupted 0x01') file.close() return end --Check header for RIFF
    ReadBytesLittle(4) -- size of file
    if not (ReadBytesAsHex(4) == '57415645') then print('File is in a incorrect format or corrupted 0x02') file.close() return end --Check WAVE header for WAVE

    while audio.lenght == nil do
        local subchunk = ReadBytesAsHex(4)
        if subchunk == nil then print('File is in a incorrect format or corrupted 0x03') file.close() return end
        local parser = parsers[subchunk]
        if parser == nil then ParseDUMMYchunk(audio, file)
        else parser(audio, file) end
    end
    file.close()

    return audio
end

return api