# QAP: 質問と応答のペア
QAPとは、とてもシンプルな形式です。

その内容は、短い質問と応答のペアだけです。

[Qandan](https://scrapbox.io/villagepump/Qanda)にインスピレーションされて制作しました。

QAPは通常、CSVなどで表現されます。

このような形式です。
```csv
question,answer
質問1,答え1
質問2,答え2
```
このような単純な形式が知識の最小単位となります。

これはカジュアルに取り入れられるでしょう。
# QAPツール
## qap-cli
Lua5.4と`ftcsv`ライブラリが必要です。

使い方: `lua qap-webui.lua {QAPのCSVファイルへのパス} 質問`

編集距離を用いて最も近い質問とその答えのペアを表示します。

## qap-webui
Lua5.4と`ftcsv`, `quinku`, `lunajson`ライブラリが必要です。(`luasocket`は`quinku`の依存関係で取得されます)

使い方: `lua qap-webui.lua {QAPのCSVファイルへのパス}`

編集距離を用いて最も近い5つの質問とその答えのペアを表示するシンプルなウェブアプリを立ち上げます。