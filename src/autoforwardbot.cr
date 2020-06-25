require "tourmaline"

class AutoForwardBot < Tourmaline::Client
  @db : JSON::Any # Array(Hash(String, (Int64 | Array(Int64))))
  @db = Storage.load_from_json

  @[Command("start")]
  def start(ctx)
    user = ctx.message.from
    user_id = user.nil? ? "unaccessible" : user.id

    text = "Hello, I'm working. Your ID is `#{user_id.to_s}`. "
    if Config.admin_ids.includes?(user_id) || Config.owner_id == user_id
      text += "You're one of my admins. "
    else
      text += "You're not one of my admins. Add your user ID to the `config.json` or forget about me, if you're not my owner. "
    end

    text += "This chat ID is #{ctx.message.chat.id}"

    ctx.message.reply(text, parse_mode: "Markdown")
  end

  @[On(:channel_post)]
  def forward_message(ctx)
    ctx.channel_post.try do |message|
      @db.as_a.each do |rec|
        if rec.as_h["channel_id"].as_i64 == message.chat.id
          rec.as_h["group_ids"].as_a.each do |group_id|
            message.forward(group_id.as_i64)
          end
        end
      end
    end
  end
end
