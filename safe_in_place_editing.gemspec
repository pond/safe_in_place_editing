########################################################################
# File::    safe_in_place_editing.gemspec.rb
# (C)::     Hipposoft 2013
#
# Purpose:: Safe in-place editing. See README.rdoc for more information.
# ----------------------------------------------------------------------
#           22-Oct-2013 (ADH): Created.
########################################################################

lib = File.expand_path( '../lib', __FILE__ )
$LOAD_PATH.unshift( lib ) unless $LOAD_PATH.include?( lib )
require 'safe_in_place_editing/version'

Gem::Specification.new do | gem |
  gem.name              = 'safe_in_place_editing'
  gem.version           = SafeInPlaceEditing::VERSION
  gem.authors           = [ 'Andrew Hodgkinson'      ]
  gem.email             = [ 'ahodgkin@rowing.org.uk' ]
  gem.description       = 'Safe In Place Editing Rails extension, providing flexible HTML safe in-place editing with string and boolean type support'
  gem.summary           = 'Safe In Place Editing Rails extension'
  gem.homepage          = 'https://github.com/pond/safe_in_place_editing'

  gem.files             = Dir[ '{lib,app}/**/*' ] + [ 'MIT-LICENSE', 'README.rdoc' ]
  gem.test_files        = gem.files.grep( %r{^(test|spec|features)/} )
  gem.require_paths     = [ 'lib' ]

  gem.add_dependency( "railties", "~> 3.2" )
end
