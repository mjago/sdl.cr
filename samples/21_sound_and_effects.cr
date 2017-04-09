require "../src/sdl"
require "../src/image"
require "../src/mixer"

alias Mix = SDL::Mixer

SDL.init(SDL::Init::VIDEO | SDL::Init::AUDIO); at_exit { SDL.quit }
Mix.init(Mix::Init::MP3); at_exit { Mix.quit }
Mix.open

DATA_DIR = File.join(__DIR__, "data")

music_file = File.join(DATA_DIR, "beat.wav")
music = Mix::Music.new music_file

samples = {} of String => Mix::Sample
channels = {} of String => Mix::Channel
names = %w(high medium low scratch)
names.each_with_index do |name, idx|
  samples[name] = Mix::Sample.new(File.join(DATA_DIR, "#{name}.wav"))
  channels[name] = Mix::Channel.new(idx)
end

window = SDL::Window.new("SDL Tutorial", 640, 480)
png = SDL::IMG.load(File.join(__DIR__, "data", "prompt.png"))
png = png.convert(window.surface)
activekey = [] of LibSDL::Keycode

puts "Q to quit..."

loop do
  case event = SDL::Event.wait
  when SDL::Event::Quit
    music.stop
    music.free
    Mix.close
    break
  when SDL::Event::Keyboard
    key = event.sym
    unless activekey.includes? key
      case key
      when .key_1?
        Mix::Channel.play samples["high"] # allocate any free channel
      when .key_2?
        channels["medium"].play samples["medium"] # play through specific channel
      when .key_3?
        channels["low"].play samples["low"]
      when .key_4?
        channels["scratch"].play samples["scratch"]
      when .key_9?
        if music.paused?
          music.resume
        elsif music.playing?
          music.pause
        else
          music.play
        end
      when .key_0?
        music.resume if music.paused?
        music.stop
      when LibSDL::Keycode::Q
        music.free
        Mix.close
        break
      end
      activekey << key
    end
    activekey.delete key if event.keyup?
  end
  png.blit(window.surface)
  window.update
end
