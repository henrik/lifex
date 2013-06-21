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
  url = "http://#{url}" unless url.include?("://")

  images = Extractor.new.get(url)
  html_images = images.map { |image|
    %{<a href="#{image.url}"><img src="#{image.medium_image}"></a>}
  }.join(" ")

  default_width = 200

  <<-HTML
    <title>LIFE Archive image extractor</title>
    <style>
      img { max-width: #{default_width}px; }
    </style>
    <h1><a href="/">LIFE Archive image extractor</a></h1>
    <h2>
      #{images.length} images
      <input type="range" min="50" max="600" step="10" value="#{default_width}" onchange="var mw = this.value; Array.prototype.slice.apply(document.images).forEach(function(i) { i.style.maxWidth = mw })">
    </h2>
    #{html_images}
  HTML
end

def show_index
  <<-HTML
    <title>LIFE Archive image extractor</title>
    <style>
      body { text-align: center; padding: 25px; }
      body, input, button { font-size: 25px; }
      input[type=text] { width: 90%; padding: 8px; text-align: center; }
    </style>
    <form action=/>
      <p>Paste an item page URL from the LIFE archive on Google Images and submit to see all images in that set.</p>
      <p><input type=text name=url placeholder="Like: http://images.google.com/hosted/life/37c45397968a844b.html"></p>
      <p><button type=submit>Submit</button></p>
      <p><a href="/?url=http://images.google.com/hosted/life/37c45397968a844b.html">See an example.</a></p>
    </form>
    <footer>
      <p>
        By <a href="http://henrik.nyh.se">Henrik</a> for <a href="http://johannaost.com">Johanna</a>.
        <a href="http://github.com/henrik/lifex">View source.</a>
      </p>
    </footer>
  HTML
end
