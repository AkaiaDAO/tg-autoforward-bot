require "tourmaline"
require "../lib/tourmaline/src/tourmaline/extra/stage.cr"

module Tools
  extend self
  @@counter = 0

  def counter
    @@counter
  end

  def inc_counter
    @@counter += 1
  end
end

class AutoForwardBot < Tourmaline::Client
  ROOT_MENU = ReplyKeyboardMarkup.build do
    button "🔢 Show all channels"
    button "✍️ Edit a channel"
  end

  EDIT_CHANNEL_MENU = ReplyKeyboardMarkup.build do
    button "📌 Add a group"
    button "✂ Delete a group"
    button "❌ Delete the channel!"
  end

  @[Command("menu")]
  def menu(ctx)
    ctx.message.from.try do |user|
      if Config.admin_ids.includes?(user.id)
        # ctx.message.respond_with_menu(ADMIN_MENU)
      elsif Config.owner_id == user.id
        ctx.message.respond("Choose what you want to do:", reply_markup: ROOT_MENU)
      else
        ctx.message.reply("You're not an admin.")
      end
    end
  end

  @[Hears("🔢 Show all channels")]
  def show_channels(ctx)
    ctx.message.reply(Tools.channel_list, parse_mode: ParseMode::Markdown)
  end


  @[Hears("✍️ Edit a channel")]
  def edit_channel(ctx)
    initial_context = {  } of String => Int64 | String
    stage = EditChannel.enter(self, chat_id: ctx.message.chat.id, context: initial_context)

    stage.on_exit do |answers|
      case answers["task"]
      when "add_group"
        Storage.add_group_to_channel(answers["channel_id"], answers["group_id"])
      when "delete_group"
        Storage.remove_group_from_channel(answers["channel_id"], answers["group_id"])
      when "delete_channel"
        Storage.remove_channel(answers["channel_id"]) 
      end
      ctx.message.respond("Done!", reply_markup: ROOT_MENU)
    end
  end

  class EditChannel(T) < Stage(T)
    @[Step(:get_id, initial: true)]
    def get_id(client)
      client.send_message(self.chat_id, "Send me the ID of the channel you want to edit")
      self.await_response do |update|
        text = update.message.try &.text
        if message = update.message && text.to_s =~ /-\d+/
          self.context["channel_id"] = text.to_s.to_i64

          self.transition :get_option
        end
      end
    end

    @[Step(:get_option)]
    def get_option(client)
      client.send_message(self.chat_id, "What do you want to do with it?", reply_markup: EDIT_CHANNEL_MENU)
      self.await_response do |update|
        text = update.message.try &.text
        if message = update.message
          if text.to_s == "📌 Add a group"
            self.transition :add_group
          elsif text.to_s == "✂ Delete a group"
            self.transition :delete_group
          elsif text.to_s == "❌ Delete the channel!"
            self.context["task"] = "delete_channel"
            self.exit
          end
        end
      end
    end

    @[Step(:add_group)]
    def add_group(client)
      client.send_message(self.chat_id, "Here are all the groups I'm in. Send me the ID of the one you want to add:")
      client.send_message(self.chat_id, Tools.group_list_hashes, parse_mode: "Markdown")
      self.await_response do |update|
        text = update.message.try &.text
        if message = update.message && text.to_s =~ /-\d+/
          self.context["group_id"] = text.to_s.to_i64
          self.context["task"] = "add_group"

          self.exit
        end
      end
    end

    @[Step(:delete_group)]
    def delete_group(client)
      client.send_message(self.chat_id, "Here are all the groups this channel forwards to. Send me the ID of the one you want to remove:")
      Storage.db.as_a.each do |channel|
        next unless channel.as_h["channel_id"] == self.context["channel_id"]
        client.send_message(self.chat_id, Tools.group_list_ids(channel.as_h["group_ids"]), parse_mode: "Markdown")
        break
      end
      self.await_response do |update|
        text = update.message.try &.text
        if message = update.message && text.to_s =~ /-\d+/
          self.context["group_id"] = text.to_s.to_i64
          self.context["task"] = "delete_group"

          self.exit
        end
      end
    end
  end

  # @[Command("add_admin")]
  # def add_admin(ctx)
  #   ctx.message.from.try do |user|
  #     if Config.owner_id == user.id && ctx.text
  #       Config.add_admin(ctx.text.to_i64)
  #     end
  #   end
  # end

  # @[Command("remove_admin")]
  # def remove_admin(ctx)
  #   ctx.message.from.try do |user|
  #     if Config.owner_id == user.id && ctx.text
  #       id = Config.admin_ids[ctx.text.to_i64 - 1]
  #       Config.remove_admin(id.to_i64)
  #     end
  #   end
  # end

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
  def register_channel(ctx)
    ctx.channel_post.try do |post|
      unless Storage.db.as_a.any? { |channel| channel.as_h["channel_id"] == post.chat.id }
        Storage.add_channel(post.chat)
      end
    end
  end

  @[On(:message)]
  def register_group(ctx)
    ctx.message.try do |post|
      if !Storage.groups.as_a.includes?(post.chat.id) && (post.chat.type == "group" || post.chat.type == "supergroup")
        Storage.add_group(post.chat)
      end
    end
  end

  @[On(:channel_post)]
  def forward_message(ctx)
    ctx.channel_post.try do |message|
      Storage.db.as_a.each do |rec|
        if rec.as_h["channel_id"].as_i64 == message.chat.id
          rec.as_h["group_ids"].as_a.each do |group_id|
            message.forward(group_id.as_i64)
          end
        end
      end
    end
  end
end
