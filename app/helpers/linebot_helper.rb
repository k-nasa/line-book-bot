module LinebotHelper
  require 'nokogiri'
  require 'open-uri'
  require 'net/http'

  def get_book_list
    url = 'https://calendar.gameiroiro.com/litenovel.php'


    html = open(url).read

    doc = Nokogiri::HTML.parse(html)

    # day =  doc.xpath('//td[@class="products-td"]')[Date.today.day-1]
    day =  doc.xpath('//td[@class="products-td"]')[0]
    book_list = day.search("div.product-description-right a")

    list  = []
    book_list.each do  |title|
      list << title.inner_text.strip.gsub(/\(.*?\)/,"")
    end
    if list.empty?
      list << "発売なし"
    end
    p list
  end
end
