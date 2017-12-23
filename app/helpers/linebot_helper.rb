module LinebotHelper
  require 'net/http'
  require 'uri'
  #購読リストを登録
  def save_list(type)
    postback_data = event['postback']['data'].split("\n").map(&:strip)
    user = User.find_by_line_id(user_id)
    if user
      unless user.SubscriptionList.find_by(record_type: type,content: postback_data[1])
        record  = user.SubscriptionList.build(record_type: type,content: postback_data[1]) 
        if record.save
          client.push_message(user_id,{type: "text",text: "「#{postback_data[1]}」を購読リストに保存しました"})
        end 
      else
        client.push_message(user_id,{type: "text",text: "「#{postback_data[1]}」はすでに登録済みです"})
        client.push_message(user_id,yes_or_no_form(postback_data[1],type))
      end
    end
  end

  #購読リストから削除
  def remove_list
    data = event['postback']['data'].split("\n")
    user = User.find_by_line_id(user_id)
    if  list = user.SubscriptionList.find_by(record_type: data[2],content: data[1] )
      list.destroy
      client.push_message(user_id,{type: "text",text: "「#{data[1]}」をリストから削除しました"})
    end
  end


  #購読リストを表示
  def show_my_list
    user = User.find_by_line_id(user_id)
    aouthor_list = user.SubscriptionList.where(record_type: "author")
    book_list = user.SubscriptionList.where(record_type: "book")

    message = "-----作者リスト-----\n"
    aouthor_list.each do |aouthor|
      message += aouthor.content + "\n"
    end
    message += "\n------本リスト-----\n"
    book_list.each do |book|
      message += book.content + "\n"
    end

    client.push_message(user_id,{type: 'text',text: message})
  end

  #友達登録時にリッチメニューを設定
  def link_menu
    uri = URI.parse("https://api.line.me/v2/bot/user/#{user_id}/richmenu/#{ENV["RICH_MENU"]}")
    puts "テスト"
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ENV["LINE_CHANNEL_TOKEN"]}"
    request["Content-Length"] = "0"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end

  def unlink_menu
    uri = URI.parse("https://api.line.me/v2/bot/user/#{user_id}/richmenu")
    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = "Bearer #{ENV['LINE_CHANNEL_TOKEN']}"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end


  def yes_or_no_form(title,type)
        {
      "type": "template",
      "altText": "this is a buttons template",
      "template": {
        "type": "buttons",
        "text": "#{title}をリストから削除しますか？",
        "actions": [
          {
            "type": "postback",
            "label": "削除",
            "data": "list_delete\n#{title}\n#{type}"
          },
          {
            "type": "postback",
            "label": "残す",
            "data": "leave"
          }
        ]
      }
    }

  end
end
