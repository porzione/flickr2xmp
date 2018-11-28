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
    content = gen(ihsh)
    ihsh[:title]&.encode!(xml: :text)
    ihsh[:descr]&.encode!(xml: :text)
    ihsh[:tags].map! { |t| t.encode xml: :text }
    content = ERB.new(@tpl, nil, '-').result_with_hash ihsh.merge(tk: TK)
    @dry ? content : File.open(filename, 'w') { |f| f.write(content) }
  end
end
