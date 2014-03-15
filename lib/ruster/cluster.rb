class Ruster::Cluster
  include Ruster::Util

  attr :entry

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
end
