# Module loads only part of ActiveSupport module that is needed for rtranslate gem,
# since ActiveSupport::JSON module spoils JSON.pretty_generate nice output

require 'active_support/core_ext/module'
require 'active_support/multibyte'

require 'active_support/core_ext/string/multibyte'
class String #:nodoc:
  include ActiveSupport::CoreExtensions::String::Multibyte
end

require 'rtranslate'
require 'ping'
