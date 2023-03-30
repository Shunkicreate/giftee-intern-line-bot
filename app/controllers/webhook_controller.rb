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
    intro_message = "こちらはどうでしょうか\n\n"
    if sended_message == 'ニュースサイト'
      selected_url = DEFAULT_URLS.sample
      intro_message = "こちらはどうでしょうか\n"
      response_message = intro_message + selected_url
    else
      response_message = get_google_response_message(intro_message, sended_message)
    end
    response_message
  end

  def pop_random_from_list(default_list, num = 1)
    poped_items = []
    poped_list = default_list
    for i in 1..num do
      poped_items.push(poped_list.shuffle.pop)
      poped_list = poped_list.shuffle
    end
    poped_items
  end

  def get_google_response_message(intro_message, sended_message, num = 1)
    response_message = intro_message
    google_news_rss_list = get_google_rss(sended_message)
    if google_news_rss_list == [nil]
      response_message = "他の言葉をお試しください。"
    else
      for google_news_rss in google_news_rss_list do
        response_message += rss_to_text(google_news_rss)
      end
    end
    response_message
  end

  def get_google_rss(sended_message, num = 1)
    params = URI.encode_www_form({q:"#{sended_message}AND(ワクワクORわくわく)",hl:"ja",gl:"JP",ceid:"JP:ja"})
    url = "https://news.google.com/rss/search?#{params}"
    rss = RSS::Parser.parse(url)
    google_news_list = pop_random_from_list(rss.items)
  end

  def rss_to_text(rss)
    p rss
    text = ""
    text += rss.title + "\n\n"
    text += rss.link + "\n"
  end

end
