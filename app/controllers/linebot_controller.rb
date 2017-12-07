class LinebotController < ApplicationController
  require 'line/bot'
  protect_from_forgery :except => [:callback]
  
  def get_callback
  end


  def callback
    body = request.body.read


    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each { |@event|
      case @event['type']
      when "message"
        message = {type: 'text' ,text: 'テストメッセージ'}
        user_id = @event['source']['userId']
        client.push_message(user_id,message)
      when "follow"
        follow()
      end
      puts "########テストメッセージ##############"
      puts @event['type']
      puts "######################################"
    }

  end

  #友達登録されたときの処理
  def follow
    user_id = @event['source']['userId']
    res = client.get_profile(user_id)
    User.new(name: res['displayName'],line_id: user_id)
    if User.save
      message = {type: text,
                 text: "友達登録ありがとう!!"
      }
      client.push_message(user_id,message)
    end
  end

  def client
    @clinet ||= Line::Bot::Client.new{ |config| 
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
