require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'net/https'
require 'open-uri'
require './lib/annotation.rb'
require './lib/text_alignment/text_alignment.rb'

require './lib/enum_files.rb'
require './lib/local_json.rb'
require './lib/original_json.rb'

require 'logger'

log = Logger.new('./tmp/log')

# コマンドラインからの引数の取得
src_option = ARGV[0]
src_folder = ARGV[1]
out_option = ARGV[2]
out_folder = ARGV[3]

# 入力フォルダ内のファイルパス・ファイル数を取得
src_files = []
src_files_count = 0
get_enum_files('.'"#{src_folder}"'', log) do |x|
  src_files.push(x)
  src_files_count = src_files_count + 1
end

src_files.each do |file|
  # 入力JSONファイルから取得
  input_json = get_local_json(file)
  annotations = JSON.parse(input_json, symbolize_names: true)
  Annotation.normalize!(annotations)

  # p annotations
    # p Annotation.normalize!("str")

  # pubannotationのサイトから取得
  original = get_original_json(annotations[:sourcedb], annotations[:sourceid])
  a =  JSON.parse(original, symbolize_names: true)
  p a[:text]
# p original
  response = Annotation.align_annotations(annotations, a[:text])
p response

  # 出力処理
  pathfile = file
  out_dir = File.dirname(pathfile)
  out_dir.gsub!(src_folder, out_folder)
  out_filename = File.basename(file)

  output_json = JSON.generate(response)
  FileUtils.mkdir_p(out_dir) unless FileTest.exist?(out_dir)
  File.open("#{out_dir}/#{out_filename}",'w') do |t|
   t.puts(output_json)
  end
end
