require 'date'

class Option
  attr_reader :id, :expiration, :option_type, :strike
  
  #[{"_id":"4f21445f8b09d40003000005","expiration":"2012-01-26","option_type":false,"strike":1060}]
  def initialize(params)
    @expiration   = Date.strptime(params["expiration"], "%Y-%m-%d")
    @option_type  = params["option_type"]
    @strike       = params["strike"]
    @id           = params["_id"]
  end
  
  def is_call?
    @option_type == true  
  end
    
  def to_short
    "#{is_call? ? 'C':'P'}#{@strike}#{@expiration.strftime('%b%y')}" 
  end
end
