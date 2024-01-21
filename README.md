# 【RadioServer】
RadioServerは[RadioRelayServer](https://github.com/burrocargado/RadioRelayServer.git)を作り変えたものです。。
MPD連携はカットして、radiko連携のみの機能になっています。


## 特徴
radiko連携呼び出しについては、API風になっています。
・プレイリスト
 /api/radiko/playlist
・radikoストリーミング
 /api/radiko/stations/[radikoステーションID]/stream
・radikoストリーミング(タイムフリー)
 /api/radiko/stations/[radikoステーションID]/stream/[開始時間(YYYYMMDDHHMMSS)]/[終了時間(YYYYMMDDHHMMSS)]


## 設定ファイル
settingsディレクトリ内に以下2ファイルあります。
・account.py
 radikoログイン情報（なければ不要）
・config.py
 RADIKO_PLAYLIST_URL='http://[サーバーURL]/api/radiko/stations/{}/stream'
 サーバーURLは初期はradikoserver:9000としています。各自の環境に合わせ、修正してください。プレイリストに反映されます。


## セットアップ
podmanでしか動作確認していません。
ContainerfileをDockerfileに変更して、ちょこっと直せば、dockerでも動くでしょう。


pythonもよくわからず、パズル感覚で改造してみました。機能追加とかもできません。

