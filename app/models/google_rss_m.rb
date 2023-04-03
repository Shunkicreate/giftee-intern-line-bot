# interface を一緒にしてあげると、使いやすくなる。
# ruby は interface を指定できない（無理やりやる方法はあるけど）
# 動的に呼び出すこともできる
class GoogleRSS < RSS2

    # google のURLはControllerが知る必要ないので、このクラスで閉じられてスッキリ
    SEARCH_URL = "https://news.google.com/rss/search"
      RECOGNIZED_VALUE = /google/
      # @return Array(NewsObject)
      def self.search(query)
          # 検索結果をゴニョゴニョして、NewsObject
          params = URI.encode_www_form({q:"#{query}AND(ワクワクORわくわく)",hl:"ja",gl:"JP",ceid:"JP:ja"})
          url = "https://news.google.com/rss/search?#{params}"
          rss = RSS::Parser.parse(url)
          
          # RSS の構造はたぶんRFC的に決まっているから
          return parse(rss)
      end
  end
  
  # https://phpjavascriptroom.com/?t=topic&p=rss_format
  # RSS2.0 の構造は決まっているのでパース
  class RSS2
      private 
  
      def parse(rss)
          # RSS2.0 の構造をよしなに解釈してあげて、NewsObject を返す
          return [NewsObject.new]
      end
  end
  
  class ToyoKeizai
      RECOGNIZED_VALUE = /toyo/
      # 例えばRSSがない場合は、このsearch処理はスクレイピングにする
      # @return Array(NewsObject)
      def self.search(query)
      end
  end
  
  class NewsAPI
      RECOGNIZED_VALUE = /news/
      # こいつはAPIを叩く
      # @return Array(NewsObject)
      def self.search(query)
      end
  end
  
  
  class NewsObject
      attr_accessor :url
      attr_accessor :title
      attr_accessor :description
  
      def to_linebot_parameter
          text = ""
          text += self.title + "\n\n"
          text += self.url + "\n"
          text += self.description if self.description.present?
      end
  end
  
  "#{サイト} から #{検索ワード} のニュースを教えて"
  
  
  class WebhookController < ApplicationController
      SERVICE_LIST = [GoogleRSS, ToyoKeizai, NewsAPI]
  
      def make_response_message(sended_message)
          services = SERVICE_LIST.select {|klass| sended_message.match?(klass::RECOGNIZED_VALUE)}
          if services.present?
              # sended_message は検索ワードだけ絞り込む必要があるけど
              result = services.sample.search(sended_message)
              response_message = result.sample(1).to_linebot_parameter
          else
              selected_url = DEFAULT_URLS.sample
              intro_message = "こちらはどうでしょうか\n"
              response_message = intro_message + selected_url
          end
      end
  end
