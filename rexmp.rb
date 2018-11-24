# frozen_string_literal: true

require 'nokogiri'

class ReXMP

  P_TITLE = %q(//*[name()='dc:title']//*[name()='rdf:Alt']//*[name()='rdf:li'])
  P_DESCR = %q(//*[name()='dc:description']//*[name()='rdf:Alt']//*[name()='rdf:li'])
  P_TAGS  = %q(//*[name()='dc:subject']//*[name()='rdf:Seq']//*[name()='rdf:li'])
  P_RDFD  = %q(//*[name()='rdf:Description'])

  def initialize ih, filename
    @doc = Nokogiri::XML(File.read filename)
    STDERR.puts "merge: t=#{title};d=#{descr};lat=#{gpslat};lon=#{gpslon};tt=#{tags}"
    #xd['Xmp.dc.subject'] = xd['Xmp.dc.subject'].split(/,\s/).concat(ih[:tags]).uniq#.join(',')
  end

  private

  # @doc.to_xml.to_s.gsub(/\n\s+\n/, "\n")

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

  def tags
    @doc.xpath(P_TAGS).map{ |n| n.content }
  end

  def tags= tt
    #@doc.xpath(P_TAGS).map{ |n| n.content }
  end

end
