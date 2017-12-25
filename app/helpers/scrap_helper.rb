module ScrapHelper
  require 'nokogiri'
  require 'open-uri'
  require 'net/http'

  def list_notify
    destination_list = {}
    SubscriptionList.all.each do |list|
      case list.record_type
      when 'book'
        if books = Book.where("title LIKE(?)","%#{list.content}%").where(release_date: Date.today)
          books.each do |book|
            destination_list[list.user.line_id] ||= []
            destination_list[list.user.line_id] << book
          end
        end
      when 'author'
        if books = Book.where("author LIKE(?)","%#{list.content}%").where(release_date: Date.today)
          books.each do |book|
            destination_list[list.user.line_id] ||= []
            destination_list[list.user.line_id] << book
          end
        end
      end
    end

    p destination_list
    destination_list.each do |user_id,book_list|
      message = "[#{Date.today}発売の本]\n---漫画---\n\n"
      book_list.uniq.each {|book| message += book.title+"(#{book.author})\n\n" if book.record_type == "漫画コミック" }
      message += "---小説---\n\n"
      book_list.uniq.each {|book| message += book.title+"(#{book.author})\n\n" if book.record_type == "ライトノベル" }
      client.push_message(user_id,{type: 'text',text: message})
    end
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
    message += "発売なし\n" if notify.empty?
    notify.each do |mes|
      message += "#{mes.title} (#{mes.author}) [#{mes.release_date}]\n\n" if mes.record_type == "ライトノベル"
    end
    message += "-----マンガ-----\n"
    message += "発売なし\n" if notify.empty?
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
      "https://calendar.gameiroiro.com/manga.php",
      "https://calendar.gameiroiro.com/manga.php?year=#{(date >> 1).year}&month=#{(date >> 1).month}",
      "https://calendar.gameiroiro.com/manga.php?year=#{(date >> 2).year}&month=#{(date >> 2).month}",
    ]
    urls.map {|url| save_book_data(url)}

  end
end
