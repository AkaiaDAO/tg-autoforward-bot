require "json"
require "option_parser"
require "./storage.cr"
require "./autoforwardbot.cr"
require "./tools.cr"

parser = OptionParser.new do |parser|
  parser.on("-c", "--config", "Path to config.json") do |path|
    Config.path = path
  end
end

parser.parse

module Config
  extend self 

  @@path : String | Nil

  def path=(path)
    @@path = path
  end

  def config : JSON::Any
    JSON.parse(File.read(@@path.not_nil!))
  end
  
  def db_path : String
    path = config.as_h["db_path"].as_s
    unless File.exists?(path)
      raise "Path #{path} doesn't exist; pass in the absolute path to the db file, for example: `/home/username/bot/db.json`" 
    end
    path
  end

  def groups_path : String
    path = config.as_h["groups_path"].as_s
    unless File.exists?(path)
      raise "Path #{path} doesn't exist; pass in the absolute path to the groups file, for example: `/home/username/bot/groups.json`" 
    end
    path
  end

  def update_config!
    File.write(ENV["CONFIG_PATH"], config.to_json)
  end

  def owner_id : Int64
    id = config.as_h["owner_id"].as_i64
  end

  def admin_ids : Array(Int64)
    ids_as_any = config.as_h["admin_ids"].as_a
    ids = [] of Int64
    ids_as_any.each do |id|
      ids << id.as_i64
    end
    ids
  end

  def add_admin(id : Int64)
    config.as_h["admin_ids"].as_a << JSON::Any.new(id)
    update_config!
  end

  def remove_admin(id : Int64)
    config.as_h["admin_ids"].as_a.delete(id)
    update_config!
  end
end

bot = AutoForwardBot.new(ENV["TG_API_KEY"])
Tools.bot = bot
bot.poll