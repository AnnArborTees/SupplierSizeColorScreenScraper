require 'rubygems'
require 'nokogiri'
require 'open-uri'

def colors_from_bodek(url)
  doc = Nokogiri::HTML(open(url))
  text = doc.at_css('.availColorsTable tr:nth-child(3)').text.strip.lstrip
  colors_text = text[text.index(':') + 2,text.size]
  colors = colors_text.split(',').map{|x| x.strip.gsub('/ ', '/').lstrip}
  return colors
end

url = "http://www.bodekandrhodes.com/cgi-bin/barlive/site.w?location=olc/cobrand-product.w&product=4420&category=3&frames=no&target=main&sponsor=000001&nocache=48001"
colors_from_bodek(url).each do |color|
  puts color
end
