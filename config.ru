require 'rack'
require 'main'

use Rack::Session::Cookie,
  :key    => 'storymap.puppetlabs.com',
  :secret => 'holyfuckingshityoudbetterwork'

run StoryMapApp
