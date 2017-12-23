class LinebotController < ApplicationController
  require 'line/bot'
  include LinebotHelper
  include ScrapHelper
  protect_from_forgery :except => [:callback]
  
  def get_callback
    render plain: "hello"
  end


  def callback
    case event['type']
    when "message"
      case event['message']['text']
      when "購読リスト"
        show_my_list
      when "最近の通知"
        # client.push_message(user_id,{type: "text", text: "Coming soon..."})
        three_month_notify
        # list_notify
      when "使い方"
        client.push_message(user_id,{type: "text",text: "使い方\nhttps://github.com/nasaemon/line-book-bot/blob/master/README.md"})

      else
        message = confirm_message
        client.push_message(user_id,message)
      end

    when "follow"
      follow

    when "unfollow"
      unfollow

    when "postback"
      postback
    end
  end



  #友達登録されたときの処理
  def follow
    res = get_profile(user_id)
    puts res['displayName']
    user = User.new(name: res['displayName'],line_id: user_id)
    if user.save
      link_menu
      message = {type: "text",
                 text: "友達登録ありがとう!!\n使い方はこちらを参照\nhttps://github.com/nasaemon/line-book-bot/blob/master/README.md"
      }
      client.push_message(user_id,message)
    else 
      message = {type: "text",
                 text: "エラー"}
      client.push_message(user_id,message)
    end
  end

  #ブロック時の処理
  def unfollow
    client.push_message(user_id,{type: "text",text: "byby"})
    unlink_menu
    user = User.find_by_line_id(user_id)
    if user 
      user.destroy
    end
  end

  #postbackリクエスト時の処理
  def postback
    postback_data = event['postback']['data'].split("\n")
    case postback_data[0]

    when "本として登録"
      save_list('book')

    when "作者として登録"
      save_list('author')

    when "list_delete"
      remove_list
    when "leave"
      client.push_message(user_id,{type: "text",text: "リストに残します"})

    when "list"
      show_my_list

    when "notify"
      list_notify

    when "how_to"
      client.push_message(user_id,{type: "text",text: "使い方"})
    end
  end

  #定期実行
  def periodic_execution
    list_notify
  end

  private
    def client
      @clinet ||= Line::Bot::Client.new{ |config| 
        config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
        config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
      }
    end

    def event
      @event ||= params['events'][0]
    end

    def user_id
      @user_id = event['source']['userId']
    end


    def get_profile(user_id)
      response = client.get_profile(user_id)
      case response
      when Net::HTTPSuccess then
        contact = JSON.parse(response.body)
      else
        p "#{response.code} #{response.body}"
      end
    end


    def confirm_message
      {
        "type": "template",
        "altText": "this is a buttons template",
        "template": {
          "type": "buttons",
          "text": "Please select",
          "actions": [
            {
              "type": "postback",
              "label": "本として登録",
              "data": "本として登録\n#{event['message']['text']}"
            },
            {
              "type": "postback",
              "label": "作者として登録",
              "data": "作者として登録\n#{event['message']['text']}"
            }
          ]
        }
      }
    end


end
