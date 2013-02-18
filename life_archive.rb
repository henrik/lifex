# encoding: utf-8

require "sinatra"
require "open-uri"
require "json"

class Image < Struct.new(:path, :thumb)
  def url
    URI.join("http://images.google.com/", path).to_s
  end

  def medium_image
    thumb.sub("_thumb", "_landing")
  end
end

class Extractor
  def initialize
    @all_images = []
  end

  def get(url)
    html = open(url).read
    js = html[%r{hife\.riArray = (\[.+\])</script>}, 1]
    images = JSON.parse(js.gsub("'", '"')).map { |path, thumb| Image.new(path, thumb) }

    images.each do |image|
      return @all_images if @all_images.include?(image)
      @all_images << image
    end

    get(images.last.url)
  end
end

get "/" do
  url = params[:url]

  if url
    show_images(url)
  else
    show_index
  end
end

def show_images(url)
  images = Extractor.new.get(url)
  html_images = images.map { |image|
    %{<a href="#{image.url}"><img src="#{image.medium_image}"></a>}
  }.join(" ")

  <<-HTML
    <title>Life Archive</title>
    <style>
      img { max-width: 200px; }
    </style>
    <h1>#{images.length} images</h1>
    #{html_images}
  HTML
end

def show_index
  <<-HTML
    <title>Life Archive</title>
    <style>
      body { text-align: center; padding: 25px; }
      body, input { font-size:28px; }
      input[type=text] { width: 20em; padding: 8px; }
    </style>
    <form action=/>
      <p>Skriv en LIFE-URL på Google Images:</p>
      <input type=text name=url>
    </form>
  HTML
end
