$:.unshift(File.expand_path("../lib", File.dirname(__FILE__)))

require "protest"
require "ruster"

def with_nodes(opts={})
  options = {
             n: 3,
             init_port: 12701,
             enabled: "yes"
            }

  options.merge!(opts)

  end_port = options[:init_port] + options[:n] - 1

  tmp = Dir.mktmpdir

  pids  = []
  ports = (options[:init_port]..end_port)

  ports.each do |port|
    pids << fork do
      dir = File.join(tmp, port.to_s)

      Dir.mkdir(dir)

      args = [
              "--port", port.to_s,
              "--dir", dir,
              "--save", "",
              "--logfile", "./redis.log"
             ]

      if options[:enabled] == "yes"
        args.concat(["--cluster-enabled", "yes",
                     "--cluster-config-file", "redis.conf",
                     "--cluster-node-timeout", "5000"])
      end

      exec "redis-server", *args
    end
  end

  # Wait for redis-server to start
  sleep 0.125

  yield ports
ensure
  pids.each { |pid| Process.kill :TERM, pid }

  Process.waitall

  FileUtils.remove_entry_secure tmp
end

Protest.report_with((ENV["PROTEST_REPORT"] || "documentation").to_sym)
