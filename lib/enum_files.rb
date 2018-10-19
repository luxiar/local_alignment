# 入力フォルダ内のファイルパス
def get_enum_files(src_filepath,log)
  begin
    Dir.foreach(src_filepath) do |x|
      next if x == '.' or x == '..'
      new_path = File.join(src_filepath, x)
      if File.directory?(new_path) then
        get_enum_files(new_path, log) {|x| yield x }
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
