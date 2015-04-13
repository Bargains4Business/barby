require 'barby/outputter'

module Barby


  #Renders images from barcodes using MiniMagick
  #
  #Registers the to_png, to_gif, to_jpg and to_image methods
  class MinimagickOutputter < Outputter
  
    register :to_png, :to_gif, :to_jpg, :to_image

    attr_accessor :height, :xdim, :ydim, :margin, :caption

    #Returns a string containing a PNG image
    def to_png(*a)
      to_blob('png', *a)
    end

    #Returns a string containint a GIF image
    def to_gif(*a)
      to_blob('gif', *a)
    end

    #Returns a string containing a JPEG image
    def to_jpg(*a)
      to_blob('jpg', *a)
    end
    
    def to_blob(format, *a)
      img = to_image(*a)
      blob = img.to_blob{|i| i.format = format }
      
      #Release the memory used by MiniMagick explicitly. Ruby's GC
      #isn't aware of it and can't clean it up automatically
      img.destroy! if img.respond_to?(:destroy!)
      
      blob
    end

    #Returns an instance of MiniMagick::Image
    def to_image(opts={})
      with_options opts do
        canvas = MiniMagick::Image.new(full_width, caption == true ? full_height + 20 : full_height)
        bars = MiniMagick::Draw.new

        x = margin
        y = margin

        if barcode.two_dimensional?
          encoding.each do |line|
            line.split(//).map{|c| c == '1' }.each do |bar|
              if bar
                bars.rectangle(x, y, x+(xdim-1), y+(ydim-1))
              end
              x += xdim
            end
            x = margin
            y += ydim
          end
        else
          booleans.each do |bar|
            if bar
              bars.rectangle(x, y, x+(xdim-1), y+(height-1))
            end
            x += xdim
          end
        end
        
        if caption
          #TODO: might need to add more options of where to add the annotation, font, pointsize, etc
          text = MiniMagick::Draw.new
          text.font_family = 'Helvetica'
          text.pointsize = 30
          text.fill = "black"
          text.stroke = "none"
          text.gravity = MiniMagick::SouthGravity
          text.annotate(canvas,0,0,0,0, barcode.data)
        end
        
        bars.draw(canvas)

        canvas
      end
    end

    #Switch to toggle if the code should be added to the image; defaults to false
    def caption
      @caption || false
    end

    #The height of the barcode in px
    #For 2D barcodes this is the number of "lines" * ydim
    def height
      barcode.two_dimensional? ? (ydim * encoding.length) : (@height || 100)
    end

    #The width of the barcode in px
    def width
      length * xdim
    end

    #Number of modules (xdims) on the x axis
    def length
      barcode.two_dimensional? ? encoding.first.length : encoding.length
    end

    #X dimension. 1X == 1px
    def xdim
      @xdim || 1
    end

    #Y dimension. Only for 2D codes
    def ydim
      @ydim || xdim
    end

    #The margin of each edge surrounding the barcode in pixels
    def margin
      @margin || 10
    end

    #The full width of the image. This is the width of the
    #barcode + the left and right margin
    def full_width
      width + (margin * 2) 
    end

    #The height of the image. This is the height of the
    #barcode + the top and bottom margin
    def full_height
      height + (margin * 2)
    end


  end


end
