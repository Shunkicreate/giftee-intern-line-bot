require 'line/bot'

class WebhookController < ApplicationController

    DEFAULT_URLS = [
      "https://news.yahoo.co.jp/",
      "https://news.google.com/home?hl=ja&gl=JP&ceid=JP:ja",
      "https://www.cnn.co.jp/",
      "https://giftee.com/announcements/specials",
      "https://toyokeizai.net/",
      "https://www.lifehacker.jp/",
    ]

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
          message = {
            type: 'text',
            text: make_response_message(event.message['text'])
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

  def make_response_message(sended_message)
    google_news_list = get_google_rss
    if sended_message == 'ニュース'
      selected_url = DEFAULT_URLS.sample
      intro_message = "こちらはどうでしょうか\n"
      response_message = intro_message + selected_url
    else
      response_message = "ニュースと言っていただくとおすすめのニュースサイトを紹介できます。"
    end
    response_message
  end

  def pop_random_from_list(default_list, num = 1)
    poped_items = []
    poped_list = default_list
    p default_list.shuffle
    for i in 1..num do
      poped_items.push(poped_list.shuffle.pop)
      poped_list = poped_list.shuffle
    end
    poped_items
  end

  def get_google_rss(num = 1)
    url = "https://news.google.com/rss/search?q=%E3%83%AF%E3%82%AF%E3%83%AF%E3%82%AFOR%E3%82%8F%E3%81%8F%E3%82%8F%E3%81%8F&hl=ja&gl=JP&ceid=JP:ja"
    rss = RSS::Parser.parse(url)
    google_news_list = pop_random_from_list(rss.items)
  end
end
