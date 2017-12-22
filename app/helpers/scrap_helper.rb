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

    book_list = get_novel_list + get_comic_list

    destination_list = {}
    book_list.each do |title,author|
      title_verification(title,author,destination_list) unless title == "発売なし"
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

  def scraping(url , date = Date.today.day-1)
    html = open(url).read

    doc = Nokogiri::HTML.parse(html)

    if date
      day =  doc.xpath('//td[@class="products-td"]')[date]
    else
      day =  doc.xpath('//td[@class="products-td"]')
    end
    books = day.search("div.product-description-right a")
    authors = day.search("div.product-description-right  p:nth-last-child(1)")

    book_list = []
    books.each do  |title|
      book_list << title.inner_text.gsub(/\(.*?\)/,"").strip
    end
    if book_list.empty?
      book_list << "発売なし"
    end

    author_list = []
    authors.each do |parson|
      author_list << parson.inner_text.gsub(" ", "") 
    end
    if author_list.empty?
      author_list << "発売なし"
    end

    book_list.zip(author_list)

  end


  #３ヶ月分の発売予定を持ってくる
  def get_three_month_book
    date = Date.today
    url1 = "https://calendar.gameiroiro.com/litenovel.php"
    url2 = "https://calendar.gameiroiro.com/litenovel.php?year=#{(date >> 1).year}&month=#{(date >> 1).month}"
    url3 = "https://calendar.gameiroiro.com/litenovel.php?year=#{(date >> 2).year}&month=#{(date >> 2).month}"

    url4 = 'https://calendar.gameiroiro.com/manga.php'
    url5 = "https://calendar.gameiroiro.com/manga.php?year=#{(date >> 1).year}&month=#{(date >> 1).month}"
    url6 = "https://calendar.gameiroiro.com/manga.php?year=#{(date >> 2).year}&month=#{(date >> 2).month}"
  end

  def three_month_notify
    book_list = get_three_month_book
    notify = []
    user = User.find_by_line_id(user_id)
    user.SubscriptionList.all.each do |list|
      book_list.each do |title,author|
        case list.record_type
        when "book"
          if title.include? list.content
            notify << "・#{title} (#{author})" 
          end
        when "author"
          if author.include? list.content
            notify << "・#{title} (#{author})" 
          end
        end
      end
    end
    client.push_message(user_id,{type: "text", text: notify.uniq.join("\n\n")  })
  end

  def get_all_book_data(url)
    html = open(url).read
    doc = Nokogiri::HTML.parse(html)
    day =  doc.xpath('//td[@class="products-td"]')
    month = doc.xpath('//th[@id = "top-th"]').inner_text.match(/.*年(\d+)月.*/)[1].to_i

    book_list = []
    day.each_with_index do |data,i|
      books = data.search("div.product-description-right a").map {|item| item.inner_text.gsub(/\(.*?\)/,"").strip }
      authors = data.search("div.product-description-right  p:nth-last-child(1)").map {|parson| parson.inner_text.gsub(" ", "")}
      books = "発売なし" if books.empty?
      authors = "発売なし" if authors.empty?
      book_list << [i+1,[books,authors]]
    end

    p [month,book_list]
  end
end
