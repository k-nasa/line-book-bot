module ScrapHelper
  require 'nokogiri'
  require 'open-uri'
  require 'net/http'

  def get_book_list
    url = 'https://calendar.gameiroiro.com/litenovel.php'


    html = open(url).read

    doc = Nokogiri::HTML.parse(html)

    day =  doc.xpath('//td[@class="products-td"]')[Date.today.day-1]
    # day =  doc.xpath('//td[@class="products-td"]')[Date.today.day]
    book_list = day.search("div.product-description-right a")

    list  = []
    book_list.each do  |title|
      list << title.inner_text.gsub(/\(.*?\)/,"").strip
    end
    if list.empty?
      list << "発売なし"
    end
    p list
  end


  #スクレイピングしてきたタイトルがSubscriptionListにあった場合userに通知
  def list_notify
    book_list = get_book_list
    destination_list = {}
    book_list.each do |title|
      SubscriptionList.all.each do |list|
        if title.include?(list.content)
          destination_list[list.user.line_id] ||= []  
          destination_list[list.user.line_id] << "・"+ title
        end
      end

    end

    p destination_list

    destination_list.each do |user_id,title_list|
      message = "---本日発売の本---\n"+title_list.join("\n")
      client.push_message(user_id,{type: 'text',text: message})
    end


  end
end
