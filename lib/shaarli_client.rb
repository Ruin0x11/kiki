class ShaarliClient
  def initialize(instance)
    @instance = instance
  end

  def links(**params)
    pp params
    args = []
    if params[:tags]
      args << "--searchtags #{params[:tags].join(' --searchtags ')}"
    end
    if params[:limit]
      args << "--limit #{params[:limit]}"
    end
    if params[:offset]
      args << "--offset #{params[:offset]}"
    end
    request "get-links", args
  end

  def update_link(link_id, **params)
    args = []
    if params[:title]
      args << "--title '#{params[:title].join(' ')}'"
    end
    if params[:private] == true
      args << "--private"
    end
    if params[:description]
      args << "--description '#{params[:description].join(' ')}'"
    end
    if params[:tags]
      args << "--tags #{params[:tags].join(' ')}"
    end
    if params[:url]
      args << "--url '#{params[:url]}'"
    end
    args << link_id.to_s
    request "put-link", args
  end

  private

  def request(type, args)
    pp args
    json = `shaarli -i #{@instance} #{type} #{args.join(" ")}`
    JSON.parse(json)
  end
end
