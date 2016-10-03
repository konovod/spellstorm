require "crsfml/crsfml.cr"
require "../config.cr"

#TODO - ugly

alias MyVec = SF::Vector2(Float32)
def vec(x, y)
  MyVec.new(Float32.new(x), Float32.new(y))
end

module Engine


  class GameObject
    property dead : Bool
    property pos : MyVec

    def initialize(owner, x, y)
      @dead = false
      @pos = vec(x, y)
      owner.objects << self if owner
    end

    def process
    end

    def draw(target : SF::RenderTarget)
    end

  end

  abstract class Game
    getter window : SF::RenderWindow
    getter objects : Array(GameObject)

    abstract def on_mouse(event, x, y)
    abstract def on_key(event : SF::Event::KeyEvent, key)
    abstract def draw
    abstract def process

    def initialize
      @window = SF::RenderWindow.new(SF::VideoMode.new(SCREENX, SCREENY), "My window")
      @window.vertical_sync_enabled = true
      #@window.framerate_limit = 60
      @quitting = false
      @objects = Array(GameObject).new
      @phys_timer = SF::Clock.new
      @fps_counter = SF::Clock.new
      @fps = 0
      @ups = 0
      @cur_fps = 0
      @cur_ups = 0
      @elapsed = 0f32

      Assets.load("./res")
    end

    private def do_draw
      @cur_fps+=1
      @objects.each do |obj|
        obj.draw(@window)
      end
      draw
    end

    private def do_process
      @cur_ups+=1
      @objects.each do |obj|
        obj.process
      end
      @objects.reject!(&.dead)
      process
    end

    def run
      @phys_timer.restart
      @fps_counter.restart
      while !@quitting
        # check all the window's events that were triggered since the last iteration of the loop
        while event = @window.poll_event
          # "close requested" event: we close the window
          case event
          when SF::Event::Closed
            @quitting = true
          when SF::Event::KeyPressed, SF::Event::KeyReleased
            on_key(event, event.code)
          when SF::Event::MouseButtonPressed, SF::Event::MouseButtonReleased
            on_mouse(event, event.x, event.y)
          when SF::Event::MouseMoved
            on_mouse(event, event.x, event.y)
          end
        end
        @elapsed += @phys_timer.restart.as_seconds
        while @elapsed > PHYS_DT
          do_process
          @elapsed -= PHYS_DT
        end
        @window.clear
        do_draw
        @window.display
        if @fps_counter.elapsed_time.as_seconds >= 1
          @fps = @cur_fps
          @ups = @cur_ups
          @cur_fps = @cur_ups = 0
          @fps_counter.restart
        end
      end
      @window.close
    end

  end


end
