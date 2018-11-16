class ErrorMsg < StandardError; end

module Function
  class << self
    # 入力フォルダ内のファイルパスの配列取得を行う
    def enum_files(source_path, ini_folder_files_max)
      # iniファイル読み込み
      inidata = IniFile.load("./process.ini")
      error_msg = ''
      Dir.foreach(source_path) do |x|
        file_cnt = 0
        next if x == '.' or x == '..'
        new_path = File.join(source_path, x)
        if File.directory?(new_path) then
          enum_files(new_path, ini_folder_files_max) {|x| file_cnt = file_cnt + 1; yield x }
          if file_cnt >= ini_folder_files_max
            error_msg = "入力フォルダ(#{new_path})内に#{ini_folder_files_max}以上のファイルが存在しています"
            raise ErrorMsg, error_msg
          end
        else
          yield new_path
        end
      end
    rescue => e
      error_msg = "入力フォルダ(#{source_path})のファイルパス取得に失敗" if error_msg.blank?
      warn "入力フォルダ(#{source_path})のファイルパス取得に失敗：#{e.backtrace}"
      raise ErrorMsg, error_msg
    end

    # 入力jsonのファイルパスのソーティングを行う
    def sort_sources(source_folder, source_files)
      source_files.sort! do |i, j|
        ret = i.casecmp(j)
        ret == 0 ? i <=> j : ret
      end
    rescue => e
      error_msg = "入力フォルダ(#{source_folder})のソーティングに失敗"
      warn "入力フォルダ(#{source_folder})のソーティングに失敗：#{e.backtrace}"
      raise ErrorMsg, error_msg
    end

    # 入力ファイル(json)の取得を行う
    def get_local_json(file_path)
      error_msg = ''
      input_json = Common.local_json(file_path)
      return nil if input_json.blank?
      # input_jsonの結果（正常と異常）により、処理追加必須
      local_json = JSON.parse(input_json, symbolize_names: true)

      # 取得した入力ファイル(json)のdenotationsのidを連番する
      if local_json[:denotations].present?
        i = 1
        json_denotations = []
        local_json[:denotations].each do |denotation|
          if denotation.has_key? :id
            denotation[:id] = "#{denotation[:id]}_#{i}"
            json_denotations << denotation
            i = i + 1
          end
        end
        local_json[:denotations] = json_denotations if json_denotations.present?
      end
      # 取得した入力ファイル(json)のrelationsのidを連番する
      if local_json[:relations].present?
        j = 1
        json_relations = []
        local_json[:relations].each do |relation|
          if relation.has_key? :id
            relation[:id] = "#{relation[:id]}_#{i}"
            json_relations << relation
            i = i + 1
          end
        end
        local_json[:relations] = json_relations if json_relations.present?
      end
      # 取得した入力ファイル(json)のrelationsのidを連番する
      if local_json[:modifications].present?
        j = 1
        json_modifications = []
        local_json[:modifications].each do |modification|
          if modification.has_key? :id
            modification[:id] = "#{modification[:id]}_#{i}"
            json_modifications << modification
            i = i + 1
          end
        end
        local_json[:modifications] = json_modifications if json_modifications.present?
      end
      # normalize処理確認
      local_json = Annotation.normalize!(local_json)
      unless local_json.class == Hash
        error_msg = "#{file_path}のnormalize処理失敗:#{local_json}"
        raise ErrorMsg, error_msg
      end
      local_json
    rescue => e
      error_msg = "#{file_path}の読み込みに失敗" if error_msg.blank?
      warn "例外発生：#{file_path}の読み込みに失敗：#{e.backtrace}"
      raise ErrorMsg, error_msg
    end

    # オリジナルファイル(json)の取得を行う
    def get_original_json(inputfile_path, sourcedb, sourceid)
      error_msg = ''
      # pubannotationサイトからオリジナルjsonを取得する
      original_json = Common.original_json(sourcedb, sourceid)
      doc = JSON.parse(original_json, symbolize_names: true) if original_json.present?
      # オリジナルファイルがhashならarray化する
      doc = [doc] if doc.class == Hash
      # オリジナルjsonがarrayかhash形式以外
      unless doc.class == Hash || doc.class == Array
        error_msg = "入力ファイル(#{inputfile_path})のオリジナルファイルの取得に失敗"
        raise ErrorMsg, error_msg
      end
      doc
    rescue => e
      error_msg = "入力ファイル(#{inputfile_path})のオリジナルjsonの取得に失敗" if error_msg.blank?
      warn "例外発生：入力ファイル(#{inputfile_path})のオリジナルjsonの取得に失敗：#{e.backtrace}"
      raise ErrorMsg, error_msg
    end

    # マージ処理（ハッシュリターン）を行う
    def merge_align_annotations(inputfile_path, annotations, doc)
      error_msg = ''
      align_annotations = Annotation.align_annotations(annotations, doc)
      unless align_annotations.class == Hash
        error_msg = "マージ処理時のalign_annotations処理失敗:#{align_annotations}"
        raise ErrorMsg, error_msg
      end
      # normalize処理確認
      annotations = Annotation.normalize!(align_annotations)
      unless annotations.class == Hash
        error_msg = "マージ処理時のnormalize処理失敗:#{annotations}"
        raise ErrorMsg, error_msg
      end
      annotations
    rescue => e
      error_msg = "マージ処理失敗（入力ファイル(#{inputfile_path})とオリジナルファイル）"
      warn "マージ処理失敗（入力ファイル(#{inputfile_path})とオリジナルファイル）：#{e.backtrace}"
      raise ErrorMsg, error_msg
    end

    # マージ処理（配列リターン）を行う
    def merge_prepare_annotations_divs(inputfile_path, annotations, divs)
      error_msg = ''
      prepare_annotations_divs = Annotation.prepare_annotations_divs(annotations, divs)
      unless prepare_annotations_divs.class == Array
        error_msg = "マージ処理時のprepare_annotations_divs処理失敗:#{prepare_annotations_divs}"
        raise ErrorMsg, error_msg
      end
      annotations = []
      annotations = prepare_annotations_divs.each do |annotation|
        # normalize処理確認
        annotations = Annotation.normalize!(annotation)
        unless annotations.class == Hash
          error_msg = "マージ処理時のnormalize処理失敗:#{annotations}"
          raise ErrorMsg, error_msg
        end
        annotations
      end
      annotations
    rescue => e
      error_msg = "マージ処理失敗（入力ファイル(#{inputfile_path})とオリジナルファイル）"
      warn "マージ処理失敗（入力ファイル(#{inputfile_path})とオリジナルファイル）：#{e.backtrace}"
      raise ErrorMsg, error_msg
    end

    # 出力フォルダにjsonファイル出力を行う
    def output_json(output_dir, outputfile, annotations, divid)
      error_msg = ''
      ret = Common.output_json(output_dir, outputfile, annotations, divid)
      outputfile = "#{outputfile}_#{divid}.json" unless divid.blank?
      error_msg = "ファイル出力：ファイル（#{outputfile}）出力に失敗"
      raise ErrorMsg, error_msg unless ret == true
      ret
    rescue => e
      error_msg = "ファイル（#{outputfile}）出力に失敗"
      warn "ファイル（#{outputfile}）出力に失敗：#{e.backtrace}"
      raise ErrorMsg, error_msg
    end

    # iniデータ更新
    def iniFileUpdate(total_files, done_files, source_folder, target_folder, error)
      ini = IniFile.load('./process.ini')
      ini['global']['total'] = total_files if total_files.present?
      ini['global']['done'] = done_files if done_files.present?
      ini['global']['source_folder'] = source_folder unless source_folder.empty?
      ini['global']['target_folder'] = target_folder unless target_folder.empty?
      ini['global']['error'] = error.empty? ? 'null' : error
      ini.write
    rescue => e
      error_msg = "iniファイル更新に失敗"
      warn "iniファイル更新に失敗：#{e.backtrace}"
      raise ErrorMsg, error_msg
    end

    # iniファイル情報取得を行う
    def getIniFile(section, name)
      inifile = IniFile.load('./process.ini')
      inifile[section][name]
    rescue => e
      error_msg = "例外発生：ini[#{section}][#{name}]の読み込むに失敗"
      warn "例外発生：ini[#{section}][#{name}]の読み込むに失敗：#{e.backtrace}"
      raise ErrorMsg, error_msg
    end

    # 入力フォルダの容量取得を行う
    def source_folder_size(source_folder)
      expath = File.expand_path(source_folder)
      sum = 0
      Dir.glob("#{expath}/**/*") do |fn|
        sum += File.stat(fn).size.to_f / 1024
      end
      sum
    end

    # プロセスメッセージ出力・メッセージをiniファイルに出力を行う
    def proc_message(message)
      puts message
      Function.iniFileUpdate('', '', '', '', message)
    end

    # プロセスメッセージ出力・メッセージをiniファイルに出力・クローズを行う
    def proc_exit(source_folder)
      Function.proc_message("入力ファイル(#{source_folder})があるドライブの空き容量が不足しています")
      exit
    end
  end
end
