class LinebotController < ApplicationController
  require 'line/bot'

  protect_from_forgery with: :null_session

  before_action :validate_signature

  def validate_signature
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
  end

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read
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
            client.reply_message(event['replyToken'], template)
          end
        end
      end
    }

    head :ok
  end

  private

  def template
    { 
      "type": "template",
      "altText": "this is a confirm templete",
      "template": {
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
