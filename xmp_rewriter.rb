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
    title(ihsh[:title])
    description(ihsh[:descr])
    usercomment(ihsh[:data])
    subject(ihsh[:tags])
    hierarchicalsubject(ihsh[:tags])
    gps(ihsh[:gps])

    @xmp.save unless @o.dry
  end

  private

  def title(title)
    @xmp.title = title if title && @xmp.title.to_s.empty?
  end

  def description(descr)
    @xmp.description = descr if descr && @xmp.description.to_s.empty?
  end

  def usercomment(data)
    next if !data || (data == @xmp.usercomment) || @xmp.usercomment.to_s.empty?

    @xmp.usercomment = data
  end

  def subject(tags)
    next unless tags

    @xmp.subject = @xmp.subject ? @xmp.subject.concat(tags).uniq : tags
  end

  def hierarchicalsubject(tags)
    next unless tags

    hs = @xmp.hierarchicalsubject
    @xmp.hierarchicalsubject = hs ? hs.concat(tags).uniq : tags
  end

  def gps(hgps)
    return unless hgps

    @xmp.gpslatitude  = hgps[:lat] unless @xmp.gpslatitude
    @xmp.gpslongitude = hgps[:lon] unless @xmp.gpslongitude
  end
end
