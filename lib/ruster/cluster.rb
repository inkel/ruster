class Ruster::Cluster
  include Ruster::Util

  attr :entry

  SLOTS = 16384

  def initialize(entry)
    @entry = entry
  end

  def info
    @entry.cluster_info
  end

  def state
    info[:cluster_state]
  end

  def ok?
    state == "ok"
  end

  def fail?
    state == "fail"
  end

  def slots_assigned
    info[:cluster_slots_assigned].to_i
  end

  def slots_ok
    info[:cluster_slots_ok].to_i
  end

  def slots_pfail
    info[:cluster_slots_pfail].to_i
  end

  def slots_fail
    info[:cluster_slots_fail].to_i
  end

  def known_nodes
    info[:cluster_known_nodes].to_i
  end

  def size
    info[:cluster_size].to_i
  end

  def current_epoch
    info[:cluster_current_epoch].to_i
  end

  def stats_messages_sent
    info[:cluster_stats_messages_sent].to_i
  end

  def stats_messages_received
    info[:stats_messages_received].to_i
  end

  def nodes
    @entry.load!
    [@entry] + @entry.friends
  end

  def add_node(ip, port)
    @entry.meet(ip, port)
  end

  def remove_node(bye)
    nodes.each do |node|
      next if node.id == bye.id
      node.forget(bye)
    end
  end

  def self.create!(addrs)
    # Check nodes
    nodes = addrs.map do |addr|
      node = ::Ruster::Node.new(addr)

      raise ArgumentError, "Redis Server at #{addr} not running in cluster mode" unless node.enabled?
      raise ArgumentError, "Redis Server at #{addr} already exists in a cluster" unless node.only_node?
      raise ArgumentError, "Redis Server at #{addr} is not empty" unless node.empty?

      node
    end

    # Allocate slots evenly among all nodes
    slots_by_node = 0.upto(SLOTS - 1).each_slice((SLOTS.to_f / nodes.length).ceil)

    nodes.each do |node|
      slots = slots_by_node.next.to_a

      node.add_slots(*slots)
    end

    # Create cluster by meeting nodes
    entry = nodes.shift

    nodes.each { |node| entry.meet node.ip, node.port }

    new(entry)
  end

  def each(*args, &block)
    nodes.each do |node|
      yield node, node.call(*args)
    end
  end

  def reshard(target, num_slots, sources)
    raise ArgumentError, "Target node #{target} is not part of the cluster" unless in_cluster?(target)
    target.load!

    sources.each do |source|
      raise ArgumentError, "Source node #{source} is not part of the cluster" unless in_cluster?(source)
      source.load!
    end

    sources.sort_by!{ |node| -node.slots.size }

    total_slots = sources.inject(0) do |sum, node|
      sum + node.all_slots.size
    end

    sources.each do |node|
      # Proportional number of slots based on node size
      node_slots = (num_slots.to_f / total_slots * node.all_slots.size)

      node.all_slots.take(node_slots).each do |slot|
        node.move_slot!(slot, target)
      end
    end
  end

  def in_cluster?(node)
    nodes.any?{ |n| n.addr == node.addr }
  end
end
