# 入力jsonファイル読み込む
def get_local_json(file_path)
  begin
    File.open(file_path, "r") do |f|
      f.read
    end
  rescue => e
    puts [file_path, e.class, e].join(" : ")
    nil
  end
end
