require 'date'
require 'net/http'
require 'uri'

class YahooFinance
  BASE_URL = 'http://finance.yahoo.com/q/hp'
  SCRAPE_URL = "#{BASE_URL}?s=%s&a=%d&b=%d&c=%d&d=%d&e=%d&f=%d&g=d"
  
  # suffixes to specify other exchanges
  SUFFIXES = %w|TO L PK|
  
  attr_accessor :data
  attr_accessor :prices
  attr_accessor :splits
  attr_accessor :dividends
  
  def initialize(symbol, start=nil, finish=nil)
    @symbol = identify_symbol(symbol)
    
    # the start date is either provided or five days ago
    @start = start || (Date.today - 5)
    
    # the finish date is either provided or today
    @finish = finish || Date.today
  end
  
  def data
    # initialize our data structure and retreive data on demand
    unless @data
      @data = {:prices => {}, :splits => {}, :dividends => {}}
      retreive_from_yahoo
    end
    @data
  end
  
  def prices
    data[:prices]
  end
  
  def splits
    data[:splits]
  end
  
  def dividends
    data[:dividends]
  end
  
  private
  
  def retreive_from_yahoo
    injest_data! grab_data_with_scrubyt
  end
  
  def grab_data_with_scrubyt
    # build the url for scraping
    url = SCRAPE_URL % [@symbol, @start.month-1, @start.day, @start.year, @finish.month-1, @finish.day, @finish.year]
    
    # build the xpath selector for the table rows
    tabel_sel = %q|//table[@id='yfncsumtab']//table[@class='yfnc_datamodoutline1']//tr|
    
    yahoo_data = Scrubyt::Extractor.define do
      fetch url
      
      # select the rows and grab the data out of the cells
      data tabel_sel, :example_type => :xpath do
        closed_on   %q|/td[@class='yfnc_tabledata1'][1]|
        open_price  %q|/td[@class='yfnc_tabledata1'][2]|
        high_price  %q|/td[@class='yfnc_tabledata1'][3]|
        low_price   %q|/td[@class='yfnc_tabledata1'][4]|
        close_price %q|/td[@class='yfnc_tabledata1'][5]|
        volume      %q|/td[@class='yfnc_tabledata1'][6]|
        adjusted_price %q|/td[@class='yfnc_tabledata1'][7]|
      end
      
      # follow the pagination and continue parsing
      next_page "Next"
    end
    
    yahoo_data.to_hash
  end
  
  def injest_data!(scraped_data)
    scraped_data.each do |row|
      # skip if the row is empty (header rows) or is the last row in the table
      # which simply has an informative note
      next if row.empty? || row[:closed_on] =~ /close price adjusted/i
      
      case row[:open_price]
      when /dividend/i      # is this a dividend row?
        injest_dividend!(row)
      when /stock split/i   # is this a split row?
        injest_split!(row)
      else
        injest_price!(row)  # this must be a standard price row
      end
    end
  end
  
  def injest_price!(row)
    date = normalize_date(row[:closed_on])
    data[:prices][date] = {
      :open     => row[:open_price].to_f,
      :high     => row[:high_price].to_f,
      :low      => row[:low_price].to_f,
      :close    => row[:close_price].to_f,
      :volume   => row[:volume].gsub(/,/, '').to_i,
      :adjusted => row[:adjusted_price].to_f
    }
  end
  
  def injest_split!(row)
    date = normalize_date(row[:closed_on])
    data[:splits][date] = row[:open_price].gsub(/[^0-9:]/, '')
  end
  
  def injest_dividend!(row)
    date = normalize_date(row[:closed_on])
    data[:dividends][date] = row[:open_price].gsub(/[^0-9.]/, '').to_f
  end
  
  def normalize_date(date)
    Date.parse(date.gsub(/-([0-9]{2})$/, '-20\1')).strftime('%Y-%m-%d')
  end
  
  def identify_symbol(symbol)
    ([symbol] + SUFFIXES.map{|s| "#{symbol}.#{s}"}).each do |sym|
      res = Net::HTTP.get_response(URI.parse("#{BASE_URL}?s=#{sym}"))
      return sym if res.code == '200'
    end
  end
end