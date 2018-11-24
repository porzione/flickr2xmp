# frozen_string_literal: true

require 'nokogiri'

class ReXMP

  P_TITLE = %q{//*[name()='dc:title']//*[name()='rdf:Alt']//*[name()='rdf:li']}
  P_DESCR = %q{//*[name()='dc:description']//*[name()='rdf:Alt']//*[name()='rdf:li']}
  P_TAGS  = %q{//*[name()='dc:subject']}
  P_RDFD  = %q{//*[name()='rdf:Description']}
  P_USERC = %q{//*[name()='exif:UserComment']//*[name()='rdf:Alt']//*[name()='rdf:li']}

  TAG_BAG = %w[Seq Bag Alt]

  def initialize ih, filename
    @doc = Nokogiri::XML(File.read filename)
    #tags_merge ['uno', 'due']
    puts "merge: t=#{title};d=#{descr};lat=#{gpslat};lon=#{gpslon};tt=#{tags};\nih:#{ih} "
    puts "uc:#{user_comment}"
  end

  private

  def out
    @doc.to_xml.to_s.gsub(/\n\s+\n/, "\n")
  end

  def title
    @doc.at_xpath(P_TITLE).content
  end

  def title= s
    @doc.at_xpath(P_TITLE).content = s
  end

  def descr
    @doc.at_xpath(P_DESCR).content
  end

  def descr= s
    @doc.at_xpath(P_DESCR).content = s
  end

  def gpslat
    @doc.at_xpath(P_RDFD).attributes['GPSLatitude'].value
  end

  def gpslat= l
    @doc.at_xpath(P_RDFD).attributes['GPSLatitude'].value = l
  end

  def gpslon
    @doc.at_xpath(P_RDFD).attributes['GPSLongitude'].value
  end

  def gpslon= l
    @doc.at_xpath(P_RDFD).attributes['GPSLongitude'].value = l
  end

  def user_comment
    @doc.at_xpath(P_USERC).content
  end

  def user_comment= c
    @doc.at_xpath(P_USERC).content = c
  end

  def tags
    return @tags if @tags
    @tags = @doc.at_xpath(P_TAGS)
      .children
      .select{ |c| TAG_BAG.include? c.name }
      .first
      .children
      .select{ |c| c.name == 'li' }
      .map{ |i| i.content }
  end

  def tags_merge new_tags
    old_tags = tags
    bag_name = @doc.at_xpath(P_TAGS)
      .children
      .select{ |c| TAG_BAG.include? c.name }
      .first.name
    raw = @doc.at_xpath "#{P_TAGS}//*[name()='rdf:#{bag_name}']"
    raw.children.remove
    @tags = old_tags.concat new_tags
    @tags.concat(new_tags).each do |t|
      nn = Nokogiri::XML::Node.new 'rdf:li', @doc
      nn.content = t
      raw.add_child(nn)
    end
  end

end
