class Range
  def split_by_days(days)
    return unless self.begin.is_a?(Date) && self.end.is_a?(Date)
    
    start = self.begin
    finish = self.end
    current_start = start
    current_finish = start + days
    
    ranges = []
    loop do
      if current_finish > finish
        ranges << (current_start..finish)
        break
      else
        ranges << (current_start..current_finish)
      end
      current_start = current_finish + 1
      current_finish = current_finish + days
    end
    ranges
  end
end
