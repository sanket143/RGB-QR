require 'rqrcode'
require 'rmagick'
require 'parallel'
include Magick

filename = ARGV[0]
output_file = "./output/" + ARGV[0]
$image_size = 200

byteArray = File.binread(filename)
unpacked = byteArray.unpack("H*")
text = unpacked[0]
total = text.size / 250
$count = 0

def getImage(text, color)

  qrcode = RQRCode::QRCode.new(text)
  png = qrcode.as_png(
    bit_depth: 1,
    border_modules: 2,
    color_mode: ChunkyPNG::COLOR_GRAYSCALE,
    color: color,
    file: nil,
    fill: 'white',
    module_px_size: 6,
    resize_exactly_to: true,
    resize_gte_to: true,
    size: $image_size
  )

  img = Image.from_blob(png.to_s)
  
  $count += 1
  return img[0]
end

def generateRGBQR(imageList)
  img = Image.new($image_size, $image_size) { self.background_color = "white" }
  pixels = img.get_pixels(0, 0, $image_size, $image_size)

  pixels0 = imageList[0].get_pixels(0, 0, $image_size, $image_size)
  pixels1 = imageList[1].get_pixels(0, 0, $image_size, $image_size)
  pixels2 = imageList[2].get_pixels(0, 0, $image_size, $image_size)

  for i in 0..(pixels.size - 1)

    if pixels0[i].to_color != "white" or pixels1[i].to_color != "white" or pixels2[i].to_color != "white"
      pixels[i].red = 0
      pixels[i].green = 0
      pixels[i].blue = 0
    end

    if pixels0[i].to_color == "red"
      pixels[i].red = 65535
    end
    if pixels1[i].to_color == "green"
      pixels[i].green = 65535
    end
    if pixels2[i].to_color == "blue"
      pixels[i].blue = 65535
    end

    if pixels0[i].to_color == "red" and pixels1[i].to_color == "green" and pixels2[i].to_color == "blue"
      pixels[i].red = 0
      pixels[i].green = 0
      pixels[i].blue = 0
    end
  end

  img.store_pixels(0, 0, $image_size, $image_size, pixels)

  return img
end

pillar = 0
qr_no = 0
partition_size = 300 * 3
partitions = (text.size().to_f/(partition_size)).ceil() - 1

def saveQR(h1, h2, h3, partitions, qr_no)
  images = ImageList.new
  images.push(getImage(h1, "red"))
  images.push(getImage(h2, "green"))
  images.push(getImage(h3, "blue"))

  puts "(#{qr_no}/#{partitions}) generating... "
  generateRGBQR(images).write("./tmp/%08d-#{partitions}.png" % qr_no)
end

while true
  utext = "(#{qr_no}/#{partitions})" + text[pillar, partition_size]
  puts "(#{qr_no}/#{partitions}) buffering... "

  text_size = utext.size()
  size_3 = (text_size / 3).floor()

  h1 = utext[0, size_3]
  h2 = utext[size_3 , size_3]
  h3 = utext[size_3 * 2, text_size]

  if qr_no == partitions
    break
  end

  saveQR(h1, h2, h3, partitions, qr_no)

  pillar = pillar + partition_size
  qr_no += 1

end

# run all threads

# File.open(output_file, 'wb' ) do |output|
#   output << unpacked.pack("H*")
# end