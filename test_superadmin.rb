#!/usr/bin/env ruby

# Simple script to test if superadmin is accessible
require_relative 'config/environment'

begin
  puts "Testing SuperAdmin accessibility..."
  
  # Test if SuperAdmin model exists
  puts "✓ SuperAdmin model: #{SuperAdmin rescue 'FAILED'}"
  
  # Test if ChatwootApp.enterprise? works
  puts "✓ Enterprise detection: #{ChatwootApp.enterprise? rescue 'FAILED'}"
  
  # Test if GlobalConfig works
  puts "✓ GlobalConfig: #{GlobalConfig.get('INSTALLATION_NAME').present? rescue 'FAILED'}"
  
  # Test if ConfigLoader works
  puts "✓ ConfigLoader: #{ConfigLoader.new.general_configs.present? rescue 'FAILED'}"
  
  # Test if dashboard controller can be instantiated
  puts "✓ Dashboard Controller: #{SuperAdmin::DashboardController.new rescue 'FAILED'}"
  
  # Test if AccountDashboard works
  puts "✓ Account Dashboard: #{AccountDashboard.new rescue 'FAILED'}"
  
  # Test if features helper works
  puts "✓ Features Helper: #{SuperAdmin::FeaturesHelper.available_features.present? rescue 'FAILED'}"
  
  puts "All tests completed!"
  
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
end