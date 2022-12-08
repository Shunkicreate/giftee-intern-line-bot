# 前提
- [render](https://render.com/) のアカウントを取得済みであること。
- [LINE Developer](https://developers.line.me/ja/) 登録が完了し、プロバイダー・channelの作成が完了していること。

# 環境
```
$ ruby -v
ruby 2.7.2p137 (2020-10-01 revision 5445e04352) [x86_64-darwin18]

$ bundle exec rails -v
Rails 6.0.2.1
```
# rails 環境構築
[こちら](https://github.com/giftee/intern-line-bot/wiki/%E3%83%AD%E3%83%BC%E3%82%AB%E3%83%AB%E7%92%B0%E5%A2%83%E6%A7%8B%E7%AF%89) を参考にローカルで rails アプリケーションが動くようにする

# デプロイ準備

1. `puma.rb`を修正
```rb
workers ENV.fetch("WEB_CONCURRENCY") { 4 }
preload_app!
```

2. `config/environments/production.rb`を修正
```rb
config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present? || ENV['RENDER'].present?
```

3. renderでbuildするための設定ファイルを作成する
- `bin`配下に`render-build.sh`を作成。
- 中身は以下
```rb
#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate
```

4. 作成したbuildファイルに実行権限を付与
```
chmod a+x bin/render-build.sh
```

5. railsのシークレットキーを発行する
```
bundle exec rake secret
```

6. render上にアプリを作成する。
- WebServicesを選択
- 任意の名前と以下のBuildCommand/StartCommandを入力
  - BuildCommand: `./bin/render-build.sh`
  - StartCommand: `bundle exec puma -C config/puma.rb`

- 環境変数を設定する
  - (key)
  - LINE_CHANNEL_SECRET(LINE developer コンソールのChannel基本設定から取得)
  - LINE_CHANNEL_TOKEN(LINE developer コンソールのChannel基本設定から取得)
  - SECRET_KEY_BASE(bundle exec rake secretで生成したもの)

# LINE Developerコンソールの設定
LINE DeveloperコンソールのChannel基本設定から、以下を設定。

- Webhook送信: 利用する
- Webhook URL: `https://XXXXXXXXXXX.onrender.com`
- Botのグループトーク参加: 利用する
- 自動応答メッセージ: 利用しない
- 友だち追加時あいさつ: 利用する

※Webhook URLの `https://XXXXXXXXXXX.onrender.com` には renderで作成したサービスのダッシュボード上部に記載されているURLを入力。Webhook URLを設定した後に接続確認ボタンを押して成功したら疎通完了。

## Q. LINE Messaging APIの動作確認をローカル環境でできますか？
A. [ngrok](https://ngrok.com/)というツールを使うとできます
