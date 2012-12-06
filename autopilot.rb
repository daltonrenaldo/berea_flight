require 'pid'
require 'socket.so'

# GLOBAL VARIABLE FOR UDP SOCKET
HOST_IP = "127.0.0.1"
PORT = 5000
TO_PORT = 5010

# This Creates a UDP socket which is used for sending
# and receiving data to the simulator
 
class UDPClient
  attr_accessor :host, :port, :socket, :to_port
  
  # Creates the object
  # @params 
  #   host: the IP of the host server
  #   port: the receiving port
  #   to_port: the port we are sending to
  
  def initialize(host, port, to_port)
    @host = host
    @port = port
    @to_port = to_port
    @socket = UDPSocket.new
  end
end

class ControlPanel
  attr_accessor :client, :heading, :latitude_deg, :longitude_deg, :roll_deg, :pitch_deg, :heading_deg, :airspeed_kt,
  :aileron, :elevator, :rudder, :throttle, :altitude_ft, :previous_alt
  
  def initialize
    socket_create()
    @pid_pitch = PID.new("Pitch", 3,1.25, 0.0, 0, 0, 1, -1)
    @rollpid_ailerons = PID.new("Roll", 3.0,0.04,0)
    # @pid_verticalspeed = PID.new(3.0,0.04,0)
    @pid_heading = PID.new("Heading", 0.05, 0, 0)
    @alt_error = 0
    @previous_alt = 0
    @desired_alt = 10000
    setup()
  end
  
  # Zeros out junk values
  def setup()
    @pid_pitch.setpoint(0)
    @rollpid_ailerons.setpoint(0)
    # @pid_verticalspeed.setpoint(-5)
    @pid_heading.setpoint(300)
  end
  
  def flipSign()
    if rand(100) > 50
      1
    else
      -1
    end
  end
  
  def noise(v, percentC, percentE)
    if rand(100) < percentC
      (v * rand(percentE)/100 * flipSign())
    else
      0.0
    end
  end
  
  # updates our control attributes
  # @params
  #   args: array with values of the aircraft's
  #         current settings
  def update(args)
    @heading = args[0].to_f
    @latitude_deg = args[1].to_f
    @longitude_deg = args[2].to_f
    @altitude_ft = args[3].to_f
    @roll_deg = args[4].to_f
    @pitch_deg = args[5].to_f
    @heading_deg = args[6].to_f
    @airspeed_kt = args[7].to_f
    @aileron = args[8].to_f
    @elevator = args[9].to_f
    @rudder = args[10].to_f
    @throttle = args[11].to_f
  end
  
  # Create a UDP socket and bind it
  
  def socket_create
    @client = UDPClient.new(HOST_IP, PORT, TO_PORT)
    @client.socket.bind(@client.host, @client.port)
  end
  
  # This function starts and runs everything
  # This is basically the autopilot
  # @params
  #   previous_run_time: time since the program as been
  #                      running
  def start(previous_run_time)
    start_time = previous_run_time
    # read in data from sim and update class  
      package = @client.socket.recvfrom(1024)
      array = package.to_s.split(',')
      update(array)
    # # # # # # #
    
    # divide the roll by 180 to get into aileron control range
    scaled_roll = (@roll_deg / 180.0)
    
    # Aileron, Elevator, Rudder, and Throttle
    control = { :aileron => @rollpid_ailerons.update(scaled_roll), # Now update the PID controller with the current roll data
                                                                    # This returns a value, the value returned is what we want 
                                                                    # to use to control the aircraft.
                :elevator => 0, 
                :rudder => 0, 
                :throttle => 2.0 }
    
    desired_rate = get_target_climb_rate
    current_rate = get_current_climb_rate(start_time)
    

    # TODO: Pitch needs to incorporate heading
    
    @pid_pitch.setpoint(desired_rate)
    control[:rudder] = heading()
    
    # We set the elevator to the negative of the pitch 
    # because of the simulator. + pitch make us go down,
    # - makes up go up
    control[:elevator] = -constrain("", @pid_pitch.update(current_rate), -0.2, 0.05)
    
    puts "CURRENT CLIMB::" + current_rate.to_s
    puts "DESIRED CLIMB::" + desired_rate.to_s
    puts "Altitude: " + @altitude_ft.to_s
    puts "Heading: " + @heading_deg.to_s
    
    # saving the current altitude before it updates
    @previous_alt = @altitude_ft
    return control
  end
  
  # this function returns the rudder control value from the PID, 
  # we have to do some math first before we call the PID controller.
  # def heading_old ()
  #    setHeading = 180   
  #    @pid_heading.setpoint(setHeading)
  #    temp = 0
  #    temp = @heading_deg + 180 
  #    if (temp <= 360)
  #      #if waypoint is greater than temp we need to go left.
  #      if ( (@heading_deg > temp) and (@heading_deg -180 <= 0) )           
  #        return -(@pid_heading.update(@heading_deg))
  #      end    
  #    end
  #    return(@pid_heading.update(@heading_deg))
  #  end
  
  def heading()
    @pid_heading.update(@heading_deg)
    
  end
  
  # Contrain a value between a min and a max
  
  def constrain (label, val, min, max)
    result = 0
    if val > max
      result = max
    elsif val < min
      result = min
    else
      result = val
    end
    puts label + result.to_s
    result
  end
    
  # Get the climb angle we need to have
  # based on the current altitude  
  def get_target_climb_rate
    @alt_error = (@desired_alt - @altitude_ft)
    constrain("climb", Math.atan2(@alt_error / 1000.0, 1.0), -0.08, 0.03)
  end
  
  # Gets the current climb rate
  # @params 
  #  start_time: this is the time when when whole iteration started
  def get_current_climb_rate( start_time )
    Math.atan2(( @altitude_ft - @previous_alt) / (Time.now - start_time)/1000.0, 1.0)
  end

end # end of ControlPanel


def time_diff_milli(start, finish)
   (finish - start) * 1000.0
end

def main
  control = ControlPanel.new
  end_time = Time.now
  
  while true
    sending = control.start(end_time)
    command = "%f,%f,%f,%f\n" % [sending[:aileron], sending[:elevator] , sending[:rudder] , sending[:throttle]]
    puts "[Send]" + command.to_s
    control.client.socket.send(command,0, control.client.host, control.client.to_port )
    end_time = Time.now
    #puts control.inspect
  end
end

main()