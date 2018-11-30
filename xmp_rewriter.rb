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
  }.freeze

  def initialize(opts = {})
    @v = opts[:v]
    @dry = opts[:dry]
    @upd = opts[:u]
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
      puts "\nf: #{f.except('XMP:UserComment')}"
      puts "ih: #{ih.except(:data)}"
      args = []
      args << title(f, ih)
      args << description(f, ih)
      args << usercomment(f, ih)
      args << subject(f, ih)
      args << hierarchicalsubject(f, ih)
      args << gps(f, ih)
      puts "args: #{args.compact}"
    end
  end

  def title(xmp, flickr)
    x = 'XMP:Title'
    s = :title
    return unless flickr[s]
    return if !xmp[x].to_s.empty? && !@upd
    return if xmp[x] == flickr[s]

    [x, flickr[s]]
  end

  def description(xmp, flickr)
    x = 'XMP:Description'
    s = :descr
    return unless flickr[s]
    return if !xmp[x].to_s.empty? && !@upd
    return if xmp[x] == flickr[s]

    [x, flickr[s]]
  end

  def usercomment(xmp, flickr)
    x = 'XMP:UserComment'
    s = :data
    return unless flickr[s]
    return if !xmp[x].to_s.empty? && !@upd
    return if xmp[x] == flickr[s]

    [x, flickr[s]]
  end

  def subject(xmp, flickr)
    x = 'XMP:Subject'
    s = :tags
    return unless flickr[s]
    return if xmp[x] && !@upd
    return if xmp[x] == flickr[s]

    xmp[x] = [xmp[x]] unless xmp[x].is_a?(Array)
    tags = xmp[x] ? xmp[x].concat(flickr[s]).uniq : flickr[s]
    [x, tags.join(',')]
  end

  def hierarchicalsubject(xmp, flickr)
    x = 'XMP:HierarchicalSubject'
    s = :tags
    return unless flickr[s]
    return if xmp[x] && !@upd
    return if xmp[x] == flickr[s]

    xmp[x] = [xmp[x]] unless xmp[x].is_a?(Array)
    tags = xmp[x] ? xmp[x].concat(flickr[s]).uniq : flickr[s]
    [x, tags.join(',')]
  end

  def gps(xmp, flickr)
    xlat = 'XMP:GPSLatitude'
    xlon = 'XMP:GPSLongitude'
    f = flickr[:gps] || return
    flat = f.strfcoord("%lat")
    flng = f.strfcoord("%lng")
    return unless flickr[:gps]

    puts "GPS: x:#{xmp[xlat]} f:#{flat}"

    # @xmp.gpslatitude  = hgps[:lat] unless @xmp.gpslatitude
    # @xmp.gpslongitude = hgps[:lon] unless @xmp.gpslongitude
  end
end
