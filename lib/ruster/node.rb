class Ruster::Node
  include Ruster::Util

  attr :addr
  attr :id
  attr :flags
  attr :master_id
  attr :ping_epoch
  attr :pong_epoch
  attr :config_epoch
  attr :state
  attr :slots
  attr :migrating
  attr :importing

  def initialize(addr)
    @addr = addr
  end

  def client
    @client ||= Redic.new("redis://#{addr}")
  end

  def enabled?
    res = client.call("INFO", "cluster")
    raise res if res.is_a?(RuntimeError)
    parse_info(res)[:cluster_enabled] == "1"
  end

  def read_info_line!(info_line)
    parts = info_line.split

    @id = parts.shift
    addr = parts.shift
    @flags = parts.shift.split(",")
    @addr = addr unless @flags.include?("myself")
    @master_id = parts.shift
    @ping_epoch = parts.shift.to_i
    @pong_epoch = parts.shift.to_i
    @config_epoch = parts.shift.to_i
    @state = parts.shift
    @slots = []
    @migrating = {}
    @importing = {}

    parts.map do |slots|
      case slots
      when /^(\d+)-(\d+)$/ then @slots << ($1.to_i..$2.to_i)
      when /^\d+$/ then @slots << (slots.to_i..slots.to_i)
      when /^\[(\d+)-([<>])-([a-z0-9]+)\]$/
        case $2
        when ">" then @migrating[$1.to_i] = $3
        when "<" then @importing[$1.to_i] = $3
        end
      end
    end.compact
  end

  def all_slots
    slots.map(&:to_a).flatten
  end

  def to_s
    "#{addr} [#{id}]"
  end

  def self.from_info_line(info_line)
    _, addr, _ = info_line.split
    new(addr).tap { |node| node.read_info_line!(info_line) }
  end
end
