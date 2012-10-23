# Flying Gator Autopilot Exploration
# (C) 2012 Cory Jones, Matthew Jadud, Tyler Khune

'''
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>. 
'''
# Imports
import socket
import re
import random
import math
from pid import PID

#pid responisble for taking in roll and changing ailerons
rollPID_ailerons = PID(3.0,0.04,0)
#PID responible for vertical speed
PID_VerticalSpeed = PID(3.0,0.04,0)
#PID responsible for controlling the pitch
PID_pitch = PID(0.38,0.0,0.0)
#PID responsible for controlling the altitude
PID_AltHold = PID(1.5,0.02,0.0)
PID_Heading = PID(0.1,0.0,0.0)
#holds the past altitude
pastAlt = 2000




# We'll do this once before flying.
def setup_plane():
  print "Running Setup."
  # Ailerons control roll.
  # We want to target a roll of zero.
  # So, we tell the rollPID to make its setPoint zero.
  global rollPID_ailerons
  global PID_heading
  global PID_pitch
  global PID_VerticalSpeed
  global PID_AltHold
  global PID_Heading
  global setHeading 
  setHeading = 40
  
  PID_AltHold.setPoint(200.00)
  rollPID_ailerons.setPoint(0)
  PID_VerticalSpeed.setPoint(-5)
  ##PID_pitch.setPoint(0)
  ##PID_AltHold.setPoint(0)
  PID_Heading.setPoint(setHeading)

# Here are the index values for each number that
# is in the "data" array.
'''
`((heading 0)
    (latitude-deg 1)
    (longitude-deg 2)
    (altitude-ft 3)
    (roll-deg 4)
    (pitch-deg 5)
    (heading-deg 6)
    (airspeed-kt 7)
    (aileron 8)
    (elevator 9)
    (rudder 10)
    (throttle 11)
'''
#this gets passed the object command
def control_plane (data):
  # Use the global PID structures
  global rollPID_ailerons
  global pastAlt
  
  #store the current pitch
  currentPitch = data[5]
  
  # Aileron, Elevator, Rudder, and Throttle
  cmd = [0,0,0,1]
  #cmd = data[8]
  cmd[1] = data[9]
	# We'll fly full throttle always.
  cmd[3] = 1.0
  # Do stuff and change how the plane flies.
  # Handle roll.
  # Get the current roll rate.
  roll = data[4]
  curAlt = data[3]
  # The roll has a range of -180 to 180.
  # Aileron control is from -1 to 1.
  # Divide the roll by 180 to get into aileron control range.
  scaled_roll = roll / 180.0
  # Now we need to update the PID controller with
  # the current roll data. This returns a value.
  # The value it returns is the value we want to use in controlling
  # our aircraft.
  #
  # By updating cmd.ailerons, we are ready to return the CMD
  # data structure and watch the aircraft fly.
  cmd[0] = (rollPID_ailerons.update(scaled_roll))
  #pitch controller
  cmd[1] = pitch_hold(currentPitch)
  
  #pass in the current altitude
  verticalSpeedHold(data[3])
  
  #pass in the current altitude
  altitudeHold(data[3])
  
  #set the past alt to the current alt before we exit
  pastAlt = data[3]
  current_heading = data[6]
  cmd[2] = heading(current_heading)
  
  return cmd

def heading(current_heading): 
  global setHeading
  setHeading = 180
  
  global PID_Heading
  global setHeading 
  
  PID_Heading.setPoint(setHeading)
  temp = 0
  temp = current_heading + 180
  
  #check to make sure temp is not greater than 360
  if temp <= 360:
    #if waypointHeading is greater than temp
    #you will need to turn left
    if current_heading > temp:
      #if current_heading minus 180 is less than zero,
      #then we need to still turn left
      if (current_heading - 180) <= 0:
          return -(PID_Heading.update(current_heading))
          
      else:
        return (PID_Heading.update(current_heading))
    #else the waypoint is less than current heading
    else:
      return (PID_Heading.update(current_heading))    
  else:
    return PID_Heading.update(current_heading)
    
#the pastalt holds the last value pof altitutde that the plane recorded
#alt is just a measurment passed in from the airplane telling us what the current altitude is. 
def rateofclimb(alt):
  #mult by 5 maybe?
  global pastAlt
  change_alt = alt - pastAlt
  return change_alt

#pastAlt is the past altitude
#the alt is the current altitude 
def altitudeHold(alt):
  global PID_AltHold
  global PID_VerticalSpeed
  goalAlt = 1000
  adjAlt = goalAlt - alt
  pidAlt = PID_AltHold.update(adjAlt)
  
  
  maxChange = 2
  
  if pidAlt >= maxChange:
    pidAlt = maxChange
  elif pidAlt < -(maxChange):
    pidAlt = -(maxChange)
  
  PID_VerticalSpeed.setPoint(pidAlt)
 
  
  
  
#alt is the current alt
#this edits the set point of the pidPitch controller
def verticalSpeedHold(alt):
  global PID_VerticalSpeed
  changeAlt = rateofclimb(alt)
  vertSpeed = PID_VerticalSpeed.update(changeAlt)
  PID_pitch.setPoint(vertSpeed)
  
  
  '''
  `((heading 0)
      (latitude-deg 1)
      (longitude-deg 2)
      (altitude-ft 3)
      (roll-deg 4)
      (pitch-deg 5)
      (heading-deg 6)
      (airspeed-kt 7)
      (aileron 8)
      (elevator 9)
      (rudder 10)
      (throttle 11)
  '''
  #working
def pitch_hold(curent_pitch):
  global PID_pitch
  curent_pitch = (-(curent_pitch))
  return PID_pitch.update(curent_pitch)
  
  
  
  
  

def main_loop():
	# UDP code from 
	# http://wiki.python.org/moin/UdpCommunication

	# The simulator is running on the same machine,
	# which is given the special loopback address
	# of '127.0.0.1'.
	SIM_IP = '127.0.0.1'

	# The simulator puts data out on port 5000, and 
	# reads data in on port 5010. These are parameters
	# that we give to the simulator when it starts, so
	# they could change, but only if we want them to.
	FROM_SIM = 5000
	TO_SIM   = 5010

	# Use the 'net, and send/read UDP packets.
	sim_sock = socket.socket (socket.AF_INET, socket.SOCK_DGRAM)

	# We have to "bind" to the port to listen for messages.
	# Note that we send a tuple: the IP address and the port.
	sim_sock.bind ((SIM_IP, FROM_SIM))

	while True:
		# recvfrom will block until data arrives.
		data, addr = sim_sock.recvfrom (1024)
		# pieces is now a list of strings.
		pieces = re.split (',', data)
		#numbers will be an array of strings.
		numbers = []
		for num in pieces:
			numbers.append(float(num))
    #print numbers
    # Set throttle to max and ailerons to something random
		# We send four pieces of data:
		# Aileron, Elevator, Rudder, and Throttle
		# IMPORTANT
		# Note how we construct a BYTE string by using the letter 'b' at the
		# start of the string. That matters a lot.
		print numbers
		CMD = control_plane(numbers)
		COMMAND = b"%f,%f,%f,%f\n" % (CMD[0], CMD[1], CMD[2], 1.0)
		print "[SEND] %s" % COMMAND
		sim_sock.sendto(COMMAND, (SIM_IP, TO_SIM))

# Run the setup
setup_plane()

# Run the main loop
main_loop()

