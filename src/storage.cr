require "json"

module Storage
  extend self

  @@db : JSON::Any
  @@db = load_db
  @@groups : JSON::Any
  @@groups = load_groups

  def groups : JSON::Any # Array(Hash(String, Int64 | String))
    @@groups
  end

  def add_group(chat : Tourmaline::Chat)
    @@groups.as_a << JSON::Any.new({ "group_id" => JSON::Any.new(chat.id), "title" => JSON::Any.new(chat.title) })
    update_groups
  end

  def remove_group(chat : Tourmaline::Chat)
    @@groups.as_a.each do |group|
      if group.as_h["group_id"] == chat.id
        @@groups.as_a.delete(group)
      end
    end
    update_groups
  end

  def load_groups : JSON::Any # Array(Hash(String, Int64 | String))
    JSON.parse(File.read(Config.groups_path))
  end

  def update_groups
    File.write(Config.groups_path, @@groups.to_json)
  end

  def db : JSON::Any # Array(Hash(String, (Int64 | String | Array(Int64))))
    @@db
  end

  def add_group_to_channel(channel_id, group_id)
    @@db.as_a.each do |channel|
      next unless channel.as_h["channel_id"] == channel_id
      channel.as_h["group_ids"].as_a << JSON::Any.new(group_id)
    end
    update_db
  end

  def remove_group_from_channel(channel_id, group_id)
    @@db.as_a.each do |channel|
      next unless channel.as_h["channel_id"] == channel_id
      channel.as_h["group_ids"].as_a.delete(group_id.to_s)
    end
    update_db
  end

  def add_channel(chat : Tourmaline::Chat)
    id = chat.id
    title = chat.title ? chat.title : "no title"
    @@db.as_a << JSON::Any.new({ "channel_id" => JSON::Any.new(id), "title" => JSON::Any.new(title), "group_ids" => JSON::Any.new([] of JSON::Any) })
    update_db
  end

  def remove_channel(id)
    @@db.as_a.each do |channel|
      if channel.as_h["channel_id"] == id
        @@db.as_a.delete(channel)
        # No `break` here in case of random bugs with duplicating records
      end
    end
    update_db
  end

  def load_db : JSON::Any # Array(Hash(String, (Int64 | String | Array(Int64))))
    JSON.parse(File.read(Config.db_path))
  end

  def update_db
    File.write(Config.db_path, @@db.to_json)
  end
end
