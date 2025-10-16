class Vector1
    attr_accessor :z
    def initialize(starting_z)
        @z = starting_z
    end

    def distance(other)
        (@z - other.z).abs
    end

    def +(other)
        Vector1.new(@z + other.z)
    end

    def scoot(other)
        @z += other.z
    end

    def swap(other)
        temp_z = other.z
        other.z = @z
        @z = temp_z
    end

    def to_s
        "(#{@z})"
    end

    def inspect
        "Vector1(#{@z})"
    end
end

# ~~~~~~~~~~~~~~~~~~~~

class Vector2
    attr_accessor :x
    attr_accessor :y
    def initialize(start_x = 0, start_y = 0)
        @x = start_x
        @y = start_y
    end

    def distance(other_v2)
        leg_x = @x - other_v2.x
        leg_y = @y - other_v2.y
        Math.sqrt((leg_x * leg_x) + (leg_y * leg_y))
    end

    def ==(other_v2)
        if @x == other_v2.x && @y == other_v2.y
            true
        else
            false
        end
    end

    def +(other_v2)
        Vector2.new(@x + other_v2.x, @y + other_v2.y)
    end

    def *(other_v2)
        Vector2.new(@x * other_v2.x, @y * other_v2.y)
    end

    def scoot(other_v2)
        @x += other_v2.x
        @y += other_v2.y
        self
    end

    def slide(integer)
        @x += integer
        @y += integer
        self
    end

    def scale(integer)
        @x *= integer
        @y *= integer
        self
    end

    def swap(other_v2)
        temp_x = other_v2.x
        temp_y = other_v2.y
        other_v2.x = @x
        other_v2.y = @y
        @x = temp_x
        @y = temp_y
        self
    end

    def flip
        temp_x = @x
        @x = @y
        @y = temp_x
        self
    end

    def to_s
        "(#{@x}, #{@y})"
    end

    def inspect
        "Vector2(#{@x}, #{@y})"
    end
end
