require 'socket.so'

HOST_IP = "127.0.0.1"
PORT = 5000;

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
  end
  
  def update(args)
    @heading = args[0]
    @latitude_deg = args[1]
    @longitude_deg = args[2]
    @roll_deg = args[3]
    @pitch_deg = args[4]
    @heading_deg = args[5]
    @airspeed_kt = args[6]
    @aileron = args[7]
    @elevator = args[8]
    @rudder = args[9]
    @throttle = args[9]
  end
  
  def socket_create
    @client = UDPClient.new(HOST_IP, PORT)
    @client.socket.bind(@client.host, @client.port)
  end
  
  def start  
      package = @client.socket.recvfrom(1024)
      array = package.to_s.split(',')
      update(array)
  end
  
end


def main
  control = ControlPanel.new
  while true
    control.start
    puts control.inspect
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