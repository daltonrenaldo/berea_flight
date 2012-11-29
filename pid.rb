#rewrite of the python PID to a ruby PID

class PID

	def initialize( label = "Mystery", p = 2.0, i = 0.0, d = 1.0, derivator = 0, integrator = 0, integrator_max = 5, integrator_min = -5)
    #what does Kp, Ki, Kd mean here?
		@Kp = p
		@Ki = i
		@Kd = d
		@Derivator = derivator
		@Integrator = integrator
		@Integrator_max = integrator_max
		@Integrator_min = integrator_min

		@set_point = 0.0
		@error = 0.0
    
    @label = label
  end
  

  def update(current_value)
  
    #Calculate PID output value for given reference input and feedback
  

    @error  =  @set_point - current_value
    
    puts @label + " ERROR :: %f " % @error
    
    @P_value  =  @Kp * @error
    @D_value  =  @Kd * ( @error - @Derivator)
    @Derivator  =  @error

    @Integrator  =  @Integrator + @error

    if @Integrator > @Integrator_max
      @Integrator  =  @Integrator_max
    elsif @Integrator < @Integrator_min
      @Integrator  =  @Integrator_min
    end
    @I_value  =  @Integrator * @Ki

    pid  =  @P_value + @I_value + @D_value
    
    puts @label + " :: " + "P %f I %f D %f" % [@P_value, @I_value, @D_value]
    return pid
  end
  
  
  def setpoint(set_point)
    
    # Initilize the setpoint of PID
    
    @set_point  =  set_point
    @Integrator = 0
    @Derivator = 0
  end
  
  def setIntegrator( integrator)
    @Integrator  =  integrator
  end
  
  def setDerivator( derivator)
    @Derivator  =  derivator
  end
  
  def setKp(p)
    @Kp = p
  end
  
  def setKi(i)
    @Ki = i
  end
  
  def setKd(d)
    @Kd = d
  end
  
  def getPoint
    return @set_point
  end
  
  def getError
    return @error
  end
  
  def getIntegrator
    return @Integrator
  end
  
  def getDerivator
    return @Derivator
  end
end