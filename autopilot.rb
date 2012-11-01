require 'pid'
require 'socket.so'


HOST_IP = "127.0.0.1"
PORT = 5000
TO_PORT = 5010
#PID responsible for controlling the pitch



class UDPClient
  attr_accessor :host, :port, :socket, :to_port
  def initialize(host, port, to_port)
    @host = host
    @port = port
    @to_port = to_port
    @socket = UDPSocket.new
  end
end

class ControlPanel
  attr_accessor :client, :heading, :latitude_deg, :longitude_deg, :roll_deg, :pitch_deg, :heading_deg, :airspeed_kt,
  :aileron, :elevator, :rudder, :throttle, :altitude_ft
  
  def initialize
    socket_create()
    @pid_pitch = PID.new(0.15,1,0.0, 0, 0, 1, -1)
    @rollpid_ailerons = PID.new(3.0,0.04,0)
    @pid_verticalspeed = PID.new(3.0,0.04,0)
    @pid_heading = PID.new(0.1, 0.0, 0.0)
    setup()
  end
  
  def setup()
    @pid_pitch.setpoint(0)
    @rollpid_ailerons.setpoint(0)
    @pid_verticalspeed.setpoint(-5)
    @pid_heading.setpoint(40)
  end
  
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
  
  def socket_create
    @client = UDPClient.new(HOST_IP, PORT, TO_PORT)
    @client.socket.bind(@client.host, @client.port)
  end
  
  def start
    # read in data from sim and update class  
      package = @client.socket.recvfrom(1024)
      array = package.to_s.split(',')
      update(array)
    # # # # # # #
    
    # Aileron, Elevator, Rudder, and Throttle
    control = {:aileron => 0, :elevator => 0, :rudder => 0, :throttle => 1}
    control[:elevator] = @elevator
    control[:throttle] = 1.0   # always fly at full throttle
    #do stuff and change how the plane flies, Handle roll, get current roll rate.
    
    #divide the roll by 180 to get into aileron control range
    scaled_roll = (@roll_deg / 180.0)
    
    # Now update hte PID controller with the current roll data
    # This returns a value, the value returned is what we want 
    # to use to control the aircraft.
    
    control[:aileron] = (@rollpid_ailerons.update(scaled_roll))
    control[:elevator] = (get_pitch(2000))
    
    # We dont need that altitude hold renaldo thinks. 
    control[:rudder] = heading()
    return control
  end
  
  # this function returns the rudder control value from the PID, we have to do some math first before we call the PID controller.
  def heading ()
    setHeading = 180   
    @pid_heading.setpoint(setHeading)
    temp = 0
    temp = @heading_deg + 180 
    if (temp <= 360)
      #if waypoint is greater than temp we need to go left.
      if ( (@heading_deg > temp) and (@heading_deg -180 <= 0) )           
        return -(@pid_heading.update(@heading_deg))
      end    
    end
    return(@pid_heading.update(@heading_deg))
  end
  #end the heading function
  
  def get_pitch(desire_alt)
    pitch = (desire_alt - @altitude_ft) / @altitude_ft
    if pitch >=0
      if pitch > 3 #max pitch
        pitch = 3
      end
    else
      if pitch < -3 #min pitch
        pitch = -3
      end
    end
    pitch
  end
    
end # end of ControlPanel


def main
  control = ControlPanel.new
  while true
    sending = control.start
    command = "%f,%f,%f,%f\n" % [sending[:aileron], sending[:elevator] , sending[:rudder] , sending[:throttle]]
    puts "[Send]" + command.to_s
    control.client.socket.send(command,0, control.client.host, control.client.to_port )
    #puts control.inspect
  end

end

main()



# #
# #
# class udp
#   create socket.
#   read first package.
#   seperate values of this package, and create teh first instance of controls class w/ these parameters 
#   filling in class variables.
#   
#   loop 
#   read in another package, 
#   call update function in controls class and update values.
#   
#   
#   class controls
#     functions: intilize - first creation
#     update_longitude
#     update_speed
#     etc etc
#     these functions will update class with new values from package.