require 'gosu'
require 'vectors'

class Ball
    attr_reader :radius
    attr_accessor :spot
    attr_accessor :speed
    attr_accessor :spin
    attr_accessor :r
    attr_accessor :held
    DIAMETER = 50.0
    SPEED_CAP = 5.0
    def initialize(win, pointer)
        @win = win
        @pointer = pointer
        @image = Gosu::Image.new('Assets/ClipArt/BlueBall.png')
        @w = DIAMETER/@image.width
        @h = DIAMETER/@image.height
        @radius = DIAMETER / 2
        @angle = 0    #rotation angle
        @spot = Vector2.new(rand(@radius..(@win.width-@radius)), rand(@radius..(@win.height-@radius)))
        @speed = Vector2.new(rand(-SPEED_CAP..SPEED_CAP), rand(-SPEED_CAP..SPEED_CAP))
        @spin = rand(-SPEED_CAP..SPEED_CAP)
        @held = false
    end

    def get_dist(other_x, other_y)
        leg_x = @spot.x - other_x
        leg_y = @spot.y - other_y
        Math.sqrt((leg_x * leg_x) + (leg_y * leg_y))
    end

    def smack(other)
        @speed.swap(other.speed)
        @spin *= -1.0
        other.spin *= -1.0
    end

    def invert
        @speed.scale(-1.0)
        @spin *= -1.0
    end

    def mixup
        @speed = Vector2.new(rand(-SPEED_CAP..SPEED_CAP), rand(-SPEED_CAP..SPEED_CAP))
        @spin = rand(-SPEED_CAP..SPEED_CAP)
    end

    def leap
        @spot = Vector2.new(rand(@radius..(@win.width-@radius)), rand(@radius..(@win.height-@radius)))
    end

    def jump
        10.times do self.move end
    end

    def kill
        @speed.x = 0.0
        @speed.y = 0.0
    end

    def wall_check
        if @spot.x <= @radius
            @speed.x = @speed.x.abs
            @spin *= -1.0
            if @held
                @held = false
                @pointer.clicked = false
                @spot.x += 10
            end
        end
        if @spot.x >= @win.width-@radius
            @speed.x = -@speed.x.abs
            @spin *= -1.0
            if @held
                @held = false
                @pointer.clicked = false
                @spot.x -= 10
            end
        end
        if @spot.y <= @radius
            @speed.y = @speed.y.abs
            @spin *= -1.0
            if @held
                @held = false
                @pointer.clicked = false
                @spot.y += 10
            end
        end
        if @spot.y >= @win.height-@radius
            @speed.y = -@speed.y.abs
            @spin *= -1.0
            if @held
                @held = false
                @pointer.clicked = false
                @spot.y -= 10
            end
        end
    end

    def drop
        @held = false
    end

    def move
        self.wall_check
        unless @held
            @spot.x += @speed.x
            @spot.y += @speed.y
        end
        @angle += @spin
    end

    def draw
        @image.draw_rot(@spot.x, @spot.y, 0, @angle, 0.5, 0.5, @w, @h)  # 0.5 = half image as center
    end
end

class Mouse
    attr_accessor :spot
    attr_reader :radius
    attr_accessor :clicked
    def initialize(win)
        @spot = Vector2.new(win.mouse_x, win.mouse_y)
        @radius = 5
        @clicked = false
    end
end

Collision = Struct.new(:ball1, :ball2) do
    def to_s
        "(#{ball1.spot.x.to_i}, #{ball1.spot.y.to_i} X #{ball2.spot.x.to_i}, #{ball2.spot.y.to_i})"
    end

    def inspect
        to_s
    end
end

class Game < Gosu::Window
    CYAN = 0xff_00ccff
    def initialize
        @width = 800
        @height = 600
        super @width, @height, false
        self.caption = "BOUNCE GAME!!!"
        @paused = false
        @font = Gosu::Font.new(25, name: "Chilanka")
        @pause_text = Gosu::Image.from_text("PAUSED", 75, font: "Purisa", :bold => true, :italic => true)
        @pointer = Mouse.new(self)
        @balls = []
        10.times { @balls.push(Ball.new(self, @pointer)) }
    end

    def needs_cursor?
        true
    end

    def button_down(id)
        unless @paused
            case id
            when Gosu::KbI then @balls.each(&:invert)
            when Gosu::KbM then @balls.each(&:mixup)
            when Gosu::KbL then @balls.each(&:leap)
            when Gosu::KbJ then @balls.each(&:jump)
            when Gosu::KbK then @balls.each(&:kill)
            when Gosu::MS_LEFT then @pointer.clicked = true
            end
        end
        if id == Gosu::KbSpace || id == Gosu::KbP
            self.pause_toggle
        end
    end

    def button_up(id)
        if id == Gosu::MS_LEFT
            @balls.each(&:drop)
            @pointer.clicked = false
        end
    end

    def pause_toggle
        @paused = !@paused
    end

# physics stuff ~~~~~~~~~~~~~~~~~~~~~~~~~
    def do_smacks
        collisions = @balls.map.with_index do |ball1, index|
            @balls[(index+1)..].map do |ball2|
                if ball1.spot.distance(ball2.spot) <= (ball1.radius + ball2.radius) &&
                (ball1.spot+ball2.speed).distance(ball2.spot+ball1.speed) >= (ball1.radius + ball2.radius)
                    if !ball1.held && !ball2.held
                        Collision.new(ball1, ball2)
                    elsif !ball1.held && ball2.held
                        ball1.invert
                        ball2.spin *= -1
                        nil
                    elsif ball1.held && !ball2.held
                        ball2.invert
                        ball1.spin *= -1
                        nil
                    else
                        nil
                    end
                else
                    nil
                end
            end
        end.flatten.compact
        collisions.each { |pair| pair.ball1.smack(pair.ball2) }
    end

    def do_click
        caught = @balls.map do |ball|
            if ball.spot.distance(@pointer.spot) <= (ball.radius + @pointer.radius)
                ball
            else
                nil
            end
        end.flatten.compact
        if caught.any?
            @balls.each(&:drop)
            caught[0].held = true
            caught[0].spot = @pointer.spot
        end
    end
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    def update
        @pointer.spot = Vector2.new(self.mouse_x, self.mouse_y)
        if @pointer.clicked
            self.do_click
        end
        self.do_smacks
        if @paused
            @balls
        else
            @balls.each(&:move)
        end
    end

    def draw
        # msg = "<- #{self.mouse_x.to_i}, #{self.mouse_y.to_i}"
        # @font.draw_text(msg, self.mouse_x, self.mouse_y, 0)
        @balls.each(&:draw)
        if @paused
            @pause_text.draw(0, 0, 0, 1, 1, CYAN)
        end
    end
end

Game.new.show
