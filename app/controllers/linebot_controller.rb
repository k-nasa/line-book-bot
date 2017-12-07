class LinebotController < ApplicationController
  require 'line/bot'
  protect_from_forgery :except => [:callback]
  
  def get_callback
    render plain: "hello"
  end


  def callback
    body = request.body.read


    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event['type']
      when "message"
        message = {type: 'text' ,text: 'テストメッセージ'}
        user_id = event['source']['userId']
        client.push_message(user_id,message)
      when "follow"
        follow(event)
      when "unfollow"
        unfollow(event)
      end
    }
  end

  #友達登録されたときの処理
  def follow(event)
    user_id = event['source']['userId']
    res = get_profile(user_id)
    puts res['displayName']
    user = User.new(name: res['displayName'],line_id: user_id)
    if user.save
      message = {type: "text",
                 text: "友達登録ありがとう!!"
      }
      client.push_message(user_id,message)
    else 
      message = {type: "text",
                 text: "エラー"
      }
    end
  end

  def unfollow(event)
    user_id = event['source']['userId']
    user = User.find_by_line_id(user_id)
    if user 
      user.destroy
      client.push_message(user_id,{type: "text",message: "byby"})
    end
  end

  def client
    @clinet ||= Line::Bot::Client.new{ |config| 
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def get_profile(user_id)
    response = client.get_profile(user_id)
    case response
    when Net::HTTPSuccess then
      contact = JSON.parse(response.body)
      # p contact['displayName']
      # p contact['pictureUrl']
      # p contact['statusMessage']
    else
      p "#{response.code} #{response.body}"
    end
  end
end
