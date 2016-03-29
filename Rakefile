# frozen_string_literal: true
# Add your own tasks in files placed in lib/tasks ending in .rake, for
# example lib/tasks/capistrano.rake, and they will automatically be available
# to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake/dsl_definition'
require 'rake'
# rubocop:disable HandleExceptions
begin; require 'parallel_tests/tasks'; rescue LoadError; end
# rubocop:enable HandleExceptions
Reservations::Application.load_tasks
