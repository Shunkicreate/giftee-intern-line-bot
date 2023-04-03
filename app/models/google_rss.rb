class GoogleRssClient
#データをとってくる。保存する
#google rssというdbに対してアクセスしてるイメージ
    def initialize
        @google_news_rss_items = []
    end

    def get_google_rss_items(search_query, num = 1)
        params = URI.encode_www_form({q:"#{search_query}AND(ワクワクORわくわく)",hl:"ja",gl:"JP",ceid:"JP:ja"})
        url = "https://news.google.com/rss/search?#{params}"
        rss = RSS::Parser.parse(url)
        @google_news_rss_items = rss.items
      end
end
