class LinebotController < ApplicationController
  require 'line/bot'

  protect_from_forgery :expect => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_seacret = ENV["LINE_CHANNEL_SEACRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless cliant.validate_signature(body, signature)
      head :bad_reqest
    end

    events = client.parse_events_from(body)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          puts event.message['text']
          #Lineから送られてきたメッセージが「アンケート」と一致するかチェック
          if event.message['text'].eql?('アンケート')
            # private内のtempleteメソッドを呼び出す
            client.reply_message(event['replyToken'], templete)
          end
        end
      end
    }

    head :ok
  end

  private

  def templete
    { 
      "type": "templete",
      "altText": "this is a confirm templete",
      "templete": {
        "type": "confirm",
        "text": "今日の勉強は楽しいですか？",
        "actions": [
          {
            "type": "message",
            "label": "楽しい",
            "text": "楽しい"
          },
          {
            "type": "message",
            "label": "楽しくない",
            "text": "楽しくない"
          }
        ]
      }
    }
  end
end
