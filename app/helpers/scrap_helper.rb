module ScrapHelper
  require 'nokogiri'
  require 'open-uri'
  require 'net/http'

  def get_novel_list
    url = 'https://calendar.gameiroiro.com/litenovel.php'
    scraping(url)
  end



  def get_comic_list
    url = 'https://calendar.gameiroiro.com/manga.php'
    scraping(url)
  end



  #スクレイピングしてきたタイトルがSubscriptionListにあった場合userに通知
  def list_notify
    novel_list = get_novel_list
    comic_list = get_comic_list

    destination_list = {}
    novel_list.each do |title,author|
      title_verification(title,author,destination_list)
    end
    
    comic_list.each do |title,author|
      title_verification(title,author,destination_list)
    end

    p destination_list

    destination_list.each do |user_id,title_list|
      message = "-------本日発売の本-------\n"+title_list.uniq.join("\n\n")
      client.push_message(user_id,{type: 'text',text: message})
    end
  end

  def title_verification(title,author,destination_list)
    SubscriptionList.all.each do |list|
      case list.record_type
      when "book"
        if title.include?(list.content) 
          destination_list[list.user.line_id] ||= []
          destination_list[list.user.line_id] << "・#{title} (#{author})"
        end
      when "author"
        if author.include?(list.content) 
          destination_list[list.user.line_id] ||= []
          destination_list[list.user.line_id] << "・#{title} (#{author})"
        end
      end
    end
    destination_list
  end

  def scraping(url)
    html = open(url).read

    doc = Nokogiri::HTML.parse(html)

    day =  doc.xpath('//td[@class="products-td"]')[Date.today.day-1]
    # day =  doc.xpath('//td[@class="products-td"]')[0]
    books = day.search("div.product-description-right a")
    authors = day.search("div.product-description-right  p:nth-last-child(1)")

    book_list = []
    books.each do  |title|
      book_list << title.inner_text.gsub(/\(.*?\)/,"").strip
    end
    if book_list.empty?
      list << "発売なし"
    end

    author_list = []
    authors.each do |parson|
      author_list << parson.inner_text.gsub(" ", "") 
    end

    p Hash[book_list.zip(author_list)]

  end

end
