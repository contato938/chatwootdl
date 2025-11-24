# This file is used by Rack-based servers to start the application.

# Attempt to increase file descriptor limit immediately
begin
  Process.setrlimit(:NOFILE, 65536)
rescue Exception => e
  warn "Failed to set ulimit: #{e.message}"
end

begin
  require_relative 'config/environment'
  run Rails.application
rescue Exception => e
  # If Rails fails to load, start a simple Rack app to show the error
  # This ensures the container stays alive and we can see what happened
  run lambda { |env|
    [
      200,
      { 'Content-Type' => 'text/html' },
      [
        "<html><head><title>Boot Error</title></head><body>",
        "<h1>Application Failed to Start</h1>",
        "<h2>Error: #{e.message}</h2>",
        "<pre>#{e.backtrace.join("\n")}</pre>",
        "<hr>",
        "<h3>Environment Variables:</h3>",
        "<pre>#{ENV.to_h.map { |k,v| "#{k}=#{v}" }.join("\n")}</pre>",
        "</body></html>"
      ]
    ]
  }
end
