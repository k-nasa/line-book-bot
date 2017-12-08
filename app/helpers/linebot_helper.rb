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

  #購読リストを登録
  def save_list(event,type)
    user_id = event['source']['userId']
    postback_data = event['postback']['data'].split("\n")
    user = User.find_by_line_id(user_id)
    if user
      unless user.SubscriptionList.find_by(record_type: type,content: postback_data[1])
        record  = user.SubscriptionList.build(record_type: type,content: postback_data[1] ) 
        if record.save
          client.push_message(user_id,{type: "text",text: "#{postback_data[1]}を購読リストに保存しました(type#{type})"})
        end 
      end
    end
  end
end
