class LinebotController < ApplicationController
  require 'line/bot'
  protect_from_forgery :except => [:callback]
  
  def get_callback
    render plain: "success"
  end


  def callback
    body = request.body.read

    puts "hello"

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']
          }
          response = client.reply_message(event['replyToken'], message)
          p response
        end
      end
    }
    head :ok
  end

  def clinet 
    @clinet ||= Line::Bot::Client.new{ |config| 
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      cinfig.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
