#rewrite of the python PID to a ruby PID

class PID:
	"""
	Discrete PID control
	"""

	def initialize( P = 2.0, I = 0.0, D = 1.0, Derivator = 0, Integrator = 0, Integrator_max = 5, Integrator_min = -5):

        #what does Kp, Ki, Kd mean here?
		@Kp = P
		@Ki = I
		@Kd = D
		@Derivator = Derivator
		@Integrator = Integrator
		@Integrator_max = Integrator_max
		@Integrator_min = Integrator_min

		@set_point = 0.0
		@error = 0.0
  end
  

	def update(current_value):
		"""
		Calculate PID output value for given reference input and feedback
		"""

		@error  =  @set_point - current_value

		@P_value  =  @Kp * @error
		@D_value  =  @Kd * ( @error - @Derivator)
		@Derivator  =  @error

		@Integrator  =  @Integrator + @error

		if @Integrator > @Integrator_max:
			@Integrator  =  @Integrator_max
		elif @Integrator < @Integrator_min:
			@Integrator  =  @Integrator_min

		@I_value  =  @Integrator * @Ki

		PID  =  @P_value + @I_value + @D_value

		return PID
  end
  
  
	def setPoint(set_point):
		"""
		Initilize the setpoint of PID
		"""
		@set_point  =  set_point
		@Integrator = 0
		@Derivator = 0
  end
  
	def setIntegrator( Integrator):
		@Integrator  =  Integrator
  end
  
	def setDerivator( Derivator):
		@Derivator  =  Derivator
  end
  
	def setKp(P):
		@Kp = P
  end
  
	def setKi(I):
		@Ki = I
  end
  
	def setKd(D):
		@Kd = D
  end
  
	def getPoint(self):
		return @set_point
  end
  
	def getError(self):
		return @error
  end
  
	def getIntegrator(self):
		return @Integrator
  end
  
	def getDerivator(self):
		return @Derivator
  end


end
