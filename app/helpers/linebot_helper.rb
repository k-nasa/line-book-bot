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
          client.push_message(user_id,{type: "text",text: "#{postback_data[1]}を購読リストに保存しました(type:#{type})"})
        end 
      else
        client.push_message(user_id,{type: "text",text: "#{postback_data[1]}はすでに登録済みです (type:#{type})"})
      end
    end
  end
end
