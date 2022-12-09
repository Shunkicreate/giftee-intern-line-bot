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

1. railsのシークレットキーを発行する
```
bundle exec rake secret
```

2. renderにログインする
- 自身のgithubアカウントでログイン(推奨)

3. render上でデータベースを作成する
- New+ ボタンからPostgreSQLを選択
- 任意の名前を入力

4. render上でアプリサーバーを作成する。
- Web Serviceを選択
- githubログインしない場合は、webサービス作成画面にてgithubアカウントを`connect`する。
- intern-line-botのリポジトリを選択する。
- サービス名を入力
- pushしたいブランチを選択
- 以下のBuildCommand/StartCommandを入力
  - BuildCommand: `./bin/render-build.sh`
  - StartCommand: `bundle exec puma -C config/puma.rb`

- 環境変数を設定する
  - WebService作成画面の下部にある`Advanced`ボタンを押す
    - (key)
    - DATABASE_URL(render上で作成したPostgreSQLのダッシュボードからInternal Database URLを取得)
    - LINE_CHANNEL_SECRET(LINE developer コンソールのChannel基本設定から取得)
    - LINE_CHANNEL_TOKEN(LINE developer コンソールのChannel基本設定から取得)
    - SECRET_KEY_BASE(bundle exec rake secretで生成したもの)

# LINE Developerコンソールの設定
LINE DeveloperコンソールのChannel基本設定から、以下を設定。

- Webhook送信: 利用する
- Webhook URL: `https://XXXXXXXXXXX.onrender.com/callback`
- Botのグループトーク参加: 利用する
- 自動応答メッセージ: 利用しない
- 友だち追加時あいさつ: 利用する

※Webhook URLには renderで作成したサービスのダッシュボード上部に記載されているURLに`/callback`をつけたものを入力。Webhook URLを設定した後に接続確認ボタンを押して成功したら疎通完了。

## Q. LINE Messaging APIの動作確認をローカル環境でできますか？
A. [ngrok](https://ngrok.com/)というツールを使うとできます
