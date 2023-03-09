require "securerandom"

class DatabasePersistence

  def initialize(session)
    @session = session
    @session[:timers] ||= []
  end

  def close_database
  end

  def timers
    @session[:timers]
  end
  
  def timer_from_id(id)
    @session[:timers].find { |list| list[:id] == id }
  end

  def create_timer(name, description)
    start_time = Time.now.to_time.to_i
    timer = { id: generate_id, name: name, description: description, start_time: start_time, paused_duration: 0}
    @session[:timers] << timer
  end

  def pause_timer(timer_id)
    timer = timer_from_id(timer_id)
    timer[:paused_time] = Time.now.to_time.to_i
  end

  def resume_timer(timer_id)
    timer = timer_from_id(timer_id)
    timer[:paused_duration] += calculate_pause(timer)
    timer[:paused_time] = nil
  end

  def complete_timer(timer_id)
    timer = timer_from_id(timer_id)
    timer[:paused_duration] += calculate_pause(timer)
    timer[:completed_time] = Time.now.to_time.to_i
  end

  def edit_timer(timer_id, name, description)
    timer = timer_from_id(timer_id)
    timer[:name] = name
    timer[:description] = description
  end

  def elapsed_time(timer_id)
    timer = timer_from_id(timer_id)
    p timer_id
    start_time = timer[:start_time]
    current_time = Time.now.to_time.to_i
    paused = timer[:paused_duration] + calculate_pause(timer)

    (start_time - current_time).abs - paused
  end

  def total_time(timer_id)
    timer = timer_from_id(timer_id)
    start_time = timer[:start_time]
    completed_time = timer[:completed_time]
    paused = timer[:paused_duration]

    (start_time - completed_time).abs - paused
  end
  

  private
  
  def calculate_pause(timer)
    return 0 unless timer[:paused_time]
    current_time = Time.now.to_time.to_i
    (current_time - timer[:paused_time]).abs
  end

  def generate_id
    SecureRandom.uuid
  end
end