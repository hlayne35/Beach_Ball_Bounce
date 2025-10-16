# Encoding: UTF-8

require "gosu"
require "chipmunk"

WIDTH = 800
HEIGHT = 600
RADIUS = 25.0
SPEED_CAP = 50.0

SUBSTEPS = 6

class Ball
    attr_reader :shape

    def initialize(win)
        @image = Gosu::Image.new('Assets/ClipArt/BlueBall.png')
        @w = (RADIUS*2.0)/@image.width
        @h = (RADIUS*2.0)/@image.height
        @radius = RADIUS
#        @color = Gosu::Color.new(0xff_000000)
#        @color.red = rand(255 - 40) + 40
#        @color.green = rand(255 - 40) + 40
#        @color.blue = rand(255 - 40) + 40
        @body = CP::Body.new(0.0001, 0.001)
        @shape = CP::Shape::Circle.new(@body, RADIUS, CP::Vec2.new(0.0, 0.0))
        @shape.collision_type = :ball
        @shape.body.p = CP::Vec2.new(rand(@radius..(WIDTH-@radius)), rand(@radius..(HEIGHT-@radius)))
        @shape.body.v = CP::Vec2.new(rand(-SPEED_CAP..SPEED_CAP), rand(-SPEED_CAP..SPEED_CAP)) # velocity
        @shape.body.a = 0.gosu_to_radians   # faces towards top of screen
        @shape.e = 1.001
        @shape.u = 0.05
        win.space.add_body(@body)
        win.space.add_shape(@shape)
    end

    def invert
        @shape.body.v = @shape.body.v * -1.0
#        @spin *= -1.0
    end

    def mixup
        @shape.body.v = CP::Vec2.new(rand(-SPEED_CAP..SPEED_CAP), rand(-SPEED_CAP..SPEED_CAP))
        @spin = rand(-SPEED_CAP..SPEED_CAP)
    end

    def leap
        @shape.body.p = CP::Vec2.new(rand(@radius..(WIDTH-@radius)), rand(@radius..(WIDTH-@radius)))
    end

=begin
    def jump
        @shape.body.apply_force(@shape.body.v * (2.0), CP::Vec2.new(0.0, 0.0))
        #require 'pry'; binding.pry
    end
=end

    def kill
        @shape.body.v.x = 0.0
        @shape.body.v.y = 0.0
    end

    def validate_position
        l_position = CP::Vec2.new(@shape.body.p.x % WIDTH, @shape.body.p.y % HEIGHT)
        @shape.body.p = l_position
    end

    def update
        # When a force or torque is set on a Body, it is cumulative
        # This means that the force you applied last SUBSTEP will compound with the
        # force applied this SUBSTEP; which is probably not the behavior you want
        # We reset the forces on the pointer each SUBSTEP for this reason
        self.shape.body.reset_forces

        # Wrap around the screen to the other side
        self.validate_position
    end

    def draw
        @image.draw_rot(@shape.body.p.x, @shape.body.p.y, 0, @shape.body.a.radians_to_gosu, 0.5, 0.5, @w, @h)
    end
end

class Pointer
    attr_reader :shape
    attr_accessor :clicked

    def initialize(win)
        @clicked = false

        #@shape.body.v = CP::Vec2.new(0.0, 0.0)
        @body = CP::Body.new(10.0, 100.0)       # figure out how to give infinite/static mass
        @shape = CP::Shape::Circle.new(@body, 5, CP::Vec2.new(win.mouse_x, win.mouse_y))
        @shape.collision_type = :mouse
        @shape.body.p = CP::Vec2.new(win.mouse_x, win.mouse_y)
#        @shape.body.a = (3*Math::PI/2.0)       # angle in radians; faces towards top of screen
        win.space.add_body(@body)
        win.space.add_shape(@shape)
    end

    # Directly set the position of our pointer
    def track(win)
        @shape.body.p = CP::Vec2.new(win.mouse_x, win.mouse_y)
    end
end

=begin
class Border
    def initialize(win)
    end
end
=end

class Wall
  attr_reader :a, :b

  def initialize(window, shape, pos)
    @window = window

    @a = CP::Vec2.new(shape[0][0], shape[0][1])
    @b = CP::Vec2.new(shape[1][0], shape[1][1])

    @body = CP::Body.new(CP::INFINITY, CP::INFINITY)
    @body.p = CP::Vec2.new(pos[0], pos[1])
    @body.v = CP::Vec2.new(0,0)

    @shape = CP::Shape::Segment.new(@body, @a, @b, 1)
    @shape.e = 1.001
    @shape.u = 0.05

    @window.space.add_static_shape(@shape)
  end
end

class Bounce_Time < (Example rescue Gosu::Window)
    attr_accessor :space

    def initialize
        super WIDTH, HEIGHT
        self.caption = "BOUNCE TIME!!!"

        @hit = Gosu::Sample.new("Assets/explosion.wav")
#        @ball_pic = Gosu::Image.new('Assets/ClipArt/BlueBall.png')
        @font = Gosu::Font.new(20)

        # Time increment over which to apply a physics "step" ("delta t")
        @dt = (1.0/60.0)

        # Create our Space and set its damping
        # A damping of 0.8 causes the ship bleed off its force and torque over time
        @space = CP::Space.new
        @space.damping = 1.0

        @pointer = Pointer.new(self)
        @pointer.track(self)

        @balls = Array.new

        # Here we define what is supposed to happen when a pointer collides with a ball.
        # I create a @remove_shapes array because we cannot remove either Shapes or Bodies
        # from Space within a collision closure.  Rather, we have to wait till the closure
        # is through executing, then we can remove the Shapes and Bodies.
        # In this case, the Shapes and the Bodies they own are removed in the Gosu::Window.update
        # phase by iterating over the @remove_shapes array.
        # Also note that both Shapes involved in the collision are passed into the closure in
        # the same order that their collision_types are defined in the add_collision_func call.
        @remove_shapes = []
        @space.add_collision_func(:mouse, :ball) do |point_shape, ball_shape|
            if @pointer.clicked
                @hit.play
                @remove_shapes << ball_shape
            end
        end

=begin
        CP::Shape::Segment.new(YOUR_STATIC_BODY, CP::Vec2.new(0, 0), CP::Vec2.new(WIDTH, 0), 1.0)
        CP::Shape::Segment.new(YOUR_STATIC_BODY, CP::Vec2.new(0, 0), CP::Vec2.new(0, HEIGHT), 1.0)
        CP::Shape::Segment.new(YOUR_STATIC_BODY, CP::Vec2.new(WIDTH, 0), CP::Vec2.new(WIDTH, HEIGHT), 1.0)
        CP::Shape::Segment.new(YOUR_STATIC_BODY, CP::Vec2.new(0, HEIGHT), CP::Vec2.new(WIDTH, HEIGHT), 1.0)
        @space.add_static_shape(THE_SEGMENT)
        # https://stackoverflow.com/questions/27628340/space-borders-in-chipmunk-with-ruby
=end

        @borders = []
        # left
        @borders << Wall.new(self, [[1, 1], [1,HEIGHT-1]], [1, 1])
        # top
        @borders << Wall.new(self, [[1, 1], [WIDTH-1, 1]], [1,1])
        # right
        @borders << Wall.new(self, [[1, 1], [1,HEIGHT-1]], [WIDTH-1, 1])
        # bottom
        @borders << Wall.new(self, [[1, 1], [WIDTH-1, 1]], [1,HEIGHT-1])
    end

    def needs_cursor?
        true
    end

    def update
        @pointer.shape.body.p = CP::Vec2.new(self.mouse_x, self.mouse_y)

        unless @paused
            SUBSTEPS.times do
                @remove_shapes.each do |shape|
                    @balls.delete_if { |ball| ball.shape == shape }
                    @space.remove_body(shape.body)
                    @space.remove_shape(shape)
                end
                @remove_shapes.clear # clear out the shapes for next pass

                @balls.each(&:update)
                @space.step(@dt)
            end

            # Each update (not SUBSTEP) we see if we need to add more balls
            if rand(100) < 5 and @balls.size < 10
                @balls.push(Ball.new(self))
            end
        end
    end

    def draw
        @balls.each(&:draw)
    end

    def button_down(id)
        unless @paused
            case id
            when Gosu::KbI then @balls.each(&:invert)
            when Gosu::KbM then @balls.each(&:mixup)
            when Gosu::KbL then @balls.each(&:leap)
#            when Gosu::KbJ then @balls.each(&:jump)
            when Gosu::KbK then @balls.each(&:kill)
            when Gosu::MS_LEFT then @pointer.clicked = true
            end
        end
        if id == Gosu::KbSpace || id == Gosu::KbP
            self.pause_toggle
        elsif id == Gosu::KB_ESCAPE
            close
        else
            super
        end
    end

    def button_up(id)
        if id == Gosu::MS_LEFT
            @pointer.clicked = false
        end
    end

    def pause_toggle
        @paused = !@paused
    end
end

Bounce_Time.new.show
