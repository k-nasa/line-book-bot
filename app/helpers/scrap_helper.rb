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



  def three_month_notify
    notify = []
    user = User.find_by_line_id(user_id)
    user.SubscriptionList.all.each do |list|
      case list.record_type
      when "book"
        if books = Book.where('title LIKE (?)',"%#{list.content}%")
          books.each {|book| notify << book}
        end
      when "author"
        if authors = Book.where('author LIKE (?)',"%#{list.content}%")
          authors.each {|author| notify << author }
        end
      end
    end

    p notify
    notify = notify.uniq
    notify = Book.where(id: notify.map{|item| item.id})
    notify = notify.order(:release_date) unless notify.empty?
    message = "-----ライトノベル-----\n"
    notify.each do |mes|
      message += "#{mes.title} (#{mes.author}) [#{mes.release_date}]\n\n" if mes.record_type == "ライトノベル"
    end
    message += "-----マンガ-----\n"
    notify.each do |mes|
      message += "#{mes.title} (#{mes.author}) [#{mes.release_date}]\n\n" if mes.record_type == "漫画コミック"
    end
    client.push_message(user_id,{type: "text", text: message})
  end

  #1ページまるまる本の情報を持ってくる
  def save_book_data(url)
    html = open(url).read
    doc = Nokogiri::HTML.parse(html)
    day =  doc.xpath('//td[@class="products-td"]')
    year = doc.xpath('//th[@id = "top-th"]').inner_text.match(/(\d*)年(\d+)月(\D*)/)[1].to_i
    month = doc.xpath('//th[@id = "top-th"]').inner_text.match(/(\d*)年(\d+)月(\D*)/)[2].to_i
    type = doc.xpath('//th[@id = "top-th"]').inner_text.match(/(\d*)年(\d+)月(\D*)発売日一覧/)[3].strip


    book_list = []
    day.each_with_index do |data,i|
      books = data.search("div.product-description-right a").map {|item| item.inner_text.gsub(/\(\D*\)/,"").gsub(/・/,"").strip }
      authors = data.search("div.product-description-right  p:nth-last-child(1)").map {|parson| parson.inner_text.gsub(" ", "") }

      unless books.empty?
        books.zip(authors).each {|book,author| Book.create(title: book,author: author,release_date: Date.new(year,month,i+1),record_type: type)}
      end
    end
  end


  #３ヶ月分の発売予定を持ってくる
  def save_three_month_book
    date = Date.today
    urls = [
      "https://calendar.gameiroiro.com/litenovel.php",
      "https://calendar.gameiroiro.com/litenovel.php?year=#{(date >> 1).year}&month=#{(date >> 1).month}",
      "https://calendar.gameiroiro.com/litenovel.php?year=#{(date >> 2).year}&month=#{(date >> 2).month}",
      "https://calendar.gameiroiro.com/litenovel.php?year=#{(date >> -1).year}&month=#{(date >> -1).month}",
      "https://calendar.gameiroiro.com/litenovel.php?year=#{(date >> -2).year}&month=#{(date >> -2).month}",
      "https://calendar.gameiroiro.com/manga.php",
      "https://calendar.gameiroiro.com/manga.php?year=#{(date >> 1).year}&month=#{(date >> 1).month}",
      "https://calendar.gameiroiro.com/manga.php?year=#{(date >> 2).year}&month=#{(date >> 2).month}"
      "https://calendar.gameiroiro.com/manga.php?year=#{(date >> -1).year}&month=#{(date >> -1).month}",
      "https://calendar.gameiroiro.com/manga.php?year=#{(date >> -2).year}&month=#{(date >> -2).month}"
    ]

  end
end
