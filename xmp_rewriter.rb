# frozen_string_literal: true

require 'mini_exiftool'

class XMPRewriter

  def initialize ih, filename, opts = {}
    @v = opts[:v]
    @filename = filename
    @xmp = MiniExiftool.new @filename
    if @v
      puts "#{filename}: #{@xmp.to_hash.slice('Title','Description','Subject')}"
      puts "js:#{ih.slice(:title, :descr, :gps, :tags)} "
    end
    @xmp.title = ih[:title] if ih[:title] && @xmp.title.to_s.empty?
    @xmp.description = ih[:descr] if ih[:descr] && @xmp.description.to_s.empty?
    if ih[:gps] && !@xmp.gpslatitude && !@xmp.gpslongitude
      @xmp.gpslatitude  = ih[:gps][:lat]
      @xmp.gpslongitude = ih[:gps][:lon]
    end
    @xmp.usercomment = ih[:data] if ih[:data] && @xmp.usercomment.to_s.empty?
    if ih[:tags]
      @xmp.subject = if @xmp.subject
                       @xmp.subject.concat(ih[:tags]).uniq
                     else
                       ih[:tags]
                     end
      @xmp.hierarchicalsubject = if @xmp.hierarchicalsubject
                       @xmp.hierarchicalsubject.concat(ih[:tags]).uniq
                     else
                       ih[:tags]
                     end

    end
    @xmp.save

  end

end
