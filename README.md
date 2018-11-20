###  入力jsonファイル格納
```
/source_folderフォルダにjsonファイルを格納する
```

### コマンドの実行方法
```
bundle exec ruby exec.rb -i /source_folder -o /out_folder -b
```
```
-i : 入力jsonフォルダ
-o : 出力jsonフォルダ
-b : リジュームせずに最初からやり直すためのオプション。
　　　オプションなしで実行すると、例外で止まった時の状態から実施される。
```

###  出力jsonファイル
```
/out_folderフォルダ内にjsonファイルが出力される
```

###  仕様内容

###  実行ファイル(exec.rb)
```
以下の処理を行う
・コマンドラインオプション(b)があった場合、リジュームせずに最初からやり直す
　iniファイルを初期化する。
・入力jsonフォルダからjsonファイルパス・ファイル数を取得する。
　取得する時はiniファイルの入力フォルダ及び、サブフォルダ毎の最大ファイル数設定値を超えたか確認する
・iniファイル更新（全入力ファイル数・入力フォルダ名・出力フォルダ名で）
・入力フォルダと同サイズのディスク空き容量があるかどうか確認する
・iniファイルの全ファイル数と処理済のファイル数が一致していたらiniファイルを初期化する
・取得したjsonファイルパスをソーティングする
・ソーティングしたjsonファイルパスごとに処理する
・　途中で止めた場合、続きから処理を再開してリジュームする
・　入力ファイル(json)を取得する
・　取得した入力ファイル(json)のsourcedb・sourceidを使用して、オリジナルjsonを取得する
・　取得したオリジナルjsonに一つのjsonオブジェクトが帰ってきたら関数モジュール経由で
　　PubAnnotationのannotationモデルの中のalign_annotationsのロジックで処理する
　　　処理した結果を取得した入力ファイル(json)の出力ファイル[sourcedb_sourceid.json]として、出力jsonフォルダに出力する
・　取得したオリジナルjsonにjson arrayが帰ってきたら関数モジュール経由で
　　PubAnnotationのannotationモデルの中のprepare_annotations_divsのロジックで処理する
　　　処理した結果を取得した入力ファイル(json)の出力ファイル[sourcedb_sourceid_divid.json]として、出力jsonフォルダに出力する
上記の各処理中にエラーが起きたら、次の処理をせずに、そこで止める。
進捗はprocess.iniに出力する
```

###  関数モジュール(function.rb)
```
※実行ファイル(exec.rb)から参照され、対象結果を返す。
```

###  共通ジュール(common.rb)
```
※関数モジュール(function.rb)から参照され、対象結果を返す。

・入力jsonファイル取得処理
・オリジナルjsonファイル取得処理
・jsonファイル出力処理
```

###  iniファイルフォーマット(process.ini)
```
[global]                   :進捗確認用のセクション
total = 0                  :入力フォルダ内の全ファイル数
done = 0                   :処理済のファルル数
source_folder = null       :入力フォルダ
target_folder = null       :出力フォルダ
error = null               :例外で止まった時のエラー内容を書き込む

[constant]                 :最大ファイル数参照用のセクション
folder_files_max = 10000   :入力フォルダ及び、サブフォルダ毎の最大ファイル数設定
```
