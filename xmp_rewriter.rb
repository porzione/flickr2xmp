# frozen_string_literal: true

require 'open3'
require 'oj'

# xmp merge
class XMPRewriter
  XMP_TAGS = {
    title: 'XMP:Title',
    descr: 'XMP:Description',
    tags:  'XMP:Subject',
    htags: 'XMP:HierarchicalSubject',
    lat:   'XMP:GPSLatitude',
    lon:   'XMP:GPSLongitude',
    id:    'XMP:FlickrId',
    url:   'XMP:FlickrUrl',
    views: 'XMP:FlickrViews',
    faves: 'XMP:FlickrFaves',
    data:  'XMP:Flickr'
  }.freeze

  def initialize(opts = {})
    @v = opts[:v]
    @dry = opts[:dry]
    @upd = opts[:u]
    @files = {}
    @cfg = "#{__dir__}/exiftool.pl"
  end

  def add_file(ihsh, filename)
    puts "add js:#{ihsh.slice(:title, :descr, :gps, :tags)} #{filename}" if @v
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
    files.each do |f|
      # puts "process file: #{f}" if @v
      file = f['SourceFile']
      ih = @files[file]
      if @v
        puts "\nf: #{f.except('XMP:UserComment')}",
             "ih: #{ih.except(:data)}"
      end
      args = []
      args << title(f, ih)
      args << description(f, ih)
      args << flickr(f, ih)
      args << subject(f, ih)
      args << hierarchicalsubject(f, ih)
      args.concat(gps(f, ih))
      next if args.empty?

      rewrite(file, args)
    end
  end

  def rewrite(file, args)
    sarg = args.compact.map { |a| "-#{a[0]}='#{a[1]}'" }.join(' ')
    cmd = "exiftool -config #{@cfg} #{sarg} #{file}"
    puts "cmd: #{cmd}" if @v
    return if @dry

    out, err, st = Open3.capture3 cmd
    if st.success?
      puts "success: #{out}" if @v
    else
      warn "ERR: #{out} #{err} #{st}"
      return
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

  #  fl_id:  'XMP:FlickrId',
  #  fl_url: 'XMP:FlickrUrl',
  #  fl_v:   'XMP:FlickrViews',
  #  fl_f:   'XMP:FlickrFaves',
  #  flickr: 'XMP:Flickr'

  def flickr(xmp, flickr)
    puts "xmp: #{xmp}"
    fl = flickr[:flickr]
    puts "fl: #{fl}"
    res = []
    fl.members.each do |s|
      x = XMP_TAGS[s]
      # puts "s:#{s} #{x} #{fl[s]}"
      res << [x, fl[s]]
    end
    res.flatten

    # return unless flickr[s]
    # return if !xmp[x].to_s.empty? && !@upd
    # return if xmp[x] == flickr[s]

    # [x, flickr[s]]
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
    # puts "gps: #{xmp[xlat]} #{xmp[xlon]}" if @v
    return [] if xmp[xlat] && xmp[xlon] && !@upd

    f = flickr[:gps] || return
    flat = f.strfcoord('%lat')
    flon = f.strfcoord('%lng')

    puts "GPS: x/f:#{xmp[xlat]}/#{flat} #{xmp[xlon]}/#{flon}" if @v
    [
      [xlat, flat],
      [xlon, flon]
    ]
  end
end
