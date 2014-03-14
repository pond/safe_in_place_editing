require 'safe_in_place_editing/version'
require 'safe_in_place_editing/controller_methods'
require 'safe_in_place_editing/helper_methods'

if defined? ActionController
  ActionController::Base.send :include, SafeInPlaceEditing
  ActionController::Base.helper SafeInPlaceEditingHelper
end

module SafeInPlaceEditing
  class Engine < ::Rails::Engine
  end
end