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
    events.each { |event|
      # case event
      # when Line::Bot::Event::Message
      #   case event.type
      #   when Line::Bot::Event::MessageType::Text
      #     message = {
      #       type: 'text',
      #       text: event.message['text']
      #     }
      #     response = client.reply_message(event['replyToken'], message)
      #     p response
      #     user_id = event['source']['userId']
      #     client.push_message(user_id,message)
      #   when "follow"
      #     puts "follow"
      #   end
      # end

      case event['type']
      when "message"
        message = {type: 'text' ,text: 'テストメッセージ'}
        user_id = event['source']['userId']
        client.push_message(user_id,message)
      when "follow"
        message = {type: 'text' ,
                   text: """友達登録ありがとう。
                   使い方はこのサイトを参考にしてね"""}
        user_id = event['source']['userId']
        client.push_message(user_id,message)
      end
      puts "########テストメッセージ##############"
      puts event['type']
      puts "######################################"
    }

  end

  def client
    @clinet ||= Line::Bot::Client.new{ |config| 
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
