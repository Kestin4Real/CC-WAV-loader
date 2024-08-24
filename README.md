The WAVLib.lua is for loading WAV files for use in ComputerCraft!
Here is a quick example script:

```
local api_WAV = require('WAVLib') --Load the API
local speaker = peripheral.find('speaker') --Prep the speaker
local audio = api_WAV.Load('Ievan Polkka.wav') --Load the audio data

local samples = 0 --Store how meny samples have played (Another name could be offset)
speaker.stop() --Stop any sounds playing by the speaker (If any)
while samples < audio.samples do --Loop true all the audio
    local buffer = {} --Prep the buffer
    for i=0, 131072 do --Get 131072 samples for the buffer
        buffer[i] = audio[math.floor((i + samples) * (audio.frequency / 48000) * 1.25)] --Load sample into the buffer
    end
    samples = samples + 131072 --Add 131072 to the already "played" samples count

    while not speaker.playAudio(buffer) do --Try to play buffered audio
        os.pullEvent("speaker_audio_empty") --Wait into speaker has finished playing audio
    end
end
```
New to GIT so any help is welcome!
Same goes for the library!
