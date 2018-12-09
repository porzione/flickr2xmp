# frozen_string_literal: true

require 'open3'
require 'oj'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash'

# xmp merge
class XMPRewriter
  XMP_TAGS = {
    title: 'XMP:Title',
    descr: 'XMP:Description',
    tags:  'XMP:Subject',
    htags: 'XMP:HierarchicalSubject',
    lat:   'XMP:GPSLatitude',
    lon:   'XMP:GPSLongitude',
    id:    'XMP-flickr:id',
    url:   'XMP-flickr:url',
    views: 'XMP-flickr:views',
    faves: 'XMP-flickr:faves',
    data:  'XMP-flickr:data'
  }.freeze

  def initialize(opts = {})
    @v = opts[:v]
    @vg = opts[:vg]
    @vv = opts[:vv]
    @dry = opts[:dry]
    @upd = opts[:u]
    @files = {}
    @cfg = "#{__dir__}/exiftool.pl"
    prepare_flickr
  end

  def add_file(ihsh, filename)
    if @v
      h = ihsh.slice(:title, :descr, :gps, :tags)
      h[:gps] = h[:gps]&.to_s(dms: false)
      puts "add js:#{h} #{filename}"
    end
    @files[filename] = ihsh
  end

  def go
    files = @files.keys.join(' ')
    if files.empty?
      warn 'no files to rewrite'
      return
    end
    keys = XMP_TAGS.values.map { |k| "-#{k}" }.join(' ')
    cmd = %(exiftool -config #{@cfg} -j -G -n #{keys} #{files})
    puts "cmd read: #{cmd}" if @v
    out, err, st = Open3.capture3 cmd
    unless st.success?
      warn "ERR go: #{out} #{err} #{st}"
      return
    end
    if out.empty?
      warn 'empty'
      return
    end
    parse_meta(out)
  end

  private

  # exiftool output names instead of XMP-flickr
  def prepare_flickr
    @fl_tags = {}
    XMP_TAGS.each_pair do |s, tag|
      if (m = tag.match(/^XMP-flickr:(?<name>\w+)$/))
        @fl_tags[s] = "XMP:#{m['name'].capitalize}"
      end
    end
    @fl_tags.freeze
  end

  def parse_meta(info)
    files = Oj.load info
    process_files(files)
  rescue Oj::ParseError => e
    warn "bad json? #{e}"
  end

  def process_files(files)
    files.each do |f|
      file = f['SourceFile']
      ih = @files[file]
      if @vv
        puts "\nf: #{f}",
             "ih: #{ih}"
      end
      args = []
      args << title(f, ih)
      args << description(f, ih)
      flickr(f, ih) { |t| args << t }
      args << subject(f, ih)
      args << hierarchicalsubject(f, ih)
      gps(f, ih) { |g| args << g }
      args.compact!
      next if args.empty?

      rewrite(file, args)
    end
  end

  def rewrite(file, args)
    puts "rewrite args:#{args.reject { |i| i[0] == 'XMP:Data' }}" if @vv
    sarg = args.map { |a| "-#{a[0]}='#{a[1]}'" }.join(' ')
    cmd = "exiftool -config #{@cfg} #{sarg} #{file}"
    puts "cmd write: #{cmd}" if @v
    return if @dry

    out, err, st = Open3.capture3 cmd
    if st.success?
      puts "success: #{out}" if @v
    else
      warn "ERR rew: #{out} #{err} #{st}"
      return
    end
  end

  def title(xmp, flickr)
    s = :title
    x = XMP_TAGS[s]
    return unless flickr[s]
    return if !xmp[x].to_s.empty? && !@upd
    return if xmp[x] == flickr[s]

    [x, flickr[s]]
  end

  def description(xmp, flickr)
    s = :descr
    x = XMP_TAGS[s]
    return unless flickr[s]
    return if !xmp[x].to_s.empty? && !@upd
    return if xmp[x] == flickr[s]

    [x, flickr[s]]
  end

  def subject(xmp, flickr)
    s = :tags
    x = XMP_TAGS[s]
    return unless flickr[s]
    return if xmp[x] && !@upd
    return if xmp[x] == flickr[s]

    xmp[x] = [xmp[x]] unless xmp[x].is_a?(Array)
    tags = xmp[x] ? xmp[x].concat(flickr[s]).uniq : flickr[s]
    [x, tags.join(',')]
  end

  def hierarchicalsubject(xmp, flickr)
    s = :htags
    x = XMP_TAGS[s]
    return unless flickr[s]
    return if xmp[x] && !@upd
    return if xmp[x] == flickr[s]

    xmp[x] = [xmp[x]] unless xmp[x].is_a?(Array)
    tags = xmp[x] ? xmp[x].concat(flickr[s]).uniq : flickr[s]
    [x, tags.join(',')]
  end

  def gps(xmp, flickr)
    raise unless block_given?

    if @vg
      f = 'SourceFile', 'XMP:GPSLatitude', 'XMP:GPSLongitude'
      puts "gps: xmp #{xmp.slice(*f)}"
    end
    fgps = flickr[:gps] || return
    [
      { s: :lat, f: '%lat' },
      { s: :lon, f: '%lng' }
    ].each do |i|
      next if xmp[i[:t]] && !@upd

      s = XMP_TAGS[i[:s]]
      fmt = fgps.strfcoord(i[:f])
      fmt_f = fmt.to_f
      puts "gps: #{i[:s]} js:#{fmt}/#{fmt_f} xmp:#{xmp[s]}" if @vg
      next if fmt_f == xmp[s]

      yield [s, fmt]
    end
  end

  def flickr(xmp, flickr)
    raise unless block_given?

    fl = flickr[:flickr]
    fl.members.each do |s|
      x = @fl_tags[s]
      next unless fl[s]
      next if xmp[x].to_s == fl[s]

      if @vv
        puts "fl[#{s}]:#{fl[s]}.#{fl[s].class}"
        puts "xmp[#{x}]:#{xmp[x]}.#{xmp[x].class}"
      end
      # full names but it doesn't matter
      fx = XMP_TAGS[s]
      yield [fx, fl[s]]
    end
  end
end
