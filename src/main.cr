require "json"
require "option_parser"
require "./storage.cr"
require "./autoforwardbot.cr"

module Config
  extend self 

  @@config_path = " "
  
  def path=(path : String)
    @@config_path = path
  end

  def path
    @@config_path
  end

  def config_hash
    json_string = File.read(@@config_path)
    config = JSON.parse(json_string)
  end

  def db_path : String
    path = config_hash["db_path"].as_s
    unless File.exists?(path)
      raise "Path #{path} doesn't exist; pass in the absolute path to the config file, for example: `/home/username/bot/db.json`" 
    end
    path
  end

  def owner_id : Int64
    id = config_hash["owner_id"].as_i64
  end

  def admin_ids : Array(Int64)
    ids_as_any = config_hash["admin_ids"].as_a
    ids = [] of Int64
    ids_as_any.each do |id|
      ids << id.as_i64
    end
    ids
  end
end

option_parser = OptionParser.parse do |parser|
  parser.on("-p PATH", "Pass the absolute path to the config.json") do |path|
    unless File.exists?(path)
      raise "Path `#{path}` doesn't exist; pass in the absolute path to the config file, for example: `/home/username/bot/config.json`"
    end
    Config.path = path
  end
end

puts "Launching the bot..."
bot = AutoForwardBot.new(ENV["TG_API_KEY"])
puts "Bot object created"
bot.poll