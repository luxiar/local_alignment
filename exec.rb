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

log = Logger.new('./tmp/log')

# コマンドラインからの引数の取得
opt = OptionParser.new
opt.on('-i')
opt.on('-o')
argv = opt.parse!(ARGV)

# 入力フォルダ内のファイルパス・ファイル数を取得
src_files = []
src_files_count = 0
GetData.enum_files('.'"#{argv[0]}"'', log) do |x|
  src_files.push(x)
  src_files_count = src_files_count + 1
end

src_files.each do |file|
  # 入力JSONファイルから取得
  input_json = GetData.local_json(file)
  # input_jsonの結果（正常と異常）により、処理追加必須
  annotations = JSON.parse(input_json, symbolize_names: true)
  Annotation.normalize!(annotations)
  # normalizeの結果（正常と異常）により、処理追加必須

  # pubannotationのサイトから取得
  original = GetData.original_json(annotations[:sourcedb], annotations[:sourceid])
  # originalの結果（正常と異常）により、処理追加必須
  original_json = JSON.parse(original, symbolize_names: true)

  output_json = Annotation.align_annotations(annotations, original_json[:text])
  # output_jsonの結果（正常と異常）により、処理追加必須
  Annotation.normalize!(output_json)
  # normalizeの結果（正常と異常）により、処理追加必須

  # jsonファイル出力
  out_dir = File.dirname(file)
  out_dir.gsub!(argv[0], argv[1])
  out_filename = File.basename(file)
  GetData.output_json(out_dir, out_filename, output_json)
  # output_jsonの結果（正常と異常）により、処理追加必須
end
