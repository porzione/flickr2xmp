#!/usr/bin/env ruby
# frozen_string_literal: true

# xmp template writer
class XmpMaker
  TK = 'github.com/porzione/flickr2xmp'

  def initialize
    @tpl = File.read('xmp.erb')
  end

  def gen(ihsh)
    ihsh[:title]&.encode!(xml: :text)
    ihsh[:descr]&.encode!(xml: :text)
    ihsh[:tags].map! { |t| t.encode xml: :text }
    ERB.new(@tpl, nil, '-').result_with_hash ihsh.merge(tk: TK)
  end

  def write(ihsh, filename)
    content = gen(ihsh)
    File.open(filename, 'w') { |f| f.write(content) }
  end

  def str(ihsh)
    gen(ihsh)
  end
end
