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

    @xmp.save unless @dry
  end

  private

  def title(title)
    return unless title

    end
    @xmp.title = title if @xmp.title.to_s.empty?
  end

  def description(descr)
    return unless descr

    @xmp.description = descr if @xmp.description.to_s.empty?
  end

  def usercomment(data)
    return if !data || (data == @xmp.usercomment)

    @xmp.usercomment = data if @xmp.usercomment.to_s.empty?
  end

  def subject(tags)
    return unless tags

    @xmp.subject = @xmp.subject ? @xmp.subject.concat(tags).uniq : tags
  end

  def hierarchicalsubject(tags)
    return unless tags

    hs = @xmp.hierarchicalsubject
    @xmp.hierarchicalsubject = hs ? hs.concat(tags).uniq : tags
  end

  def gps(hgps)
    return unless hgps

    @xmp.gpslatitude  = hgps[:lat] unless @xmp.gpslatitude
    @xmp.gpslongitude = hgps[:lon] unless @xmp.gpslongitude
  end
end
