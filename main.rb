require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'
require 'mechanize'
require 'watir'
require 'watir-webdriver'
require 'watir-webdriver/wait'
require 'watir-nokogiri'

bodek_csv = CSV.read('csv/bodek_and_rhodes.csv')
ss_csv = CSV.read('csv/ss_activewear.csv')
sanmar_csv = CSV.read('csv/sanmar.csv')
aa_csv = CSV.read('csv/american_apparel.csv')
tultex_csv = CSV.read('csv/tultex.csv')
CSV_URL_COL = 3
possible_sizes = ['2XS', 'XS', 'S', 'M', 'L', 'XL', '2XL', '3XL', '4XL', '5XL', '6XL', '7XL', 'S/M', 'L/XL', '2XL/3XL', 'LT', 'XLT', '2XLT', '3XLT', '4XLT', '2T', '3T', '4T', '5/6T']

def size_range(input, possible_size)
  size_split = input.split('-')
  if size_split.length == 2
    if size_split[0] == 'XXS'
      size_split[0] = '2XS'
    end
    start_val = possible_size.index(size_split[0])
    end_val = possible_size.index(size_split[1])
    new_size = possible_size[start_val..end_val].join('!')
  else
    new_size = input
  end
  new_size
end

#######################################################################################################################
# TULTEX APPAREL Stuff
#######################################################################################################################
tultex_colors = Array.new
tultex_sizes = Array.new
n=0

CSV.foreach('csv/tultex.csv') do |row|
  url = URI.parse(URI.encode("#{row[CSV_URL_COL].strip}"))
  browser = Watir::Browser.new(:chrome)
  browser.goto "#{url}"
  page = Nokogiri::HTML(browser.div(id: 'product').html)
  colors = page.css('tbody')[1].css('td').map { |x| x.text.gsub(/\A[[:space:]]+|[[:space:]]+\z/, '').strip }.join('!')
  page_sizes = page.css('p').text.split('Sizes:')[1].split('Specs:')[0].gsub(/\A[[:space:]]+|[[:space:]]+\z/, '').strip.sub '*-', '-'
  x = page_sizes.split(' - ')
  if x.length > 1
    page_sizes = x.join('-')
  end
  sizes = size_range(page_sizes, possible_sizes)
  tultex_colors << colors
  tultex_sizes << sizes
  puts 'tultex ' + (n+=1).to_s
  browser.close
end

tultex_csv.each do |color|
  color << tultex_colors.shift
end

tultex_csv.each do |size|
  size << tultex_sizes.shift
end

CSV.open('tultex-info.csv', 'w') do |csv|
  tultex_csv.each do |row|
    csv << row
  end
end

#######################################################################################################################
# AMERICAN APPAREL Stuff
#######################################################################################################################
aa_colors = Array.new
aa_sizes = Array.new
n=0

CSV.foreach('csv/american_apparel.csv') do |row|
  url = URI.parse(URI.encode("#{row[CSV_URL_COL].strip}"))
  browser = Watir::Browser.new(:chrome)
  browser.goto "#{url}"
  colors = Nokogiri::HTML(browser.div(class: 'colors').html).css('div[onclick]').map { |x| x['title'] }.join('!')
  sizes = Nokogiri::HTML(browser.ul(class: 'inventoryHeader').html).css('li')[1..-1].map { |x| x.text }.join('!')

  aa_colors << colors
  aa_sizes << sizes

  puts 'aa ' + (n+=1).to_s
  browser.close
end

aa_csv.each do |color|
  color << aa_colors.shift
end

aa_csv.each do |size|
  size << aa_sizes.shift
end

CSV.open('aa-info.csv', 'w') do |csv|
  aa_csv.each do |row|
    csv << row
  end
end

#######################################################################################################################
# BODEK Stuff
#######################################################################################################################
def colors_from_bodek(url)
  page = Nokogiri::HTML(open(url))
  text = page.at_css('.availColorsTable tr:nth-child(3)').text.strip.lstrip
  colors_text = text[text.index(':') + 2, text.size]
  colors = colors_text.split(',').map { |x| x.strip.gsub('/ ', '/').lstrip }
  return colors
end

def sizes_from_bodek(url)
  doc = Nokogiri::HTML(open(url))
  text = doc.at_css('.availColorsTable tr:nth-child(3)').text.strip.lstrip
  sizes_text = text[0, text.index(':')]
  return sizes_text
end

bodek_colors = Array.new
bodek_sizes = Array.new
n=0
CSV.foreach('csv/bodek_and_rhodes.csv') do |row|
  url = URI.parse(URI.encode("#{row[CSV_URL_COL].strip}"))
  color = colors_from_bodek(url).map { |color| color }.join('!')
  bodek_colors << color
  size = sizes_from_bodek(url)
  bodek_sizes << size_range(size, possible_sizes)
  puts 'bodek ' + (n+=1).to_s
end

bodek_csv.each do |color|
  color << bodek_colors.shift
end

bodek_csv.each do |size|
  size << bodek_sizes.shift
end

CSV.open('bodek-info.csv', 'w') do |csv|
  bodek_csv.each do |row|
    csv << row
  end
end

#######################################################################################################################
# SS Stuff
#######################################################################################################################
ss_colors = Array.new
ss_sizes = Array.new
n=0
CSV.foreach('csv/ss_activewear.csv') do |row|
  url = URI.parse(URI.encode("#{row[CSV_URL_COL].strip}"))
  agent = Mechanize.new
  agent.get("http://www.ssactivewear.com")
  form = agent.page.forms.first
  form.fields[2].value = 'ss_username'
  form.fields[3].value = 'ss_password'
  agent.submit(form, form.buttons[0])
  agent.get(url)

  color_html = agent.page.at '.itemColors'
  colors_array = Array.new
  color_html.elements.each do |color|
    colors_array << color.text
  end

  size_html = agent.page.at '.rowh'
  sizes_array = Array.new
  size_html.elements.drop(1).each do |size|
    sizes_array << size.text
  end

  ss_colors << colors_array.join('!')
  ss_sizes << sizes_array.join('!')
  puts 'ss ' + (n+=1).to_s
end

ss_csv.each do |color|
  color << ss_colors.shift
end

ss_csv.each do |size|
  size << ss_sizes.shift
end

CSV.open('ss-info.csv', 'w') do |csv|
  ss_csv.each do |row|
    csv << row
  end
end

#######################################################################################################################
# SANMAR Stuff
#######################################################################################################################
sanmar_colors = Array.new
sanmar_sizes = Array.new
n=0
CSV.foreach('csv/sanmar.csv') do |row|
  url = URI.parse(URI.encode("#{row[CSV_URL_COL].strip}"))
  agent = Mechanize.new
  agent.get(url)

  overview = agent.page.at '.overview'
  color_table = overview.elements.at ('tr')
  colors_array = Array.new
  color_table.elements.each do |xxx|
    colors_array << xxx.text.strip
  end
  sanmar_colors << colors_array.join('!')

  description = agent.page.at '.description'
  sizes_text = description.at ('.bold-text')
  sizes_text = sizes_text.text
  sizes_split = sizes_text.split(':')
  sizes = sizes_split[1].strip
  sanmar_sizes << size_range(sizes, possible_sizes)

  puts 'sanmar ' + (n+=1).to_s
end

sanmar_csv.each do |color|
  color << sanmar_colors.shift
end

sanmar_csv.each do |size|
  size << sanmar_sizes.shift
end

CSV.open('sanmar-info.csv', 'w') do |csv|
  sanmar_csv.each do |row|
    csv << row
  end
end
#######################################################################################################################