class Stock < ActiveRecord::Base
  has_many :daily_entries
  
  async_after_create do |stock|
    stock.populate_entries!
  end
  
  def populate_entries!
    ranges = split_by_days(Date.parse('2000-01-01'), Date.today, 100)
    ranges.each do |start, finish|
      self.async_send(:populate_for_range, start.to_s, finish.to_s)
    end
  end
  
  def populate_for_range(start, finish)
    s = Date.parse(start)
    f = Date.parse(finish)
    data = YahooFinance.new(self.symbol, s, f)
    data.prices.each do |k, v|
      self.daily_entries.find_or_create_by_created_on(:created_on => k) do |e|
        e.open_price = v[:open]
        e.close_price = v[:close]
        e.high_price = v[:high]
        e.low_price = v[:low]
      end
    end
  end
  
  def split_by_days(start, finish, days)
    current_start = start
    current_finish = start + days
    
    returning([]) do |ranges|
      loop do
        if current_finish > finish
          ranges << [current_start, finish]
          break
        else
          ranges << [current_start, current_finish]
        end
        current_start = current_finish + 1
        current_finish = current_finish + days
      end
    end
  end
end
