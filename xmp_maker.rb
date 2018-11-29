#!/usr/bin/env ruby
# frozen_string_literal: true

# xmp template writer
class XmpMaker
  TK = 'github.com/porzione/flickr2xmp'

  def initialize(opts)
    @dry = opts[:dry]
    @tpl = File.read('xmp.erb')
  end

  def write(ihsh, filename)
    ihsh[:title]&.encode!(xml: :text)
    ihsh[:descr]&.encode!(xml: :text)
    ihsh[:tags].map! { |t| t.encode xml: :text }
    content = ERB.new(@tpl, nil, '-').result_with_hash ihsh.merge(tk: TK)
    File.open(filename, 'w') { |f| f.write(content) } unless @dry
  end
end
