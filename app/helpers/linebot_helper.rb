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
        client.push_message(user_id,yes_or_no_form)
      end
    end
  end

  #購読リストから削除


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


  def yes_or_no_form
    {
      "type": "template",
      "altText": "this is a confirm template",
      "template": {
        "type": "confirm",
        "text": "リストから削除しますか？",
        "actions": [
          {
            "type": "message",
            "label": "yes",
            "text": "yes"
          },
          {
            "type": "message",
            "label": "No",
            "text": "no"
          }
        ]
      }
    }
  end
end
