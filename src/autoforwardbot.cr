require "tourmaline"
require "../lib/tourmaline/src/tourmaline/extra/routed_menu.cr"

class AutoForwardBot < Tourmaline::Client
  @db : JSON::Any # Array(Hash(String, (Int64 | Array(Int64))))
  @db = Storage.load_from_json

  MY_MENU = RoutedMenu.build do
    route "/" do
      content "Choose an option:"
      buttons(columns: 2) do
        route_button "Change admins", to: "/admins"
        route_button "Change forwarding options", to: "/forwarding"
      end
    end

    route "/admins" do
      parse_mode Tourmaline::ParseMode::HTML
      content Tools.admin_list
      buttons do
        back_button "Back"
      end
    end


  end

  @[Command("menu")]
  def menu(ctx)

    ctx.message.respond_with_menu(MY_MENU)
  end

  @[Command("info")]
  def info(ctx)
    user = ctx.message.from
    user_id = user.nil? ? "unaccessible" : user.id
    if Config.admin_ids.includes?(user_id) || Config.owner_id == user_id
      text = "Add me to all the channels you want to forward from (only as a channel admin); then, add me to all the groups you want to forward to.
Once that's set up, press /menu and follow the instructions."
    else
      text = "You're not one of my admins."
    end
    ctx.message.reply(text)
  end

  @[Command("start")]
  def start(ctx)
    user = ctx.message.from
    user_id = user.nil? ? "unaccessible" : user.id

    text = "Hello, I'm working. Your ID is `#{user_id.to_s}`. "
    if Config.admin_ids.includes?(user_id) || Config.owner_id == user_id
      text += "You're one of my admins. Use /info to see what to do. "
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

  def prettify

  end
end
