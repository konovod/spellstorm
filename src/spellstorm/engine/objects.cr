require "./engine.cr"

module Engine
  abstract class SpriteObject < GameObject
    abstract def my_tex : SF::Texture

    def initialize(owner, x, y, radius)
      super(owner, x, y)
      @sprite = SF::Sprite.new
      tex = my_tex
      tex.smooth = true
      @sprite.texture = tex
      @sprite.position = {x, y}
      w = tex.size.x
      h = tex.size.y
      @sprite.origin = {w/2.0, h/2.0}
      @sprite.scale = {2.0*radius/w, 2.0*radius/h}
    end

    def draw(target : SF::RenderTarget)
      target.draw @sprite
    end
  end

  class Background < GameObject
    def initialize(owner, tex : SF::Texture)
      super(owner, 0, 0)
      @obj = SF::RectangleShape.new({SCREENX, SCREENY})
      tex.repeated = true
      @obj.texture = tex
      w = tex.size.x
      h = tex.size.y
      @obj.texture_rect = SF.int_rect(0, 0, SCREENX, SCREENY)
    end

    def draw(target : SF::RenderTarget)
      target.draw @obj
    end
  end

  abstract class SimplePhysicObject < SpriteObject
    getter target : MyVec

    def target=(vec : MyVec)
      @control_body.position = CP.v(vec.x, vec.y)
      @target = vec
    end

    abstract def my_mass : Float

    def my_maxspeed : Float
      100.0
    end

    def my_moveforce : Float
      100.0
    end

    def initialize(owner, x, y, radius)
      super(owner, x, y, radius)
      mass = my_mass
      moment = CP.moment_for_circle(mass, 0.0, radius)
      @body = CP::Body.new(mass, moment)
      @body.position = CP.v(x, y)
      owner.space.add(@body)
      @shape = CP::CircleShape.new(@body, radius)
      owner.space.add(@shape)
      @shape.friction = 0.7 # TODO materials

      @control_body = CP::Body.new_static
      @control_body.position = @body.position
      @target = vec(x, y)
      @leash = CP::PivotJoint.new(@body, @control_body, CP.vzero)
      @leash.max_bias = my_maxspeed
      @leash.max_force = my_moveforce
      owner.space.add(@leash)
    end

    def draw(target : SF::RenderTarget)
      @sprite.position = {@body.position.x, @body.position.y}
      super
    end
  end
end
