# 各情報を取得する
module Common
  class << self
    # 入力jsonファイル取得
    def local_json(file_path)
      File.open(file_path, 'r') do |f|
        f.read
      end
    rescue
      false
    end

    # オリジナルjsonファイル取得
    def original_json(sourcedb, sourceid)
      # pubannotationサイトからオリジナルjsonを取得する
      url = "http://pubannotation.org/docs/sourcedb/#{sourcedb}/sourceid/#{sourceid}.json"
      uri = URI.parse(url)
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.get(uri.request_uri)
      end
      case response
        when Net::HTTPSuccess
          json = response.body
          JSON.parse(json, symbolize_names: true)
        else
          [uri.to_s, response.value].join("：")
        end
    rescue => e
      [uri.to_s, e.class, e].join("：")
    end

    # jsonファイル出力
    def output_json(output_dir, outputfile, annotations, divid)
      json_file = JSON.generate(annotations)
      FileUtils.mkdir_p(output_dir) unless FileTest.exist?(output_dir)
      outputfile = "#{outputfile}_#{divid}.json" unless divid.blank?
      if FileTest.exist?(outputfile)
        # 既存ファイルの読み込む
        json_data = File.open(outputfile, 'r') do |io|
          io.read
        end
        data = JSON.parse(json_data, symbolize_names: true)
        # 既存ファイルの編集
        if data.class == Hash
          if data[:divid] = annotations[:divid]
            unless annotations[:denotations].blank?
              annotations[:denotations].each do |denotation|
                data[:denotations] << denotation
              end
            end
            unless annotations[:relations].blank?
              annotations[:relations].each do |relation|
                data[:relations] << relation
              end
            end
            unless annotations[:modifications].blank?
              annotations[:modifications].each do |modification|
                data[:modifications] << modification
              end
            end
          else
            data = [data]
            data << annotations
          end
        elsif data.class == Array
          data.each do |dt|
            if dt[:divid] = annotations[:divid]
              unless annotations[:denotations].blank?
                annotations[:denotations].each do |denotation|
                  dt[:denotations] << denotation
                end
              end
              unless annotations[:relations].blank?
                annotations[:relations].each do |relation|
                  dt[:relations] << relation
                end
              end
              unless annotations[:modifications].blank?
                annotations[:modifications].each do |modification|
                  dt[:modifications] << modification
                end
              end
            else
              dt << annotations
            end
          end
        end
        # 編集したファイルを保存する
        File.open(outputfile, 'w') do |io|
          JSON.dump(data, io)
        end
      else
        # 新規ファイルに書き込み
        File.open(outputfile, 'w') do |f|
          f.puts(json_file)
        end
      end
      true
    rescue => e
      [e.class, e].join("：")
    end
  end
end
