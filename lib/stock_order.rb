require 'rubygems'
require 'state_machine'

PriceChanged = Struct.new :symbol, :amount, :timestamp
class StockOrder
	state_machine :state, :initial => :long do
	  
	  after_transition :from => :with_new_price_message_received, :do => [:refresh_price, :adjust_trailing_stop]
	  event :price_changed do
	    transition all - :closed => :with_new_price_message_received
	  end
	  
	  event :time_tick do
	    transition :long => same
	    transition :with_new_price_message_received => :long, :if => :new_price_is_confirmed?
	    transition :with_new_price_message_received => :closed, :if => :should_sell?
	  end
	  
	end
	
	attr_reader :price, :pending_price, :trailing_stop
	
	def initialize symbol, amount, timestamp
	 @price = PriceChanged.new symbol, amount, timestamp
	 adjust_trailing_stop
	 super()
	end
	
	# Here we can do a clock that ticks every second to send this to us.
	def time_tick timestamp
	  @now = timestamp
	  super
	end
	
	def price_changed price_data
	  @pending_price = price_data
	  super
	end
	
	private
  	def new_price_is_confirmed?
  	  @now - @pending_price.timestamp >= 15 && @pending_price.amount > @price.amount
  	end
  	  
	  def adjust_trailing_stop
	    @trailing_stop = @price.amount - 1
	  end
	  
	  def should_sell?
	   @pending_price.amount < @trailing_stop  && @now - @pending_price.timestamp >= 30
	  end
	  
	  def refresh_price
	   @price = @pending_price
	  end
end
