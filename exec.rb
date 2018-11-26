require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'net/https'
require 'open-uri'
require 'optparse'
require 'each_with_anim'
require 'inifile'
require 'sys/filesystem'
require './lib/annotation.rb'
require './lib/text_alignment/text_alignment.rb'
require './lib/common.rb'
require './lib/function.rb'

# コマンドラインからの引数の取得（i:入力jsonフォルダ、o:出力jsonフォルダ、b:最初からやり直すオプション）
@argv = ARGV.getopts('i:o:b')

begin
  # 比較用の変数初期化
  cmp_inputfile_path = nil
  cmp_sourcedb = nil
  cmp_sourceid = nil
  # コマンドラインオプションの取得
  source_folder = '.'"#{@argv['i']}"''
  target_folder = '.'"#{@argv['o']}"''
  option_beginning = @argv['b']
  # コマンドラインオプション(b)があった場合、リジュームせずに最初からやり直す
  Function.setBeginning(target_folder) if option_beginning

  # 入力ファイルのファイルパス配列を取得。
  ini_folder_files_max = Function.getIniFile('constant', 'folder_files_max')
  source_files = []
  source_files_count = 0
  # 入力フォルダーのファイルパスを配列化、ファイル数を取得する。
  Function.enum_files(source_folder, ini_folder_files_max) do |x|
    source_files << x
    source_files_count = source_files_count + 1
  end

  # 全入力ファイル数・入力フォルダ名・出力フォルダ名をiniファイルに設定
  Function.iniFileUpdate(source_files_count, '', source_folder, target_folder, '')

  # 入力フォルダと同サイズのディスク空き容量がなければエラーにする
  stat = Sys::Filesystem.stat('/')
  dest_free = (stat.blocks_free * stat.block_size).to_f / 1024
  src_folder_size = Function.source_folder_size(source_folder)
  Function.proc_exit(source_folder) if dest_free < src_folder_size

  # iniファイル読み込み
  ini_total = Function.getIniFile('global', 'total')
  ini_done = Function.getIniFile('global', 'done')
  # 全入力ファイル数が正常終了のファイル数と一致している場合、iniファイルを初期化する
  Function.iniFileUpdate(0, 0, 'null', 'null', 'null') if source_files_count == ini_done
  # 取得したファイルパスをソーティングする
  source_files = Function.sort_sources(source_folder, source_files)

  source_files.each_with_animation.with_index do |inputfile_path, index|
    # 途中で止めた場合、続きから処理を再開してリジュームする
    next if ini_done > index
    if ini_done < ini_total
      index = ini_done
      inputfile_path = inputfile_path
    end
    # 入力ファイル(json)を取得する
    local_json = Function.get_local_json(inputfile_path)
    sourcedb = local_json[:sourcedb]
    sourceid = local_json[:sourceid]
    # 出力ファイルのファイルパス設定
    output_dir = File.dirname(inputfile_path)
    output_dir.gsub!(@argv['i'], @argv['o'])
    output_filename = "#{sourcedb}_#{sourceid}"
    outputfile = "#{output_dir}/#{output_filename}"
    # 同じファイルパスのjsonファイルのsourcedbとsourceidが一致している場合
    if cmp_inputfile_path == inputfile_path and cmp_sourcedb == sourcedb and cmp_sourceid == sourceid
      next
    else
      cmp_inputfile_path = inputfile_path
      cmp_sourcedb = sourcedb
      cmp_sourceid = sourceid
      # オリジナルjsonを取得する
      original_json = Function.get_original_json(inputfile_path, sourcedb, sourceid)
      if original_json.length == 1
        # マージ処理（ハッシュリターン）
        merge_annotations = Function.merge_align_annotations(inputfile_path, local_json, original_json[0][:text])
        # 出力処理
        outputfile = "#{outputfile}.json"
        Function.output_json(output_dir, outputfile, merge_annotations, '')
      else
        # マージ処理（配列リターン）
        merge_annotations = Function.merge_prepare_annotations_divs(inputfile_path, local_json, original_json)
        # 取得した入力ファイル(json)とオリジナルファイル(json)を整列する
        next unless merge_annotations.present?
        if merge_annotations.length == 1
          # 出力処理
          outputfile = "#{outputfile}.json"
          Function.output_json(output_dir, outputfile, merge_annotations[0], merge_annotations[0][:divid])
        else
          merge_annotations.each do |annotation|
            # 出力処理（複数）
            Function.output_json(output_dir, outputfile, annotation, annotation[:divid])
          end
        end
      end
      ini_done = index + 1
      Function.iniFileUpdate('', ini_done, '', '', '')
    end
  end
rescue ErrorMsg => e
  Function.proc_message e.message
end
