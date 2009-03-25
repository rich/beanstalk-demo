class DailyEntry < ActiveRecord::Base
  belongs_to :stock
  
  named_scope :oldest_first, :order => "created_on asc"
end
