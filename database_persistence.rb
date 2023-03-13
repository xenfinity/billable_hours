require "pg"
require_relative "time_calculation"

DATABASE_NAME = 'billing_app_db'
TIMERS_TABLE = 'timers'
SCHEMA_FILE = 'schema.sql'

class DatabasePersistence

  def initialize(logger)
    @logger = logger
    @db = choose_database
    @timers = @db.quote_ident(TIMERS_TABLE)
  end

  def choose_database
    if Sinatra::Base.production?
      PG.connect(ENV['DATABASE_URL'])
    else
      PG.connect(dbname: DATABASE_NAME)
    end
  end

  def close_connection
    @db.close
  end

  def query(statement, *params) 
    log_SQL(statement, params)
    @db.exec_params(statement, params)
  end

  def log_SQL(statement, params)
    log_string = <<~LOG
    \n
    SQL Query
    ---------------------
    #{statement}
    LOG
    params.each_with_index do |param, index|
      log_string += "\n$#{index + 1}: #{param}\n"
    end
    log_string += "---------------------"
    @logger.info(log_string)
  end

  def format_timer(tuple)
    paused_time = tuple["paused_time"] ? tuple["paused_time"].to_i : nil
    completed_time = tuple["completed_time"] ? tuple["completed_time"].to_i : nil
    { id: tuple["id"].to_i, 
      name: tuple["name"], 
      description: tuple["description"], 
      start_time: tuple["start_time"].to_i, 
      paused_time: paused_time, 
      completed_time: completed_time, 
      paused_duration: tuple["paused_duration"].to_i }
  end

  def format_timers(data)
    data.map do |tuple|
      p tuple
      format_timer(tuple)
    end
  end

  def timers
    timers = <<~SQL
    SELECT * FROM #{@timers};
    SQL

    data = query(timers)
    p data
    format_timers(data)

    # @session[:timers]
  end
  
  def timer_from_id(id)
    find_timer = <<~SQL
    SELECT * FROM #{@timers}
    WHERE id = $1;
    SQL

    result = query(find_timer, id)
    format_timer(result.first)
    # @session[:timers].find { |list| list[:id] == id }
  end

  def create_timer(name, description, start_time)
    create_timer = <<~SQL
    INSERT INTO #{@timers}
    (name, description, start_time)
    VALUES
    ($1, $2, $3);
    SQL

    query(create_timer, name, description, start_time)
    # 
    # timer = { id: generate_id, name: name, description: description, start_time: start_time, paused_duration: 0}
    # @session[:timers] << timer
  end

  def pause_timer(timer_id, paused_time)
    pause = <<~SQL
    UPDATE #{@timers}
    SET paused_time = $2
    WHERE id = $1;
    SQL

    query(pause, timer_id, paused_time)
    # timer = timer_from_id(timer_id)
    # timer[:paused_time] = Time.now.to_time.to_i
  end

  def resume_timer(timer_id)
    timer = timer_from_id(timer_id)
    resume = <<~SQL
    UPDATE #{@timers}
    SET paused_duration = $2,
        paused_time = NULL
    WHERE id = $1;
    SQL

    query(resume, timer_id, calculate_paused_duration(timer))
    # timer = timer_from_id(timer_id)
    # timer[:paused_duration] += calculate_pause(timer)
    # timer[:paused_time] = nil
  end

  def complete_timer(timer_id, completed_time)
    timer = timer_from_id(timer_id)
    complete = <<~SQL
    UPDATE #{@timers}
    SET paused_duration = $2,
        completed_time = $3
    WHERE id = $1;
    SQL

    query(complete, timer_id, calculate_paused_duration(timer), completed_time)
    # timer = timer_from_id(timer_id)
    # timer[:paused_duration] += calculate_pause(timer)
    # timer[:completed_time] = Time.now.to_time.to_i
  end

  def edit_timer(timer_id, name, description)
    set_name = <<~SQL
    UPDATE #{@timers}
    SET name = $2,
    SET description = $3
    WHERE id = $1;
    SQL

    query(set_name, name, description)
    # timer = timer_from_id(timer_id)
    # timer[:name] = name
    # timer[:description] = description
  end

  # def elapsed_time(timer_id)
  #   timer = timer_from_id(timer_id)
  #   start_time = timer[:start_time]
  #   current_time = Time.now.to_time.to_i
  #   paused = timer[:paused_duration] + calculate_pause(timer)

  #   (start_time - current_time).abs - paused
  # end

  # def completed_time(timer_id)
  #   timer = timer_from_id(timer_id)
  #   start_time = timer[:start_time]
  #   completed_time = timer[:completed_time]
  #   paused = timer[:paused_duration]

  #   (start_time - completed_time).abs - paused
  # end

end