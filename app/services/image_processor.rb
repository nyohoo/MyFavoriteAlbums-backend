class ImageProcessor
  require 'open-uri'
  require 'mini_magick'

  def initialize(image_paths)
    @image_paths = image_paths
  end

  def process_images
    tmp_images = download_images
    uuid = SecureRandom.hex(8)
    create_montage(tmp_images, uuid)
    cleanup_images(tmp_images)
    uuid
  end

  private

  def download_images
    @image_paths.map do |image_path|
      filename = File.basename(image_path)
      output_path = "./tmp/#{filename}"

      File.open(output_path, 'w+b') do |output|
        URI.open(image_path) do |data|
          output.puts(data.read)
        end
      end

      output_path
    end
  end

  def create_montage(image_paths, uuid)
    MiniMagick::Tool::Montage.new do |montage|
      image_paths.each { |image| montage << image }
      montage.geometry "640x640+0+0"
      montage.tile "3x3"
      montage << "./tmp/#{uuid}.jpg"
    end
  end

  def cleanup_images(image_paths)
    image_paths.each { |image| File.delete(image) }
  end
end
