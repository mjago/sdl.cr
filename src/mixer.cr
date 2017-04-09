require "./lib_mixer"
require "./sdl"

module SDL
  module Mixer
    private alias LMix = LibMixer
    alias Init = LMix::Init
    alias Chunk = LMix::Mix_Chunk
    alias Type = LMix::MusicType
    alias FadeStatus = LMix::FadeStatus
    MAX_VOLUME = LMix::MIN_MAX_VOLUME

    def self.init(flags : Init)
      ret = LMix.init(flags)
      unless (ret & flags.value) == flags.value
        raise SDL::Error.new("Mix_Init failed to init #{flags}")
      end
    end

    def self.open(freq = 44100, format = 0_u16, channels = 2, sample_size = 2048)
      format = format == 0 ? LMix::MIX_DEFAULT_FORMAT : format.to_u16
      ret = LMix.open_audio(freq, format, channels, sample_size)
      raise SDL::Error.new("Mix_OpenAudio") unless ret == 0
      ret
    end

    def self.query_spec(frequency_ptr, format_ptr, channels_ptr)
      format = 0_u16
      ret = LMix.query_spec(frequency_ptr, pointerof(format), channels_ptr)
      raise SDL::Error.new("Mix_QuerySpec") unless ret > 0
      format_ptr.value = format.to_i32
      ret
    end

    def self.close
      LMix.close_audio
    end

    def self.quit
      LMix.quit
    end
  end

  # Sample Class

  module Mixer
    class Sample
      protected getter sample

      def initialize(filename = nil)
        load filename if filename
      end

      def load(filename)
        rwops = LibSDL.rw_from_file(filename, "rb")
        @sample = LMix.load_wav_rw(rwops, 1)
        raise SDL::Error.new("Mix_LoadWAV_RW") unless @sample
      end

      def quick_load(mem)
        @sample = LMix.quick_load_wav(mem)
        raise SDL::Error.new("Mix_QuickLoad_WAV") unless @sample
      end

      def quick_load(mem, size)
        @sample = LMix.quick_load_raw(mem, size)
        raise SDL::Error.new("Mix_QuickLoad_WAV") unless @sample
      end

      def free
        LMix.free_chunk(sample)
      end

      def self.decoder_count
        LMix.get_num_chunk_decoders
      end

      def self.decoder_name(index)
        LMix.get_chunk_decoder(index)
      end
    end
  end

  # Music Class

  module Mixer
    class Music
      private getter music : Pointer(LMix::Music) | Nil

      def initialize(filename = nil)
        @music = filename ? load(filename) : nil
      end

      def play(repeats = -1)
        LMix.play_music(music, repeats)
      end

      def pause
        LMix.pause_music
      end

      def resume
        LMix.resume_music
      end

      def stop
        LMix.halt_music
      end

      def playing?
        LMix.music_playing == 1
      end

      def paused?
        LMix.music_paused == 1
      end

      def rewind
        LMix.rewind_music
      end

      def fade_in(loops = -1, msec = 1000)
        LMix.fade_in_music(music, loops, msec)
      end

      def fade_out(msec = 1000)
        LMix.fade_out_music(msec)
      end

      def volume=(volume)
        LMix.music_volume(volume > MAX_VOLUME ? MAX_VOLUME : volume)
      end

      def volume
        LMix.music_volume(-1)
      end

      def load(filename, typ : Type? = nil)
        rwops = LibSDL.rw_from_file(filename, "rb")
        @music = typ ? load_music_type(rwops, typ) : load_music(rwops)
      end

      def free
        LMix.free_music(music)
        @music = nil
      end

      private def load_music(rwops)
        audio = LMix.load_mus_rw(rwops, 1)
        raise SDL::Error.new("Mix_LoadMUSType_RW") unless audio
        audio
      end

      private def load_music_type(rwops, typ)
        audio = LMix.load_mus_type_rw(rwops, typ.to_s, 1)
        raise SDL::Error.new("Mix_LoadMUS_RW") unless audio
        audio
      end
    end
  end

  # Channel Class

  module Mixer
    class Channel
      property id

      def initialize(@id = 1)
        @@count ||= 8 unless @@count
      end

      def self.allocate_channels(count)
        @@count = count
        LMix.allocate_channels(count)
      end

      def self.reserve_channels(count)
        @@reserved = count
        LMix.reserve_channels(count)
      end

      def self.play(smpl, repeats = 0)
        LMix.play_channel(-1, smpl.sample, repeats)
      end

      def self.play(smpl, repeats = 0, ticks = -1)
        LMix.play_channel_timed(-1, smpl.sample, repeats, ticks)
      end

      def self.fade_in(smpl : Sample, loops = 0, ms = 1000, ticks = -1)
        LMix.fade_in_channel(-1, smpl.sample, loops, ms, ticks)
      end

      def self.fade_out(ms = 1000)
        LMix.fade_out_channel(-1, ms)
      end

      def self.resume
        LMix.resume_music(-1)
      end

      def self.expire(ticks)
        LMix.channel_expire(-1, ticks)
      end

      def self.channels
        @@count || 0
      end

      def self.reserved
        @@reserved || 0
      end

      def self.volume=(volume)
        LMix.channel_volume(-1, volume > MAX_VOLUME ? MAX_VOLUME : volume)
      end

      def self.paused_count
        LMix.channel_paused(-1)
      end

      def self.finished(func)
        LMix.cb_channel_finished(func)
      end

      def play(smpl, repeats = 0)
        LMix.play_channel(id, smpl.sample, repeats)
      end

      def play(smpl, repeats = 0, ticks = -1)
        LMix.play_channel_timed(id, smpl.sample, repeats, ticks)
      end

      def fade_in(smpl : Sample, loops = 0, ms = 1000, ticks = -1)
        LMix.fade_in_channel(id, smpl.sample, loops, ms, ticks)
      end

      def fade_out(ms = 1000)
        LMix.fade_out_channel(id, ms)
      end

      def expire
        LMix.channel_expire(id, ticks)
      end

      def fading?
        LMix.fading? id
      end

      def paused?
        LMix.channel_paused(id) == 1
      end

      def volume=(volume)
        LMix.channel_volume(id, volume > MAX_VOLUME ? MAX_VOLUME : volume)
      end

      def volume
        LMix.channel_volume(id, -1)
      end
    end
  end
end
