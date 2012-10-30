require 'pid'
require 'socket.so'


HOST_IP = "127.0.0.1"
PORT = 5000;
#PID responsible for controlling the pitch



class UDPClient
  attr_accessor :host, :port, :socket
  def initialize(host, port)
    @host = host
    @port = port
    @socket = UDPSocket.new
  end
end

class ControlPanel
  attr_accessor :client, :heading, :latitude_deg, :longitude_deg, :roll_deg, :pitch_deg, :heading_deg, :airspeed_kt,
  :aileron, :elevator, :rudder, :throttle
  
  def initialize
    socket_create()
    @pid_pitch = PID.new(0.15,1,0.0, 0, 0, 1, -1)
  end
  
  def update(args)
    @heading = args[0]
    @latitude_deg = args[1]
    @longitude_deg = args[2]
    @altitude_ft = args[3]
    @roll_deg = args[4]
    @pitch_deg = args[5]
    @heading_deg = args[6]
    @airspeed_kt = args[7]
    @aileron = args[8]
    @elevator = args[9]
    @rudder = args[10]
    @throttle = args[11]
  end
  
  def socket_create
    @client = UDPClient.new(HOST_IP, PORT)
    @client.socket.bind(@client.host, @client.port)
  end
  
  def start  
      package = @client.socket.recvfrom(1024)
      array = package.to_s.split(',')
      update(array)
      puts get_pitch(2000)
      
      @pid_pitch.setpoint(get_pitch(2000))
  end
  
  def get_pitch(desire_alt)
    pitch = (desire_alt - @altitude_ft.to_f) / @altitude_ft.to_f
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
    control.start
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