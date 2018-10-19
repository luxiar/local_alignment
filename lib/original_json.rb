# サーバー上のjsonファイル取得
def get_original_json(sourcedb, sourceid)
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
