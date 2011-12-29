require 'spec_helper'

describe StockOrder do
  include SyntacticSugar
  
  let (:order) { StockOrder.new 'EUR', 10.some_currency, 12345 }
  
  context 'when being long' do
    it 'should have its trailing stop adjusted' do
      order.trailing_stop.should be_equal 9.some_currency
    end
    
    it 'should stay long as time goes by and nothing happens' do
      order.time_tick order.price.timestamp + 10.seconds
      
      order.should be_long
    end
    
    it 'should be with price changed if a new price changed message is received' do
      order.price_changed PriceChanged.new 'EUR', 10.some_currency, 12345
      
      order.should be_with_new_price_message_received
    end
  end
  
  describe 'As new price messages arrive' do
    context 'when the price goes up' do
      let (:new_price) { PriceChanged.new 'EUR', 11.some_currency, 12346 }
      
      it 'should go long if the new price point was held for 15 seconds or more' do
        order.price_changed new_price
        order.time_tick new_price.timestamp + 15.seconds

        order.should be_long
      end
    
      it 'should be still waiting if the confirmation time did not elapse' do
        order.price_changed new_price
        order.time_tick new_price.timestamp + only_11.seconds
      
        order.should be_with_new_price_message_received
      end
      
      it 'should record the new price and adjust the traling after price the new price was confirmed' do
        order.price_changed new_price
        order.time_tick new_price.timestamp + 15.seconds
        
        order.price.should == new_price
        order.trailing_stop.should == 10.some_currency
      end
    end
    
    context 'when the price broke the trailing stop' do
      let (:trailing_stop_breaking_price) { PriceChanged.new 'EUR', 8.some_currency, 12346 }
      
      it 'should not be closed if the required time did not elapse' do
        order.price_changed trailing_stop_breaking_price
        order.time_tick order.pending_price.timestamp + only_11.seconds
      
        order.should be_with_new_price_message_received
      end
    
      it 'should be closed if the required time elapsed' do
        order.price_changed trailing_stop_breaking_price
        order.time_tick order.pending_price.timestamp + 30.seconds
      
        order.should be_closed
      end
    end
  end
  
  context 'when it was closed' do 
    before do
      order.state = 'closed'
    end
    
    it 'ignores any new price messages' do
      order.price_changed PriceChanged.new 'EUR', 8.some_currency, 12346
      
      order.should be_closed
    end
    
    it 'ignores time as it goes by' do
      order.time_tick 12361
      
      order.should be_closed
    end
  end
end