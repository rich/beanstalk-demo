class Ad < ActiveRecord::Base
  async_after_create do |ad|
    ad.fetch_ad
  end
  
  def need_ad?
    url.present? && body.blank? && title.blank?
  end
  
  def fetch_ad
    return unless need_ad?
    
    values = case self.url
    when /craigslist/i
      grab_from_craigslist
    end
    
    self.body = values[:ad_body]
    self.title = values[:ad_title]
    self.save!
  end
  
  def grab_from_craigslist
    ad = Scrubyt::Extractor.define do
      fetch self.url
      ad "//body" do
        ad_title "/h2"
        ad_body "/div[@id='userbody']"
      end
    end
    ad.to_hash.first
  end
end
