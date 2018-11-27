#!/usr/bin/env ruby
# frozen_string_literal: true

# xmp template writer
class XmpMaker
  TK = 'github.com/porzione/flickr2xmp'

  def initialize
    @tpl = File.read('xmp.erb')
  end

  def write(ihsh, filename)
    ih[:title]&.encode!(xml: :text)
    ih[:descr]&.encode!(xml: :text)
    ih[:tags].map! { |t| t.encode xml: :text }
    xmp = ERB.new(@tpl, nil, '-').result_with_hash ihsh.merge(tk: TK)
    File.open(filename, 'w') { |f| f.write(xmp) }
  end
end
