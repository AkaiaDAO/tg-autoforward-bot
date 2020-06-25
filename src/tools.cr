require "./main.cr"

module Tools
  extend self

  @@bot = AutoForwardBot.new(ENV["TG_API_KEY"])

  def bot=(bot : AutoForwardBot)
    @@bot = bot
  end

  def bot : AutoForwardBot
    @@bot
  end

  def admin_list : String
    owner_id = Config.owner_id
    admin_ids = Config.admin_ids
    output = "Owner: #{prettify(owner_id)}
Admins:"
    output += prettify(admin_ids)
    output
  end

  def prettify(id : Int64) : String
    begin
      link(@@bot.not_nil!.get_chat_member(id, id).user)
    rescue exception
      puts exception.message
      "<a href='tg://user?id=#{id}'>#{id}</a>"
    end
  end

  def prettify(id_list : Array(Int64)) : String
    output = ""
    id_list.each do |id|
      output += "\n"
      output += prettify(id)
    end
    output
  end

  def link(user : Tourmaline::User) : String
    id = user.id
    first_name = user.first_name
    last_name = user.last_name

    unless last_name
      return "<a href='tg://user?id=#{id}'>#{HTML.escape(first_name)}</a>"
    end

    "<a href='tg://user?id=#{id}'>#{HTML.escape(first_name)} #{HTML.escape(last_name)}</a>"
  end
end
