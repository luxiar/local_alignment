class ErrorMsg < StandardError; end

module Function
  class << self
    # 出力jsonフォルダの削除を行う
    def setBeginning(target_folder)
      # 出力jsonフォルダがあったら削除する
      FileUtils.rm_rf(target_folder) if File.directory?(target_folder)
    rescue => e
      error_msg = error_message("Failed to delete output folder:#{e.message}", '', '', "#{target_folder}", "#{__FILE__}", "#{__method__}")
      warn warning_message("#{e.message}", '', '', "#{target_folder}", "#{e.backtrace.reject { |line| line =~ /gem/ }.join("\n")}")
      raise ErrorMsg, error_msg
    end

    # 入力フォルダ内のファイルパスの配列取得を行う
    def enum_files(source_folder, ini_folder_files_max)
      error_msg = ''
      Dir.foreach(source_folder) do |x|
        file_cnt = 0
        next if x == '.' or x == '..'
        new_path = File.join(source_folder, x)
        if File.directory?(new_path) then
          enum_files(new_path, ini_folder_files_max) {|x| file_cnt = file_cnt + 1; yield x }
          if file_cnt >= ini_folder_files_max
            error_msg = error_message("More than #{ini_folder_files_max} files exist.", '', "#{source_folder}", '', "#{__FILE__}", "#{__method__}")
            raise ErrorMsg, error_msg
          end
        else
          yield new_path
        end
      end
    rescue => e
      error_msg = error_message("Failed to get file path array:#{e.message}", '', "#{source_folder}", '', "#{__FILE__}", "#{__method__}")
      warn warning_message("#{e.message}", '', "#{source_folder}", '', "#{e.backtrace.reject { |line| line =~ /gem|rbenv/ }.join("\n")}")
      raise ErrorMsg, error_msg
    end

    # 入力jsonのファイルパスのソーティングを行う
    def sort_sources(source_folder, source_files)
      source_files.sort! do |i, j|
        ret = i.casecmp(j)
        ret == 0 ? i <=> j : ret
      end
    rescue => e
      error_msg = error_message("File path sort failed.", '', "#{source_folder}", '', "#{__FILE__}", "#{__method__}")
      warn warning_message("#{e.message}", '', "#{source_folder}", '', "#{e.backtrace.reject { |line| line =~ /gem/ }.join("\n")}")
      raise ErrorMsg, error_msg
    end

    # 入力ファイル(json)の取り込みを行う
    def get_local_json(inputfile_path, index)
      error_msg = ''
      input_json = Common.local_json(inputfile_path)
      if input_json == false
        error_msg = error_message("Failed to get source file.", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}")
        raise ErrorMsg, error_msg
      end
      local_json = JSON.parse(input_json, symbolize_names: true)
      # 連番化を行う
      local_json = renumber local_json, index
      # normalize処理確認
      local_json = Annotation.normalize!(local_json)
      unless local_json.class == Hash
        error_msg = error_message("Normalize processing failed:#{local_json}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}")
        raise ErrorMsg, error_msg
      end
      local_json
    rescue => e
      error_msg = error_message("#{e.message}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}") if error_msg.blank?
      warn warning_message("#{e.message}", "#{inputfile_path}", '', '', "#{e.backtrace.reject { |line| line =~ /gem|rbenv/ }.join("\n")}")
      raise ErrorMsg, error_msg
    end

    # 連番化を行う
    def renumber local_json, index
      # 取得した入力ファイル(json)のdenotationsのidを連番する
      if local_json[:denotations].present?
        local_json[:denotations] = local_json[:denotations]
          .map do |denotation|
            if denotation.has_key? :id
              denotation[:id] = "#{denotation[:id]}_#{index}"
            end
            denotation
          end
        # 取得した入力ファイル(json)のrelationsのidを連番する
        if local_json[:relations].present?
          local_json[:relations] = local_json[:relations]
            .map do |relation|
              if relation.has_key? :id
                relation[:id] = "#{relation[:id]}_#{index}"
                relation[:subj] = "#{relation[:subj]}_#{index}"
                relation[:obj] = "#{relation[:obj]}_#{index}"
                json_relations << relation
              end
              relation
            end
        end
        # 取得した入力ファイル(json)のmodificationsのidを連番する
        if local_json[:modifications].present?
          local_json[:modifications] = local_json[:modifications]
            .map do |modification|
              if modification.has_key? :id
                modification[:id] = "#{modification[:id]}_#{index}"
                modification[:obj] = "#{modification[:obj]}_#{index}"
                json_modifications << modification
              end
              modification
            end
        end
      end
      local_json
    end

    # オリジナルファイル(json)の取得を行う
    def get_original_json(inputfile_path, sourcedb, sourceid)
      error_msg = ''
      original_json = Common.original_json(sourcedb, sourceid)
      # オリジナルjsonがarrayかhash形式以外
      unless original_json.class == Hash || original_json.class == Array
        error_msg = error_message("Failed to get original file:#{original_json}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}")
        raise ErrorMsg, error_msg
      end
      # オリジナルファイルがhashならarray化する
      original_json = [original_json] if original_json.class == Hash
      original_json
    rescue => e
      error_msg = error_message("#{e.message}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}") if error_msg.blank?
      warn warning_message("#{e.message}", "#{inputfile_path}", '', '', "#{e.backtrace.reject { |line| line =~ /gem|rbenv/ }.join("\n")}")
      raise ErrorMsg, error_msg
    end

    # アライン処理（ハッシュリターン）を行う
    def align_annotations(inputfile_path, annotations, doc)
      error_msg = ''
      align_annotations = Annotation.align_annotations(annotations, doc)
      unless align_annotations.class == Hash
        error_msg = error_message("Failed to align process (hash return):#{align_annotations.class}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}")
        raise ErrorMsg, error_msg
      end
      align_annotations
    rescue => e
      error_msg = error_message("#{e.message}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}") if error_msg.blank?
      warn warning_message("#{e.message}", "#{inputfile_path}", '', '', "#{e.backtrace.reject { |line| line =~ /gem|rbenv/ }.join("\n")}")
      raise ErrorMsg, error_msg
    end

    # アライン処理（配列リターン）を行う
    def prepare_annotations_divs(inputfile_path, annotations, divs)
      error_msg = ''
      prepare_annotations_divs = Annotation.prepare_annotations_divs(annotations, divs)
      unless prepare_annotations_divs.class == Array
        error_msg = error_message("Failed to align process (array return):#{prepare_annotations_divs.class}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}")
        raise ErrorMsg, error_msg
      end
      prepare_annotations_divs
    rescue => e
      error_msg = error_message("#{e.message}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}") if error_msg.blank?
      warn warning_message("#{e.message}", "#{inputfile_path}", '', '', "#{e.backtrace.reject { |line| line =~ /gem|rbenv/ }.join("\n")}")
      raise ErrorMsg, error_msg
    end

    # 出力フォルダにjsonファイル出力を行う
    def output_json(inputfile_path, output_dir, outputfile, annotations, divid)
      error_msg = ''
      output = Common.output_json(output_dir, outputfile, annotations, divid)
      unless output == true
        error_msg = error_message("File output failed:#{output}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}")
        raise ErrorMsg, error_msg
      end
      output
    rescue => e
      error_msg = error_message("#{e.message}", "#{inputfile_path}", '', '', "#{__FILE__}", "#{__method__}") if error_msg.blank?
      warn warning_message("#{e.message}", "#{inputfile_path}", '', '', "#{e.backtrace.reject { |line| line =~ /gem|rbenv/ }.join("\n")}")
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
      error_msg = error_message("Failed to update ini file", '', '', '', "#{__FILE__}", "#{__method__}")
      warn warning_message("Failed to update ini file", '', '', '', "#{e.backtrace.reject { |line| line =~ /gem/ }.join("\n")}")
      raise ErrorMsg, error_msg
    end

    # iniファイル情報取得を行う
    def getIniFile(section, name)
      inifile = IniFile.load('./process.ini')
      inifile[section][name]
    rescue => e
      error_msg = error_message("Failed to read ini[#{section}][#{name}]", '', '', '', "#{__FILE__}", "#{__method__}")
      warn warning_message("Failed to read ini[#{section}][#{name}]", '', '', '', "#{e.backtrace.reject { |line| line =~ /gem/ }.join("\n")}")
      raise ErrorMsg, error_msg
    end

    # エラーメッセージ情報を纏める
    def error_message(message_info, source_file, source_folder, target_folder, file, method)
      message = "ERROR:"
      message = "#{message} message: '#{message_info}', " unless message_info.blank?
      message = "#{message} source_file: '#{source_file}', " unless source_file.blank?
      message = "#{message} source_folder: '#{source_folder}', " unless source_folder.blank?
      message = "#{message} target_folder: '#{target_folder}', " unless target_folder.blank?
      message = "#{message} file: '#{file}', " unless file.blank?
      message = "#{message} method: '#{method}'" unless method.blank?
      message
    end

    # 警告メッセージ情報を纏める
    def warning_message(message_info, source_file, source_folder, target_folder, backtrace_info)
      message = "WARNING:"
      message = "#{message} message: '#{message_info}', " unless message_info.blank?
      message = "#{message} \nsource_file: '#{source_file}', " unless source_file.blank?
      message = "#{message} \nsource_folder: '#{source_folder}', " unless source_folder.blank?
      message = "#{message} \ntarget_folder: '#{target_folder}', " unless target_folder.blank?
      message = "#{message} \nbacktrace: '#{backtrace_info}' " unless backtrace_info.blank?
      message
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
      Function.proc_message("There is free space on the drive with source folder:#{source_folder}")
      exit
    end
  end
end
