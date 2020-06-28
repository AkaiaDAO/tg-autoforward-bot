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
    id_list.each_with_index do |id, index|
      output += "\n"
      output += (index + 1).to_s
      output += prettify(id)
    end
    output
  end

  def group_list_ids(groups)
    output = [] of String
    Storage.groups.as_a.each do |gr_group|
      groups.as_a.each do |arg_group| 
        if gr_group.as_h["group_id"] == arg_group
          id = gr_group.as_h["group_id"]
          title = gr_group.as_h["title"]
          output << "     #{title} (`#{id}`)"
        end
      end
    end
    output.join("\n")
  end

  def group_list_hashes(groups = Storage.groups)
    output = [] of String
    Storage.groups.as_a.each do |gr_group|
      groups.as_a.each do |arg_group| 
        if gr_group.as_h["group_id"] == arg_group.as_h["group_id"]
          id = gr_group.as_h["group_id"]
          title = gr_group.as_h["title"]
          output << "     #{title} (`#{id}`)"
        end
      end
    end
    output.join("\n")
  end

  def channel_list
    output = [] of String
    Storage.db.as_a.each do |channel|
      id = channel.as_h["channel_id"]
      title = channel.as_h["title"]
      groups = channel.as_h["group_ids"]

      output << "#{title} (`#{id}`)
Forwarding to:
#{group_list_ids(groups)}"
    end
    output.join("\n")
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
