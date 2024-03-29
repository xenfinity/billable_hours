def calculate_pause(paused_time)
  return 0 unless paused_time
  current_time = Time.now.to_time.to_i

  (current_time - paused_time).abs
end

def calculate_paused_duration(timer)
  paused_time = timer[:paused_time]
  paused_duration = timer[:paused_duration]

  paused_duration + calculate_pause(paused_time)
end

def calculate_elapsed(timer)
  start_time = timer[:start_time]
  current_time = Time.now.to_time.to_i
  paused_time = timer[:paused_time]
  paused = timer[:paused_duration] + calculate_pause(paused_time)
  (start_time - current_time).abs - paused
end

def calculate_completed(timer)
  start_time = timer[:start_time]
  completed_time = timer[:completed_time]
  paused = timer[:paused_duration]

  (start_time - completed_time).abs - paused
end

def format_duration(seconds)
  return 'now' if seconds == 0

  seconds_map = {
    31536000 => :year,
    86400 => :day,
    3600 => :hour,
    60 => :minute,
    1 => :second
  }

  count = {
    second: 0,
    minute: 0,
    hour: 0,
    day: 0,
    year: 0
  }

  # find count of each unit of time
  seconds_map.each {|num_sec, unit|
    if seconds/num_sec >= 1
      count[unit] = seconds/num_sec
      seconds -= num_sec * count[unit]
    end
  }

  # build string from hash
  count.select! {|_, value| value != 0}
  result = ""
   
  first = count.keys[0]
  second = count.keys[1]

  count.each {|unit, value| 
    result.prepend(" and ") if unit == second
    
    current = "#{value} #{unit.to_s}"
    current << 's' if value > 1
    current << ', ' unless unit == first || unit == second

    result.prepend(current)
  }
  result
end

