# frozen_string_literal: true

require 'mini_exiftool'

class ReXMP

  def initialize ih, filename, opts = {}
    @v = opts[:v]
    @filename = filename
    @xmp = MiniExiftool.new @filename
    if @v
      puts "> xmp #{filename}: #{@xmp.to_hash.slice('Title','Description','Subject')}"
      puts "> json:#{ih.slice(:title, :descr, :gps, :tags)} "
    end
    @xmp.title = ih[:title] if ih[:title] && @xmp.title.to_s.empty?
    @xmp.description = ih[:descr] if ih[:descr] && @xmp.description.to_s.empty?
    tags_merge ih[:tags]
    unless @xmp.gpslatitude && @xmp.gpslongitude
      @xmp.gpslatitude  = ih[:gps][:lat]
      @xmp.gpslongitude = ih[:gps][:lon]
    end
    puts "> uc ih e:#{ih[:data].to_s.empty?} xmp e:#{@xmp.usercomment.to_s.empty?}"
    @xmp.usercomment = ih[:data] if ih[:data] && @xmp.usercomment.to_s.empty?

    pp @xmp.to_hash
    #write
  end

  def write
    #File.open(@filename, 'w') { |f| f.write(out) }
  end

  private

  def tags_merge new_tags
    old_tags = @xmp.subject
    @xmp.subject = old_tags.concat(new_tags).uniq
  end

end
