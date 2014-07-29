class RoverTread

  def initialize(rover, index)
    @rover = rover
    @index = index
    @is_moving = false
    @start_time = 0
    @TREAD_DELAY_SEC = 1.0
  end

  def moving?
    @is_moving
  end

  def update value

    if value == 0
      if @is_moving
        @rover.spin_wheels(@index, 0)
        @is_moving = false
      end

    else
      if value < 0
        wheel = @index
      else
        wheel = @index+1
      end

      current_time = Time.now.to_i
      if( current_time -  @start_time > @TREAD_DELAY_SEC )
        @start_time = current_time
        @rover.spin_wheels(wheel, (value.abs*10).round.to_i )
        @is_moving = true
      end
    end

  end

end