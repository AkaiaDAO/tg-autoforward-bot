require "json"
require "option_parser"
require "./storage.cr"
require "./autoforwardbot.cr"
require "./tools.cr"

module Config
  extend self 

  @@config = JSON.parse(File.read(ENV["CONFIG_PATH"]))
  
  def db_path : String
    path = @@config.as_h["db_path"].as_s
    unless File.exists?(path)
      raise "Path #{path} doesn't exist; pass in the absolute path to the db file, for example: `/home/username/bot/db.json`" 
    end
    path
  end

  def owner_id : Int64
    id = @@config.as_h["owner_id"].as_i64
  end

  def admin_ids : Array(Int64)
    ids_as_any = @@config.as_h["admin_ids"].as_a
    ids = [] of Int64
    ids_as_any.each do |id|
      ids << id.as_i64
    end
    ids
  end
end

bot = AutoForwardBot.new(ENV["TG_API_KEY"])
Tools.bot = bot
bot.poll