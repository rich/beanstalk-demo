class Stock < ActiveRecord::Base
  has_many :daily_entries
  
  async_after_create do |stock|
    stock.populate_entries!
  end
  
  def populate_entries!
    range = Date.parse('2000-01-01')..Date.today
    ranges = range.split_by_days(100)
    ranges.each do |r|
      self.async_send(:populate_for_range, r.begin.to_s, r.end.to_s)
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
end
