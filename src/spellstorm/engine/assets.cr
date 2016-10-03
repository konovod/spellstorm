require "crsfml/crsfml.cr"

module Engine
  # TODO - atlas?
  class Assets
    @@tex = {} of String => SF::Texture
    @@font = {} of String => SF::Font

    private def self.recursive_load(dir, relpath)
      Dir.foreach(dir) do |fn|
        next if fn[0] == '.'
        fullname = File.join(dir, fn)
        resname = relpath.empty? ? fn : File.join(relpath, fn)
        if File.directory?(fullname)
          recursive_load(fullname, resname)
        elsif {".png", ".bmp", ".gif", ".jpeg", ".jpg"}.includes? File.extname(fn)
          puts "loading texture: #{fn}"
          @@tex[resname] = SF::Texture.from_file(fullname)
        elsif File.extname(fn) == ".ttf"
          puts "loading font: #{fn}"
          @@font[resname] = SF::Font.from_file(fullname)
        end
      end
    end

    def self.load(dir : String)
      recursive_load(dir, "")
    end

    def self.texture(s)
      @@tex[s]
    end

    def self.font(s)
      @@font[s]
    end
  end

  class Font
    def self.[](s)
      Assets.font(s)
    end
  end

  class Tex
    def self.[](s)
      Assets.texture(s)
    end
  end
end
