# frozen_string_literal: true

require 'pp'
require 'open3'
require 'oj'

# xmp merge
class XMPRewriter
  XMP_TAGS = {
    title: 'XMP:Title',
    descr: 'XMP:Description',
    data:  'XMP:UserComment',
    tags:  'XMP:Subject',
    htags: 'XMP:HierarchicalSubject',
    lat:   'XMP:GPSLatitude',
    lon:   'XMP:GPSLongitude'
  }

  def initialize(opts = {})
    @v = opts[:v]
    @dry = opts[:dry]
    @files = {}
  end

  def add_file(ihsh, filename)
    if @v
      # fields = %(Title Description Subject)
      # puts "add rewr: #{filename} #{@xmp.to_hash.slice(*fields)}"
      puts "js:#{ihsh.slice(:title, :descr, :gps, :tags)} "
    end
    @files[filename] = ihsh
  end

  def go
    files = @files.keys.join(' ')
    keys = XMP_TAGS.values.map { |k| "-#{k}" }.join(' ')
    cmd = %(exiftool -j -G -n #{keys} #{files})
    out, err, st = Open3.capture3 cmd
    unless st.success?
      warn "ERR: #{out} #{err} #{st}"
      return
    end
    if out.empty?
      warn 'empty'
      return
    end
    parse_meta(out)
  end

  private

  def parse_meta(info)
    files = Oj.load info
    process_files(files)
  rescue Oj::ParseError => e
    warn "bad json? #{e}"
  end

  def process_files(files)
    # pp files[f['SourceFile']]
    files.each do |f|
      file = f['SourceFile']
      ih = @files[file]
      puts "f:#{f.except('XMP:UserComment')}"
      puts "ih:#{ih.except(:data)}"
      title(f, ih)
      #description(ih[:descr])
      #usercomment(ih[:data])
      #subject(ih[:tags])
      #hierarchicalsubject(ih[:tags])
      #gps(ih[:gps])
    end
  end

  def title(xmp, flickr)
    # xmp['XMP:Title'] flickr[:title]
    x = 'XMP:Title'
    return unless flickr[:title]

    xmp[x] = flickr[:title] if @xmp.title.to_s.empty?
  end

  def description(descr)
    # f['XMP:Description'] :descr
    return unless descr

    @xmp.description = descr if @xmp.description.to_s.empty?
  end

  def usercomment(data)
    # f['XMP:UserComment'] :data
    return if !data || (data == @xmp.usercomment)

    @xmp.usercomment = data if @xmp.usercomment.to_s.empty?
  end

  def subject(tags)
    # f['XMP:Subject'] :tags
    return unless tags

    @xmp.subject = @xmp.subject ? @xmp.subject.concat(tags).uniq : tags
  end

  def hierarchicalsubject(tags)
    # f['XMP:HierarchicalSubject']
    return unless tags

    hs = @xmp.hierarchicalsubject
    @xmp.hierarchicalsubject = hs ? hs.concat(tags).uniq : tags
  end

  def gps(hgps)
    # f['XMP:GPSLatitude'] f['XMP:GPSLongitude'] gps: [:lat :lon]
    return unless hgps

    @xmp.gpslatitude  = hgps[:lat] unless @xmp.gpslatitude
    @xmp.gpslongitude = hgps[:lon] unless @xmp.gpslongitude
  end
end
