require "rubygems"
require "xmpp4r"
require "xmpp4r/message"
require "xmpp4r/roster"
require "yaml"
include Jabber

Jabber::debug = true

def load_config()
  $settings = YAML::load_file("config.yaml")
  $jsettings = $settings["Jabber"];
end

load_config();

client = Client.new(JID::new($jsettings["JID"]));
client.connect($jsettings["Server"]);
client.auth($jsettings["Pass"]);
client.send(Presence.new.set_type(:available))

roster = Roster::Helper.new(client)

roster.add_subscription_request_callback do |item,pres|
  roster.accept_subscription(pres.from)
end

$commands = Hash.new

def add_command(cmd, &block)
  $commands[cmd] = block
end

add_command "tweet" do |m, s|
    msg = Message.new("arelius@gmail.com", "Received #{m.body}");
    msg.type=:chat
    client.send(msg);
end

client.delete_message_callback("process_message")
client.add_message_callback 0, "process_message" do |m|
  if($jsettings["Privl"].include?(m.from.bare.to_s.downcase))
    bdy = m.body.to_s;
    cmd = bdy.split[0].downcase;
    s = bdy[cmd.length..bdy.length].strip
    p = $commands[cmd];
    if(p)
        p.call(m, s);
    end
  end
end
