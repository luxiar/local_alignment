# 各情報を取得する
module GetData
  class << self
    # 入力フォルダ内のファイルパス
    def enum_files(src_filepath,log)
      begin
        Dir.foreach(src_filepath) do |x|
          next if x == '.' or x == '..'
          new_path = File.join(src_filepath, x)
          if File.directory?(new_path) then
            enum_files(new_path, log) {|x| yield x }
          else
            yield new_path
          end
        end
      rescue => e
        logger.error([src_filepath, e.class, e].join(" : "))
        puts [src_filepath, e.class, e].join(" : ")
        nil
      end
    end

    # 入力jsonファイル読み込む
    def local_json(file_path)
      begin
        File.open(file_path, "r") do |f|
          f.read
        end
      rescue => e
        puts [file_path, e.class, e].join(" : ")
        nil
      end
    end

    # サーバー上のjsonファイル取得
    def original_json(sourcedb, sourceid)
      url = "http://pubannotation.org/docs/sourcedb/#{sourcedb}/sourceid/#{sourceid}.json"
      uri = URI.parse(url)

      begin
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          http.get(uri.request_uri)
        end
        case response
          when Net::HTTPSuccess
            response.body
          else
            puts [uri.to_s, response.value].join(" : ")
            nil
          end
      rescue => e
        puts [uri.to_s, e.class, e].join(" : ")
        nil
      end
    end

    # jsonファイル出力
    def output_json(out_dir, out_filename, output_json)
      begin
        json_file = JSON.generate(output_json)
        FileUtils.mkdir_p(out_dir) unless FileTest.exist?(out_dir)
        File.open("#{out_dir}/#{out_filename}",'w') do |t|
          t.puts(json_file)
        end
      rescue => e
        puts [out_dir, out_filename, e.class, e].join(" : ")
        nil
      end
    end
  end
end
