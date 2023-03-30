require 'line/bot'

class WebhookController < ApplicationController
  protect_from_forgery except: [:callback] # CSRF対策無効化

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head 470
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message_text = make_return_message(event.message['text'])
          message = {
            type: 'text',
            text: message_text
          }
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    }
    head :ok
  end

  private

  DEFAULT_URLS = [
    "https://news.yahoo.co.jp/",
    "https://news.google.com/home?hl=ja&gl=JP&ceid=JP:ja",
    "https://www.cnn.co.jp/",
    "https://giftee.com/announcements/specials",
    "https://toyokeizai.net/",
    "https://www.lifehacker.jp/",
  ]

  def make_return_message(sended_message)
    if sended_message == 'ニュース'
      selected_url = DEFAULT_URLS.sample
      intro_message = "こちらはどうでしょうか\n"
      all_message = intro_message + selected_url
    else
      all_message = "ニュースと言っていただくとおすすめのニュースサイトを紹介できます。"
    end
    all_message
  end
end
