#!/usr/bin/env ruby
# frozen_string_literal: true

class XmpMaker

  TK = 'github.com/porzione/flickr2xmp'

  def initialize
    @tpl = File.read('xmp.erb')
  end

  def write ih, filename
    ih[:title].encode!(xml: :text) if ih[:title]
    ih[:descr].encode!(xml: :text) if ih[:descr]
    ih[:tags].map! { |t| t.encode xml: :text }
    xmp = ERB.new(@tpl, nil, '-').result_with_hash ih.merge(tk: TK)
    File.open(filename, 'w') { |f| f.write(xmp) }
  end

end
