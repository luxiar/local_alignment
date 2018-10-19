require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'net/https'
require 'open-uri'
require 'optparse'
require 'logger'
require './lib/annotation.rb'
require './lib/text_alignment/text_alignment.rb'
require './lib/get_data.rb'

# コマンドラインからの引数の取得
@argv = ARGV.getopts("i:o:")
# ログファイル作成
log = Logger.new('./tmp/log')

# 入力ファイル(json)を取得する
def get_local_json(file_path)
  input_json = GetData.local_json(file_path)
  # input_jsonの結果（正常と異常）により、処理追加必須
  annotations = JSON.parse(input_json, symbolize_names: true)
  Annotation.normalize!(annotations)
  # normalizeの結果（正常と異常）により、処理追加必須
  annotations
end

# オリジナルファイル(json)を取得する
def get_original_json(sourcedb, sourceid)
  # pubannotationのサイトからjsonファイルを取得する
  original = GetData.original_json(sourcedb, sourceid)
  # originalの結果（正常と異常）により、処理追加必須
  JSON.parse(original, symbolize_names: true)
end

def get_align_annotations(annotations, doc)
  output_json = Annotation.align_annotations(annotations, doc)
  # output_jsonの結果（正常と異常）により、処理追加必須
  Annotation.normalize!(output_json)
  # normalizeの結果（正常と異常）により、処理追加必須
  output_json
end

def output_json(file_path, align_annotations)
  out_dir = File.dirname(file_path)
  out_dir.gsub!(@argv['i'], @argv['o'])
  out_filename = File.basename(file_path)
  GetData.output_json(out_dir, out_filename, align_annotations)
  # output_jsonの結果（正常と異常）により、処理追加必須
end

# 入力フォルダ内のファイルパス・ファイル数を取得
src_files = []
src_files_count = 0
GetData.enum_files('.'"#{@argv['i']}"'', log) do |x|
  src_files.push(x)
  src_files_count = src_files_count + 1
end

src_files.each do |file|
  # 入力ファイル(json)を取得する
  annotations = get_local_json(file)
  # オリジナルファイル(json)を取得する
  original_json = get_original_json(annotations[:sourcedb], annotations[:sourceid])
  # 取得した入力ファイル(json)とオリジナルファイル(json)を整列する
  align_annotations = get_align_annotations(annotations, original_json[:text])
  # 整列したjsonファイルを出力
  output_json(file, align_annotations)
end
