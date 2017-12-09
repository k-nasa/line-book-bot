module ScrapHelper
  require 'nokogiri'
  require 'open-uri'
  require 'net/http'

  def get_book_list
    url = 'https://calendar.gameiroiro.com/litenovel.php'


    html = open(url).read

    doc = Nokogiri::HTML.parse(html)

    day =  doc.xpath('//td[@class="products-td"]')[Date.today.day-1]
    # day =  doc.xpath('//td[@class="products-td"]')[1]
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
    book_list.each do |title|
      if much = SubscriptionList.where(content: title)
        much.each do |much_book|
          user_id = much_book.user.line_id
          client.push_message(user_id,{type: "text",text: "#{title}"})
        end
      end
    end

  end
end
