module LinebotHelper
  #購読リストを登録
  def save_list(event,type)
    user_id = event['source']['userId']
    postback_data = event['postback']['data'].split("\n")
    user = User.find_by_line_id(user_id)
    if user
      unless user.SubscriptionList.find_by(record_type: type,content: postback_data[1])
        record  = user.SubscriptionList.build(record_type: type,content: postback_data[1] ) 
        if record.save
          client.push_message(user_id,{type: "text",text: "「#{postback_data[1]}」を購読リストに保存しました(type:#{type})"})
        end 
      else
        client.push_message(user_id,{type: "text",text: "「#{postback_data[1]}」はすでに登録済みです (type:#{type})"})
        client.push_message(user_id,yes_or_no_form(postback_data[1],type))
      end
    end
  end

  #購読リストから削除
  def remove_list(event)
    user_id = event['source']['userId']
    data = event['postback']['data'].split("\n")
    user = User.find_by_line_id(user_id)
    if  list = user.SubscriptionList.find_by(type: data[2],content: data[1] )
      list.destroy
      client.push_message(user_id,{type: "text",text: "「#{data[1]}」をリストから削除しました(type:#{data[2]})"})
    end
  end


  #購読リストを表示
  def show_my_list(event)
    user_id = event['source']['userId']
    user = User.find_by_line_id(user_id)
    aouthor_list = user.SubscriptionList.where(record_type: "aouthor")
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
