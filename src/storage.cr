require "json"

module Storage
  extend self

  def load_from_json
    JSON.parse(File.read(Config.db_path))
  end

  def update_json(db)
    File.write(Config.db_path, db.to_json)
  end
end
