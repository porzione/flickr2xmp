# frozen_string_literal: true

require 'mini_exiftool'

# xmp merge
class XMPRewriter
  def initialize(ihsh, filename, opts = {})
    @v = opts[:v]
    @dry = opts[:dry]
    @filename = filename
    @xmp = MiniExiftool.new @filename
    if @v
      fields = %(Title Description Subject)
      puts "#{filename}: #{@xmp.to_hash.slice(*fields)}"
      puts "js:#{ihsh.slice(:title, :descr, :gps, :tags)} "
    end
    @xmp.title = ihsh[:title] if ihsh[:title] && @xmp.title.to_s.empty?
    @xmp.description = ihsh[:descr] if ihsh[:descr] && @xmp.description.to_s.empty?
    if ihsh[:gps] && !@xmp.gpslatitude && !@xmp.gpslongitude
      @xmp.gpslatitude  = ihsh[:gps][:lat]
      @xmp.gpslongitude = ihsh[:gps][:lon]
    end
    @xmp.usercomment = ihsh[:data] if ihsh[:data] &&
                                      @xmp.usercomment.to_s.empty? &&
                                      (ihsh[:data] != @xmp.usercomment)
    if ihsh[:tags]
      @xmp.subject = if @xmp.subject
                       @xmp.subject.concat(ihsh[:tags]).uniq
                     else
                       ihsh[:tags]
                     end
      @xmp.hierarchicalsubject = if @xmp.hierarchicalsubject
                                   @xmp.hierarchicalsubject.concat(ihsh[:tags]).uniq
                                 else
                                   ihsh[:tags]
                                 end
    end
    @xmp.save
  end
end
